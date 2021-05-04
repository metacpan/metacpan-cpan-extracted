package Net::Async::DigitalOcean::RateLimited;

use strict;
use warnings;
use Data::Dumper;

use Net::Async::HTTP;
use parent qw( Net::Async::HTTP );

sub prepare_request {
    my ($elf, $req) = @_;
#warn "prepare $elf";
    $elf->SUPER::prepare_request( $req );
    warn $req->as_string . " >>>> DigitalOcean" if $elf->{digitalocean_trace};

    if (my $limits = $elf->{digitalocean_rate_limit}) {                       # if we already experienced some limit information from the server
#warn "rate_limit current ".Dumper $limits;  # 

	my $backoff = $elf->{digitalocean_rate_limit_backoff} //= 0;          # default is to not wait

	my $absolute = $elf->{digitalocean_rate_limit_absolute} //= {         # compile it the policy into absolute values
	    map { ( $_ =~ /(\d+)\%/ 
		          ? $limits->{Limit} * $1 / 100
		          : $_) => $elf->{digitalocean_rate_limit_policy}->{$_} }
	    keys %{ $elf->{digitalocean_rate_limit_policy} } 
	};
#warn "absolute ".Dumper $absolute;
#warn "remaining ".$limits->{Remaining};
	foreach my $threshold ( sort keys %$absolute ) {                      # analyse - starting from the lowest
#warn "limit found $limits->{Remaining} < $threshold";
	    if ($limits->{Remaining} < $threshold) {                          # if we are already under that
		$backoff = &{$absolute->{ $threshold }} ( $backoff );         # compute new backoff, following the expression provided
		$backoff = 0 if $backoff < 0;                                 # dont want to go negative here
#warn "\\_ NEW backoff $backoff";
		last;                                                         # no further going up
	    }
	}
	
	$elf->{digitalocean_rate_limit_backoff} = $backoff;
#warn "have to wait $backoff ".$elf->loop;
	$elf->loop->delay_future( after => $backoff )->get if $backoff > 0;
#warn "\\_ done waiting";
    }

    return $req;
};

sub process_response {
    my ($elf, $resp) = @_;
    warn "DigitalOcean >>>> ".$resp->as_string if $elf->{digitalocean_trace};

    if ($elf->{digitalocean_rate_limit_policy}) { # if this is turned on
	if (my $limit = $resp->headers->header('RateLimit-Limit')) { # and if we actually got something
	    $elf->{digitalocean_rate_limit} = { Limit     => $limit,
						Remaining => $resp->headers->header('RateLimit-Remaining'),
						Reset     => $resp->headers->header('RateLimit-Reset'), };
	}
    }
    $elf->SUPER::process_response( $resp );
}

1;

package Net::Async::DigitalOcean;

use strict;
use warnings;

use JSON;
use Data::Dumper;
use HTTP::Status qw(:constants);

use Moose;

our $VERSION = '0.04';

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
no warnings 'once';
our $log = Log::Log4perl->get_logger("nado");

=head1 NAME

Net::Async::DigitalOcean - Async client for DigitalOcean REST APIv2

=head1 SYNOPSIS

    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new;      # the god-like event loop

    use Net::Async::DigitalOcean;
    my $do = Net::Async::DigitalOcean->new( loop => $loop );
    $do->start_actionables;               # activate polling incomplete actions

    # create a domain, wait for it
    $do->create_domain( {name => "example.com"} )
       ->get;   # block here

    # create a droplet, wait for it
    my $dr = $do->create_droplet({
	"name"       => "www.example.com",
	"region"     => "nyc3",
	"size"       => "s-1vcpu-1gb",
	"image"      => "openfaas-18-04",
	"ssh_keys"   => [],
	"backups"    => 'true',
	"ipv6"       => 'true',
	"monitoring" => 'true',
				  })
       ->get; $dr = $dr->{droplet}; # skip type

    # reboot
    $do->reboot(id => $dr->{id})->get;
    # reboot all droplets tagged with 'prod:web'
    $do->reboot(tag => 'prod:web')->get;

    

=head1 OVERVIEW

=head2 Platform

