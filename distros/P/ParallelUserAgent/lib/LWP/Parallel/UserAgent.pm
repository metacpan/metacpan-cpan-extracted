# -*- perl -*-
# $Id: UserAgent.pm,v 1.31 2004/02/10 15:19:19 langhein Exp $
# derived from: UserAgent.pm,v 2.1 2001/12/11 21:11:29 gisle Exp $
#         and:  ParallelUA.pm,v 1.16 1997/07/23 16:45:09 ahoy Exp $

package LWP::Parallel::UserAgent::Entry;

require 5.004;
use Carp();

# allowed fields in Parallel::UserAgent entry
my %fields = (
	      arg => undef, 
	      fullpath => undef,
	      protocol => undef,
	      proxy => undef,
	      redirect_ok => undef,
	      response => undef,
	      request => undef,
	      size => undef, 
	      cmd_socket => undef,
	      listen_socket => undef,
	      content_size => undef,
	      );

sub new {
    my($class, $init) = @_;

    my $self = { 
	_permitted => \%fields,
	%fields, 
    };
    $self = bless $self, $class;

    if ($init) {
	foreach (keys %$init) {
	    # call functions and initialize with given values
	    $self->$_($init->{$_});
	}
    }
    $self;
}

sub get {
    my $self = shift;
    my @answer;
    my $field;
    foreach $field (@_) {
	push (@answer, $self->$field() );
    }
    @answer;
}

use vars qw($AUTOLOAD);

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) || die "$self is not an object";
    my $name = $AUTOLOAD;
    $name =~ s/.*://;  # strip fully qualified portion
    unless ( exists $self->{_permitted}->{$name} ) {
	Carp::croak "Can't access '$name' field in $type object";
    } 
    if (@_) {
	return $self->{$name} = $_[0];
    } else {
	return $self->{$name};
    }
}

sub DESTROY { };

package LWP::Parallel::UserAgent;

use Exporter();

$ENV{PERL_LWP_USE_HTTP_1.0} = "Yes"; # until i figure out gisle's http1.1 stuff
require LWP::Parallel::Protocol;
require LWP::UserAgent;
@ISA = qw(LWP::UserAgent Exporter);

@EXPORT = qw(); 
# callback commands
@EXPORT_OK = qw(C_ENDCON C_ENDALL C_LASTCON);
%EXPORT_TAGS = (CALLBACK => [qw(C_ENDCON C_ENDALL C_LASTCON)]);

sub C_ENDCON { -1; }; # end current connection (but keep waiting/connecting)
sub C_LASTCON{ -2; }; # don't start any new connections
sub C_ENDALL { -3; }; # end all connections and return from 'wait'-method

require HTTP::Request;
require HTTP::Response;

use Carp ();
use LWP::Debug ();
use HTTP::Status ();
use HTTP::Date qw(time2str);
use IO::Select;
use strict;

=head1 NAME

LWP::Parallel::UserAgent - A class for parallel User Agents

=head1 SYNOPSIS

  require LWP::Parallel::UserAgent;
  $ua = LWP::Parallel::UserAgent->new();
  ...

  $ua->redirect (0); # prevents automatic following of redirects
  $ua->max_hosts(5); # sets maximum number of locations accessed in parallel
  $ua->max_req  (5); # sets maximum number of parallel requests per host
  ...
  $ua->register ($request); # or
  $ua->register ($request, '/tmp/sss'); # or
  $ua->register ($request, \&callback, 4096);
  ...
  $ua->wait ( $timeout ); 
  ...
  sub callback { my($data, $response, $protocol) = @_; .... }

=head1 DESCRIPTION

This class implements a user agent that access web sources in parallel.

Using a I<LWP::Parallel::UserAgent> as your user agent, you typically start by
registering your requests, along with how you want the Agent to process 
the incoming results (see $ua->register).

Then you wait for the results by calling $ua->wait.  This method only
returns, if all requests have returned an answer, or the Agent timed
out.  Also, individual callback functions might indicate that the
Agent should stop waiting for requests and return. (see $ua->register)

See the file L<LWP::Parallel> for a set of simple examples.

=head1 METHODS

The LWP::Parallel::UserAgent is a sub-class of LWP::UserAgent, but not all
of its methods are available here. However, you can use its main
methods, $ua->simple_request and $ua->request, in order to simulate 
singular access with this package. Of course, if a single request is all
you need, then you should probably use LWP::UserAgent in the first place,
since it will be faster than our emulation here.

For parallel access, you will need to use the new methods that come with
LWP::Parallel::UserAgent, called $pua->register and $pua->wait. See below
for more information on each method.

=over 4

=cut


#
# Additional attributes in addition to those found in LWP::UserAgent:
#
# $self->{'entries_by_sockets'} = {}	Associative Array of registered
#                            		requests, indexed via sockets
#
# $self->{'entries_by_requests'} = {}	Associative Array of registered 
#					requests, indexed via requests
#

=item $ua = LWP::Parallel::UserAgent->new();

Constructor for the parallel UserAgent.  Returns a reference to a
LWP::Parallel::UserAgent object.

Optionally, you can give it an existing LWP::Parallel::UserAgent (or 
even an LWP::UserAgent) as a first argument, and it will "clone" a
new one from this (This just copies the behavior of LWP::UserAgent.
I have never actually tried this, so let me know if this does not do
what you want).

=cut

sub new {
    my($class,$init) = @_;

    # my $self = new LWP::UserAgent $init;
    my $self = new LWP::UserAgent; # thanks to Kirill
    $self = bless $self, $class;

    # handle responses per default
    $self->{'handle_response'} 	 = 1;
    # do not perform nonblocking connects per default
    $self->{'nonblock'} = 0;
    # don't handle duplicates per default
    $self->{'handle_duplicates'} = 0;
    # do not use ordered lists per default
    $self->{'handle_in_order'}   = 0;
    # do not cache failed connection attempts
    $self->{'remember_failures'} = 0;

    # supply defaults
    $self->{'max_hosts'} 	= 7;
    $self->{'max_req'}		= 5;

    $self->initialize;
}

=item $ua->initialize;

Takes no arguments and initializes the UserAgent. It is automatically
called in LWP::Parallel::UserAgent::new, so usually there is no need to
call this explicitly.

However, if you want to re-use the same UserAgent object for a number
of "runs", you should call $ua->initialize after you have processed the
results of the previous call to $ua->wait, but before registering any
new requests.

=cut


