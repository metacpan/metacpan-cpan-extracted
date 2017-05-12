# $Id: TCP.pm,v 1.2 2004/08/02 09:40:41 avpurshottam Exp $
# TCP Proxy Component - Andrew v. Purshottam andy@andypurshottam.com 22 Jun 2004
# Module structure adapted from PoCo::Server::TCP

# to do:
#   - clean up exported logic below
#   - rationalize and document session aliases
#   - document the connection between per client server sessions and 
#     per client client [sic!] sessions 
#   - change  OrigPort and OrigAddress to RemotePort and RemoteServer
#   - should the test code get installed and if so where? Study a famous module
#     for example.

package POE::Component::Proxy::TCP;

use strict;
use Exporter();

use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);

@EXPORT = qw();
use vars qw($VERSION);
$VERSION = (qw($Revision: 1.2 $ ))[1];

use Carp qw(carp croak);
use Socket qw(INADDR_ANY inet_ntoa);
use POSIX qw(ECONNABORTED ECONNRESET);

use POE;
use POE::Component::Client::TCP;
use POE::Filter::Stream;
use POE::Filter::Line;
use POE::Session;
use POE::Component::Server::TCP;

use POE::Component::Proxy::TCP::PoeDebug;

use fields qw(clients  alias address
	      orig_address port remote_client_filter
	      remote_server_input_filter remote_server_output_filter 
	      data_from_client data_from_server 
	      session_type session_params args client_connected
);

sub new {
  my $type = shift;

  # Helper so we don't have to type it all day.  $mi is a name I call
  # myself.
  my $mi = $type . '->new()';
  # All instance state should now live in the hash.
  my $self = bless {@_},$type;

  # hash mapping server session ids to client session ids.
  $self->{clients} = {};

  # param list is list of name, value pairs so must be even number.
  croak "$mi requires an even number of parameters." if (@_ & 1);
  my %param = @_;

  # Validate what we're given.
  croak "$mi needs a Port parameter" unless exists $param{Port};

  # Extract parameters.
  $self->{alias}   = delete $param{Alias};
  $self->{address} = delete $param{Address};
  $self->{orig_address} = delete $param{OrigAddress};
  $self->{port}    = delete $param{Port};
  $self->{orig_port}    = delete $param{OrigPort};
  $self->{remote_client_filter} = delete $param{RemoteClientFilter};
  $self->{remote_server_input_filter} = delete $param{RemoteServerInputFilter};
  $self->{remote_server_output_filter} = delete $param{RemoteServerOutputFilter};

  foreach ( qw( DataFromClient DataFromServer)) {
    croak "$_ must be a coderef"
      if defined($param{$_}) and ref($param{$_}) ne 'CODE';
  }

  $self->{data_from_client}    = delete $param{DataFromClient};
  $self->{data_from_server}      = delete $param{DataFromServer};

  # Defaults.
  $self->{address} = INADDR_ANY unless defined $self->{address};
  $self->{remote_client_filter} = "POE::Filter::Stream" 
    unless defined $self->{remote_client_filter};
  $self->{remote_server_input_filter} = "POE::Filter::Stream" 
    unless defined $self->{remote_server_input_filter};
  $self->{remote_server_output_filter} = "POE::Filter::Stream" 
    unless defined $self->{remote_server_output_filter};

  $self->{session_type} = 'POE::Session' unless defined $self->{session_type};
  if (defined($self->{session_params}) && ref($self->{session_params})) {
    if (ref($self->{session_params}) ne 'ARRAY') {
      croak "SessionParams must be an array reference";
    }   
  } else {
    $self->{session_params} = [ ];
  }

#   $self->{client_error}  = \&_default_client_error unless defined $self->{client_error};
  $self->{client_connected}    = sub {} unless defined $self->{client_connected};
#   $self->{client_disconnected} = sub {} unless defined $self->{client_disconnected};
#   $self->{client_flushed}      = sub {} unless defined $self->{client_flushed};

  $self->{data_from_client}    = sub {} unless defined $self->{data_from_client};
  $self->{data_from_server}    = sub {} unless defined $self->{data_from_server};

  $self->{args} = [] unless defined $self->{args};
  
  # Extra states.
  
  
  my $shutdown_on_error = 1;
  if (exists $param{ClientShutdownOnError}) {
    $shutdown_on_error = delete $param{ClientShutdownOnError};
  }
  
  # Complain about strange things we're given.
  foreach (sort keys %param) {
    carp "$mi doesn't recognize \"$_\" as a parameter";
  }
  
  # Server side of proxy, clients connect to this
  $self->{server_component} = POE::Component::Server::TCP->new
    (Alias => $self->{alias},
     Port               => $self->{port},
     InlineStates       => { send => sub {
			       my ( $heap, $message ) = @_[ HEAP, ARG0 ];
			       dbprint(5, "sending to client:$message");
			       $heap->{client}->put($message);
			       
			     } },
     Args => [$self], # so handle_client_connect_to_proxy_server gets $self
     ClientConnected    => \&handle_client_connect_to_proxy_server,
     ClientError        => \&handle_remote_client_error, 
     ClientDisconnected => \&handle_remote_client_disconnect,
     ClientInput        => \&handle_input_from_remote_client,
     ClientInputFilter  => $self->{remote_server_input_filter},
     ClientOutputFilter => $self->{remote_server_output_filter}
    );
  return $self;
}