L<DigitalOcean|https://www.digitalocean.com/> is a cloud provider which offers you to spin up
servers (droplets) with a specified OS, predefined sizes in predefined regions. You can also procure
storage volumes, attach those to the droplets, make snapshots of the volumes or the whole
droplet. There are also interfaces to create and manage domains and domain record, ssh keys, various
kinds of images or tags to tag the above things. On top of that you can build systems with load
balancers, firewalls, distributable objects (Spaces, similar to Amazon's S3). Or, you can go along
with the Docker pathway and/or create and run kubernetes structures.

See the L<DigitalOcean Platform|https://docs.digitalocean.com/products/platform/> for more.

DigitalOcean offers a web console to administrate all this, but also a
L<RESTy interface|https://docs.digitalocean.com/reference/api/>.

=head2 REST API, asynchronous

This client library can be used by applications to talk to the various DigitalOcean REST endpoints. But in contrast
to similar libraries, such as L<DigitalOcean> or L<WebService::DigitalOcean>, this library operates in I<asynchronous> mode:

Firstly, all HTTP requests are launched asynchronously, without blocking until their respective responses come in.

But more importantly, L<long-lasting actions|https://www.digitalocean.com/community/tutorials/how-to-use-and-understand-action-objects-and-the-digitalocean-api>, 
such as creating a droplet, snapshoting volumes or rebooting a set of droplets are handled by the
library itself; the application does not need to keep track of these open actions, or keep polling
for their completion.

The way this works is that the application first has to create the event loop and - with it -
create a handle to the DigitalOcean API server:

    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    use Net::Async::DigitalOcean;
    my $do = Net::Async::DigitalOcean->new( loop => $loop );
    $do->start_actionables;

You also should start a timer I<actionables>. In regular intervals it will check with the
server, whether open actions have been completed or not.

With that, every method (except a few) return a L<Future> object, such when creating
a droplet:

    my $f = $do->create_droplet({
	"name"       => "example.com",
	"region"     => "nyc3",
	"size"       => "s-1vcpu-1gb",
	"image"      => "openfaas-18-04",
        ....
				  });

The application can either choose to wait synchronously:

    my $d = $f->get; # wait, and receive the response as HASH

or, alternatively, can specify what should happen once the result comes in:

    $f->on_done( sub { my $d = shift;
                       warn "droplet $d->{droplet}->{name} ready (well, almost)"; } );

Futures can also be combined in various ways; one extremely useful is to wait for several actions to
complete in one go:

    Future->wait_all(
                      map { $do->create_volume( ... ) }
                      qw(one two another) )->get;

=head2 Success and Failure

When futures succeed, the application will usually get a result in form of a Perl HASH (see below). If
a future fails and the failure is not handled specifically (by adding a C<< ->on_fail >> handler),
then an exception will be raised. The library tries to figure out what the real message from the
server was.

=head2 Data Structures

Another difference to other libraries in this arena is that it does not try to artifically
I<objectify> things into classes, such as for the I<droplet>, I<image> and other concepts.

Instead, the library truthfully transports Perl HASHes and LISTs via JSON to the server and back;
even to the point to B<exactly> reflect the L<API specification|https://developers.digitalocean.com/documentation/v2/> .
That way you can always look up what to precisely expect as result.

But as the server chooses to I<type> results, the application will have to cope with that

    my $d = $do->create_droplet({
	"name"       => "example.com",
        ....
	                        })->get;
    $d = $d->{droplet}; # now I have the droplet itself

=for readme include file="INSTALLATION" type="pod"

=for readme stop

=head2 Caveat Rate-Limiting

To avoid being swamped the DigitalOcean server enforces several measures to limit abuse:

=over

=item * Limit on the number of HTTP requests within a certain time window.

In the current version this client is rather aggressively trying to get things done. If you get
too many TOO_MANY_REQUESTS errors, you may want to increase the poll time of actions (see C<actionables>).

Future version will support policies to be set by the application.

=item * Limit on the total number of droplets to be created

Such a case will result in an exception.

=item * Limit on the number of droplets to be created in one go

Such a case will result in an exception.

=item * Limit in the number of snapshots

In that case the client will wait for the indicated time. That may well be several minutes!

=item * Limit in the size of volumes

Such a case will result in an exception.

=item * Limit in the size of droplets

Such a case will result in an exception.

=back

=head1 INTERFACE

There is only one object class here, that of the I<DigitalOcean> handle. All its methods - unless
specifically mentioned - typically return one L<Future> object.

=head2 Constants

=over

=item * DIGITALOCEAN_API (string)

Base HTTP endpoint for the DigitalOcean APIv2

=back

=cut

use constant DIGITALOCEAN_API => 'https://api.digitalocean.com/v2';

=pod

=head2 Constructor

=cut

has 'loop'                 => (isa => 'IO::Async::Loop',             is => 'ro' );
has '_http'                => (isa => 'Net::Async::HTTP',	     is => 'ro' );
has 'endpoint'             => (isa => 'Str',		             is => 'ro' );
has '_actions'             => (isa => 'HashRef', 		     is => 'ro', default => sub { {} });
has '_actionables'         => (isa => 'IO::Async::Timer::Periodic',  is => 'rw' );
has 'rate_limit_frequency' => (isa => 'Int|Undef',                   is => 'ro', default => 2);
has 'bearer'               => (isa => 'Str|Undef',                   is => 'ro' );

=pod

Following fields are honored:

=over

=item * C<loop> (required; L<IO::Async::Loop>)

Event loop to keep things going.


=item * C<endpoint> (optional; string)

If this field is completely omitted, then the DigitalOcean endpoint is chosen as default.

If the field exists, but is kept C<undef>, then the environment variable C<DIGITALOCEAN_API> is
consulted. If that is missing, then an exception is raised.

If the field exists, and the value is defined, it will be used.

=item * C<bearer> (optional; string)

To be authenticated to the official DigitalOcean endpoints the library will have to send
an C<Authentication> HTTP header with the I<bearer information> to the server. Once you
have an account, you can L<create such a bearer token|https://docs.digitalocean.com/reference/api/create-personal-access-token/>.

If this C<bearer> field is missing or C<undef>, then the environment variable C<DIGITALOCEAN_BEARER>
will be consulted. If there is no such token, and the endpoint is the official one, an exception
will be raised. Otherwise, the missing bearer is tolerated (as you would if you test against a local
server).

=item * C<throtteling> (optional; string)

I<This is currently not implemented.>

=item * C<tracing> (optional; any value)

If set to something non-zero, then a HTTP trace (sending and receiving, headers and body) is written to
C<STDERR>. This helps tremendously during debugging.

=item * C<rate_limit_frequency> (optional; integer; in seconds; default 5)

This time interval is used to regularily poll the server for incomplete actions. Note, that for that
to happen, you have to start/stop the timer explicitly:

   $do->start_actionables; # from now on do something with DigitalOcean
   $do->stop_actionables;  # dont need it anymore

=back

=cut

our $POLICY = {
    SUPER_DEFENSIVE => { 
       '100%' => sub { 0; },
	'70%' => sub { $_[0] +  1; },
	'50%' => sub { $_[0] +  2; },
	'30%' => sub { $_[0] + 10; },
    } 
};

# 

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my %options = @_;

    $log->logdie ("IO::Async::Loop missing") unless $options{loop};

    my $endpoint = exists $options{endpoint}   # if user hinted that ENV can be used
                      ? delete $options{endpoint} // $ENV{DIGITALOCEAN_API}
                      : DIGITALOCEAN_API;
    $endpoint or $log->logdie ("no testing endpoint provided");

    my $bearer = delete $options{bearer} // $ENV{DIGITALOCEAN_BEARER}; # might be undef
    $log->logdie ("bearer token missing") if ! defined $bearer && $endpoint eq DIGITALOCEAN_API;

    my $throtteling = delete $options{throtteling} // $ENV{DIGITALOCEAN_THROTTELING}; # might be undef
    $throtteling = 1 if $endpoint eq DIGITALOCEAN_API; # no way around this

    my $tracing  = delete $options{tracing}; # only via that path

    use HTTP::Cookies;
    my $http = Net::Async::DigitalOcean::RateLimited->new(
	user_agent => "Net::Async::DigitalOcean $VERSION",
#	timeout    => 30,
	cookie_jar => HTTP::Cookies->new( 
	    file     => "$ENV{'HOME'}/.digitalocean-perl-cookies",
	    autosave => 1, ),
	);
    $http->configure( +headers => { 'Authorization' => "Bearer $bearer" } ) if defined $bearer;
    $http->{digitalocean_trace}             = 1                             if $tracing;
    $http->{digitalocean_rate_limit_policy} = $POLICY->{SUPER_DEFENSIVE}    if $throtteling;

    $options{loop}->add( $http );

    return $class->$orig (%options,
                          _http        => $http,
			  endpoint     => $endpoint,
			  bearer       => $bearer,
                          );
};

