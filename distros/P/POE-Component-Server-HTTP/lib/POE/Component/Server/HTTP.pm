package POE::Component::Server::HTTP;
use strict;
use Socket qw(inet_ntoa);
use HTTP::Date;
use HTTP::Status;
use File::Spec;
use Exporter ();
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);

use constant RC_WAIT => -1;
use constant RC_DENY => -2;
@EXPORT = qw(RC_OK RC_WAIT RC_DENY);

use POE qw(Wheel::ReadWrite Driver::SysRW Session Filter::Stream Filter::HTTPD);
use POE::Component::Server::TCP;
use Sys::Hostname qw(hostname);

$VERSION = "0.09";

use POE::Component::Server::HTTP::Response;
use POE::Component::Server::HTTP::Request;
use POE::Component::Server::HTTP::Connection;

use constant DEBUG => 0;

use Carp;

my %default_headers = (
    "Server" => "POE HTTPD Component/$VERSION ($])",
   );

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->{Headers} = { %default_headers,  ($self->{Headers} ? %{$self->{Headers}}: ())};

    $self->{TransHandler} = [] unless($self->{TransHandler});
    $self->{ErrorHandler} = {
        '/' => \&default_http_error,
    } unless($self->{ErrorHandler});
    $self->{PreHandler} = {} unless($self->{PreHandler});
    $self->{PostHandler} = {} unless($self->{PostHandler});

    if (ref($self->{ContentHandler}) ne 'HASH') {
        croak "You need a default content handler or a ContentHandler setup"
          unless(ref($self->{DefaultContentHandler}) eq 'CODE');
        $self->{ContentHandler} = {};
        $self->{ContentHandler}->{'/'} = $self->{DefaultContentHandler};
    }
    if (ref $self->{ErrorHandler} ne 'HASH') {
        croak "ErrorHandler must be a hashref or a coderef"
          unless(ref($self->{ErrorHandler}) eq 'CODE');
        $self->{ErrorHandler}={'/' => $self->{ErrorHandler}};
    }

    # DWIM on these handlers
    foreach my $phase (qw(PreHandler PostHandler)) {
        # NOTE: we want the following 2 cases to fall through to the last case
        if('CODE' eq ref $self->{$phase}) {     # CODE to { / => [ CODE ]}
            $self->{$phase}={'/' => [$self->{$phase}]};
        }
        if('ARRAY' eq ref $self->{$phase}) {    # ARRAY to { / => ARRAY }
            $self->{$phase}={'/' => $self->{$phase}};
        }
        if('HASH' eq ref $self->{$phase}) {     # check all hash keys
            while(my($path, $todo)=each %{$self->{$phase}}) {
                if('CODE' eq ref $todo) {
                    $self->{$phase}{$path}=[$todo];
                    next;
                }
                next if 'ARRAY' eq ref $todo;
                croak "$phase\->{$path} must be an arrayref";
            }
            next;
        }
        croak "$phase must be a hashref";
    }

    $self->{Hostname} = hostname() unless($self->{Hostname});

    my $alias = "PoCo::Server::HTTP::[ID]";
    my $tcp_alias = $alias . "::TCP";
    my $session =  POE::Session->create(
        inline_states => {
            _start => sub {
                my $id=$_[SESSION]->ID;
                $alias =~ s/\[ID\]/$id/;
                $tcp_alias =~ s/\[ID\]/$id/;
                $_[KERNEL]->alias_set($alias);
            },
            _stop => sub { },
            accept => \&accept,
            input => \&input,
            execute => \&execute,
            error => \&error,
            shutdown => sub {
                my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
                $kernel->call($tcp_alias, "shutdown");
                $kernel->alias_remove($alias);
            },
        },
        heap => { self => $self }
       );


    POE::Component::Server::TCP->new(
        Port => $self->{Port},
        Address => $self->{Address},
        Alias => $tcp_alias,
        Error => sub {
            $poe_kernel->post($session, 'error', @_[ARG0..ARG2]);
        },
#        ClientError => sub {
#            $poe_kernel->post($session, 'error', @_[ARG0..ARG2]);
#        },
        Acceptor => sub {
            $poe_kernel->post($session,'accept',@_[ARG0..ARG2]);
        });

    return { httpd => $alias, tcp => $tcp_alias };
}

sub handler_queue {
    return [qw(
        TransHandler
        Map
        PreHandler
        ContentHandler
        Send
        PostHandler
        Cleanup
       )];
}

