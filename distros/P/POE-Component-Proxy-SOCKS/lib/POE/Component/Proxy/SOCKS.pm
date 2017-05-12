package POE::Component::Proxy::SOCKS;
$POE::Component::Proxy::SOCKS::VERSION = '1.04';
#ABSTRACT: A POE based SOCKS 4 proxy server.

use strict;
use warnings;
use POE qw(Component::Client::Ident Component::Client::DNS Wheel::SocketFactory Wheel::ReadWrite Filter::Stream);
use Socket;
use Net::Netmask;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => { shutdown       => '_shutdown',
		      send_event     => '__send_event',
		      ident_agent_reply => '_ident_agent_reply',
		      ident_agent_error => '_ident_agent_error',
	            },
	   $self => [ qw(
			_start
			register
			unregister
			_accept_client
			_accept_failed
			_conn_input
			_conn_error
			_conn_alarm
			__send_event
			_ident_done
			_reject_client
			_dns_response
			_do_connect
			_do_bind
			_sock_connection
			_sock_up
			_sock_failed
			_sock_input
			_sock_down
			_sock_alarm
			_bind_request
		        )
	   ],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub _conn_exists {
  my ($self,$wheel_id) = @_;
  return 0 unless $wheel_id and defined $self->{clients}->{ $wheel_id };
  return 1;
}

sub _link_exists {
  my ($self,$wheel_id) = @_;
  return 0 unless $wheel_id and defined $self->{links}->{ $wheel_id };
  return 1;
}

sub _sock_exists {
  my ($self,$wheel_id) = @_;
  return 0 unless $wheel_id and defined $self->{sockets}->{ $wheel_id };
  return 1;
}

sub _bind_request {
  my ($self,$id) = @_;
  return unless $self->_conn_exists( $id );
  my $client = $self->{clients}->{ $id };
  my $match;
  foreach my $cid ( keys %{ $self->{clients} } ) {
     next if $cid eq $id;
     next if $self->{clients}->{ $cid }->{dstip} ne $client->{dstip};
     next if $self->{clients}->{ $cid }->{dstport} ne $client->{dstport};
     $match = $cid;
     last;
  }
  return $match;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub _start {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
	$kernel->alias_set( $self->{alias} );
  }
  else {
	$kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  if ( $kernel != $sender ) {
    my $sender_id = $sender->ID;
    $self->{events}->{'socksd_all'}->{$sender_id} = $sender_id;
    $self->{sessions}->{$sender_id}->{'ref'} = $sender_id;
    $kernel->refcount_increment($sender_id, __PACKAGE__);
    $kernel->post( $sender, 'socksd_registered', $self );
  }

  $self->{resolver} = POE::Component::Client::DNS->spawn( Alias => 'socksd' . $self->{session_id}, Timeout => 10 );

  $self->{filter} = POE::Filter::Stream->new();

  $self->{listener} = POE::Wheel::SocketFactory->new(
      ( defined $self->{address} ? ( BindAddress => $self->{address} ) : () ),
      ( defined $self->{port} ? ( BindPort => $self->{port} ) : ( BindPort => 1080 ) ),
      SuccessEvent   => '_accept_client',
      FailureEvent   => '_accept_failed',
      SocketDomain   => AF_INET,             # Sets the socket() domain
      SocketType     => SOCK_STREAM,         # Sets the socket() type
      SocketProtocol => 'tcp',               # Sets the socket() protocol
      Reuse          => 'on',                # Lets the port be reused
  );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{listener};
  delete $self->{clients};
  delete $self->{sockets};
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  $self->_unregister_sessions();
  $self->{resolver}->shutdown();
  return;
}

sub _accept_client {
  my ($kernel,$self,$socket,$peeraddr,$peerport) = @_[KERNEL,OBJECT,ARG0..ARG2];
  my $sockaddr = inet_ntoa( ( unpack_sockaddr_in ( getsockname $socket ) )[1] );
  my $sockport = ( unpack_sockaddr_in ( getsockname $socket ) )[0];
  $peeraddr = inet_ntoa( $peeraddr );

  if ( $self->denied( $peeraddr ) ) {
     $self->_send_event( 'socksd_denied', $peeraddr, $peerport );
     return;
  }

  my $wheel = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	Filter => $self->{filter},
	InputEvent => '_conn_input',
	ErrorEvent => '_conn_error',
	FlushedEvent => '_conn_flushed',
  );

  return unless $wheel;

  my $id = $wheel->ID();
  $self->{clients}->{ $id } =
  {
	wheel    => $wheel,
	peeraddr => $peeraddr,
	peerport => $peerport,
	sockaddr => $sockaddr,
	sockport => $sockport,
  };
  $self->_send_event( 'socksd_connection', $id, $peeraddr, $peerport, $sockaddr, $sockport );

  $self->{clients}->{ $id }->{alarm} = $kernel->delay_set( '_conn_alarm', $self->{time_out} || 120, $id );

  if ( $self->{ident} ) {
       POE::Component::Client::Ident::Agent->spawn(
		PeerAddr => $peeraddr,
		PeerPort => $peerport,
		SockAddr => $sockaddr,
	        SockPort => $sockport,
		BuggyIdentd => 1,
		TimeOut => 10,
		Reference => $id );
  }

  return;
}