=pod

=head2 Methods

=head3 Polling the Server

=over

=item * C<start_actionables> ([ C<$interval> ])

This starts the timer. The optional interval integer overrides what the C<$do> object would use as
default.

=cut

sub start_actionables {
    my ($elf, $interval) = @_;

    $interval //= $elf->rate_limit_frequency;

    use IO::Async::Timer::Periodic;
    my $actionables = IO::Async::Timer::Periodic->new(
	interval => $interval,
	on_tick => sub {
#warn "tick";
	    my $actions = $elf->_actions; # handle

#	    my %done; # collect done actions here
	    foreach my $action ( values %$actions ) {
		my ($a, $f, $u, $r) = @$action;
# warn "looking at ".Dumper $a, $u, $r;
		next if $a->{status} eq 'completed';
		next unless defined $u;   # virtual actions
		$log->debug( "probing action $a->{id} for ".($a->{type}//$a->{rel}));
#warn "not completed asking for ".$a->{id}.' at '.$u;
# TODO type check
		my $f2 = _mk_json_GET_future( $elf, $u );
		$f2->on_done( sub {
#warn "action returned ".Dumper \@_;
		    my ($b) = @_; $b = $b->{action};
#warn "asking for action done, received ".Dumper $b;
		    if ($b->{status} eq 'completed') {
#warn "!!! completed with result $r".Dumper $r;
			if ($f->is_done) {                                   # this future has already been completed, THIS IS STRANGE
			    $log->warn("already completed action $a->{id} was again completed, ignoring...");
			} else {
			    $action->[0] = $b;                               # replace the pending action with the completed version
			    $f->done( $r ); # if                             # report this as done, but ...
			}
		    } elsif ($b->{status} eq 'errored') {
			$f->fail( $b );
		    }                                                        # not completed: keep things as they are
			      } );
	    }
#warn "done ".Dumper [ keys %done ];
#	    delete $actions->{$_} for keys %done;                 # purge actions
	},
	);
    $elf->_actionables( $actionables );
    $elf->_http->loop->add( $actionables );
    $actionables->start;
}

=pod

=item * C<stop_actionables>

Simply stops the timer. At any time it can be restarted.

=cut

sub stop_actionables {
    my ($elf) = @_;
    $elf->_actionables->stop;
}

=pod

=back

=cut
    
#-- helper functions ---------------------------------------------------------------

sub _mk_json_GET_futures {
    my ($do, $path) = @_;

    $log->debug( "launching futures GET $path" );
    my $f = $do->_http->loop->new_future;
#warn "futures setup ".$do->endpoint . $path;
    $do->_http->GET(  $do->endpoint . $path  )
             ->on_done( sub {
		 my ($resp) = @_;
#warn "futures resp ".Dumper $resp;
		 if ($resp->is_success) {
		     if ($resp->content_type eq 'application/json') {
			 my $data = from_json ($resp->content);
			 if ($data->{links} && (my $next = $data->{links}->{next})) {     # we found a continuation
#warn "next $next";
			     $next  =~ /page=(\d+)/ or $log->logdie ("cannot find next page inside '$next'");
                             my $page = $1;
			     if ( $path =~ /page=/ ) {
				 $path =~ s/page=\d+/page=$page/;
			     } elsif ($path =~ /\?/) {
				 $path .= "&page=$page"
			     } else {
				 $path .= "?page=$page";
			 }
#warn "pager $page path '$path'";
			     $f->done( $data, $do->_mk_json_GET_futures( $path ) );
			 } else {
			     $f->done( $data, undef );
			 }
		     } else {
			 $f->fail( "sizes not JSON" );
		     }
		 } else {
		     my $message = $resp->message; chop $message;
		     $f->fail( $message );
		 }
			} )
	     ->on_fail( sub {
		 my ( $message ) = @_;
		 $log->logdie ("message from server '$message'");
			} );
    return $f;
}

sub _mk_json_GET_future {
    my ($do, $path) = @_;

    $log->debug( "launching future GET $path" );
    my $f = $do->_http->loop->new_future;
    $do->_http->GET(  $do->endpoint . $path  )
             ->on_done( sub {
		 my ($resp) = @_;
#warn Dumper $resp;
		 if ($resp->is_success) {
		     if ($resp->content_type eq 'application/json') {
			 $f->done( from_json ($resp->content) );
		     } else {
			 $f->fail( "sizes not JSON" );
		     }
		 } else {
		     my $message= $resp->message; chop $message;
		     $f->fail( $message );
		 }
			} )
	     ->on_fail( sub {
		 my ( $message ) = @_; chop $message;
		 $log->logdie ("message from server '$message'");
			} );
    return $f;
}

sub _handle_response {
    my ($do, $resp, $f) = @_;

#warn "handle response ".Dumper $resp;
    sub _message_crop {
	my $message = $_[0]->message; chop $message;
	return $message;
    }

    if ($resp->code == HTTP_OK) {
	$f->done( from_json ($resp->content) );

    } elsif ($resp->code == HTTP_NO_CONTENT) {
	$f->done( );

    } elsif ($resp->code == HTTP_ACCEPTED
          || $resp->code == HTTP_CREATED) {                                                                   # for long-living actions
#warn "got accepted";
	if (! $resp->content) {                                                                               # yes, we can really get a ACCEPTED, but no content :/
	    $f->done( 42 );

	} elsif ($resp->content_type eq 'application/json') {
	    my $data = from_json ($resp->content);
#warn Dumper $data;
	    if (my $action = $data->{action}) {                                                               # if we only get an action to wait for
#warn "got action".Dumper $action;
		$do->_actions->{ $action->{id} } = [ $action, $f, '/actions/'.$action->{id}, 42 ];          # memory this, the future, and a reasonable final result

	    } elsif (my $links = $data->{links}) {
#warn "link actions";
		if (my $res = $data->{droplet}) {
		    my $endpoint = $do->endpoint;
		    foreach my $action (@{ $links->{actions} }) {                                             # should probably be only one entry
#warn "action found ".Dumper $action;
			$action->{status} = 'in-progress';                                                    # faking it
			my $href = $action->{href};
			$href =~ s/$endpoint//; # remove endpoint to make href relative
			$do->_actions->{ $action->{id} } = [ $action, $f, $href, $res ];                      # memory this, the future, and a reasonable final result
		    }

		} elsif ($res = $data->{droplets}) {
#warn "preliminary result".Dumper $res;
		    my @fs;
		    my @ids;
#warn "got actions";
		    foreach my $action (@{ $links->{actions} }) {
#warn "action found ".Dumper $action;
			my $f2 = $do->_http->loop->new_future;                                                 # for every action we create a future
			push @fs, $f2;                                                                        # collect the futures
			$action->{status} = 'in-progress';                                                    # faking it
			$do->_actions->{ $action->{id} } = [ $action, $f2, '/actions/'.$action->{id}, 42 ]; # memorize this, the future, the URL and a reasonable final result
			push @ids, $action->{id};                                                             # collect the ids
		    }
#warn "ids ".Dumper \@ids;
		    my $f3 = Future->wait_all( @fs )                                                          # all these futures will be waited for to be done, before
			->then( sub {                                                                         # warn "all subfutures done ";
			    $f->done( $res );                                                                 # the final future can be called done
				} );
		    $do->_actions->{ join '|', @ids } = [ { id     => 'xxx'.int(rand(10000)),                 # id does not matter
							    rel    => 'compoud-create',                       # my invention
							    status => 'compound-in-progress' }, $f3, undef, $res ]; # compound, virtual action

		} else { # TODO, other stuff
		    warn "unhandled situation for ".Dumper $data;
		}
	    } elsif (my $actions = $data->{actions}) {                                                        # multiple actions bundled (e.g. reboot several droplets)
		my @fs;
		my @ids;
#warn "got actions";
		foreach my $action (@$actions) {
#warn "action found ".Dumper $action;
		    my $f2 = $do->_http->loop->new_future;                                                    # for every action we create a future
		    push @fs, $f2; # collect the futures
		    $do->_actions->{ $action->{id} } = [ $action, $f2, '/actions/'.$action->{id}, 42 ];       # memorize this, the future, the URL and a reasonable final result
		    push @ids, $action->{id};                                                                 # collect the ids
		}
		my $f3 = Future->wait_all( @fs )                                                              # all these futures will be waited for to be done, before
		    ->then( sub { # warn "all subfutures done ";
			$f->done( 42 );                                                                       # the final future can be called done
			    } );
		$do->_actions->{ join '|', @ids } = [ { id => 'xxx',                                          # id does not matter
							status => 'compound-in-progress' }, $f3, undef, 42 ]; # compound, virtual action
		
	    } else {
		$f->done( $data );
#		warn "not handled reaction from the server ".Dumper $data;
#		$f->done( 42 );
	    }
	} else {
	    $f->fail( "returned data not JSON" );
	}
    } elsif ($resp->is_redirect) {
	    $f->fail( _message_crop( $resp ) );

    } elsif ($resp->code == HTTP_TOO_MANY_REQUESTS) {
	my $json = $resp->content;
	my $data = from_json ($json);
#warn "message ".$data->{message};
	my $bounce_time; # agenda
	if ($data->{message} =~ /rate-limited.+?(\d+)m(\d+)s/) {                                               # detect a hint that this operation is limited
#warn ">>>$1<<>>$2<<<";
	    $bounce_time   = $1 * 60 + $2; # seconds
	    $bounce_time //= 30;           # default
	} else {
	    $bounce_time = 30;             # just guessing something
	}
	$log->info( "server sent HTTP_TOO_MANY_REQUEST => will have to wait for $bounce_time seconds, and then repeat request" );

	$do->loop->watch_time( after => $bounce_time,
			       code  => sub { 
				       $log->debug( "repeating previously failed request to ".$resp->request->uri );
				       $do->_http->do_request( request => $resp->request )
					        ->on_done( sub {
						    my ($resp) = @_;
						    _handle_response( $do, $resp, $f );
							   } )
						->on_fail( sub {
						    my ( $message ) = @_; chop $message;
						    $log->logdie ("message from server '$message'");
							   } );
			       });


    } elsif (! $resp->is_success) {
#warn "failed request ".$resp->message . ' (' . $resp->code . ') '. $resp->content;
	if (my $json = $resp->content) {
	    my $data = from_json ($json);
#warn "error JSON ".Dumper $data;
	    $f->fail( $data->{message} );
	} else {
	    $f->fail( _message_crop( $resp ));
	}

    } else { # some other response
	warn "unhandled request ".$resp->message . ' (' . $resp->code . ') '. $resp->content;
	$f->fail( _message_crop( $resp ));
    }
}

sub _mk_json_POST_future {
    my ($do, $path, $body) = @_;

    $log->debug( "launching future POST $path" );

    my $f = $do->_http->loop->new_future;
    $do->_http->POST( $do->endpoint . $path,
		     to_json( $body), 
		     content_type => 'application/json' )
             ->on_done( sub {
		 my ($resp) = @_;
#warn "response ".Dumper $resp;
		 _handle_response( $do, $resp, $f );
			} )
	     ->on_fail( sub {
		 my ( $message ) = @_; chop $message;
#warn "XXXXX $message";
		 $log->logdie ("message from server '$message'");
			} );
    return $f;
}

sub _mk_json_PUT_future {
    my ($do, $path, $body) = @_;

    $log->debug( "launching future PUT $path" );
    my $f = $do->_http->loop->new_future;
    $do->_http->PUT( $do->endpoint . $path,
		     to_json( $body), 
		     content_type => 'application/json' )
             ->on_done( sub {
		 my ($resp) = @_;
#warn "response ".Dumper $resp;
		 _handle_response( $do, $resp, $f );
			} )
	     ->on_fail( sub {
		 my ( $message ) = @_; chop $message;
		 $log->logdie ("message from server '$message'");
			} );
    return $f;
}

sub _mk_json_DELETE_future {
    my ($do, $path, $headers) = @_;

    $log->debug( "launching future DELETE $path" );
    my $f = $do->_http->loop->new_future;
    $do->_http->do_request( uri    => $do->endpoint . $path,
			   method => "DELETE",
			   ($headers ? (headers => $headers) : ()),   )
             ->on_done( sub {
		 my ($resp) = @_;
#warn Dumper $resp;
		 _handle_response( $do, $resp, $f );

		 # if ($resp->code == HTTP_NO_CONTENT) {
		 #     $f->done( );
		 # } elsif ($resp->code == HTTP_ACCEPTED) {
		 #     $f->done( );
		 # } else {
		 #     $f->fail( $resp->message );
		 # }
			} )
	     ->on_fail( sub {
		 my ( $message ) = @_; chop $message;
		 $log->logdie ("message from server '$message'");
			} );
    return $f;
}

=pod

=head3 Meta Interface

If you work with the official DigitalOcean server, then this section can/should be ignored.

This subinterface allows to communicate with test servers to better control the test environent.

=over

=item * C<meta_reset>

This deletes ALL resources on the server, providing a clean slate for a following test.

=cut

sub meta_reset {
    my ($do) = @_;
    return _mk_json_POST_future( $do, "meta/reset", {});
}

=pod

=item * C<meta_ping>

This I<pings> the server which simply sends a I<pong> response.

=cut

sub meta_ping {
    my ($do) = @_;
    return _mk_json_POST_future( $do, "meta/ping", {});
}

=pod

=item * C<meta_account> (C<$account_HASH>)

Typically sets/resets operational limits, such as the number of volumes or droplets to be created.
This will be more detailed later.

=cut

sub meta_account {
    my ($do, $v) = @_;
    return _mk_json_POST_future( $do, "meta/account", $v);
}

=pod

=item * C<meta_statistics>

Returns eventually a rough statistics on what happened on the server.

=cut

sub meta_statistics {
    my ($do) = @_;
    return _mk_json_GET_future( $do, "meta/statistics");
}

=pod

=item * C<meta_capabilities>

Lists which sections (chapters) of the L<API specification|https://developers.digitalocean.com/documentation/v2/>
are implemented on the server. Returns a HASH, to be detailed later.

=cut

sub meta_capabilities {
    my ($do) = @_;
    return _mk_json_GET_future( $do, "meta/capabilities");
}

=pod

=back

=head3 L<Account|https://developers.digitalocean.com/documentation/v2/#account>

=over

=item * C<account>

Returns account information for the current user (as identified by the I<bearer token>) as a HASH.

=cut

sub account {
    my ($do) = @_;
    return _mk_json_GET_future( $do, "/account" );
}

=pod

=back

=head3 L<Block Storage|https://developers.digitalocean.com/documentation/v2/#list-all-block-storage-volumes>

=over

=item * C<volumes>

List all volumes. 

=item * C<volumes> (name => C<$name>)

List all volumes with a certain name.

=cut

sub volumes {
    my ($do, $key, $val) = @_;
    
    if (defined $key && $key eq 'name') {
	return _mk_json_GET_future( $do, "/volumes?name=$val" );
    } else {
	return _mk_json_GET_future( $do, '/volumes' );
    }
}

=pod

=item * C<create_volume> (C<$volume_HASH>)

Instigate to create a volume with your spec.

=cut

sub create_volume {
    my ($do, $v) = @_;
    return _mk_json_POST_future( $do, '/volumes', $v);
}
    
=pod

=item * C<volume> (id => C<$volume_id>)

=item * C<volume> (name => C<$name>, C<$region>)

Returns volume information, the volume either identified by its id, or the name/region combination.

=cut

sub volume {
    my ($do, $key, $val, $reg) = @_;

    if ($key eq 'id') {
	return _mk_json_GET_future( $do, "/volumes/$val" );
    } else {
	return _mk_json_GET_future( $do, "/volumes?name=$val&region=$reg" );
    }
}

=pod

=item * C<snapshots> (volume => C<$volume_id>)

List volume snapshots.

=cut

sub snapshots {
    my ($do, $key, $val ) = @_;

    if ($key eq 'volume') {
	return _mk_json_GET_future( $do, "/volumes/$val/snapshots");
    } elsif ($key eq 'droplet') {
	return _mk_json_GET_future( $do, "/droplets/$val/snapshots");
    } else {
	$log->logdie( "unhandled in method snapshots");
    }
}

=pod

=item * C<create_snapshot> (C<$volume_id>, C<$HASH>)

Creates a new volume snapshot with C<name> and C<tags> provided in the HASH.

=cut

sub create_snapshot {
    my ($do, $volid, $s ) = @_;
    return _mk_json_POST_future( $do, "/volumes/$volid/snapshots", $s);
}

=pod

=item * C<delete_volume> (id => C<$volume_id>)

=item * C<delete_volume> (name => C<$name>, C<$region>)

Delete a volume, either identified by its id, or the name/region combination.

=cut

sub delete_volume {
    my ($do, $key, $val, $reg) = @_;

    if ($key eq 'id') {
	return _mk_json_DELETE_future( $do, '/volumes/'. $val );

    } elsif ($key eq 'name') {
	return _mk_json_DELETE_future( $do, "/volumes?name=$val&region=$reg" );

    } else {
	$log->logdie ("invalid specification");
    }
}
    
=pod

=item * C<delete_snapshot> (C<$snapshot_id>)

Delete volume snapshot with a given id.

=cut

sub delete_snapshot {
    my ($do, $id) = @_;
    return _mk_json_DELETE_future( $do, '/snapshots/'. $id );
}

=pod

=back

=head3 L<Block Storage Actions|https://developers.digitalocean.com/documentation/v2/#attach-a-block-storage-volume-to-a-droplet>

=over

=item * C<volume_attach> (C<$volume_id>, C<$attach_HASH>)

Attaches a given volume to a droplet specified in the HASH.

Attaching by name is NOT IMPLEMENTED.

Note that the region of the droplet and that of the volume must agree to make that work.

=item * C<volume_detach> (C<$volume_id>, C<$attach_HASH>)

Detach the specified volume from the droplet named in the HASH.

Detaching by name is NOT IMPLEMENTED.

=cut

sub volume_attach {
    my ($do, $vid, $attach) = @_;
    return _mk_json_POST_future( $do, "/volumes/$vid/actions", $attach);
}

sub volume_detach {
    my ($do, $vid, $attach) = @_;
    return _mk_json_POST_future( $do, "/volumes/$vid/actions", $attach);
}

=pod

=item * C<volume_resize> (C<$volume_id>, C<$resize_HASH>)

Resizes the volume.

=cut

sub volume_resize {
    my ($do, $vid, $resize) = @_;
    return _mk_json_POST_future( $do, "/volumes/$vid/actions", $resize);
}

=pod

=back

=head3 L<Domains|https://developers.digitalocean.com/documentation/v2/#list-all-domains>

=over

=item * C<domains>

Lists all domains.

=cut

sub domains {
    my ($do) = @_;
    return _mk_json_GET_futures( $do, "/domains" );
}

=pod

=item * C<create_domain> (C<$domain_HASH>)

Creates a domain entry with the given specification.

Note that you can enter here anything, as the DigitialOcean DNS servers are not necessarily
authoritative for such a domain.

=cut

sub create_domain {
    my ($do, $d) = @_;
    return _mk_json_POST_future( $do, '/domains', $d);
}

=pod

=item * C<domain> (C<$name>)

Retrieves information of a named domain.

=cut

sub domain {
    my ($do, $name) = @_;
    return _mk_json_GET_future( $do, "/domains/$name");
}

=pod

=item * C<delete_domain> (C<$name>)

Deletes the named domain.

=cut

sub delete_domain {
    my ($do, $name) = @_;
    return _mk_json_DELETE_future( $do, '/domains/'. $name );
}

=pod

=back

=head3 L<Domain Records|https://developers.digitalocean.com/documentation/v2/#list-all-domain-records>

=over

=item * C<domain_records>

=item * C<domain_records> (C<$name>, type => C<$record_type>)

=item * C<domain_records> (C<$name>, name => C<$record_name>)

List domain records of the named domain; either all of them or filtered according to type or to name.

=cut

sub domain_records {
    my ($do, $name, %options) = @_;

    my @params;
    push @params, "type=$options{type}"
	if $options{type};
    push @params, "name=" . ($options{name} eq '@' ? $name : $options{name})
	if $options{name};

    return _mk_json_GET_futures( $do, "/domains/$name/records" .(@params ? '?'.join '&', @params : '') );
}

=pod

=item * C<create_record> (C<$name>, C<$record_HASH>)

Create new domain record within the named domain.

=cut

sub create_record {
    my ($do, $name, $r) = @_;
    return _mk_json_POST_future( $do, "/domains/$name/records", $r);
}

=pod

=item * C<domain_record> (C<$name>, C<$record_id>)

Retrieves the record for a given id from the named domain.

=cut

sub domain_record {
    my ($do, $name, $id) = @_;
    return _mk_json_GET_future( $do, "/domains/$name/records/$id");
}

=pod

=item * C<update_record> (C<$name>, C<$record_id>, C<$record_HASH>)

Selectively updates information in the record hash into the domain record with that id, all for the
named domain.


=cut

sub update_record {
    my ($do, $name, $id, $r) = @_;
    return _mk_json_PUT_future( $do, "/domains/$name/records/$id", $r);
}

=pod

=item * C<delete_record> (C<$name>, C<$record_id>)

Deletes the record with the given id from the named domain.

=cut

sub delete_record {
    my ($do, $name, $id) = @_;
    return _mk_json_DELETE_future( $do, "/domains/$name/records/$id");
}

=pod

=back

=head3 L<Droplets|https://developers.digitalocean.com/documentation/v2/#create-a-new-droplet>

=over

=item * C<create_droplet> (C<$droplet_HASH>)

Instigate to create new droplet(s) specified by the HASH.

If you specify not a C<name> field, but a C<names> field with an ARRAY of names, then multiple
droplets will be created. (There is a user-specific limit on how many can be created in one go.)

Note that resulting droplets may have the networking information incomplete (as that seems
to be determined rather late). To get this right, you will have to retrieve that droplet
information a bit later.

=cut

sub create_droplet {
    my ($do, $v) = @_;
    return _mk_json_POST_future( $do, '/droplets', $v);
}

=pod

=item * C<droplet> (id => C<$droplet_id>)

=item * C<droplet> (name => C<$droplet_name>, C<$region>)

Retrieve droplet information based on its id, or alternatively by name and region.

=cut

sub droplet {
    my ($do, $key, $val, $reg) = @_;

    if ($key eq 'id') {
	return _mk_json_GET_future( $do, "/droplets/$val" );
    } else {
	return _mk_json_GET_future( $do, "/droplets?name=$val&region=$reg" );
    }
}

=pod

=item * C<droplets>

List all droplets.

Listing of droplets based on name is NOT IMPLEMENTED.

=cut

sub droplets {
    my ($do) = @_;
    return _mk_json_GET_futures( $do, "/droplets");
}

=pod

=item * C<droplets_all>

This B<convenience> method will return a future which - when done - will return the B<complete> list
of droplets, not just the first page.

=cut

sub droplets_all {
    my ($do) = @_;

    my $g = $do->_http->loop->new_future;
    my @l = ();

    my $f = $do->droplets;
    _iprepare( $f, \@l, $g );
    return $g;

    sub _iprepare {
	my ($f, $l2, $g) = @_;
	$f->on_done( sub {
	    (my $l, $f) = @_;
	    push @$l2, @{ $l->{droplets} };
	    if (defined $f) {
		_iprepare( $f, $l2, $g );
	    } else {
		$g->done( { droplets => $l2, meta => { total => scalar @$l2 } } );
	    }
		     } );
    }
}

=pod

=item * C<droplets_kernels>

NOT IMPLEMENTED

=item * C<snapshots> (droplet => C<$droplet_id>)

List all droplet snapshots for that very droplet.

=item * C<backups> (C<$droplet_id>)

List backups of droplet specified by id.

=cut

sub backups {
    my ($do, $id ) = @_;
    return _mk_json_GET_future( $do, "/droplets/$id/backups");
}

=pod

=item * C<droplet_actions> (id => C<$droplet_id>)

=item * C<droplet_actions> (tag => C<$tag>)

NOT IMPLEMENTED

List all actions (also completed ones) of a specific droplet.

=cut

sub droplet_actions {
    my ($do, $key, $val) = @_;

    if ($key eq 'id') {
	return _mk_json_GET_future( $do, "/droplets/$val/actions" );
    } elsif ($key eq 'tag') {
	$log->logdie( "unhandled in method droplet_actions" );
    } else {
	$log->logdie( "unhandled in method droplet_actions" );
    }
}

=pod

=item * C<delete_droplet> (id => C<$droplet_id>)

=item * C<delete_droplet> (tag => C<$tag>)

Delete a specific droplet by id, or alternatively, a set specified by a tag.

=cut

sub delete_droplet {
    my ($do, $key, $val) = @_;

    if ($key eq 'id') {
	return _mk_json_DELETE_future( $do, "/droplets/$val" );
    } elsif ($key eq 'tag') {
	return _mk_json_DELETE_future( $do, "/droplets?tag_name=$val" );
    } else {
	$log->logdie( "unhandled in method delete_droplet" );
    }
}
    
=pod

=item * C<list_neighbors>

NOT IMPLEMENTED

=item * C<associated_resources> (id => C<$droplet_id>)

List volumes attached, snapshots thereof, and snapshots of the droplet itself.

=cut

sub associated_resources {
    my ($do, $key, $val) = @_;

    if ($key eq 'id') {
	return _mk_json_GET_future( $do, "/droplets/$val/destroy_with_associated_resources" );
    } elsif ($key eq 'check_status') {
	return _mk_json_GET_future( $do, "/droplets/$val/destroy_with_associated_resources/status" );
    } else {
	$log->logdie( "unhandled in method associated_resources" );
    }
}
    
=pod

=item * C<delete_selective_associated_resources>

NOT IMPLEMENTED

=item * C<delete_with_associated_resources> (id => C<$droplet_id>)

Deletes the droplet and all its associated resources.

=cut

sub delete_with_associated_resources {
    my ($do, $key, $val) = @_;

    if ($key eq 'id') {
	return _mk_json_DELETE_future( $do, "/droplets/$val/destroy_with_associated_resources/dangerous", { 'X-Dangerous' => 'true' } );
    } else {
	$log->logdie( "unhandled in method delete_with_associated_resources" );
    }
}
    
=pod

=item * C<associated_resources> (check_status => C<$droplet_id>)

Check which resources are already deleted.

=item * C<delete_with_associated_resources_retry>

NOT IMPLEMENTED

=back

=head3 L<Droplet Actions|https://developers.digitalocean.com/documentation/v2/#droplet-actions>

=over

=item * C<enable_backups> (id => C<$droplet_id>)

=item * C<enable_backups> (tag => C<$tag>)

Enable regular backups (done by DigitalOcean).

=cut

sub enable_backups {
    my ($do, $key, $val) = @_;
    _perform_droplet_actions( $do, $key, $val, 'enable_backups' );
}

=pod

=item * C<disable_backups> (id => C<$droplet_id>)

=item * C<disable_backups> (tag => C<$tag>)

Disable regular backups.

=cut

sub disable_backups {
    my ($do, $key, $val) = @_;
    _perform_droplet_actions( $do, $key, $val, 'disable_backups' );
}

=pod

=item * C<reboot> (id  => C<$droplet_id>)

=item * C<reboot> (tag => C<$tag>)

Reboots the specified droplet(s), either one via the id, or several via a tag.

=cut

sub reboot {
    my ($do, $key, $val) = @_;
    _perform_droplet_actions( $do, $key, $val, 'reboot' );
}

=pod

=item * C<power_cycle> (id  => C<$droplet_id>)

=item * C<power_cycle> (tag => C<$tag>)

Power-cycles the specified droplet(s), either one via the id, or several via a tag.

=cut

sub power_cycle {
    my ($do, $key, $val) = @_;
    _perform_droplet_actions( $do, $key, $val, 'power_cycle' );
}

=pod

=item * C<shutdown> (id  => C<$droplet_id>)

=item * C<shutdown> (tag => C<$tag>)

Shuts down the specified droplet(s), either one via the id, or several via a tag.

=cut

sub shutdown {
    my ($do, $key, $val) = @_;
    _perform_droplet_actions( $do, $key, $val, 'shutdown' );
}

=pod

=item * C<power_off> (id  => C<$droplet_id>)

=item * C<power_off> (tag => C<$tag>)

Powers down the specified droplet(s), either one via the id, or several via a tag.

=cut

sub power_off {
    my ($do, $key, $val) = @_;
    _perform_droplet_actions( $do, $key, $val, 'power_off' );
}

=pod

=item * C<power_on> (id  => C<$droplet_id>)

=item * C<power_on> (tag => C<$tag>)

Powers on the specified droplet(s), either one via the id, or several via a tag.

=cut

sub power_on {
    my ($do, $key, $val) = @_;
    _perform_droplet_actions( $do, $key, $val, 'power_on' );
}

=pod

=item * C<restore> (id  => C<$droplet_id>, C<$image>)

=item * C<restore> (tag => C<$tag>, C<$image>)

Restores the specified droplet(s) with the image given.

=cut

sub restore {
    my ($do, $key, $val, $image) = @_;
    _perform_droplet_action( $do, $key, $val, { type => 'restore', image => $image });
}

=pod

=item * C<password_reset> (id  => C<$droplet_id>)

=item * C<password_reset> (tag => C<$tag>)

Resets password on the specified droplet(s), either one via the id, or several via a tag.

=cut

sub password_reset {
    my ($do, $key, $val) = @_;
    _perform_droplet_actions( $do, $key, $val, 'password_reset' );
}

=pod

=item * C<resize> (id  => C<$droplet_id>, C<$new_size>, C<$diskresize_yes>)

=item * C<resize> (tag => C<$tag>,        C<$new_size>, C<$diskresize_yes>)

Resizes the specified droplet(s).

=cut

sub resize {
    my ($do, $key, $val, $size, $disk) = @_;
    _perform_droplet_action( $do, $key, $val, { type => 'resize', size => $size, disk => $disk });
}

=pod

=item * C<rebuild> (id  => C<$droplet_id>, C<$image>)

=item * C<rebuild> (tag => C<$tag>, C<$image>)

Rebuilds the specified droplet(s) with the image given.

NOTE: I do not understand the difference to C<restore>.

=cut

sub rebuild {
    my ($do, $key, $val, $image) = @_;
    _perform_droplet_action( $do, $key, $val, { type => 'rebuild', image => $image });
}

=pod

=item * C<rename> (id  => C<$droplet_id>, C<$name>)

Renames the specified droplet to a new name.

=cut

sub rename {
    my ($do, $key, $val, $name) = @_;
    _perform_droplet_action( $do, $key, $val, { type => 'rename', name => $name });
}

=pod

=item * C<enable_ipv6> (id => C<$droplet_id>)

=item * C<enable_ipv6> (tag => C<$tag>)

Turn on IPv6 on specified droplet(s).

Note, that it takes a while on the server to get this configured.

Note, that there does not seem a way to disable IPv6 for a droplet.

=cut

sub enable_ipv6 {
    my ($do, $key, $val) = @_;
    _perform_droplet_actions( $do, $key, $val, 'enable_ipv6' );
}

=pod

=item * C<enable_private_networking> (id => C<$droplet_id>)

=item * C<enable_private_networking> (tag => C<$tag>)

Enables ... well.

=cut

sub enable_private_networking {
    my ($do, $key, $val) = @_;
    _perform_droplet_actions( $do, $key, $val, 'enable_private_networking' );
}

=pod

=item * C<create_droplet_snapshot> (id => C<$droplet_id>)

=item * C<create_droplet_snapshot> (tag => C<$tag>)

Creates a new snapshot of the specified droplet(s).

=cut

sub create_droplet_snapshot {
    my ($do, $key, $val) = @_;
    _perform_droplet_actions( $do, $key, $val, 'snapshot');
}

=pod

=item * C<droplet_action>

NOT IMPLEMENTED

=cut


sub _perform_droplet_actions {
    my ($do, $key, $val, $type) = @_;
    _perform_droplet_action( $do, $key, $val, { type => $type });
}

sub _perform_droplet_action {
    my ($do, $key, $val, $body) = @_;

    if ($key eq 'id') {
	return _mk_json_POST_future( $do, "/droplets/$val/actions",          $body );
    } elsif ($key eq 'tag') {
	return _mk_json_POST_future( $do, "/droplets/actions?tag_name=$val", $body );
    } else {
	$log->logdie( "unhandled in method _perform_droplet_action" );
    }
}

=pod

=back

=head3 L<Images|https://developers.digitalocean.com/documentation/v2/#images>

=over

=item * C<images>

List all images.

=item * C<images> (type => 'distribution')

List all distribution images.

=item * C<images> (type => 'application')

List all application images.

=item * C<images> (private => 'true')

List all user images.

=item * C<images> (tag_name => C<$tag>)

List all images tagged with the tag.

=cut

sub images {
    my ($do, $key, $val) = @_;
    if ($key) {
	return _mk_json_GET_futures( $do, "/images?$key=$val");
    } else {
	return _mk_json_GET_futures( $do, "/images");
    }
}

=pod

=item * C<images_all>

This B<convenience> method returns a future, which - when done - will return complete list of
images. For that it will iterate over all pages, if any, and collects all results into a list.

=cut

sub images_all {
    my $do = shift;
    
    my $g = $do->_http->loop->new_future;            # the HTTP request to be finished eventually
    my @l = ();                                     # into this list all results will be collected

    my $f = $do->images( @_ );                      # launch the first request (with the original parameters)
    _prepare( $f, \@l, $g );                        # setup the reaction to the incoming response
    return $g;

    sub _prepare {
	my ($f, $l2, $g) = @_;
	$f->on_done( sub {                                                        # when the response comes in
	    (my $l, $f) = @_;                                                     # we get the result and (maybe) a followup future
	    push @$l2, @{ $l->{images} };                                         # accumulate the result
	    if (defined $f) {                                                     # if there is a followup
		_prepare( $f, $l2, $g );                                          # repeat and rinse
	    } else {
		$g->done( $l2 );  # we are done set this as overall result
	    }
		     } );
    }
}

=pod

=item * C<create_custom_image>

NOT IMPLEMENTED

=item * C<image>

NOT IMPLEMENTED

=item * C<update_image>

NOT IMPLEMENTED

=item * C<image_actions>

NOT IMPLEMENTED

=item * C<delete_image>

NOT IMPLEMENTED

=back

=head3 L<Regions|https://developers.digitalocean.com/documentation/v2/#list-all-regions>

=over

=item * C<regions>

List all available regions.

=cut

sub regions {
    my ($do) = @_;
    return _mk_json_GET_future( $do, "/regions"  );
}

=pod

=back

=head3 L<Sizes|https://developers.digitalocean.com/documentation/v2/#list-all-sizes>.

=over

=item * C<sizes>

List all sizes.

=cut

sub sizes {
    my ($do) = @_;
    return _mk_json_GET_future( $do, "/sizes" );
}

=pod

=back

=head3 L<SSH keys|https://developers.digitalocean.com/documentation/v2/#list-all-keys>

=over

=item * C<keys>

List all keys.

=cut

sub keys {
    my ($do, $id) = @_;
    return _mk_json_GET_futures( $do, "/account/keys");
}

=pod

=item * C<create_key> (C<$key_HASH>)

Create a new key with a provided HASH.

=cut

sub create_key {
    my ($do, $key) = @_;
    return _mk_json_POST_future( $do, "/account/keys", $key);
}

=pod

=item * C<key> (C<$key_id>)

Retrieve existing key given by the id.

=cut

sub key {
    my ($do, $id) = @_;
    return _mk_json_GET_future( $do, "/account/keys/$id");
}

=pod

=item * C<update_key> (C<$key_id>, C<$key_HASH>)

Selectively update fields for a given key.

=cut

sub update_key {
    my ($do, $id, $key) = @_;
    return _mk_json_PUT_future( $do, "/account/keys/$id", $key);
}

=pod

=item * C<delete_key> (C<$key_id>)

Delete a specific key.

=cut

sub delete_key {
    my ($do, $id) = @_;
    return _mk_json_DELETE_future( $do, "/account/keys/$id");
}

=pod

=back

=head1 SEE ALSO

=over

=item * INSTALLATION file in this distribution

=item * examples/*.pl in this distribution

=item * t/*.t test suites in this distribution

=item * L<Github|https://github.com/drrrho/net-async-digitalocean-perl>

=item * Topic Map knowledge in ontologies/digitalocean-clients.atm in this distribution

=item * L<DigitalOcean API|https://docs.digitalocean.com/reference/api/>

=item * Other Perl packages which talk to DigitalOcean are L<DigitalOcean> and L<WebService::DigitalOcean>

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2021 Robert Barta.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


1;