sub handle_remote_client_error {
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
  my $self = $heap->{self};
  my $session_id = $session->ID;
  dbprint(1, "Client $session_id disconnected due to error .");
  delete $self->{clients}->{$session_id};
  #  XXX delete proxy client on heap???
};

sub handle_remote_client_disconnect {
  my ( $kernel, $session, $heap ) = @_[ KERNEL, SESSION, HEAP ];
  my $self = $heap->{self};
  my $session_id = $session->ID;
  delete $heap->{proxy_client};
  delete $self->{clients}->{$session_id};
  dbprint(1, "Client $session_id disconnected.");
};

sub handle_input_from_remote_client {
  my ( $kernel, $session, $heap, $input ) = @_[ KERNEL, SESSION, HEAP, ARG0 ];
  my $self = $heap->{self};
  my $session_id = $session->ID;
  my $proxy_client_session_alias = $self->{clients}->{$session_id};
  
  dbprint(3, "Input:$input from $session_id sending to ", 
    $heap->{proxy_client_session_alias});

  # send the input to the remote server
  $kernel->post($heap->{proxy_client_session_alias}, "send_server", $input);
  # do whatever application specification processing is called for.
  $self->{data_from_client}->($input);
}

# called in a Proxy Server Connection Session, passed self as parameter,
# responsible for setting in session heap.
sub handle_client_connect_to_proxy_server {
  my ( $kernel, $session, $heap, $self ) = @_[ KERNEL, SESSION, HEAP, ARG0 ];
  # The per client session spawed by PoCo::Server::TCP
  my $session_id = $session->ID;
  # Standard alias name.
  # XXX Should use the alias passed to constructor as prefix!
  my $proxy_client_session_alias = $self->{alias} . "client". $session_id; 
  $heap->{proxy_client_session_alias} = $proxy_client_session_alias;
  # Provides access to proxy object in per client connection  server component session.
  $heap->{self} = $self;
  $self->{clients}->{$session_id} = $proxy_client_session_alias;
  dbprint(2, "Client $session_id connected.");
  # invoke the client connected callback.
  $self->{client_connected}->($session_id); 
  # self is passed down to Proxy Client Connection session.
  # Create the per client connection client component session.
  $heap->{proxy_client} = 
    POE::Component::Client::TCP->new
	( Alias => $proxy_client_session_alias,
	  RemoteAddress => $self->{orig_address},
	  RemotePort => $self->{orig_port},
	  Filter     => $self->{remote_client_filter},
	  Args => [$self],
	  Started => sub {
	    my ( $kernel, $heap, $inner_self) = @_[ KERNEL, HEAP, ARG0];
	    $heap->{parent_client_session} = $session_id;
	    $heap->{self} = $inner_self;
	    $heap->{is_connected_to_server} = 0;
	    dbprint(3, "connected to $inner_self->{orig_address}:$inner_self->{orig_port}");
	  },
	  Connected => sub {
	    my ( $kernel, $heap) = @_[ KERNEL, HEAP];
	    $heap->{is_connected_to_server} = 1;
	    $heap->{parent_client_session} = $session_id;
	    dbprint(3, "connected to $self->{orig_address}:$self->{orig_port}");
	  },
	  
	  # The connection failed.
	  ConnectError => sub {
	    dbprint(1, "could not connect to $self->{orig_address}:$self->{orig_port}");
	    $heap->{is_connected_to_server} = 0;
	    # XXX do something to shut the system down
	    # no in some applications wish to keep going and wait for new connection.
	    #$_[KERNEL]->yield("shutdown");
	  },
	  
	  # The remote server has sent us something, 
	  # so send it to the remote client and perform
	  # whatever aookication specific log (eg logging to
	  # screen) is required.
	  ServerInput => sub {
	    my ( $kernel, $heap, $input ) = @_[ KERNEL, HEAP, ARG0 ];
	    if (defined($input)) {
	      dbprint(3, "Input from remote server $self->{orig_address} :", 
		    "$self->{orig_port}: -$input- sending to",
		      "remote client and any callback");
	      $kernel->post($heap->{parent_client_session}, 
			    "send", $input);
	      $self->{data_from_server}->($input);
	    } else {
	      dbprint(1, "ServerInput event but no input!");
	    }
	  },
	  
	  ConnectError => sub  {
	    my ($syscall_name, $error_number, $error_string) = @_[ARG0, ARG1, ARG2];
	    dbprint(2, "ConnectError from ORIG_SERVER on", 
	      " $self->{orig_port} : $self->{orig_address}");
	  },
	  
	  Disconnected   => sub {
	    dbprint(1, "Disconnected from ORIG_SERVER on", 
	      "$self->{orig_port} : $self->{orig_address}");
	    $_[KERNEL]->post($session_id, "shutdown");
	  },
	  
	  ServerError => sub  {
	    my ($syscall_name, $error_number, $error_string) = @_[ARG0, ARG1, ARG2];
	    dbprint(1, "ServerError from ORIG_SERVER on $self->{orig_port} :",
	      "$self->{orig_address}");
	  },
	  
	  InlineStates =>
	  {             
	   # Send data to the server.
	   send_server => sub {
	     my ( $heap, $message ) = @_[ HEAP, ARG0 ];
	     dbprint(3, "sending to server:$self->{orig_address}:$self->{orig_port}:",
	       "mess:$message.");
	     if ($heap->{is_connected_to_server}) {
	       $heap->{server}->put($message);
	     } else {
	       dbprint(1, "send_server error not connected to server.");
	     }
	   },
	  },
	);
}