sub error_queue {
    return [qw(
        Map
        ErrorHandler
        PostHandler
        Cleanup
       )];
}

# Set up queue for handling this request
sub rebuild_queue {
    my( $self, $handlers) = @_;
    my $now = $handlers->{Queue}[0];      # what phase are we about to do?

    if (not $now) {                      # this means we are post Cleanup
        # (which could be keep-alive)
        DEBUG and warn "Error post-Cleanup!";
        # we need Map to turn set up ErrorHandler
        $handlers->{Queue} = ['Map', 'ErrorHandler', 'Cleanup'];
        # Note : sub error set up fake request/response objects, etc
    }
    elsif ($now eq 'TransHandler' or $now eq 'Map' or
           $now eq 'PreHandler' or $now eq 'ContentHandler' or
           $now eq 'Send' or $now eq 'PostHandler') {

        $handlers->{Queue}=$self->error_queue;
    }
    elsif ($now eq 'Cleanup') {
        # we need Map to turn set up ErrorHandler
        unshift @{$handlers->{Queue}}, 'Map', 'ErrorHandler';
    }

    # clear these lists, so that Map builds new ones
    $handlers->{PostHandler} = [];
    $handlers->{PreHandler}  = [];
}

sub accept {
    my ($socket,$remote_addr, $remote_port) = @_[ARG0, ARG1, ARG2];
    my $self = $_[HEAP]->{self};
    my $connection = POE::Component::Server::HTTP::Connection->new();
    $connection->{remote_ip} = inet_ntoa($remote_addr);
    $connection->{remote_addr} = getpeername($socket);
    $connection->{local_addr} = getsockname($socket);

    $connection->{handlers} = {
        TransHandler => [@{$self->{TransHandler}}],
        PreHandler   => [],
        ContentHandler => undef,
        PostHandler  => [],
        # IMHO, Queue should be set in 'input' --PG
        Queue => $self->handler_queue,
    };

    my $wheel = POE::Wheel::ReadWrite->new(
        Handle => $socket,
        Driver => POE::Driver::SysRW->new,
        Filter => POE::Filter::HTTPD->new(),
        InputEvent => 'input',
        FlushedEvent => 'execute',
        ErrorEvent => 'error'
       );
    DEBUG and warn "Accept remote_ip=$connection->{remote_ip} id=", $wheel->ID;

    $_[HEAP]->{wheels}->{$wheel->ID} = $wheel;
    $_[HEAP]->{c}->{$wheel->ID} = $connection
}


sub input {
    my ($request,$id) = @_[ARG0, ARG1];

    DEBUG and warn "Input id=$id uri=", $request->uri->as_string;
    bless $request, 'POE::Component::Server::HTTP::Request';
    my $c = $_[HEAP]->{c}->{$id};
    my $self = $_[HEAP]->{self};

    if ($request->uri) {
        $request->uri->scheme('http');
        $request->uri->host($self->{Hostname});
        $request->uri->port($self->{Port});
    }
    $request->{connection} = $c;

    my $response = POE::Component::Server::HTTP::Response->new();

    $response->{connection} = $c;

    $c->{wheel} = $_[HEAP]->{wheels}->{$id};

    $c->{request} = $request;
    $c->{response} = $response;
    $c->{session} = $_[SESSION];
    $c->{my_id} = $id;
    $poe_kernel->yield('execute',$id);
}

sub error {
    my ($op, $errnum, $errstr, $id) = @_[ARG0..ARG3];
    unless ( $_[HEAP]->{c}{$id} ) {
        warn "Error $op $errstr ($errnum) happened after Cleanup!\n";
        return;
    }
    my $c = $_[HEAP]->{c}->{$id};
    my $self = $_[HEAP]->{self};

    DEBUG and warn "$$: HTTP error op=$op errnum=$errnum errstr=$errstr id=$id\n";
    if ($op eq 'accept') {
        die  "$$: HTTP error op=$op errnum=$errnum errstr=$errstr id=$id\n";
    }
    elsif ($op eq 'read' or $op eq 'write') {
        # connection closed or other error

        ## Create some temporary objects if needed
        unless($c->{request}) {
            my $request = POE::Component::Server::HTTP::Request->new(
                ERROR => '/'
               );
            $request->{connection} = $c;
            $c->{request}=$request;
        }
        $c->{request}->header(Operation => $op);
        $c->{request}->header(Errnum    => $errnum);
        $c->{request}->header(Error     => $errstr);

        unless ($c->{response}) {
            my $response = POE::Component::Server::HTTP::Response->new();
            $response->{connection} = $c;
            $c->{response}=$response;
        }
        $c->{session} ||= $_[SESSION];
        $c->{my_id}   ||= $id;
        $c->{wheel}   ||= $_[HEAP]{wheels}{$id};

        # mark everything hence forth as an error
        $c->{request}->is_error(1);
        $c->{response}->is_error(1);

        # and rebuild the queue
        $self->rebuild_queue($c->{handlers});
        $poe_kernel->yield('execute',$id);
    }
}