sub initialize {
    my $self = shift;

    # list of entries
    $self->{'entries_by_sockets'} = {};   
    $self->{'entries_by_requests'} = {};

    $self->{'previous_requests'}  = {};

    # connection handling
    $self->{'current_connections'} = {}; # hash
    $self->{'pending_connections'} = {}; # hash (of [] arrays)
    $self->{'ordpend_connections'} = []; # array
    $self->{'failed_connections'}  = {}; # hash

    # duplicates
    $self->{'seen_request'} = {};

    # select objects for reading & writing
    $self->{'select_in'} = IO::Select->new();
    $self->{'select_out'} = IO::Select->new();

    $self;
}

=item $ua->redirect ( $ok )

Changes the default value for permitting Parallel::UserAgent to follow
redirects and authentication-requests.  The standard value is 'true'.

See C<$ua->register> for how to change the behaviour for particular
requests only.

=cut

sub redirect {
    my $self = shift;
  LWP::Debug::trace("($_[0])");
    $self->{'handle_response'} = $_[0]  if defined $_[0];
}

=item $ua->nonblock ( $ok )

Per default, LWP::Parallel will connect to a site using a blocking call. If
you want to speed this step up, you can try the new non-blocking version of 
the connect call by setting $ua->nonblock to 'true'. 
The standard value is 'false' (although this might change in the future if
nonblocking connects turn out to be stable enough.)

=cut

sub nonblock {
    my $self = shift;
  LWP::Debug::trace("($_[0])");
    $self->{'nonblock'} = $_[0]  if defined $_[0];
}


=item $ua->duplicates ( $ok )

Changes the default value for permitting Parallel::UserAgent to ignore
duplicate requests.  The standard value is 'false'.

=cut

sub duplicates {
    my $self = shift;
  LWP::Debug::trace("($_[0])");
    $self->{'handle_duplicates'} = $_[0]  if defined $_[0];
}

=item $ua->in_order ( $ok )

Changes the default value to restricting Parallel::UserAgent to
connect to the registered sites in the order they were registered. The
default value FALSE allows Parallel::UserAgent to make the connections
in an apparently random order.

=cut

sub in_order {
  my $self = shift;
  LWP::Debug::trace("($_[0])");
  $self->{'handle_in_order'} = $_[0]  if defined $_[0];
}

=item $ua->remember_failures ( $yes )

If set to one, enables ParalleUA to ignore requests or connections to
sites that it failed to connect to before during this "run". If set to
zero (the dafault) Parallel::UserAgent will try to connect to every
single URL you registered, even if it constantly fails to connect to a
particular site.

=cut

sub remember_failures {
  my $self = shift;
  LWP::Debug::trace("($_[0])");
  $self->{'remember_failures'} = $_[0]  if defined $_[0];
}

=item $ua->max_hosts ( $max )

Changes the maximum number of locations accessed in parallel. The
default value is 7.

Note: Although it says 'host', it really means 'netloc/server'! That
is, multiple server on the same host (i.e. one server running on port
80, the other one on port 6060) will count as two 'hosts'.

=cut

sub max_hosts {
    my $self = shift;
  LWP::Debug::trace("($_[0])");
    $self->{'max_hosts'} = $_[0]  if defined $_[0];
}

=item $ua->max_req ( $max )

Changes the maximum number of requests issued per host in
parallel. The default value is 5.

=cut

sub max_req {
    my $self = shift;
  LWP::Debug::trace("($_[0])");
    $self->{'max_req'} = $_[0]  if defined $_[0];
}

=item $ua->register ( $request [, $arg [, $size [, $redirect_ok]]] )

Registers the given request with the User Agent.  In case of an error,
a C<HTTP::Request> object containing the HTML-Error message is
returned.  Otherwise (that is, in case of a success) it will return
undef.

The C<$request> should be a reference to a C<HTTP::Request> object
with values defined for at least the method() and url() attributes.

C<$size> specifies the number of bytes Parallel::UserAgent should try
to read each time some new data arrives.  Setting it to '0' or 'undef'
will make Parallel::UserAgent use the default. (8k)

Specifying C<$redirect_ok> will alter the redirection behaviour for
this particular request only. '1' or any other true value will force
Parallel::UserAgent to follow redirects, even if the default is set to
'no_redirect'. (see C<$ua->redirect>) '0' or any other false value
should do the reverse. See LWP::UserAgent for using an object's
C<requests_redirectable> list for fine-tuning this behavior.

If C<$arg> is a scalar it is taken as a filename where the content of
the response is stored.

If C<$arg> is a reference to a subroutine, then this routine is called
as chunks of the content is received.  An optional C<$size> argument
is taken as a hint for an appropriate chunk size. The callback
function is called with 3 arguments: the data received this time, a
reference to the response object and a reference to the protocol
object. The callback can use the predefined constants C_ENDCON,
C_LASTCON and C_ENDALL as a return value in order to influence pending
and active connections. C_ENDCON will end this connection immediately,
whereas C_LASTCON will inidicate that no further connections should be
made. C_ENDALL will immediately end all requests and let the
Parallel::UserAgent return from $pua->wait().

If C<$arg> is omitted, then the content is stored in the response
object itself.

If C<$arg> is a C<LWP::Parallel::UserAgent::Entry> object, then this
request will be registered as a follow-up request to this particular
entry. This will not create a new entry, but instead link the current
response (i.e. the reason for re-registering) as $response->previous
to the new response of this request.  All other fields are either
re-initialized ($request, $fullpath, $proxy) or left untouched ($arg,
$size). (This should only be use internally)

LWP::Parallel::UserAgent->request also allows the registration of
follow-up requests to existing requests, that required redirection or
authentication. In order to do this, an Parallel::UserAgent::Entry
object will be passed as the second argument to the call. Usually,
this should not be used directly, but left to the internal
$ua->handle_response method!

=cut