sub _accept_failed {
  my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
  delete $self->{listener};
  $self->_send_event( 'socksd_listener_failed', $operation, $errnum, $errstr );
  return;
}

sub _ident_agent_reply {
  my ($kernel,$self,$ref,$opsys,$other) = @_[KERNEL,OBJECT,ARG0,ARG1,ARG2];
  my $wheel_id = $ref->{Reference};
  return unless $self->_conn_exists( $wheel_id );
  my $ident = '';
  #$ident = $other if uc ( $opsys ) ne 'OTHER';
  $ident = $other;
  $self->{clients}->{ $wheel_id }->{ident} = $ident;
  $kernel->yield( '_ident_done' => $wheel_id );
  return;
}

sub _ident_agent_error {
  my ($kernel,$self,$ref,$error) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $wheel_id = $ref->{Reference};
  return unless $self->_conn_exists( $wheel_id );
  $self->{clients}->{ $wheel_id }->{ident} = '';
  $kernel->yield( '_ident_done' => $wheel_id );
  return;
}

sub _ident_done {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  return unless defined $self->{clients}->{ $id }->{user_id};
  return unless defined $self->{clients}->{ $id }->{ident};
  my $client = $self->{clients}->{ $id };
  unless ( $client->{ident} ) {
    $kernel->yield( '_reject_client', $id, '92', 'No Ident Response' );
    return;
  }
  unless ( $client->{ident} eq $client->{user_id} ) {
    $kernel->yield( '_reject_client', $id, '93', 'Ident and user_id mismatch' );
    return;
  }
  $kernel->yield( '_do_connect', $id ) if $client->{cd} eq '1';
  $kernel->yield( '_do_bind', $id ) if $client->{cd} eq '2';
  return;
}

sub _reject_client {
  my ($kernel,$self,$id,$reject_id,$reason) = @_[KERNEL,OBJECT,ARG0,ARG1,ARG2];
  return unless $self->_conn_exists( $id );
  my $client = $self->{clients}->{ $id };
  $client->{reject} = $reject_id;
  my $response = pack "CCnN", 0, $reject_id, $client->{dstport}, inet_aton( $client->{dstip} );
  $client->{wheel}->put( $response );
  $self->_send_event( 'socksd_rejected', $id, $reject_id, $reason );
  return;
}

sub _parse_input {
  my $input = shift || return;
  my $null_idx = index $input, "\0";
  return if $null_idx == -1;
  my $request = substr $input, 0, $null_idx;
  return unless $request;
  my $packet = substr $input, 0, 4;
  return unless $packet or length $packet == 4;
  my @results = unpack "CCn", $packet;
  return unless scalar @results == 3;
  my $dstip = substr $input, 4, 4;
  return unless $dstip;
  push @results, $dstip;
  my $remainder = substr $input, 8;
  $remainder =~ s/\0$//g;
  my ($id,$host) = split /\0/, $remainder;
  $id = '' unless $id;
  push @results, $id, $host;
  return @results;
}