# The default server error handler logs to STDERR and shuts down the
# server connection.
# XXX remove both of these somoday, they are not used.

sub _default_server_error {
  warn( 'Server ', $_[SESSION]->ID,
	" got $_[ARG0] error $_[ARG1] ($_[ARG2])\n"
      );
  # delete $_[HEAP]->{listener};
}

# The default client error handler logs to STDERR and shuts down the
# client connection.

sub _default_client_error {
  my ($syscall, $errno, $error) = @_[ARG0..ARG2];
  unless ($syscall eq "read" and ($errno == 0 or $errno == ECONNRESET)) {
    $error = "(no error)" unless $errno;
    warn(
	 'Client session ', $_[SESSION]->ID,
	 " got $syscall error $errno ($error)\n"
	);
  }
}

1;

__END__

=head1 NAME

POE::Component::Proxy::TCP - a simplified TCP proxy

=head1 SYNOPSIS

  use POE qw(Component::Proxy::TCP);
  POE::Component::Proxy::TCP->new
  (Alias => "ProxyServerSessionAlias",
   Port               => $local_server_port,
   OrigPort           => $remote_server_port,
   OrigAddress        => $remote_server_host,
   DataFromClient    => \&data_from_client_handler,
   DataFromServer    => \&data_from_server_handler,
  );


  # gets called with data passed from server.
  # called inside the per client connected session created by PoCo::Server::TCP
  sub data_from_server_handler {
    my $server_data = shift; 
    # show obtaining other session info esp per proxy session info
  };

  # gets called with data passed from remote client
  # 
  sub data_from_client_handler {
    my $server_data = shift; 
  };

  # show obtaining other session info esp per proxy session info
  # Reserved HEAP variables:

  $heap->{self}        = Proxy object / instance var hash 
  $heap->{self}->losta stuff add documentation
  [do the per connection ones]