sub default_http_error {
    my ($request, $response) = @_;

    my $op = $request->header('Operation');
    my $errstr = $request->header('Error');
    my $errnum = $request->header('Errnum');
    return if $errnum == 0 and $op eq 'read';     # socket closed

    warn "Error during HTTP $op: $errstr ($errnum)\n";
}


sub execute {
    my $id = $_[ARG0];
    my $self = $_[HEAP]->{self};
    my $connection = $_[HEAP]->{c}->{$id};
    my $handlers = $connection->{handlers};

    my $response = $connection->{response};
    my $request  = $connection->{request};

    my $state;
  HANDLERS:
    while (1) {
        $state = $handlers->{Queue}->[0];
        DEBUG and warn "Execute state=$state id=$id";

        if ($state eq 'Map') {
            $self->state_Map( $request->uri ? $request->uri->path : '',
                              $handlers, $request );
            shift @{$handlers->{Queue}};
            next;
        }
        elsif ($state eq 'Send') {
            $self->state_Send( $response,  $_[HEAP]->{wheels}->{$id} );
            shift @{$handlers->{Queue}};
            last;
        }
        elsif ($state eq 'ContentHandler' or
               $state eq 'ErrorHandler') {
            # this empty sub should really make a 404
            my $sub = $handlers->{ $state } || sub {};

            # XXX: we should wrap this in an eval and return 500
            my $retvalue = $sub->($request, $response);
            shift @{$handlers->{Queue}};
            if ($retvalue == RC_WAIT) {
                if( $state eq 'ErrorHandler') {
                    warn "ErrorHandler is not allowed to return RC_WAIT";
                }
                else {
                    last HANDLERS;
                }
            }
            next;
        }
        elsif ($state eq 'Cleanup') {
            if (not $response->is_error and $response->streaming()) {
                $_[HEAP]->{wheels}->{$id}->set_output_filter(POE::Filter::Stream->new() );
                unshift(@{$handlers->{Queue}},'Streaming');
                next HANDLERS;
            }

            delete($response->{connection});
            delete($request->{connection});

            # under HTTP/1.1 connections are always kept alive, unless
            # there's a Connection: close present
            my $close = 1;
            if ( $request->protocol eq 'HTTP/1.1' ) {
                $close = 0;                   # keepalive
                # It turns out the connection field can contain multiple
                # comma separated values
                my $conn = $request->header('Connection');
                $close = 1 if qq(,$conn,) =~ /,\s*close\s*,/i;
            }

            unless ($close) {
                DEBUG and warn "Keepalive connection still active";
                # Breaking encapsulation causes immolation --richardc
                # We'll need a new POE::Filter::HTTPD
                $_[HEAP]{wheels}{$id}[2] = (ref $_[HEAP]{wheels}{$id}[2])->new;

                # IMHO, Queue should be set in 'input' --PG
                $handlers->{Queue} = $self->handler_queue;
            }
            else {
                DEBUG and warn "Close connection";
                delete($connection->{handlers});
                delete($connection->{wheel});
                delete($_[HEAP]->{c}->{$id});
                delete($_[HEAP]->{wheels}->{$id});
            }
            last HANDLERS;
        }
        elsif ($state eq 'Streaming') {
            $self->{StreamHandler}->($request, $response);
            last HANDLERS;
        }

      DISPATCH:     # this is used for {Trans,Pre,Post}Handler
        while (1) {
            my $handler = shift(@{$handlers->{$state}});
            last DISPATCH unless($handler);
            my $retvalue = $handler->($request,$response);

            if ($retvalue == RC_DENY) {
                last DISPATCH;
            }
            elsif ($retvalue == RC_WAIT) {
                last HANDLERS;
            }
        }

        shift @{$handlers->{Queue}};
        last unless(0 != @{$handlers->{Queue}});
    }
}