sub register {
  my ($self, $request, $arg, $size, $redirect) = @_;
  my $entry;

  unless (ref($request) and $request->can('url')) {
    Carp::carp "Can't use '$request' as an HTTP::Request object. Ignoring";
    return LWP::UserAgent::_new_response($request, &HTTP::Status::RC_NOT_IMPLEMENTED,
		               "Unknown request type: '$request'");
  }
  LWP::Debug::debug("(".$request->url->as_string .
		    ", ". (defined $arg ? $arg : '[undef]') . 
		    ", ". (defined $size ? $size : '[undef]') .
		    ", ". (defined $redirect ? $redirect : '[undef]') . ")");
  
  my($failed_connections,$remember_failures,$handle_duplicates,
     $previous_requests)= @{$self}{qw(failed_connections
     remember_failures handle_duplicates previous_requests)};

  my $response = HTTP::Response->new(0, '<empty response>'); 
  # make sure our request gets stored within the response
  # (usually this is done automatically by LWP in case of
  # a successful connection, but we want to have this info
  # available even when something goes wrong)
  $response->request($request);

  # so far Parallel::UserAgent can handle http, ftp, and file requests
  # (anybody volunteering to porting the rest of the protocols?!)
  unless ( $request->url->scheme eq 'http' or $request->url->scheme eq 'ftp'
           # https suggestion by <mszabo@coralwave.com>
           or $request->url->scheme eq 'https'
	   # file scheme implementation by
	   or $request->url->scheme eq 'file'
	   ){
    $response->code (&HTTP::Status::RC_NOT_IMPLEMENTED);
    $response->message ("Unknown Scheme: ". $request->url->scheme);
    Carp::carp "Parallel::UserAgent can not handle '". $request->url->scheme .
      "'-requests. Request ignored!";
    # simulate immediate response from server
    $self->on_failure ($request, $response);
    return $response;
  }	
  
  my $netloc = $self->_netloc($request->url); 
  
  # check if we already tried to connect to this location, and failed
  if ( $remember_failures  and  $failed_connections->{$netloc} ) {
    $response->code (&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
    $response->message ("Server unavailable");
    # simulate immediate response from server
    $self->on_failure ($request, $response);
    return $response;
  }
  
  # duplicates handling: check if we connected to same URL before
  if ($handle_duplicates and $previous_requests->{$request->url->as_string}){
    $response->code (&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
    $response->message ("Duplicate Request: ". $request->url);
    ## just ignore the request for now. if you want to simulate
    ## immediate response from server, uncomment this line:
    # $self->on_failure ($request, $response);
    return $response;
  }
  
  # support two calling techniques: new request or follow-up
  # 1) follow-up request:
  if ( ref($arg) and  ( ref($arg) eq "LWP::Parallel::UserAgent::Entry") ) {
    # called with $entry object as first parameter.
    # re-register new request with same entry:
    $entry = $arg;
    # link the previous response to our new response object
    $response->previous($entry->response);
    # and update the fields in our entry
    $entry->request($request);
    $entry->response($response);
    # re-registered requests are put first in line (->unshift)
    # and stored underneath the host they're accessing:
    #  (first make sure we have an array to push things onto)
    $self->{'pending_connections'}->{$netloc} = []
      unless $self->{'pending_connections'}->{$netloc};
    unshift (@{$self->{'pending_connections'}->{$netloc}}, $entry);
    unshift (@{$self->{'ordpend_connections'}}, $entry);

    # 2) new request:
  } else {
    # called first time, create new entry object
    $size ||= 8192;
    $entry = LWP::Parallel::UserAgent::Entry->new( { 
      request  	=> $request, 
      response 	=> $response, 
      arg 	=> $arg, 
      size	=> $size, 
      content_size => 0,
      redirect_ok => $self->{'handle_response'},
    } );
    # if the user specified 
    $entry->redirect_ok($redirect) if defined $redirect;
    
    # store new entry by request (only new entries)
    $self->{'entries_by_requests'}->{$request} = $entry;
    
    # new requests are put at the end
    #  (first make sure we have an array to push things onto)
    $self->{'pending_connections'}->{$netloc} = []
      unless $self->{'pending_connections'}->{$netloc};
    push (@{$self->{'pending_connections'}->{$netloc}}, $entry);
    push (@{$self->{'ordpend_connections'}}, $entry);
  }
  # duplicates handling: remember this entry
  if ($handle_duplicates) {
    $previous_requests->{$request->url->as_string} = $entry;
  }
  
  return;
}

# Create a netloc from the url or return an alias netloc for file: proto
# Fix netloc for file: reqs to generic localhost.file - this can be changed
# if necessary.  Test to ensure url->scheme doesn't return undef (JB)
sub _netloc {
    my $self = shift;
    my $url = shift;

    my $netloc;
    if ($url->scheme eq 'file') {
      $netloc = 'localhost.file';
    } else {
      $netloc = $url->host_port; # eg www.cs.washington.edu:8001
    }
    $netloc;
}


# this method will take the pending entries one at a time and
# decide wether we have enough bandwith (as specified by the
# values in 'max_req' and 'max_hosts') to connect this request.
# If not, the entry will stay on the stack (w/o changing the
# order)
sub _make_connections {
  my $self = shift;
  if ($self->{'handle_in_order'}) {
    $self->_make_connections_in_order;
  } else {
    $self->_make_connections_unordered;
  }
}

sub _make_connections_in_order {
  my $self = shift;
  LWP::Debug::trace('()');
  
  my ($entry, @queue, %busy);
  # get first entry from pending connections
  while ( $entry = shift @{ $self->{'ordpend_connections'} } ) {
    my $netloc = $self->_netloc($entry->request->url);
    push (@queue, $entry), next  if $busy{$netloc};
    unless ($self->_check_bandwith($entry)) {
      push (@queue, $entry);
      $busy{$netloc}++;
    };
  };
  # the un-connected entries form the new stack
  $self->{'ordpend_connections'} = \@queue;
}

# unordered connections have the advantage that we do not have to 
# care about screwing up our list of pending connections. This will
# speed up our iteration through the list
sub _make_connections_unordered {
  my $self = shift;
  LWP::Debug::trace('()');
  
  my ($entry, $queue, $netloc);
  # check every host in sequence (use 'each' for better performance)
  my %delete;
 SERVER:
  while (($netloc, $queue) = each %{$self->{'pending_connections'}}) {
    # get first entry from pending connections at this host
  ENTRY:
    while ( $entry = shift @$queue ) {
      unless ( $self->_check_bandwith($entry) ) {
	# we don't have enough bandwith -- put entry back on queue
	LWP::Debug::debug("Not enough bandwidth for request to $netloc");
	unshift @$queue, $entry;
	# we can stop here for this server
	next SERVER;
      }
    } # of while ENTRY
    # mark for deletion if we emptied the queue at this location
  LWP::Debug::debug("Queue for $netloc contains ". scalar @$queue . " pending connections");
    $delete{$netloc}++ unless scalar @$queue;
  } # of while SERVER
  # delete all netlocs that we completely handled
  foreach (keys %delete) { 
    LWP::Debug::debug("Deleting queue for $_");
      delete $self->{'pending_connections'}->{$_} 
  }
}

	
# this method checks the available bandwith and either connects
# the request and returns 1, or, in case we didn't have enough
# bandwith, returns undef
sub _check_bandwith {
    my ( $self, $entry ) = @_;
    LWP::Debug::trace("($entry [".$entry->request->url."] )");

    my($failed_connections, $remember_failures ) =
      @{$self}{qw(failed_connections remember_failures)};
    
    my ($request, $response) = ($entry->request, $entry->response);
    my $url  = $request->url;
    my $netloc = $self->_netloc($url);

    if ( $remember_failures and $failed_connections->{$netloc} ) {
	$response->code (&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
	$response->message ("Server unavailable");
	# simulate immediate response from server
	$self->on_failure ($request, $response, $entry);
	return 1;
    }

    if ( $self->_active ($netloc) ) {
	if ( $self->_req_available ( $url ) ) {
	    $self->on_connect ( $request, $response, $entry );
	    unless ( $self->_connect ( $entry ) ) {
		# only increase connection count if _connect doesn't
		# return error
		$self->{'current_connections'}->{$netloc}++;
	    } else {
	        # calling ->on_failure is done within ->_connect
		$self->{'failed_connections'}->{$netloc}++;
	    }
	} else { 
	  LWP::Debug::debug ("No open request-slots available");
	    return; };
    } elsif ( $self->_hosts_available ) {
	$self->on_connect ( $request, $response, $entry );
	unless ( $self->_connect ( $entry ) ) {
	    # only increase connection count if _connect doesn't return error
	    $self->{'current_connections'}->{$netloc}++;
	} else {
	    # calling ->on_failure is done within ->_connect
	    LWP::Debug::debug ("Failed connection for '" . $netloc ."'");
	    $self->{'failed_connections'}->{$netloc}++;
	}
    } else {
      LWP::Debug::debug ("No open host-slots available");
	return;
    }
    # indicate success here
    return 1;
}

#
# helper methods for _make_connections:
#
# number of active connections per netloc
sub _active { shift->{'current_connections'}->{$_[0]}; }; 
# request-slots available at netloc
sub _req_available { 
    my ( $self, $url ) = @_; 
    $self->{'max_req'} > $self->_active($self->_netloc($url)); 
};
# host-slots available
sub _hosts_available { 
    my $self = shift; 
    $self->{'max_hosts'} > scalar keys %{$self->{'current_connections'}}; 
};


# _connect will take the request of the given entry and try to connect
# to the host specified in its url. It returns the response object in
# case of error, undef otherwise.
sub _connect {
  my ($self, $entry) = @_;
  LWP::Debug::trace("($entry [".$entry->request->url."] )");
  local($SIG{"__DIE__"});	# protect against user defined die handlers
  
  my ( $request, $response ) = $entry->get( qw(request response) );
  
  my ($error_response, $proxy, $protocol, $timeout, $use_eval, $nonblock) = 
    $self->init_request ($request);
  if ($error_response) {
    # we need to manually set code and message of $response as well, so
    # that we have the correct information in our $entry as well
    $response->code ($error_response->code);
    $response->message ($error_response->message);
    $self->on_failure ($request, $error_response, $entry);
    return $error_response;
  }
  
  my ($socket, $fullpath);

  # figure out host and connect to site
  if ($use_eval) {
    eval { 
      ($socket, $fullpath) = 
	 $protocol->handle_connect ($request, $proxy, $timeout, $nonblock );
    };
    if ($@) {
      if ($@ =~ /^timeout/i) {
	$response->code (&HTTP::Status::RC_REQUEST_TIMEOUT);
	$response->message ('User-agent timeout');
      } else {
	# remove file/line number
	# $@ =~ s/\s+at\s+\S+\s+line\s+\d+.*//s;  
	$response->code (&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
	$response->message ($@);
      }
    }
  } else {
    # user has to handle any dies, usually timeouts
    ($socket, $fullpath) = 
	 $protocol->handle_connect ($request, $proxy, $timeout, $nonblock );
  }

  unless ($socket) {
    # something went wrong. Explanation might be in second argument
    unless ($response->code) {
      # set response code and message accordingly (note: simply saying
      # $response = $fullpath or $response = HTTP::Response->new would
      # only affect the local copy of our response object. When using
      # its ->code and ->message methods directly, we can affect the
      # original instead!)
      if (ref($fullpath) =~ /response/i) {
	$response->code ($fullpath->code);
	$response->message ($fullpath->message);
      } else {
	$response->code (&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
	$response->message ("Failed on connect for unknown reasons");
      }
    }
  }
  # response should be empty, unless something went wrong
  if ($response->code) {
    $self->on_failure ($request, $response, $entry);
    # should we remove $entry from 'entries_by_request' list here? no!
    return $response;
  } else {
    # update $socket, $protocol, $fullpath and $proxy info
    $entry->protocol($protocol);
    $entry->fullpath($fullpath);
    $entry->proxy($proxy);
    $entry->cmd_socket($socket);
    $self->{'entries_by_sockets'}->{$socket}   = $entry;
#  LWP::Debug::debug ("Socket is $socket");
    # last not least: register socket with (write-) Select object
    $self->_add_out_socket($socket);
  }
  
  return;
}

# once we're done with a connection, we have to make sure that all
# references to it's socket are removed, and that the counter for its
# netloc is properly decremented.
sub _remove_current_connection {
  my ($self, $entry ) = @_;
  LWP::Debug::trace("($entry [".$entry->request->url."] )");

  $entry->cmd_socket(undef);
  $entry->listen_socket(undef);

  my $netloc = $self->_netloc($entry->request->url);
  if ( $self->_active ($netloc) ) {
    delete $self->{'current_connections'}->{$netloc}
    unless --$self->{'current_connections'}->{$netloc};
  } else {
    # this is serious! better stop here
    Carp::confess "No connections for '$netloc'";
  }
}

=item $ua->on_connect ( $request, $response, $entry ) 

This method should be overridden in an (otherwise empty) subclass in
order to present customized messages for each connection attempted by
the User Agent.

=cut

sub on_connect {
  my ($self, $request, $response, $entry) = @_;  
  LWP::Debug::trace("(".$request->url->as_string.")");
}

=item $ua->on_failure ( $request, $response, $entry )

This method should be overridden in an (otherwise empty) subclass in
order to present customized messages for each connection or
registration that failed.

=cut

sub on_failure {
  my ($self, $request, $response, $entry) = @_;
  LWP::Debug::trace("(".$request->url->as_string.")");
}

=item $ua->on_return ( $request, $response, $entry ) 

This method should be overridden in an (otherwise empty) subclass in
order to present customized messages for each request returned. If a
callback function was registered with this request, this callback
function is called before $pua->on_return.

Please note that while $pua->on_return is a method (which should be
overridden in a subclass), a callback function is NOT a method, and
does not have $self as its first parameter. (See more on callbacks
below)

The purpose of $pua->on_return is mainly to provide messages when a
request returns. However, you can also re-register follow-up requests
in case you need them.

If you need specialized follow-up requests depending on the request
that just returend, use a callback function instead (which can be
different for each request registered). Otherwise you might end up
writing a HUGE if..elsif..else.. branch in this global method.

=cut

sub on_return {
  my ($self, $request, $response, $entry) = @_;
  LWP::Debug::trace("(".join (", ",$request->url->as_string,
			      (defined $response->code ?
			        $response->code : '[undef]'),
			      (defined $response->message ?
			        $response->message : '[undef]')) .")");
}

=item $us->discard_entry ( $entry )

Completely removes an entry from memory, in case its output is not
needed. Use this in callbacks such as C<on_return> or <on_failure> if
you want to make sure an entry that you do not need does not occupy
valuable main memory.

=cut

# proposed by Glenn Wood <glenn@savesmart.com>
# additional fixes by Kirill http://www.en-directo.net/mail/kirill.html
sub discard_entry {
    my ($self, $entry) = @_;
  LWP::Debug::trace("($entry)") if $entry;

    # Entries are added to ordpend_connections in $self->register:  
    #    push (@{$self->{'ordpend_connections'}}, $entry);
    #
    # the reason we even maintain this ordered list is that
    # currently the user can change the "in_order" flag any
    # time, even if we already started 'wait'ing. 
    my $entries = $self->{ordpend_connections};
    @$entries = grep $_ != $entry, @$entries;

    $entries = $self->{entries_by_requests};
    delete @$entries{grep $entries->{$_} == $entry, keys %$entries};

    $entries = $self->{entries_by_sockets};
    delete @$entries{grep $entries->{$_} == $entry, keys %$entries};

    return;
}


=item $ua->wait ( $timeout )

Waits for available sockets to write to or read from.  Will timeout
after $timeout seconds. Will block if $timeout = 0 specified. If
$timeout is omitted, it will use the Agent default timeout value.

=cut

sub wait {
  my ($self, $timeout) = @_;
  LWP::Debug::trace("($timeout)") if $timeout;
  
  my $foobar;
  
  $timeout = $self->{'timeout'} unless defined $timeout; 
  
  # shortcuts to in- and out-filehandles
  my $fh_out = $self->{'select_out'};
  my $fh_in  = $self->{'select_in'};
  my $fh_err;			# ignore errors for now
  my @ready;
  
  my ($active, $pending);
 ATTEMPT:
  while ( $active = scalar keys %{ $self->{'current_connections'} }  or
	  $pending = scalar ($self->{'handle_in_order'}? 
			     @{ $self->{'ordpend_connections'} } :
			     keys %{ $self->{'pending_connections'} } ) ) {
    # check select
    if ( (scalar $fh_in->handles) or (scalar $fh_out->handles) ) {
      LWP::Debug::debug("Selecting Sockets, timeout is $timeout seconds");
      unless ( @ready = IO::Select->select ($fh_in, $fh_out, 
					    undef, $timeout) ) {
	# 
	# empty array, means that select timed out
	LWP::Debug::trace('select timeout');
	my ($socket);
	# set all active requests to "timed out" 
	foreach $socket ($fh_in->handles ,$fh_out->handles) {
	  my $entry = $self->{'entries_by_sockets'}->{$socket};
	  delete $self->{'entries_by_sockets'}->{$socket};
	  unless ($entry->response->code) {
	    # moved the creation of the timeout response into the loop so that
	    # each entry gets its own response object (otherwise they'll all 
	    # share the same request entry in there). thanks to John Salmon 
	    # <john@thesalmons.org> for pointing this out.
	    my $response = HTTP::Response->new(&HTTP::Status::RC_REQUEST_TIMEOUT,
					     'User-agent timeout (select)');
	    # don't overwrite an already existing response
	    $entry->response ($response);
	    $response->request ($entry->request);
	    # only count as failure if we have no response yet
	    $self->on_failure ($entry->request, $response, $entry);
	  } else {
	    my $res = $entry->response;
	    $res->message ($res->message . " (timeout)");
	    $entry->response ($res);
	    # thanks to Jonathan Feinberg <jdf@pobox.com> who finally
	    # reminded me that partial replies should trigger some sort 
	    # of on_xxx callback as well. Let's try on_failure for now,
	    # unless people think that on_return is the right thing to
	    # call here:
	    $self->on_failure ($entry->request, $res, $entry);
	  }
	  $self->_remove_current_connection ( $entry );
	} 
	# and delete from read- and write-queues
	foreach $socket ($fh_out->handles) { $fh_out->remove($socket); }
	foreach $socket ($fh_in->handles)  { $fh_in->remove($socket);  }
	# continue processing -- pending requests might still work!
      } else {
	# something is ready for reading or writing
	my ($ready_read, $ready_write, $error) = @ready;
        my ($socket);

	#
	# WRITE QUEUE
	#
	foreach $socket (@$ready_write) {
	  my $so_err;
	  if ($socket->can("getsockopt")) { # we also might have IO::File!
            ## check if there is any error (suggested by Mike Heller)
            $so_err = $socket->getsockopt( Socket::SOL_SOCKET(), 
	                                   Socket::SO_ERROR() );
            LWP::Debug::debug( "SO_ERROR: $so_err" ) if $so_err;
          }
          # modularized this chunk so that it can be reused by 
	  # POE::Component::Client::UserAgent
	  $self->_perform_write ($socket, $timeout) unless $so_err;

	}
	
	#
	# READ QUEUE
	#
	foreach $socket (@$ready_read) {

          # modularized this chunk so that it can be reused by 
	  # POE::Component::Client::UserAgent
          $self->_perform_read ($socket, $timeout);

	}
      }				# of unless (@ready...) {} else {}
      
    } else {
      # when we are here, can we have active connections?!! 
      #(you might want to comment out this huge Debug statement if
      #you're in a hurry. Then again, you wouldn't be using perl then,
      #would you!?)
      LWP::Debug::trace("\n\tCurrent Server: ".
			scalar (keys %{$self->{'current_connections'}}) .
			" [ ". join (", ", 
			  map { $_, $self->{'current_connections'}->{$_} }
			  keys %{$self->{'current_connections'}}) .
			" ]\n\tPending Server: ".
			($self->{'handle_in_order'}? 
			 scalar @{$self->{'ordpend_connections'}} :
			 scalar (keys %{$self->{'pending_connections'}}) .
			 " [ ". join (", ", 
			  map { $_, 
			       scalar @{$self->{'pending_connections'}->{$_}} }
			       keys %{$self->{'pending_connections'}}) .
			 " ]") );
    } # end of if $sel->handles
    # try to make new connections
    $self->_make_connections;
  } # end of while 'current_connections' or 'pending_connections'
  
  # should we delete fh-queues here?!
  # or maybe re-initialize in case we register more requests later?
  # in that case we'll have to make sure we don't try to reconnect
  # to old sockets later - so we should create new Select-objects!
  $self->_remove_all_sockets();
  
  # allows the caller quick access to all issued requests,
  # although some original requests may have been replaced by
  # redirects or authentication requests...
  return $self->{'entries_by_requests'};
}

# socket handling modularized in order to work better with POE
# as suggested by Kirill http://www.en-directo.net/mail/kirill.html
#
sub _remove_out_socket { 
  my ($self,$socket) = @_; 
  $self->{select_out}->remove($socket);
}

sub _remove_in_socket { 
  my ($self,$socket) = @_; 
  $self->{select_in}->remove($socket);
}

sub _add_out_socket { 
  my ($self,$socket) = @_; 
  $self->{select_out}->add($socket);
}

sub _add_in_socket { 
  my ($self,$socket) = @_; 
  $self->{select_in}->add($socket);
}

sub _remove_all_sockets { 
  my ($self) = @_;
  $self->{select_in} = IO::Select->new();
  $self->{select_out} = IO::Select->new();
}

sub _perform_write
{
  my ($self, $socket, $timeout) = @_;
  LWP::Debug::debug('Writing to Sockets');
  my $entry = $self->{'entries_by_sockets'}->{$socket};
  
  my ( $request, $protocol, $fullpath, $arg, $proxy) = 
    $entry->get( qw(request protocol fullpath arg proxy) );

  my ($listen_socket, $response);
  if ($self->{'use_eval'}) {
    eval {
      ($listen_socket, $response) = 
	$protocol->write_request ($request, 
				  $socket, 
				  $fullpath, 
				  $arg,
				  $timeout,
				  $proxy);
    };
    if ($@) {
      # if our call fails, we might not have a $response object, so we
      # have to create a new one here
      if ($@ =~ /^timeout/i) {
	$response = LWP::UserAgent::_new_response($request, &HTTP::Status::RC_REQUEST_TIMEOUT,
					'User-agent timeout (syswrite)');
      } else {
	# remove file/line number
	# $@ =~ s/\s+at\s+\S+\s+line\s+\d+.*//s;  
	$response = LWP::UserAgent::_new_response($request, &HTTP::Status::RC_INTERNAL_SERVER_ERROR,
					$@);
      }
      $entry->response ($response);
      $self->on_failure ($request, $response, $entry);	    
    }
  } else {
    # user has to handle any dies, usually timeouts
    ($listen_socket, $response) = 
      $protocol->write_request ($request, 
				$socket, 
				$fullpath, 
				$arg,
				$timeout,
				$proxy);
  }

  if ($response and !$response->is_success) {
    $entry->response($response);
    $entry->response->request($request);
    LWP::Debug::trace('Error while issuing request '.
		      $request->url->as_string);
  } elsif ($response) {
           # successful response already?
    LWP::Debug::trace('Fast response for request '.
		      $request->url->as_string . 
		      ' ['. length($response->content) . 
		      ' bytes]');
    $entry->response($response);
    $entry->response->request($request);
    my $content = $response->content;
    $response->content(''); # clear content here, so that it
                            # can be properly processed by ->receive
    unless ($request->method eq 'DELETE') { # JB
        $protocol->receive_once($arg, $response, $content, $entry);
    }
  }
  # one write is (should be?) enough
  delete $self->{'entries_by_sockets'}->{$socket};
  $self->_remove_out_socket($socket);

  if (ref($listen_socket)) {
    # now make sure we start reading from the $listen_socket:
    # file existing entry under new (listen_)socket
    $self->_add_in_socket ($listen_socket);
    $entry->listen_socket($listen_socket);
    $self->{'entries_by_sockets'}->{$listen_socket} = $entry;
  } else {
    # remove from current_connections
    $self->_remove_current_connection ( $entry );
  } 

  return;
}       

sub _perform_read
{
  my ($self, $socket, $timeout) = @_;

  LWP::Debug::debug('Reading from Sockets');
  my $entry = $self->{'entries_by_sockets'}->{$socket};
  
  my ( $request, $response, $protocol, $fullpath, $arg, $size) =
    $entry->get( qw(request response protocol 
		    fullpath arg size) );
  
  my $retval;
  if ($self->{'use_eval'}) {
    eval {
      $retval =  $protocol->read_chunk ($response, $socket, $request,
					$arg, $size, $timeout,
					$entry);
    };
    if ($@) {
      if ($@ =~ /^timeout/i) {
	$response->code (&HTTP::Status::RC_REQUEST_TIMEOUT);
	$response->message ('User-agent timeout (sysread)');
      } else {
	# remove file/line number
	# $@ =~ s/\s+at\s+\S+\s+line\s+\d+.*//s;  
	$response->code (&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
	$response->message ($@);
      }
      $self->on_failure ($request, $response, $entry);	    
    }
  } else {
    # user has to handle any dies, usually timeouts
    $retval =  $protocol->read_chunk ($response, $socket, $request,
				      $arg, $size, $timeout,
				      $entry);
  }

  # examine return value. $retval is either a positive
  # number, indicating the number of bytes read, or
  # '0' (for EOF), or a callback-function code (<0)
  
  LWP::Debug::debug ("'$retval' = read_chunk from $entry (".
		     $request->url.")");
  
  # call on_return method if it's the end of this request
  unless ($retval > 0) {
    my $command = $self->on_return ($request, $response, $entry);
    $retval = $command  if defined $command and $command < 0;
    
    LWP::Debug::debug ("received '". (defined $command ? $command : '[undef]').
		       "' from on_return");
    
  }

  if ($retval > 0) { 
    # In this case, just update response entry
    # $entry->response($response);
  } else { # zero or negative, that means: EOF, C_LASTCON, C_ENDCON, C_ENDALL
    # read_chunk returns 0 if we reached EOF
    $self->_remove_in_socket($socket);
    # use protocol dependent method to close connection
    $entry->protocol->close_connection($entry->response, $socket, 
				$entry->request, $entry->cmd_socket);	    
    #  $socket->shutdown(2); # see "man perlfunc" & "man 2 shutdown"
    close ($socket);
    $socket = undef; # close socket

    # remove from current_connections
    $self->_remove_current_connection ( $entry );
    # handle redirects and security if neccessary
    
    if ($retval eq C_ENDALL) {
      # should we clean up a bit? Remove Select-queues:
      $self->_remove_all_sockets();
      return $self->{'entries_by_requests'};
    } elsif ($retval eq C_LASTCON) {
      # just delete all pending connections
      $self->{'pending_connections'} = {};
      $self->{'ordpend_connections'} = [];
    } else {
      if ($entry->redirect_ok) {
	$self->handle_response ($entry);
      } 
      # pop off next pending_connection (if bandwith available)
      $self->_make_connections;
    }
  }
  return;
}

=item $ua->handle_response($request, $arg [, $size])

Analyses results, handling redirects and security.  This method may
actually register several different, additional requests.

This method should not be called directly. Instead, indicate for each
individual request registered with C<$ua->register()> whether or not
you want Parallel::UserAgent to handle redirects and security, or
specify a default value for all requests in Parallel::UserAgent by
using C<$ua->redirect()>.

=cut

# this should be mainly the old LWP::UserAgent->request, although the
# beginning and end are different (gets all of its data via $entry
# parameter!)  Also, instead of recursive calls this uses
# $ua->register now.

sub handle_response
{
    my($self, $entry) = @_;
    LWP::Debug::trace("-> ($entry [".$entry->request->url->as_string.'] )');

    # check if we should process this response
    # (maybe later - for now always check)

    my ( $response, $request ) = $entry->get( qw( response request ) );
    
    my $code = $response->code;

    LWP::Debug::debug('Handling result: '. 
                      (HTTP::Status::status_message($code) ||
		       "Unknown code $code"));

    if ($code == &HTTP::Status::RC_MOVED_PERMANENTLY or
	$code == &HTTP::Status::RC_MOVED_TEMPORARILY) {

	# Make a copy of the request and initialize it with the new URI
	my $referral = $request->clone;

	# And then we update the URL based on the Location:-header.
	my($referral_uri) = $response->header('Location');
	{
	    # Some servers erroneously return a relative URL for redirects,
	    # so make it absolute if it not already is.
	    local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
	    my $base = $response->base;
	    $referral_uri = $HTTP::URI_CLASS->new($referral_uri, $base)
		            ->abs($base);
	}

	$referral->url($referral_uri);
	$referral->remove_header('Host');

	# don't do anything unless we're allowed to redirect
	return $response unless $self->redirect_ok($referral, $response);  # fix by th. boutell

	# Check for loop in the redirects
	my $count = 0;
	my $r = $response;
	while ($r) {
	    if (++$count > 13 ||
		$r->request->url->as_string eq $referral_uri->as_string) {
		$response->header("Client-Warning" =>
				  "Redirect loop detected");
		return $response;
	    }
	    $r = $r->previous;
	}
	# From: "Andrey A. Chernov" <ache@nagual.pp.ru>
	$self->cookie_jar->extract_cookies($response)
	    if $self->cookie_jar;
	# register follow up request
      LWP::Debug::trace("<- (registering follow up request: $referral, $entry)");
	return $self->register ($referral, $entry);

    } elsif ($code == &HTTP::Status::RC_UNAUTHORIZED ||
	     $code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED
	    )
    {
	my $proxy = ($code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED);
	my $ch_header = $proxy ?  "Proxy-Authenticate" : "WWW-Authenticate";
	my @challenge = $response->header($ch_header);
	unless (@challenge) {
	    $response->header("Client-Warning" => 
			      "Missing Authenticate header");
        # added the argument to header here (a guess at which header) 
        # because it dies if you pass no header https://rt.cpan.org/Ticket/Display.html?id=46821
	  LWP::Debug::trace("<- ($response [".$response->header('Client-Warning').'] )');
	    return $response;
	}
	
	require HTTP::Headers::Util;
	CHALLENGE: for my $challenge (@challenge) {
	  $challenge =~ tr/,/;/;  # "," is used to separate auth-params!!
	  ($challenge) = HTTP::Headers::Util::split_header_words($challenge);
	  my $scheme = lc(shift(@$challenge));
	  shift(@$challenge); # no value
	  $challenge = { @$challenge };  # make rest into a hash
	  for (keys %$challenge) {       # make sure all keys are lower case
	      $challenge->{lc $_} = delete $challenge->{$_};
	  }

	  unless ($scheme =~ /^([a-z]+(?:-[a-z]+)*)$/) {
	    $response->header("Client-Warning" => 
			      "Bad authentication scheme '$scheme'");
        # added the argument to header here (a guess at which header) 
        # because it dies if you pass no header https://rt.cpan.org/Ticket/Display.html?id=46821
	    LWP::Debug::trace("<- ($response [".$response->header('Client-Warning').'] )');
	    return $response;
	  }
	  $scheme = $1;  # untainted now
	  my $class = "LWP::Authen::\u$scheme";
	  $class =~ s/-/_/g;
	
	  no strict 'refs';
	  unless (%{"$class\::"}) {
	    # try to load it
	    eval "require $class";
	    if ($@) {
		if ($@ =~ /^Can\'t locate/) {
		    $response->header("Client-Warning" =>
				      "Unsupport authentication scheme '$scheme'");
		} else {
		    $response->header("Client-Warning" => $@);
		}
		next CHALLENGE;
	    }
	  }
          LWP::Debug::trace("<- authenticates");
	  return $class->authenticate($self, $proxy, $challenge, $response,
				    $request, $entry->arg, $entry->size);
	}
        # added the argument to header here (a guess at which header) 
        # because it dies if you pass no header https://rt.cpan.org/Ticket/Display.html?id=46821
        LWP::Debug::trace("<- ($response [".$response->header('Client-Warning').'] )');
	return $response;
    }
    LWP::Debug::trace("<- standard exit ($response)");
    return $response;
}

# helper function for (simple_)request method.
sub _single_request {
  my $self = shift;
  my $res;
  if ( $res = $self->register (@_) ) { 
    return $res->error_as_HTML;
  }
  my $entries = $self->wait(5);
  foreach (keys %$entries) {
      my $response = $entries->{$_}->response;
#    $cookie_jar->extract_cookies($response) if $cookie_jar;
      $response->header("Client-Date" => HTTP::Date::time2str(time));
      return $response;
  }
}

=item DEPRECATED $ua->deprecated_simple_request($request, [$arg [, $size]])

This method simulated the behavior of LWP::UserAgent->simple_request.
It was actually kinda overkill to use this method in
Parallel::UserAgent, and it was mainly here for testing backward
compatibility with the original LWP::UserAgent. 

The name has been changed to deprecated_simple_request in case you 
need it, but because it it no longer compatible with the most recent
version of libwww, it will no longer run by default.

The following 
description is taken directly from the corresponding libwww pod:

$ua->simple_request dispatches a single WWW request on behalf of a
user, and returns the response received.  The C<$request> should be a
reference to a C<HTTP::Request> object with values defined for at
least the method() and url() attributes.

If C<$arg> is a scalar it is taken as a filename where the content of
the response is stored.

If C<$arg> is a reference to a subroutine, then this routine is called
as chunks of the content is received.  An optional C<$size> argument
is taken as a hint for an appropriate chunk size.

If C<$arg> is omitted, then the content is stored in the response
object itself.

=cut

# sub simple_request
# (see LWP::UserAgent)

# Took this out because with the new libwww it goes into deep
# recursion.  I believe calls that might have hit this will now
# just go to LWP::UserAgent's implementation.  If I comment
# these out, tests pass; with them in, you get this deep
# recursion.  I'm assuming it's ok for them to just
# go away, since they were deprecated many years ago after
# all.
sub deprecated_send_request {
  my $self = shift;
  
  $self->initialize;
  my $redirect = $self->redirect(0);
  my $response = $self->_single_request(@_);
  $self->redirect($redirect);
  return $response;
}

=item DEPRECATED $ua->deprecated_request($request, $arg [, $size])

Previously called 'request' and included for compatibility testing with 
LWP::UserAgent. Every day usage was deprecated, and now you have to call it
with the deprecated_request name if you want to use it (because an incompatibility
was introduced with the newer versions of libwww). 

Here is what LWP::UserAgent has to say about it:

Process a request, including redirects and security.  This method may
actually send several different simple reqeusts.

The arguments are the same as for C<simple_request()>.

=cut

sub deprecated_request {
  my $self = shift;
  
  $self->initialize;
  my $redirect = $self->redirect(1);
  my $response = $self->_single_request(@_);
  $self->redirect($redirect);
  return $response;
}

=item $ua->as_string

Returns a text that describe the state of the UA.  Should be useful
for debugging, if it would print out anything important. But it does
not (at least not yet). Try using LWP::Debug...

=cut

sub as_string {
    my $self = shift;
    my @s;
    push(@s, "Parallel UA: [$self]");
    push(@s, "    <Nothing in here yet, sorry>");
    join("\n", @s, '');
}

1;

#
# Parallel::UserAgent specific methods
#
sub init_request {
    my ($self, $request) = @_;
    my($method, $url) = ($request->method, $request->url);
    LWP::Debug::trace("-> ($request) [$method $url]");

    # Check that we have a METHOD and a URL first
    return LWP::UserAgent::_new_response($request, &HTTP::Status::RC_BAD_REQUEST, "Method missing")
	unless $method;
    return LWP::UserAgent::_new_response($request, &HTTP::Status::RC_BAD_REQUEST, "URL missing")
	unless $url;
    return LWP::UserAgent::_new_response($request, &HTTP::Status::RC_BAD_REQUEST, "URL must be absolute")
	unless $url->scheme;
	

    LWP::Debug::trace("$method $url");

    # Locate protocol to use
    my $scheme = '';

    my $proxy = $self->_need_proxy($url);
    if (defined $proxy) {
	$scheme = $proxy->scheme;
    } else {
	$scheme = $url->scheme;
    }
    my $protocol;
    eval {
	# add Parallel extension here
	$protocol = LWP::Parallel::Protocol::create($scheme);
    };
    if ($@) {
        # remove file/line number
	# $@ =~ s/\s+at\s+\S+\s+line\s+\d+.*//s;  
	return LWP::UserAgent::_new_response($request, &HTTP::Status::RC_NOT_IMPLEMENTED, $@)
    }

    # Extract fields that will be used below
    my ($agent, $from, $timeout, $cookie_jar,
        $use_eval, $parse_head, $max_size, $nonblock) =
      @{$self}{qw(agent from timeout cookie_jar
                  use_eval parse_head max_size nonblock)};

    # Set User-Agent and From headers if they are defined
    $request->init_header('User-Agent' => $agent) if $agent;
    $request->init_header('From' => $from) if $from;
    $request->init_header('Range' => "bytes=0-$max_size") if $max_size;
    $cookie_jar->add_cookie_header($request) if $cookie_jar;

    # Transfer some attributes to the protocol object
    $protocol->can('parse_head') ?
   $protocol->parse_head($parse_head) :
   $protocol->_elem('parse_head', $parse_head);
    $protocol->max_size($max_size);

    LWP::Debug::trace ("<- (undef".
		       ", ". (defined $proxy ? $proxy : '[undef]').
		       ", ". (defined $protocol ? $protocol : '[undef]').
		       ", ". (defined $timeout ? $timeout : '[undef]').
		       ", ". (defined $use_eval ? $use_eval : '[undef]').")");

    (undef, $proxy, $protocol, $timeout, $use_eval, $nonblock);
}

=head1 ADDITIONAL METHODS

=item $ua->use_alarm([$boolean])

This function is not in use anymore and will display a warning when 
called and warnings are enabled.

=cut

sub use_alarm {
    warn "The Parallel::UserAgent->use_alarm method is not available anymore.\n" if $^W;
}

=head1 Callback functions

You can register a callback function. See LWP::UserAgent for details.

=head1 BUGS

Probably lots! This was meant only as an interim release until this
functionality is incorporated into LWPng, the next generation libwww
module (though it has been this way for over 2 years now!)

Needs a lot more documentation on how callbacks work!

=head1 SEE ALSO

L<LWP::UserAgent>

=head1 COPYRIGHT

Copyright 1997-2004 Marc Langheinrich E<lt>marclang@cpan.org>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

__END__