=head1 EXAMPLE

  use warnings;
  use strict;
  use diagnostics;
  use POE;
  use POE::Filter::Stream;
  use POE::Filter::Line;
  use POE::Component::Proxy::TCP;
  $|++;  

  POE::Component::Proxy::TCP->new
  (Alias => "ProxyServerSessionAlias",
   Port               => 4000,
   OrigPort           => 5000,
   OrigAddress        => "localhost",
   DataFromClient    => sub {print "From client:", shift(), "\n";},
   DataFromServer    => sub {print "From server:", shift(), "\n";},
   RemoteClientFilter => "POE::Filter::Stream",
   RemoteServerOutputFilter => "POE::Filter::Stream",
   RemoteServerInputFilter => "POE::Filter::Stream"
  );

  $poe_kernel->run();
  exit 0;

=head1 DESCRIPTION

The POE::Component::Proxy::TCP proxy component hides the steps needed
to create a TCP proxy server using PoCo::Server::TCP and
PoCo::Client::TCP.  The steps aren't many, but they're still tiresome
after a while.

The proxy that PoCo::Client::TCP helps you create accepts tcp
connections on a specified well-know port from remote clients, and
connects to a remote server at a specified host and port. It then
copies all data that it receives from either side to the other,
calling given callbacks to perform any application specific
processing.  When writing callbacks, one must pay attention to which
session runs the callback and what heap variables are available in
that session.

=head2 Session Structure

  - Proxy Server Listener Session, created by PoCo::Server::TCP
    - Proxy Server Connection Sessions, per remote client connection
      Created in PoCo::Server:
      - Proxy Client Connection Sessions, created by 
        PoCo::Client::TCP

  Constructor parameters:

=over 2
 
=item Alias

Alias is an optional name by which the server side of the proxy
will be named.

  Alias => 'proxyServer'

=item DataFromClient

DataFromClient is a coderef that will be called to handle input
recieved from the remote client.  The callback receives its parameters
directly from PoCo::Client::TCP after its fileration.  ARG0 is the
input record. This coderef is executed in a Proxy Client Connection
Session. @_[HEAP]->{self} holds a reference to the proxy object from
which various parameters by be obtained.


  DataFromClient => \&data_input_handler

=item DataFromServer

DataFromServer is a coderef that will be called to handle input
recieved from the remote server.  The callback receives its parameters
directly from PoCo::Server::TCP after its fileration.  ARG0 is the
input record. This coderef is executed in a Proxy Server Connection
Session. @_[HEAP]->{self} holds a reference to the proxy object from
which various parameters by be obtained.

  DataFromServer => \&server_data_input_handler


=item RemoteClientFilter

[The sense of client and server in what follows is reversed! Yeah, I know
why that is, but its ugly and should get fixed someday.]