sub state_Map {
    my $self = shift;
    my $path = shift;
    my $handlers = shift;
    my $request = shift;
    my $filename;
    (undef, $path,$filename) = File::Spec->splitpath($path);
    my @dirs = File::Spec->splitdir($path);
    pop @dirs;

    DEBUG and warn "dirs=", join ',', @dirs;

    my @check;
    my $fullpath;
    foreach my $dir (@dirs) {
        $fullpath .= $dir.'/';
        push @check, $fullpath;
    }

    push(@check, "$check[-1]$filename") if($filename);

    DEBUG and warn "check=", join ',', @check;

    my @todo;
    unless ($request->is_error) {
        @todo=qw(PreHandler ContentHandler PostHandler);
    }
    else {
        @todo=qw(ErrorHandler PostHandler);
    }

    foreach my $path (@check) {
        foreach my $phase (@todo) {
            next unless exists($self->{$phase}->{$path});
            if ('ARRAY' eq ref $self->{$phase}{$path}) {
                push @{$handlers->{$phase}}, @{$self->{$phase}->{$path}};
            }
            else {
                $handlers->{$phase}=$self->{$phase}->{$path};
            }
        }
    }
    require Data::Dumper if DEBUG;
    DEBUG and warn "Map ", Data::Dumper::Dumper( $handlers );
}

sub state_Send {
    my $self = shift;
    my $response = shift;
    my $wheel = shift;

    $response->header(%{$self->{Headers}});
    unless ($response->header('Date')) {
        $response->header('Date',time2str(time));
    }
    if (!($response->header('Content-Lenth')) && !($response->streaming())) {
        use bytes;
        $response->header('Content-Length',length($response->content));
    }

    $wheel->put($response);
}

1;
__END__


=head1 NAME

POE::Component::Server::HTTP - Foundation of a POE HTTP Daemon

=head1 SYNOPSIS

 use POE::Component::Server::HTTP;
 use HTTP::Status;
 my $aliases = POE::Component::Server::HTTP->new(
     Port => 8000,
     ContentHandler => {
           '/' => \&handler1,
           '/dir/' => sub { ... },
           '/file' => sub { ... }
     },
     Headers => { Server => 'My Server' },
  );

  sub handler {
      my ($request, $response) = @_;
      $response->code(RC_OK);
      $response->content("Hi, you fetched ". $request->uri);
      return RC_OK;
  }

  POE::Kernel->call($aliases->{httpd}, "shutdown");
  # next line isn't really needed
  POE::Kernel->call($aliases->{tcp}, "shutdown");

=head1 DESCRIPTION

POE::Component::Server::HTTP (PoCo::HTTPD) is a framework for building
custom HTTP servers based on POE. It is loosely modeled on the ideas of
apache and the mod_perl/Apache module.

It is built alot on work done by Gisle Aas on HTTP::* modules and the URI
module which are subclassed.

PoCo::HTTPD lets you register different handler, stacked by directory that
will be run during the cause of the request.

=head2 Handlers

Handlers are put on a stack in fifo order. The path /foo/bar/baz/honk.txt
will first push the handlers of / then of /foo/ then of /foo/bar/, then of
/foo/bar/baz/, and lastly /foo/bar/baz/honk.txt.  Pay attention to
directories!  A request for /honk will not match /honk/ as you are used to
with apache.  If you want /honk to act like a directory, you should have
a handler for /honk which redirects to /honk/.

However, there can be only one ContentHandler and if any handler installs
a ContentHandler that will override the old ContentHandler.

If no handler installs a ContentHandler it will find the closest one
directory wise and use it.

There is also a special StreamHandler which is a coderef that gets
invoked if you have turned on streaming by doing
$response->streaming(1);

Handlers take the $request and $response objects as arguments.

=over 4

=item RC_OK

Everything is ok, please continue processing.

=item RC_DENY

If it is a TransHandler, stop translation handling and carry on with
a PreHandler, if it is a PostHandler do nothing, else return denied to
the client.

=item RC_WAIT

This is a special handler that suspends the execution of the handlers.
They will be suspended until $response->continue() is called, this is
usefull if you want to do a long request and not blocck.

=back

The following handlers are available.

=over 4

=item TransHandler

