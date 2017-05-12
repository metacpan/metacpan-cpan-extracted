package POE::Component::Client::SOCKS;
$POE::Component::Client::SOCKS::VERSION = '1.02';
#ABSTRACT: SOCKS enable any POE Component

use strict;
use warnings;
use Carp;
use Socket;
use POE qw(Wheel::SocketFactory Filter::Stream Wheel::ReadWrite);

sub spawn {
  my $package = shift;
  return $package->_create( 'spawn', @_ );
}

sub connect {
  my $self;
  eval {
    if ( (ref $_[0]) && $_[0]->isa(__PACKAGE__) ) {
	$self = shift;
    }
  };
  if ( $self ) {
	$poe_kernel->post( $self->{session_id}, 'connect', @_ );
	return 1;
  }
  my $package = shift;
  return $package->_create( 'connect', @_ );
}

sub bind {
  my $self;
  eval {
    if ( (ref $_[0]) && $_[0]->isa(__PACKAGE__) ) {
	$self = shift;
    }
  };
  if ( $self ) {
	$poe_kernel->post( $self->{session_id}, 'bind', @_ );
	return 1;
  }
  my $package = shift;
  return $package->_create( 'bind', @_ );
}

sub _create {
  my $package = shift;
  my $command = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  my $self = bless { }, $package;
  if ( $command =~ /^(bind|connect)$/ ) {
     unless ( $opts{successevent} and $opts{failureevent} ) {
	warn "You must specify 'SuccessEvent' and 'FailureEvent' for '$command'\n";
        return;
     }
     unless ( $opts{remoteaddress} and $opts{remoteport} ) {
	warn "You must specify 'RemoteAddress' and 'RemotePort'\n";
        return;
     }
     unless ( $opts{socksproxy} ) {
	warn "You must specify 'SocksProxy'\n";
        return;
     }
     if ( $command eq 'bind' and $opts{remoteaddress} !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ) {
	warn "You specified 'bind' but 'RemoteAddress' is not an IP address\n";
        return;
     }
  }
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => { shutdown => '_shutdown',
		      connect  => '_command',
		      bind     => '_command',
	   },
	   $self => [qw(_start
			_disconnect
			_create_socket
			_sock_failed
			_sock_up
			_conn_input
			_conn_error) ],
	],
	heap => $self,
	args => [ $command, %opts ],
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
  return 1;
}