sub _conn_input {
  my ($kernel,$self,$input,$id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  return unless $self->_conn_exists( $id );
  my $client = $self->{clients}->{ $id };
  $kernel->delay_adjust( $client->{alarm}, $self->{time_out} || 120 );
  unless ( $client->{link_id} ) {
     # No uplink the client must be negotiating
     my @args = _parse_input( $input );
     unless ( @args ) {
	delete $self->{clients}->{ $id };
	return;
     }
     my ($vn,$cd,$dstport,$dstip,$userid,$host) = @args;
     $dstip = inet_ntoa( $dstip );
     unless ( $dstip ) {
	delete $self->{clients}->{ $id };
	return;
     }
     $client->{dstip} = $dstip;
     $client->{dstport} = $dstport;
     $client->{user_id} = $userid;
     if ( $vn ne '4' or $cd !~ /^(1|2)$/ ) {
	$kernel->yield( '_reject_client', $id, '91', 'Invalid request' );
	return;
     }
     if ( $dstip =~ /^0\.0\.0\./ and $cd ne '2' ) {
	# SOCKS 4a request
	unless ( $host ) {
	  $kernel->yield( '_reject_client', $id, '91', 'SOCKS4a request. No host' );
	  return;
	}
	my $response = $self->{resolver}->resolve(
      		event   => '_dns_response',
      		host    => $host,
      		context => { id => $id },
    	);
    	if ( $response ) {
      	   $kernel->yield( _dns_response => $response );
        }
	return;
     }
     if ( $cd eq '2' ) {
	my $cid = $self->_bind_request( $id );
	unless ( $cid ) {
	  $kernel->yield( '_reject_client', $id, '91', 'Invalid request' );
	  return;
	}
  	$client->{primary} = $cid;
  	$kernel->yield( '_ident_done', $id ) if $self->{ident};
  	$kernel->yield( '_do_bind', $id ) unless $self->{ident};
	return;
     }
     $kernel->yield( '_ident_done', $id ) if $self->{ident};
     $kernel->yield( '_do_connect', $id ) unless $self->{ident};
     return;
  }
  return unless $self->_link_exists( $client->{link_id} );
  $self->{links}->{ $client->{link_id} }->{wheel}->put( $input );
  return;
}

sub _dns_response {
  my ($kernel,$self,$arg) = @_[KERNEL,OBJECT,ARG0];
  my $net_dns_packet = $arg->{response};
  my $net_dns_errorstring = $arg->{error};
  my $id = $arg->{context}->{id};
  return unless $self->_conn_exists( $id );
  unless( defined $net_dns_packet ) {
	$kernel->yield( '_reject_client', $id, '91', 'DNS failed' );
	return;
  }
  my @net_dns_answers = $net_dns_packet->answer;
  unless ( @net_dns_answers ) {
	$kernel->yield( '_reject_client', $id, '91', 'No DNS answers' );
	return;
  }
  foreach my $net_dns_answer (@net_dns_answers) {
    next unless $net_dns_answer->type eq 'A';
    $self->{clients}->{ $id }->{dstip} = $net_dns_answer->rdatastr;
    $self->_send_event( 'socksd_dns_lookup', $id, $arg->{host}, $self->{clients}->{ $id }->{dstip} );
    $kernel->yield( '_ident_done', $id ) if $self->{ident};
    $kernel->yield( '_do_connect', $id ) unless $self->{ident};
    return;
  }
  $kernel->yield( '_reject_client', $id, '91', 'No DNS records found' );
  return;
}

sub _conn_error {
  my ($self,$errstr,$id) = @_[OBJECT,ARG2,ARG3];
  return unless $self->_conn_exists( $id );
  $self->_delete_client( $id );
  $self->_send_event( 'socksd_disconnected', $id, $errstr );
  return;
}

sub _conn_flushed {
  my ($self,$id) = @_[OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  return if $self->{clients}->{ $id }->{link_id};
  return unless $self->{clients}->{ $id }->{reject};
  $self->_delete_client( $id );
  return;
}

sub _conn_alarm {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  $self->_delete_client( $id );
  $self->_send_event( 'socksd_disconnected', $id );
  return;
}

sub _delete_client {
  my ($self,$id) = @_;
  return unless $self->_conn_exists( $id );
  my $client = delete $self->{clients}->{ $id };
  if ( $client->{link_id} and $self->_link_exists( $client->{link_id} ) ) {
    delete $self->{links}->{ $client->{link_id} };
  }
  if ( $client->{factory} and $self->_sock_exists( $client->{factory} ) ) {
    delete $self->{sockets}->{ $client->{factory} };
  }
  return 1;
}

sub _do_connect {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  my $client = $self->{clients}->{ $id };
  my $factory = POE::Wheel::SocketFactory->new(
	SocketDomain   => AF_INET,
	SocketType     => SOCK_STREAM,
	SocketProtocol => 'tcp',
	RemoteAddress  => $client->{dstip},
	RemotePort     => $client->{dstport},
	SuccessEvent   => '_sock_up',
	FailureEvent   => '_sock_failed',
  );
  my $fact_id = $factory->ID();
  $client->{factory} = $fact_id;
  $self->{sockets}->{ $fact_id } = { client => $id, factory => $factory };
  return;
}

sub _do_bind {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  my $client = $self->{clients}->{ $id };
  my $primary = $client->{primary};
  return unless $self->_conn_exists( $primary );
  my $link_id = $self->{clients}->{ $primary }->{link_id};
  return unless $link_id or $self->_link_exists( $link_id );
  my $bindaddr = $self->{links}->{ $link_id }->{sockaddr};
  my $factory = POE::Wheel::SocketFactory->new(
	SocketDomain   => AF_INET,
	SocketType     => SOCK_STREAM,
	SocketProtocol => 'tcp',
	BindAddress    => $bindaddr,
	BindPort       => 0,
	Reuse          => 'yes',
	SuccessEvent   => '_sock_connection',
	FailureEvent   => '_sock_failed',
  );
  my $sockname = $factory->getsockname();
  unless ( $sockname ) {
    $kernel->yield( '_reject_client', $id, '91', 'Socket failed' );
    return;
  }
  my ($port, $myaddr) = sockaddr_in( $sockname );
  my $fact_id = $factory->ID();
  $client->{factory} = $fact_id;
  $self->{sockets}->{ $fact_id } = { client => $id, factory => $factory };
  $self->{sockets}->{ $fact_id }->{alarm} = $kernel->delay_set( '_sock_alarm', $self->{time_out} || 120, $fact_id, $id );
  my $response = pack "CCnN", 0, 90, $port, $myaddr;
  $client->{wheel}->put( $response );
  $self->_send_event( 'socksd_bind_up', $id, $fact_id, inet_ntoa( $myaddr ), $port );
  return;
}

sub _sock_failed {
  my ($kernel,$self,$op,$errno,$errstr,$fact_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  my $factory = delete $self->{sockets}->{ $fact_id };
  $kernel->alarm_remove( $factory->{alarm} );
  my $client_id = $factory->{client};
  delete $self->{clients}->{ $client_id }->{factory} if $self->_conn_exists( $client_id );
  $kernel->yield( '_reject_client', $client_id, '91', 'Socket failed', $op, $errno, $errstr );
  return;
}

sub _sock_up {
  my ($kernel,$self,$socket,$fact_id) = @_[KERNEL,OBJECT,ARG0,ARG3];
  my $sockaddr = inet_ntoa( ( unpack_sockaddr_in ( getsockname $socket ) )[1] );
  my $sockport = ( unpack_sockaddr_in ( getsockname $socket ) )[0];
  my $factory = delete $self->{sockets}->{ $fact_id };
  my $client_id = $factory->{client};
  return unless $self->_conn_exists( $client_id );
  my $wheel = POE::Wheel::ReadWrite->new(
      Handle       => $socket,
      Filter	   => POE::Filter::Stream->new(),
      InputEvent   => '_sock_input',
      ErrorEvent   => '_sock_down',
  );
  my $link_id = $wheel->ID();
  $self->{clients}->{ $client_id }->{link_id} = $link_id;
  $self->{links}->{ $link_id } = { client => $client_id, wheel => $wheel, sockaddr => $sockaddr, sockport => $sockport };
  my $client = $self->{clients}->{ $client_id };
  my $response = pack "CCnN", 0, 90, $client->{dstport}, unpack("N", inet_aton( $client->{dstip}) );
  $client->{wheel}->put( $response );
  $self->_send_event( 'socksd_sock_up', $client_id, $link_id, $client->{dstip}, $client->{dstport} );
  return;
}

sub _sock_connection {
  my ($kernel,$self,$socket,$peeraddr,$fact_id) = @_[KERNEL,OBJECT,ARG0,ARG1,ARG3];
  my $sockaddr = inet_ntoa( ( unpack_sockaddr_in ( getsockname $socket ) )[1] );
  my $sockport = ( unpack_sockaddr_in ( getsockname $socket ) )[0];
  $peeraddr = inet_ntoa( $peeraddr );
  my $factory = delete $self->{sockets}->{ $fact_id };
  $kernel->alarm_remove( $factory->{alarm} );
  my $client_id = $factory->{client};
  return unless $self->_conn_exists( $client_id );
  my $client = $self->{clients}->{ $client_id };
  unless ( $peeraddr eq $client->{dstip} ) {
     $kernel->yield( '_reject_client', $client_id, '91', 'dstip and connecting ip differ' );
     return;
  }
  my $wheel = POE::Wheel::ReadWrite->new(
      Handle       => $socket,
      Filter	   => POE::Filter::Stream->new(),
      InputEvent   => '_sock_input',
      ErrorEvent   => '_sock_down',
  );
  my $link_id = $wheel->ID();
  $client->{link_id} = $link_id;
  $self->{links}->{ $link_id } = { client => $client_id, wheel => $wheel, sockaddr => $sockaddr, sockport => $sockport };
  my $response = pack "CCnN", 0, 90, $sockport, inet_aton( $sockaddr );
  $client->{wheel}->put( $response );
  $self->_send_event( 'socksd_sock_up', $client_id, $link_id, $sockaddr, $sockport );
  return;
}

sub _sock_alarm {
  my ($kernel,$self,$fact_id,$client_id) = @_[KERNEL,OBJECT,ARG0..ARG1];
  delete $self->{sockets}->{ $fact_id };
  delete $self->{clients}->{ $client_id };
  return;
}

sub _sock_input {
  my ($kernel,$self,$input,$link_id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  return unless $self->_link_exists( $link_id );
  my $client_id = $self->{links}->{ $link_id }->{client};
  return unless $self->_conn_exists( $client_id );
  $self->{clients}->{ $client_id }->{wheel}->put( $input );
  return;
}

sub _sock_down {
  my ($self,$errstr,$link_id) = @_[OBJECT,ARG2,ARG3];
  return unless $self->_link_exists( $link_id );
  my $client_id = $self->{links}->{ $link_id }->{client};
  $self->{clients}->{$client_id}->{wheel}->flush;
  my $link = delete $self->{links}->{ $link_id };
  if ( $link->{client} and $self->_conn_exists( $link->{client} ) ) {
    delete $self->{clients}->{ $link->{client} };
  }
  $self->_send_event( 'socksd_sock_down', $link->{client}, $link_id, $errstr );
  $self->_send_event( 'socksd_disconnected', $link->{client} );
  return;
}

sub register {
  my ($kernel, $self, $session, $sender, @events) =
    @_[KERNEL, OBJECT, SESSION, SENDER, ARG0 .. $#_];

  unless (@events) {
    warn "register: Not enough arguments";
    return;
  }

  my $sender_id = $sender->ID();

  foreach (@events) {
    $_ = "socksd_" . $_ unless /^_/;
    $self->{events}->{$_}->{$sender_id} = $sender_id;
    $self->{sessions}->{$sender_id}->{'ref'} = $sender_id;
    unless ($self->{sessions}->{$sender_id}->{refcnt}++ or $session == $sender) {
      $kernel->refcount_increment($sender_id, __PACKAGE__);
    }
  }

  $kernel->post( $sender, 'socksd_registered', $self );
  return;
}

sub unregister {
  my ($kernel, $self, $session, $sender, @events) =
    @_[KERNEL,  OBJECT, SESSION,  SENDER,  ARG0 .. $#_];

  unless (@events) {
    warn "unregister: Not enough arguments";
    return;
  }

  $self->_unregister($session,$sender,@events);
  undef;
}

sub _unregister {
  my ($self,$session,$sender) = splice @_,0,3;
  my $sender_id = $sender->ID();

  foreach (@_) {
    $_ = "socksd_" . $_ unless /^_/;
    my $blah = delete $self->{events}->{$_}->{$sender_id};
    unless ( $blah ) {
	warn "$sender_id hasn't registered for '$_' events\n";
	next;
    }
    if (--$self->{sessions}->{$sender_id}->{refcnt} <= 0) {
      delete $self->{sessions}->{$sender_id};
      unless ($session == $sender) {
        $poe_kernel->refcount_decrement($sender_id, __PACKAGE__);
      }
    }
  }
  undef;
}

sub _unregister_sessions {
  my $self = shift;
  my $socksd_id = $self->session_id();
  foreach my $session_id ( keys %{ $self->{sessions} } ) {
     if (--$self->{sessions}->{$session_id}->{refcnt} <= 0) {
        delete $self->{sessions}->{$session_id};
	$poe_kernel->refcount_decrement($session_id, __PACKAGE__)
		unless ( $session_id eq $socksd_id );
     }
  }
}

sub __send_event {
  my( $self, $event, @args ) = @_[ OBJECT, ARG0, ARG1 .. $#_ ];
  $self->_send_event( $event, @args );
  return;
}

sub send_event {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, '__send_event', @_ );
}

sub _send_event  {
  my $self = shift;
  my ($event, @args) = @_;
  my $kernel = $POE::Kernel::poe_kernel;
  my $session = $kernel->get_active_session()->ID();
  my %sessions;

  $sessions{$_} = $_ for (values %{$self->{events}->{'socksd_all'}}, values %{$self->{events}->{$event}});

  $kernel->post( $_ => $event => @args ) for values %sessions;
  undef;
}

##################
# Access Control #
##################

sub add_denial {
  my $self = shift;
  my $netmask = shift || return;
  return unless $netmask->isa('Net::Netmask');
  $self->{denials}->{ $netmask } = $netmask;
  return 1;
}

sub del_denial {
  my $self = shift;
  my $netmask = shift || return;
  return unless $netmask->isa('Net::Netmask');
  return unless $self->{denials}->{ $netmask };
  delete $self->{denials}->{ $netmask };
  return 1;
}

sub add_exemption {
  my $self = shift;
  my $netmask = shift || return;
  return unless $netmask->isa('Net::Netmask');
  $self->{exemptions}->{ $netmask } = $netmask unless $self->{exemptions}->{ $netmask };
  return 1;
}

sub del_exemption {
  my $self = shift;
  my $netmask = shift || return;
  return unless $netmask->isa('Net::Netmask');
  return unless $self->{exemptions}->{ $netmask };
  delete $self->{exemptions}->{ $netmask };
  return 1;
}

sub denied {
  my $self = shift;
  my $ipaddr = shift || return;
  return 0 if $self->exempted( $ipaddr );
  foreach my $mask ( keys %{ $self->{denials} } ) {
    return 1 if $self->{denials}->{ $mask }->match($ipaddr);
  }
  return 0;
}

sub exempted {
  my $self = shift;
  my $ipaddr = shift || return;
  foreach my $mask ( keys %{ $self->{exemptions} } ) {
    return 1 if $self->{exemptions}->{ $mask }->match($ipaddr);
  }
  return 0;
}

qq[SOCKS it to me];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Proxy::SOCKS - A POE based SOCKS 4 proxy server.

=head1 VERSION

version 1.04

=head1 SYNOPSIS

   use strict;
   use Net::Netmask;
   use POE qw(Component::Proxy::SOCKS);

   $|=1;

   POE::Session->create(
      package_states => [
   	'main' => [ qw(_start _default socksd_registered) ],
      ],
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     my ($kernel,$heap) = @_[KERNEL,HEAP];
     $heap->{socksd} = POE::Component::Proxy::SOCKS->spawn( alias => 'socksd', ident => 0 );
     return;
   }

   sub socksd_registered {
     my $socksd = $_[ARG0];
     my $all = Net::Netmask->new2('any');
     my $loopback = Net::Netmask->new2('127.0.0.1');
     my $local = Net::Netmask->new2('192.168.1.0/24');
     $socksd->add_denial( $all );
     $socksd->add_exemption( $loopback );
     $socksd->add_exemption( $local );
     return;
   }

   sub _default {
     my ($event, $args) = @_[ARG0 .. $#_];
     my @output = ( "$event: " );

     foreach my $arg ( @$args ) {
       if ( ref($arg) eq 'ARRAY' ) {
          push( @output, "[" . join(" ,", @$arg ) . "]" );
       } else {
          push ( @output, "'$arg'" );
       }
     }
     print STDOUT join ' ', @output, "\n";
     return 0;
   }

=head1 DESCRIPTION

POE::Component::Proxy::SOCKS is a L<POE> component that implements a SOCKS version 4/4a
proxy server. It has IP address based access controls, provided by L<Net::Netmask>, and
can use IDENT to further confirm user identity.

POE sessions may register with the SOCKS component to receive events relating to
connections etc.

The poco supports both SOCKS CONNECT and SOCKS BIND commands.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Starts a new SOCKS proxy session and returns an object. If spawned from within another
POE session, the parent session will be automagically registered and receive a
C<socksd_registered> event. See below for details.

Takes several optional parameters:

  'alias', a kernel alias to address the poco by;
  'address', set a particular IP address on a multi-homed box to bind to;
  'port', set a particular TCP port to listen on, default 1080;
  'ident', indicate whether ident lookups should be performed, default 0;
  'options', pass a hashref of POE session options;
  'time_out', adjust the time out period in seconds, default is 120 seconds;

=back

=head1 METHODS

These methods are available on the returned POE::Component::Proxy::SOCKS object:

=over

=item C<session_id>

Returns the POE session ID of the poco's session.

=item C<shutdown>

Terminates the poco, dropping all connections and pending connections.

=item C<send_event>

Sends an event through the poco's event handling system.

=item C<add_denial>

Takes one mandatory argument. The mandatory argument is a L<Net::Netmask> object that will be used to check connecting IP addresses against.

=item C<del_denial>

Takes one mandatory argument, a L<Net::Netmask> object to remove from the current denial list.

=item C<denied>

Takes one argument, an IP address. Returns true or false depending on whether that IP is denied or not.

=item C<add_exemption>

Takes one mandatory argument, a L<Net::Netmask> object that will be checked against connecting IP addresses for exemption from denials.

=item C<del_exemption>

Takes one mandatory argument, a L<Net::Netmask> object to remove from the current exemption list.

=item C<exempted>

Takes one argument, an IP address. Returns true or false depending on whether that IP is exempt from denial or not.

=back

=head1 INPUT EVENTS

=over

=item C<register>

Takes N arguments: a list of event names that your session wants to listen for, minus the 'socksd_' prefix, ( this is
similar to L<POE::Component::IRC> ).

Registering for 'all' will cause it to send all SOCKSD-related events to you; this is the easiest way to handle it.

=item C<unregister>

Takes N arguments: a list of event names which you don't want to receive. If you've previously done a 'register' for a particular event which you no longer care about, this event will tell the SOCKSD to stop sending them to you. (If you haven't, it just ignores you. No big deal).

=item C<shutdown>

Terminates the poco, dropping all connections and pending connections.

=back

=head1 OUTPUT EVENTS

The component generates a number of C<socksd_> prefixed events that are dispatched to registered sessions.

=over

=item C<socksd_registered>

This event is sent to a registering session. ARG0 is POE::Component::Proxy::SOCKS
object.

=item C<socksd_denied>

Generated whenever a client is denied access. ARG0 is the client IP and ARG1 the client port.

=item C<socksd_connection>

Generated when client successfully connects. ARG0 is a unique client ID, ARG1 is the peer address, ARG2 is the peer port, ARG3 is our socket address and ARG4 is our socket port.

=item C<socksd_rejected>

Generated when a SOCKS transaction is rejected. ARG0 is the unique client ID, ARG1 is the SOCKS result code and ARG2 is a reason for the rejection.

=item C<socksd_listener_failed>

Generated if the poco fails to get a listener. ARG0 is the operation, ARG1 is the errnum and ARG2 is the errstr.

=item C<socksd_disconnected>

Generated whenever a client disconnects. ARG0 is the unique client ID.

=item C<socksd_dns_lookup>

Generated whenever the poco services a successful SOCKS 4a DNS lookup. ARG0 is the unique
client ID. ARG1 is the hostname resolved and ARG2 is the IP address of that host.

=item C<socksd_sock_up>

Generated when a CONNECT is successful. ARG0 is the unique client ID, ARG1 is the unqiue link ID, ARG2 is the destination IP and ARG3 the destination port.

=item C<socksd_bind_up>

Generated whenever a BIND is succesful. ARG0 is the unique client ID, ARG1 is the unique ID for the listener, ARG2 is our socket IP and ARG3 is our port.

=item C<socksd_sock_down>

Generated whenever a socket to an application server is terminated. ARG0 is the unique client ID, ARG1 is the unqiue link ID, ARG2 is the error string.

=back

=head1 SEE ALSO

L<http://socks.permeo.com/protocol/socks4.protocol>

L<http://socks.permeo.com/protocol/socks4a.protocol>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