TransHandlers are run before the URI has been resolved, giving them a chance
to change the URI. They can therefore not be registred per directory.

    new(TransHandler => [ sub {return RC_OK} ]);

A TransHandler can stop the dispatching of TransHandlers and jump to the next
handler type by specifing RC_DENY;

=item PreHandler

PreHandlers are stacked by directory and run after TransHandler but
before the ContentHandler. They can change ContentHandler (but beware,
other PreHandlers might also change it) and push on PostHandlers.

    new(PreHandler => { '/' => [sub {}], '/foo/' => [\&foo]});

=item ContentHandler

The handler that is supposed to give the content. When this handler
returns it will send the response object to the client. It will
automaticly add Content-Length and Date if these are not set. If the
response is streaming it will make sure the correct headers are
set. It will also expand any cookies which have been pushed onto the
response object.

    new(ContentHandler => { '/' => sub {}, '/foo/' => \&foo});

=item ErrorHandler

This handler is called when there is a read or write error on the socket.
This is most likely caused by the remote side closing the connection.
$resquest->is_error and $response->is_error will return true.  Note that
C<PostHanlder> will still called, but C<TransHandler> and C<PreHandler>
won't be.  It is a map to coderefs just like ContentHandler is.

=item PostHandler

These handlers are run after the socket has been flushed.

    new(PostHandler => { '/' => [sub {}], '/foo/' => [\&foo]});


=item StreamHandler

If you turn on streaming in any other handler, the request is placed in
streaming mode.  This handler is called, with the usual parameters, when
streaming mode is first entered, and subsequently when each block of data is
flushed to the client.

Streaming mode is turned on via the C<$response> object:

    $response->streaming(1);

You deactivate streaming mode with the same object:

    $response->close;

Content is also sent to the client via the C<$response> object:

    $response->send($somedata);

The output filter is set to POE::Filter::Stream, which passes the data
through unchanged.  If you are doing a multipart/mixed response, you will
have to set up your own headers.

Example:

    sub new {
        .....
        POE::Component::Filter::HTTP->new(
                 ContentHandler => { '/someurl' => sub { $self->someurl(@_) },
                 StreamHandler  => sub { $self->stream(@_),
            );
    }

    sub someurl {
        my($self, $resquest, $response)=@_;
        $self->{todo} = [ .... ];
        $response->streaming(1);
        $response->code(RC_OK);         # you must set up your response header
        $response->content_type(...);

        return RC_OK;
    }

    sub stream {
        my($self, $resquest, $response)=@_;

        if( @{$self->{todo}} ) {
            $response->send(shift @{$self->{todo}});
        }
        else {
            $response->close;
        }
    }

Another example can be found in t/30_stream.t.  The parts dealing with
multipart/mixed are well documented and at the end of the file.

NOTE: Changes in streaming mode are only verified when StreamHandler exits.
So you must either turn streaming off in your StreamHandler, or make sure
that the StreamHandler will be called again.  This last is done by sending
data to the client.  If for some reason you have no data to send, you can
get the same result with C<continue>. Remember that this will also cause the
StreamHandler to be called one more time.

    my $aliases=POE::Component::Filter::HTTP->new( ....);

    # and then, when the end of the stream in met
    $response->close;
    $response->continue;

NOTE: even when the stream ends, the client connection will be held open if
Keepalive is active.  To force the connection closed, set the I<Connection>
header to I<close>:

    $resquest->header(Connection => 'close');

I<This might be a bug.  Are there any cases where we'd want to keep the
connection open after a stream?>



=back

=head1 Events

The C<shutdown> event may be sent to the component indicating that it
should shut down.  The event may be sent using the return value of the
I<new()> method (which is a session id) by either post()ing or
call()ing.

I've experienced some problems with the session not receiving the
event when it gets post()ed so call() is advised.

=head1 See Also

Please also take a look at L<HTTP::Response>, L<HTTP::Request>,
L<URI>, L<POE> and L<POE::Filter::HTTPD>

=head1 TODO

=over 4

=item Document Connection Response and Request objects.

=item Write more tests

=item Add a PoCo::Server::HTTP::Session that matches a http session against poe session using cookies or other state system

=item Add more options to streaming

=item Figure out why post()ed C<shutdown> events don't get received.

=item Probably lots of other API changes

=back

=head1 AUTHOR

Arthur Bergman, arthur@contiller.se

Additional hacking by Philip Gwyn, poe-at-pied.nu

Released under the same terms as POE.

=cut