sub _start {
  my ($kernel,$self,$sender,$command,@args) = @_[KERNEL,OBJECT,SENDER,ARG0..$#_];
  $self->{session_id} = $_[SESSION]->ID();
  $self->{filter} = POE::Filter::Stream->new();
  if ( $command eq 'spawn' ) {
     my $opts = { @args };
     $self->{$_} = $opts->{$_} for keys %{ $opts };
     $kernel->alias_set($self->{alias}) if $self->{alias};
     $kernel->refcount_increment($self->{session_id}, __PACKAGE__) unless $self->{alias};
     return;
  }
  if ( $kernel == $sender ) {
	croak "'connect' and 'bind' should be called from another POE Session\n";
  }
  $self->{sender_id} = $sender->ID();
  $kernel->refcount_increment( $self->{sender_id}, __PACKAGE__ );
  $kernel->yield( $command, @args );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  unless ( $self->{sender_id} ) {
     $kernel->alias_remove($_) for $kernel->alias_list();
     $kernel->refcount_decrement($self->{session_id}, __PACKAGE__) unless $self->{alias};
  }
  $kernel->refcount_decrement( $_->{sender_id}, __PACKAGE__ ) for values %{ $self->{socks} };
  $kernel->refcount_decrement( $_->{sender_id}, __PACKAGE__ ) for values %{ $self->{conns} };
  delete $self->{socks};
  delete $self->{conns};
  return;
}

sub _command {
  my ($kernel,$self,$state,$session,$sender) = @_[KERNEL,OBJECT,STATE,SESSION,SENDER];
  my $args;
  if ( ref $_[ARG0] eq 'HASH' ) {
     $args = $_[ARG0];
  }
  else {
     $args = { @_[ARG0..$#_] };
  }
  $args->{cmd} = $state;
  if ( $session == $sender ) {
     $args->{sender_id} = $self->{sender_id};
  }
  else {
     $args->{lc $_} = delete $args->{$_} for keys %{ $args };
     $args->{sender_id} = $sender->ID();
     unless ( $args->{successevent} and $args->{failureevent} ) {
	warn "You must specify 'SuccessEvent' and 'FailureEvent'\n";
        return;
     }
     unless ( $args->{remoteaddress} and $args->{remoteport} ) {
	warn "You must specify 'RemoteAddress' and 'RemotePort'\n";
        return;
     }
     unless ( $args->{socksproxy} ) {
	warn "You must specify 'SocksProxy'\n";
        return;
     }
     if ( $state eq 'bind' and $args->{remoteaddress} !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ) {
	warn "You specified 'bind' but 'RemoteAddress' is not an IP address\n";
        return;
     }
     $kernel->refcount_increment( $args->{sender_id}, __PACKAGE__ );
  }
  if ( $state eq 'connect' ) {
    if ( $args->{remoteaddress} =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ) {
      # SOCKS 4
      $args->{packet} = pack ('CCn', 4, 1, $args->{remoteport}) .
	inet_aton($args->{remoteaddress}) . ( $args->{socks_id} || '' ) . (pack 'x');
    }
    else {
      # SOCKS 4a
      $args->{packet} = pack ('CCn', 4, 1, $args->{remoteport}) .
	inet_aton('0.0.0.1') . ( $args->{socks_id} || '' ) . (pack 'x') .
	$args->{remoteaddress} . (pack 'x');
    }
  }
  else {
    $args->{packet} = pack ('CCn', 4, 2, $args->{remoteport}) .
      inet_aton($args->{remoteaddress}) . ( $args->{socks_id} || '' ) . (pack 'x');
  }
  $kernel->yield( '_create_socket', $args );
  return;
}

sub _create_socket {
  my ($kernel,$self,$args) = @_[KERNEL,OBJECT,ARG0];
  my $factory = POE::Wheel::SocketFactory->new(
    SocketDomain   => AF_INET,
    SocketType     => SOCK_STREAM,
    SocketProtocol => 'tcp',
    RemoteAddress  => $args->{socksproxy},
    RemotePort     => $args->{socksport} || 1080,
    SuccessEvent   => '_sock_up',
    FailureEvent   => '_sock_failed',
  );
  $args->{factory} = $factory;
  $self->{socks}->{ $factory->ID } = $args;
  return;
}

sub _sock_failed {
  my ($kernel,$self,$operation,$errnum,$errstr,$factory_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  my $args = delete $self->{socks}->{ $factory_id };
  delete $args->{factory};
  delete $args->{packet};
  my $sender_id = delete $args->{sender_id};
  $args->{sockerr} = [ $operation, $errnum, $errstr ];
  $kernel->refcount_decrement( $sender_id, __PACKAGE__ );
  $kernel->post( $sender_id, $args->{failureevent}, $args );
  return;
}

sub _sock_up {
  my ($kernel,$self,$socket,$peeraddr,$peerport,$fact_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  $peeraddr = inet_aton( $peeraddr );
  my $args = delete $self->{socks}->{ $fact_id };
  delete $args->{factory};
  $args->{socket} = $socket;
  my $wheel = POE::Wheel::ReadWrite->new(
     Handle       => $socket,
     Filter       => $self->{filter},
     InputEvent   => '_conn_input',
     ErrorEvent   => '_conn_error',
  );
  $args->{wheel} = $wheel;
  $self->{conns}->{ $wheel->ID } = $args;
  $wheel->put( $args->{packet} );
  return;
}

sub _conn_input {
  my ($kernel,$self,$input,$wheel_id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  if ( length $input != 8 ) {
     $kernel->yield( '_disconnect', $wheel_id, 'Mangled response from SOCKS proxy' );
     return;
  }
  my @resp = unpack "CCnN", $input;
  unless ( scalar @resp == 4 and $resp[0] eq '0' and $resp[1] =~ /^(90|91|92|93)$/ ) {
     $kernel->yield( '_disconnect', $wheel_id, 'Mangled response from SOCKS proxy' );
     return;
  }
  my ($vn,$cd,$dstport,$dstip) = @resp;
  my $args = delete $self->{conns}->{ $wheel_id };
  delete $args->{wheel};
  delete $args->{packet};
  my $sender_id = delete $args->{sender_id};
  unless ( $cd eq '90' ) {
     delete $args->{socket};
     $args->{socks_error} = $cd;
     $kernel->post( $sender_id, $args->{failureevent}, $args );
     $kernel->refcount_decrement( $sender_id, __PACKAGE__ );
     return;
  }
  $args->{socks_response} = [ $cd, inet_ntoa( pack "N", $dstip ), $dstport ];
  $kernel->post( $sender_id, $args->{successevent}, $args );
  $kernel->refcount_decrement( $sender_id, __PACKAGE__ );
  return;
}

sub _conn_error {
  my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  my $args = delete $self->{conns}->{ $wheel_id };
  delete $args->{wheel};
  delete $args->{socket};
  delete $args->{packet};
  my $sender_id = delete $args->{sender_id};
  $args->{sockerr} = [ $operation, $errnum, $errstr ];
  $kernel->post( $sender_id, $args->{failureevent}, $args );
  $kernel->refcount_decrement( $sender_id, __PACKAGE__ );
  return;
}

sub _disconnect {
  my ($kernel,$self,$wheel_id,$reason) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $args = delete $self->{conns}->{ $wheel_id };
  delete $args->{wheel};
  delete $args->{socket};
  delete $args->{packet};
  my $sender_id = delete $args->{sender_id};
  $args->{socks_unknown} = $reason;
  $kernel->refcount_decrement( $sender_id, __PACKAGE__ );
  $kernel->post( $sender_id, $args->{failureevent}, $args );
  return;
}

'SOCKS it to me!';

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Client::SOCKS - SOCKS enable any POE Component

=head1 VERSION

version 1.02

=head1 SYNOPSIS

Spawning a SOCKS broker:

   use strict;
   use POE qw(Component::Client::SOCKS Wheel::ReadWrite Filter::Line);
   use Data::Dumper;

   my $poco = POE::Component::Client::SOCKS->spawn( options => { trace => 0 } );

   POE::Session->create(
	  package_states => [
      'main' => [ qw(_start _success _failed _conn_input _conn_error) ],
    ],
    heap => { sockify => $poco },
    options => { trace => 0 },
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     my ($kernel,$heap) = @_[KERNEL,HEAP];
     $heap->{sockify}->connect( 
      SocksProxy => '127.0.0.1',
      RemoteAddress => 'cou.ch',
      RemotePort => 6667,
      SuccessEvent => '_success',
      FailureEvent => '_failed',
     );
     return;
   }

   sub _success {
     my ($heap,$args) = @_[HEAP,ARG0];
     warn Dumper( $args );
     $heap->{wheel} = POE::Wheel::ReadWrite->new(
      Handle => $args->{socket},
      Filter => POE::Filter::Line->new(),
      InputEvent => '_conn_input',
      ErrorEvent => '_conn_error',
     );
     return;
   }

   sub _failed {
     warn Dumper( $_[ARG0] );
     return;
   }

   sub _conn_input {
     warn $_[ARG0], "\n";
     return;
   }

   sub _conn_error {
     delete $_[HEAP]->{wheel};
     return;
   }

A one shot CONNECT request:

   use strict;
   use POE qw(Component::Client::SOCKS Wheel::ReadWrite Filter::Line);
   use Data::Dumper;

   POE::Session->create(
    package_states => [
      'main' => [ qw(_start _success _failed _conn_input _conn_error) ],
    ],
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     my ($kernel,$heap) = @_[KERNEL,HEAP];
     POE::Component::Client::SOCKS->connect( 
      SocksProxy => '127.0.0.1',
      RemoteAddress => 'cou.ch',
      RemotePort => 6667,
      SuccessEvent => '_success',
      FailureEvent => '_failed',
     );
     return;
   }

   sub _success {
     my ($heap,$args) = @_[HEAP,ARG0];
     warn Dumper( $args );
     $heap->{wheel} = POE::Wheel::ReadWrite->new(
      Handle => $args->{socket},
      Filter => POE::Filter::Line->new(),
      InputEvent => '_conn_input',
      ErrorEvent => '_conn_error',
     );
     return;
   }

   sub _failed {
     warn Dumper( $_[ARG0] );
     return;
   }

   sub _conn_input {
     warn $_[ARG0], "\n";
     return;
   }

   sub _conn_error {
     delete $_[HEAP]->{wheel};
     return;
   }

=head1 DESCRIPTION

POE::Component::Client::SOCKS provides SOCKSification services to other POE sessions and components. It
accepts connection requests and deals with all the SOCKS negotiation on your behalf. It returns either a
SuccessEvent which will have a shiny socket handle for you to use or an FailureEvent which should say what went wrong.

SOCKS 4 and 4a based servers are supported.

=head1 CONSTRUCTORS

One may start POE::Component::Client::SOCKS in two ways. If you spawn it creates a session that can then broker lots
of SOCKS connections on your behalf. Or you may use 'connect' and 'bind' to broker one connection instance.

  POE::Component::Client::SOCKS->spawn( ... );

  POE::Component::Client::SOCKS->connect( ... );

  POE::Component::Client::SOCKS->bind( ... );

=over

=item C<spawn>

Creates a new POE::Component::Client::SOCKS session that may be used lots of times. Takes the following optional
parameters:

  'alias', set an alias that you can use to address the component later;
  'options', a hashref of POE session options;

Returns an object.

=item C<connect>

Creates a one-shot POE::Component::Client::SOCKS session that will connect to a SOCKS server and negotiate a
CONNECT. Takes the following parameters ( mandatory ones are indicated ):

  'SocksProxy', the SOCKS server that you want to connect to (Mandatory);
  'RemoteAddress', the address that you want the SOCKS proxy to connect to (Mandatory);
  'RemotePort', the port that you want the SOCKS proxy to connect to (Mandatory);
  'SuccessEvent', the event that will be sent when a CONNECT is successful (Mandatory);
  'FailureEvent', the event to send when a CONNECT is not successful or errored (Mandatory);
  'SocksPort', the SOCKS server port to connect to (default is 1080);

Takes any number of arbitary parameters that will passed through to the SuccessEvent/FailureEvent. Please use underscore prefixes to avoid future API changes.

=item C<bind>

Creates a one-shot POE::Component::Client::SOCKS session that will connect to a SOCKS server and negotiate a
BIND. Takes the following parameters ( mandatory ones are indicated ):

  'SocksProxy', the SOCKS server that you want to connect to (Mandatory);
  'RemoteAddress', the address that you want the SOCKS proxy to connect to (Mandatory);
  'RemotePort', the port that you want the SOCKS proxy to connect to (Mandatory);
  'SuccessEvent', the event that will be sent when a BIND is successful (Mandatory);
  'FailureEvent', the event to send when a BIND is not successful or errored (Mandatory);
  'SocksPort', the SOCKS server port to connect to (default is 1080);

Takes any number of arbitary parameters that will passed through to the SuccessEvent/FailureEvent. Please use underscore prefixes to avoid future API changes.

=back

=head1 METHODS

=over

=item C<connect>

Connect to a SOCKS server and negotiate a
CONNECT. Takes the following parameters ( mandatory ones are indicated ):

  'SocksProxy', the SOCKS server that you want to connect to (Mandatory);
  'RemoteAddress', the address that you want the SOCKS proxy to connect to (Mandatory);
  'RemotePort', the port that you want the SOCKS proxy to connect to (Mandatory);
  'SuccessEvent', the event that will be sent when a CONNECT is successful (Mandatory);
  'FailureEvent', the event to send when a CONNECT is not successful or errored (Mandatory);
  'SocksPort', the SOCKS server port to connect to (default is 1080);

Takes any number of arbitary parameters that will passed through to the SuccessEvent/FailureEvent. Please use underscore prefixes to avoid future API changes.

=item C<bind>

Connect to a SOCKS server and negotiate a
BIND. Takes the following parameters ( mandatory ones are indicated ):

  'SocksProxy', the SOCKS server that you want to connect to (Mandatory);
  'RemoteAddress', the address that you want the SOCKS proxy to connect to (Mandatory);
  'RemotePort', the port that you want the SOCKS proxy to connect to (Mandatory);
  'SuccessEvent', the event that will be sent when a BIND is successful (Mandatory);
  'FailureEvent', the event to send when a BIND is not successful or errored (Mandatory);
  'SocksPort', the SOCKS server port to connect to (default is 1080);

Takes any number of arbitary parameters that will passed through to the SuccessEvent/FailureEvent. Please use underscore prefixes to avoid future API changes.

=item C<shutdown>

Terminates the component. Disconnects any pending SOCKS requests.

=item C<session_id>

=back

=head1 INPUT EVENTS

=over

=item C<connect>

Connect to a SOCKS server and negotiate a
CONNECT. Takes the following parameters ( mandatory ones are indicated ):

  'SocksProxy', the SOCKS server that you want to connect to (Mandatory);
  'RemoteAddress', the address that you want the SOCKS proxy to connect to (Mandatory);
  'RemotePort', the port that you want the SOCKS proxy to connect to (Mandatory);
  'SuccessEvent', the event that will be sent when a CONNECT is successful (Mandatory);
  'FailureEvent', the event to send when a CONNECT is not successful or errored (Mandatory);
  'SocksPort', the SOCKS server port to connect to (default is 1080);

Takes any number of arbitary parameters that will passed through to the SuccessEvent/FailureEvent. Please use underscore prefixes to avoid future API changes.

=item C<bind>

Connect to a SOCKS server and negotiate a
BIND. Takes the following parameters ( mandatory ones are indicated ):

  'SocksProxy', the SOCKS server that you want to connect to (Mandatory);
  'RemoteAddress', the address that you want the SOCKS proxy to connect to (Mandatory);
  'RemotePort', the port that you want the SOCKS proxy to connect to (Mandatory);
  'SuccessEvent', the event that will be sent when a BIND is successful (Mandatory);
  'FailureEvent', the event to send when a BIND is not successful or errored (Mandatory);
  'SocksPort', the SOCKS server port to connect to (default is 1080);

Takes any number of arbitary parameters that will passed through to the SuccessEvent/FailureEvent. Please use underscore prefixes to avoid future API changes.

=item C<shutdown>

Terminates the component. Disconnects any pending SOCKS requests.

=back

=head1 OUTPUT EVENTS

The component returns either a SuccessEvent or an FailureEvent, you specify the events in your session that you wish to
be triggered for each type. ARG0 will be a hashref. See details following.

Any arbitary parameters passed though will be in the returned hashref.

=over

=item C<SuccessEvent>

All the parameters passed to 'connect' or 'bind' will be present, plus:

  'socket', the socket handle of the connection to the SOCKS server;
  'socks_response', an arrayref consisting of the reply from the SOCKS server:
	            the result code, the dest IP and the dest port.

For a BIND, the dest IP and the dest port are the address and port that the SOCKS server has opened for
listening.

=item C<FailureEvent>

Generated if something went wrong, either a connection could not be established with the SOCKS server or
the SOCKS server rejected our request.

If a connection to the SOCKS server could not be established then the following will exist:

  'sockerr', an arrayref containing the operation, errnum and errstr as returned by 
	     POE::Wheel::SocketFactory;

If the SOCKS server rejected our request for some reason the following will exist:

  'socks_unknown', a string error message. This is generated if we get a garbled response
		   from the SOCKS server;
  'socks_error', an integer response from the SOCKS server, indicating that it has rejected the
		 request.

=back

=head1 SEE ALSO

L<http://socks.permeo.com/protocol/socks4.protocol>

L<http://socks.permeo.com/protocol/socks4a.protocol>

L<POE::Wheel::SocketFactory>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