RemoteClientFilter specifies the type of filter that will parse input from
the server (!).  It may either be a scalar or a list reference.  If it is
a scalar, it will contain a POE::Filter class name.  If it is a list
reference, the first item in the list will be a POE::Filter class
name, and the remaining items will be constructor parameters for the
filter.  For example, this changes the line separator to a vertical
bar:

  RemoteClientFilter => [ "POE::Filter::Line", InputLiteral => "|" ],

RemoteClientFilter is optional.  The component will supply a
"POE::Filter::Stream" instance if none is specified.  If you supply a
different value for Filter, then you must also C<use> that filter
class.

=item RemoteServerInputFilter

RemoteServerInputFilter specifies the type of filter that will parse input from
each client.  It may either be a scalar or a list reference.  If it is
a scalar, it will contain a POE::Filter class name.  If it is a list
reference, the first item in the list will be a POE::Filter class
name, and the remaining items will be constructor parameters for the
filter.  For example, this changes the line separator to a vertical
bar:

  RemoteServerInputFilter => [ "POE::Filter::Line", InputLiteral => "|" ],

RemoteServerInputFilter is optional.  The component will supply a
"POE::Filter::Stream" instance if none is specified.  If you supply a
different value for Filter, then you must also C<use> that filter
class.

=item RemoteServerOutputFilter

RemoteServerOutputFilter specifies the type of filter that will parse input from
each client.  It may either be a scalar or a list reference.  If it is
a scalar, it will contain a POE::Filter class name.  If it is a list
reference, the first item in the list will be a POE::Filter class
name, and the remaining items will be constructor parameters for the
filter.  For example, this changes the line separator to a vertical
bar:

  RemoteServerOutputFilter => [ "POE::Filter::Line", InputLiteral => "|" ],

RemoteServerOutputFilter is optional.  The component will supply a
"POE::Filter::Stream" instance if none is specified.  If you supply a
different value for Filter, then you must also C<use> that filter
class.

=item OrigPort

OrigPort is the port the to which the proxy server will connect to when client
connects to the proxy server.

  Port => 80

=item Port

Port is the port the on which the proxy server will listen for tcp connections.

  Port => 30023

=item OrigAddress

Address or host to which the proxy will connect when connected to by a
client.  It defaults to localhost.  It's passed directly to
PoCo::Client::TCP as its RemoteAddress parameter, so it can be in
whatever form SocketFactory supports.  At the time of this writing,
that's a dotted quad, an IPv6 address, a host name, or a packed
Internet address.

  Address => '127.0.0.1'   # Localhost IPv4
  Address => "::1"         # Localhost IPv6
  Address =>'www.dc.state.fl.us'

=back

=head1 EVENTS


=head1 SEE ALSO

  POE::Component::Server::TCP, POE::Component::Client::TCP, 
  POE::Wheel::SocketFactory, POE::Wheel::ReadWrite, POE::Filter

=head1 CAVEATS

Like most reusable components, PoCo::Proxy::TCP started as a hardcoded
fragement of another project, and was converted to a component by
parameterization.  Undoubtly thare are still hardcoded elements that
need to be changed for given applications that can now only be changed
by hacking the source.  This will be fixed incrementally. Suggestions
encouraged. In particular, there outght to be a semistandard way to 
added states to to nested sessions.[There almost is one implied by other
PoCos I think?.]

=head1 BUGS



=head1 AUTHORS & COPYRIGHTS

POE::Component::Proxy::TCP is Copyright 2004 by Andrew V. Purshottam.
All rights are reserved.  POE::Component::Proxy::TCP is free
software, and it may be redistributed and/or modified under the same
terms as Perl itself.

 POE::Component::Proxy::TCP is based on:
  - POE::Component::Server::TCP - for module structure and parameter 
    handling.
  - POE::Component::Server::HTTP - for instance variable conventions

This POD is based on PODs in POE distribution, which were probably 
mainly written by Rocco.

=cut
