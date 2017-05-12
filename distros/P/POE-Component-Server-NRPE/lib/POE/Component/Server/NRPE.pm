package POE::Component::Server::NRPE;
{
  $POE::Component::Server::NRPE::VERSION = '0.18';
}

#ABSTRACT: A POE Component implementation of NRPE Daemon.

use strict;
use warnings;
use Socket;
use Carp;
use Net::Netmask;
use Net::SSLeay qw(die_now);
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Wheel::Run Filter::Stream Filter::Line);
use POE::Component::SSLify qw(Server_SSLify);
use POE::Component::Server::NRPE::Constants;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  my $access = delete $opts{access} || [ Net::Netmask->new('any') ];
  $access = [ ] unless ref $access eq 'ARRAY';
  foreach my $acl ( @$access ) {
	next unless $acl->isa('Net::Netmask');
	push @{ $opts{access} }, $acl;
  }
  $opts{verstring} = __PACKAGE__ . ' v' . $POE::Component::Server::NRPE::VERSION unless $opts{verstring};
  $opts{version} = 2 unless $opts{version} and $opts{version} eq '1';
  $opts{usessl} = 1 unless defined $opts{usessl} and $opts{usessl} eq '0';
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
		$self => { shutdown       => '_shutdown',
		},
		$self => [qw(
				_start
				_accept_client
				_accept_failed
				_conn_input
				_conn_error
				_conn_flushed
				_conn_alarm
				_sig_child
				_stdout
				_wheel_close
				_wheel_error
				_wheel_alarm
				_session_alarm
				register_command
				unregister_command
				return_result
		)],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub session_id {
  return $_[0]->{session_id};
}

sub getsockname {
  return unless $_[0]->{listener};
  return $_[0]->{listener}->getsockname();
}

sub add_command {
  my $self = shift;
  my %args;
  if ( ref $_[0] eq 'HASH' ) {
    %args = %{ $_[0] };
  }
  elsif ( ref $_[0] eq 'ARRAY' ) {
    %args = @{ $_[0] };
  }
  else {
    %args = @_;
  }
  $args{lc $_} = delete $args{$_} for keys %args;
  return unless $args{command} and $args{program};
  return if defined $self->{commands}->{ $args{command} } or defined $self->{sess_cmds}->{ $args{command} };
  $args{args} = [ $args{args} ] if ref $args{args} ne 'ARRAY';
  $self->{commands}->{ delete $args{command} } = \%args;
  return 1;
}

sub del_command {
  my $self = shift;
  my $command = shift || return;
  return unless defined $self->{commands}->{ $command };
  delete $self->{commands}->{ $command };
  return 1;
}

sub register_command {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  my $sender_id = $sender->ID();
  my %args;
  if ( ref $_[ARG0] eq 'HASH' ) {
    %args = %{ $_[ARG0] };
  }
  elsif ( ref $_[ARG0] eq 'ARRAY' ) {
    %args = @{ $_[ARG0] };
  }
  else {
    %args = @_[ARG0..$#_];
  }
  $args{lc $_} = delete $args{$_} for keys %args;
  unless ( $args{command} ) {
    warn "No 'command' argument supplied\n";
    return;
  }
  unless ( $args{event} ) {
    warn "No 'event' argument supplied\n";
    return;
  }
  if ( defined $self->{commands}->{ $args{command} } ) {
    warn "There is an internal command called '$args{command}' already\n";
    return;
  }
  if ( defined $self->{sess_cmds}->{ $args{command} } ) {
    warn "There is a session command called '$args{command}' already\n";
    return;
  }
  $self->{sess_cmds}->{ $args{command} } = { session => $sender_id, event => $args{event} };
  $kernel->refcount_increment( $sender_id, __PACKAGE__ );
  return;
}

sub unregister_command {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  my $sender_id = $sender->ID();
  my %args;
  if ( ref $_[ARG0] eq 'HASH' ) {
    %args = %{ $_[ARG0] };
  }
  elsif ( ref $_[ARG0] eq 'ARRAY' ) {
    %args = @{ $_[ARG0] };
  }
  else {
    %args = @_[ARG0..$#_];
  }
  $args{lc $_} = delete $args{$_} for keys %args;
  unless ( $args{command} ) {
    warn "No 'command' argument supplied\n";
    return;
  }
  unless ( defined $self->{sess_cmds}->{ $args{command} } ) {
    warn "There isn't a session command called '$args{command}'\n";
    return;
  }
  unless ( $self->{sess_cmds}->{ $args{command} }->{session} eq $sender_id ) {
    warn "Session '$sender_id' isn't the registered owner of '$args{command}'\n";
    return;
  }
  delete $self->{sess_cmds}->{ $args{command} };
  $kernel->refcount_decrement( $sender_id, __PACKAGE__ );
  return;
}

sub return_result {
  my ($kernel,$self,$sender,$id,$status,$output) = @_[KERNEL,OBJECT,SENDER,ARG0..ARG2];
  my $sender_id = $sender->ID();
  return unless $id and defined $self->{clients}->{ $id };
  $kernel->alarm_remove( $self->{clients}->{ $id }->{sess_alarm} );
  return unless $self->{clients}->{ $id }->{session} and $self->{clients}->{ $id }->{session} eq $sender_id;
  $output = 'NRPE: Unable to read output' unless $output;
  $status = NRPE_STATE_UNKNOWN unless $status or $status =~ /^\d+$/ or ( $status >= 0 or $status <= 3 );
  $self->_send_response( $id, $status, $output );
  return;
}

sub _conn_exists {
  my ($self,$wheel_id) = @_;
  return 0 unless $wheel_id and defined $self->{clients}->{ $wheel_id };
  return 1;
}

sub _disconnect {
  my ($self,$wheel_id) = @_;
  return unless $wheel_id and defined $self->{clients}->{ $wheel_id };
  delete $self->{clients}->{ $wheel_id };
  return 1;
}

sub _send_response {
  my $self = shift;
  my ($wheel_id,$status,$response) = @_;
  return unless $wheel_id and defined $self->{clients}->{ $wheel_id };
  my $packet;
  if ( $self->{version} == 1 ) {
     $packet = pack "NNNNa[1024]", 2, 1, $status, length( $response ), $response;
  }
  else {
     $packet = _gen_packet_ver2( $status, $response );
  }
  $self->{clients}->{ $wheel_id }->{wheel}->put( $packet );
  return 1;
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
  $self->{filter} = POE::Filter::Stream->new();
  $self->{listener} = POE::Wheel::SocketFactory->new(
      ( defined $self->{address} ? ( BindAddress => $self->{address} ) : () ),
      ( defined $self->{port} ? ( BindPort => $self->{port} ) : ( BindPort => 5666 ) ),
      SuccessEvent   => '_accept_client',
      FailureEvent   => '_accept_failed',
      SocketDomain   => AF_INET,             # Sets the socket() domain
      SocketType     => SOCK_STREAM,         # Sets the socket() type
      SocketProtocol => 'tcp',               # Sets the socket() protocol
      Reuse          => 'on',                # Lets the port be reused
  );
  if ( $self->{version} eq '2' and $self->{usessl} ) {
	eval { $self->{_ctx} = _SSLify_Initialise(); };
	if ($@) {
	   warn "SSL initialisation failed: $@\n";
	   $self->{usessl} = 0;
	}
  }
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{listener};
  delete $self->{clients};
  delete $self->{wheels};
  delete $self->{pids};
  $kernel->refcount_decrement( $_, __PACKAGE__ ) for
	map { $self->{sess_cmds}->{$_}->{session} } keys %{ $self->{sess_cmds} };
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  return;
}

sub _accept_failed {
  my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  warn "Listener: $wheel_id generated $operation error $errnum: $errstr\n";
  delete $self->{listener};
  $kernel->yield( '_shutdown' );
  return;
}

sub _accept_client {
  my ($kernel,$self,$socket,$peeraddr,$peerport) = @_[KERNEL,OBJECT,ARG0..ARG2];
  my $sockaddr = inet_ntoa( ( unpack_sockaddr_in ( CORE::getsockname $socket ) )[1] );
  my $sockport = ( unpack_sockaddr_in ( CORE::getsockname $socket ) )[0];
  $peeraddr = inet_ntoa( $peeraddr );

  return unless grep { $_->match( $peeraddr ) } @{ $self->{access} };

  if ( $self->{version} == 2 and $self->{usessl} ) {
	eval { $socket = Server_SSLify( $socket, $self->{_ctx} ) };
	warn "Failed to SSLify the socket: $@\n" if $@;
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
  $self->{clients}->{ $id }->{alarm} = $kernel->delay_set( '_conn_alarm', $self->{time_out} || 60, $id );
  return;
}

sub _conn_input {
  my ($kernel,$self,$input,$id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  return unless $self->_conn_exists( $id );
  return if $self->{clients}->{ $id }->{cmd_id};
  $kernel->alarm_remove( $self->{clients}->{ $id }->{alarm} );
  my $data;
  if ( $self->{version} == 1 ) {
     my $length = length $input;
     if ( $length != 1040 ) {
	$self->_disconnect( $id );
	return;
     }
     my @args = unpack "NNNNa*", $input;
     if ( $args[0] ne '1' or $args[1] ne '1' or $args[2] !~ /^[0123456789]*$/ ) {
	$self->_disconnect( $id );
	return;
     }
     $args[4] =~ s/\x00*$//g;
     $data = $args[4];
  }
  else {
     my $length = length $input;
     if ( $length != 1036 ) {
	$self->_disconnect( $id );
	return;
     }
     my @args = unpack "nnNnZ*", $input;
     if ( $args[0] ne '2' or $args[1] ne '1' or $args[3] !~ /^[0123456789]*$/ ) {
	$self->_disconnect( $id );
	return;
     }
     $args[4] =~ s/\x00*$//g;
     $data = $args[4];
  }
  unless ( $data ) {
    $self->_disconnect( $id );
    return;
  }
  if ( $data eq '_NRPE_CHECK' ) {
     $self->_send_response( $id, NRPE_STATE_OK, $self->{verstring} );
    return;
  }
  if ( defined $self->{commands}->{ $data } ) {
    my $wheel = POE::Wheel::Run->new(
	Program     => $self->{commands}->{ $data }->{program},
	ProgramArgs => $self->{commands}->{ $data }->{args},
	StdoutEvent => '_stdout',
	CloseEvent  => '_wheel_close',
	ErrorEvent  => '_wheel_error',
    );
    my $wheel_id = $wheel->ID();
    my $wheel_pid = $wheel->PID();
    $self->{clients}->{ $id }->{cmd_id} = $wheel_id;
    $self->{clients}->{ $id }->{cmd_pid} = $wheel_pid;
    $self->{wheels}->{ $wheel_id } = { wheel => $wheel, pid => $wheel_pid, client => $id };
    $self->{pids}->{ $wheel_pid } = { wheel_id => $wheel_id, client => $id };
    $kernel->sig_child( $wheel_pid, '_sig_child' );
    $self->{pids}->{ $wheel_pid }->{alarm_id} = $kernel->delay_set( '_wheel_alarm', $self->{time_out} || 60, $wheel_pid, $wheel_id );
    return;
  }
  if ( defined $self->{sess_cmds}->{ $data } ) {
    my $rec = $self->{sess_cmds}->{ $data };
    $kernel->post( $rec->{session}, $rec->{event}, $id, $rec->{context} );
    $self->{clients}->{ $id }->{sess_alarm} = $kernel->delay_set( '_session_alarm', $self->{time_out} || 60, $id, $rec->{session} );
    $self->{clients}->{ $id }->{session} = $rec->{session};
    return;
  }
  $self->_send_response( $id, NRPE_STATE_CRITICAL, sprintf("NRPE: Command '%s' not defined", $data ) );
  return;
}

sub _stdout {
  my ($self,$input,$wheel_id) = @_[OBJECT,ARG0,ARG1];
  $self->{pids}->{ $self->{wheels}->{ $wheel_id }->{pid} }->{output} = $input;
  return;
}

sub _wheel_close {
  my ($self,$wheel_id) = @_[OBJECT,ARG0];
  my $wheel = delete $self->{wheels}->{ $wheel_id };
  return unless $wheel;
  delete $self->{clients}->{ $wheel->{client} }->{cmd_id};
  return;
}

sub _wheel_error {
  my ($self,$wheel_id) = @_[OBJECT,ARG3];
  my $wheel = delete $self->{wheels}->{ $wheel_id };
  return unless $wheel;
  delete $self->{clients}->{ $wheel->{client} }->{cmd_id};
  return;
}

sub _wheel_alarm {
  my ($self,$wheel_pid,$wheel_id) = @_[OBJECT,ARG0,ARG1];
  $self->{pids}->{ $wheel_pid }->{timed_out} = sprintf("NRPE: Command timed out after %d seconds", $self->{time_out} || 60 );
  $self->{wheels}->{ $wheel_id }->{wheel}->kill(9);
  return;
}

sub _session_alarm {
  my ($self,$id,$session_id) = @_[OBJECT,ARG0,ARG1];
  $self->_send_response( $id, NRPE_STATE_CRITICAL, sprintf("NRPE: Command timed out after %d seconds", $self->{time_out} || 60 ) );
  return;
}

sub _conn_error {
  my ($self,$errstr,$id) = @_[OBJECT,ARG2,ARG3];
  return unless $self->_conn_exists( $id );
  my $client = delete $self->{clients}->{ $id };
  if ( $client->{cmd_id} ) {
	delete $self->{wheels}->{ $client->{cmd_id} };
	delete $self->{pids}->{ $client->{cmd_pid} };
  }
  return;
}

sub _conn_flushed {
  my ($self,$id) = @_[OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  my $client = delete $self->{clients}->{ $id };
  return;
}

sub _conn_alarm {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  my $client = delete $self->{clients}->{ $id };
  if ( $client->{cmd_id} ) {
	delete $self->{wheels}->{ $client->{cmd_id} };
	delete $self->{pids}->{ $client->{cmd_pid} };
  }
  return;
}

sub _sig_child {
  my ($kernel,$self,$signal,$pid,$status) = @_[KERNEL,OBJECT,ARG0..ARG2];
  $pid = delete $self->{pids}->{ $pid };
  if ( $pid ) {
    $kernel->alarm_remove( $pid->{alarm_id} );
    my ( $return, $output );
    if ( $pid->{output} ) {
	    $output = $pid->{output};
    }
    else {
	    $output = 'NRPE: Unable to read output';
    }
    $output = $pid->{timed_out} if $pid->{timed_out};
    $return = $status >> 8;
    $return = NRPE_STATE_UNKNOWN if $return < 0 or $return > 3;
    $return = NRPE_STATE_UNKNOWN if $pid->{timed_out};
    $self->_send_response( $pid->{client}, $return, $output );
  }
  return $kernel->sig_handled();
}

# These functions are derived from http://www.stic-online.de/stic/html/nrpe-generic.html
# Copyright (C) 2006, 2007 STIC GmbH, http://www.stic-online.de
# Licensed under GPLv2

sub _gen_packet_ver2 {
  my $result = shift;
  my $data = shift;
  for ( my $i = length ( $data ); $i < 1024; $i++ ) {
    $data .= "\x00";
  }
  $data .= "SR";
  my $res = pack "n", $result;
  my $packet = "\x00\x02\x00\x02";
  my $tail = $res . $data;
  my $crc = ~_crc32( $packet . "\x00\x00\x00\x00" . $tail );
  $packet .= pack ( "N", $crc ) . $tail;
  return $packet;
}

sub _crc32 {
    my $crc;
    my $len;
    my $i;
    my $index;
    my @args;
    my ($arg) = @_;
    my @crc_table =(
             0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419,
             0x706af48f, 0xe963a535, 0x9e6495a3, 0x0edb8832, 0x79dcb8a4,
             0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07,
             0x90bf1d91, 0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
             0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7, 0x136c9856,
             0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9,
             0xfa0f3d63, 0x8d080df5, 0x3b6e20c8, 0x4c69105e, 0xd56041e4,
             0xa2677172, 0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
             0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3,
             0x45df5c75, 0xdcd60dcf, 0xabd13d59, 0x26d930ac, 0x51de003a,
             0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423, 0xcfba9599,
             0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
             0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d, 0x76dc4190,
             0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f,
             0x9fbfe4a5, 0xe8b8d433, 0x7807c9a2, 0x0f00f934, 0x9609a88e,
             0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
             0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed,
             0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
             0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3,
             0xfbd44c65, 0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
             0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a,
             0x346ed9fc, 0xad678846, 0xda60b8d0, 0x44042d73, 0x33031de5,
             0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa, 0xbe0b1010,
             0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
             0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17,
             0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6,
             0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615,
             0x73dc1683, 0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
             0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1, 0xf00f9344,
             0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb,
             0x196c3671, 0x6e6b06e7, 0xfed41b76, 0x89d32be0, 0x10da7a5a,
             0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
             0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252, 0xd1bb67f1,
             0xa6bc5767, 0x3fb506dd, 0x48b2364b, 0xd80d2bda, 0xaf0a1b4c,
             0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef,
             0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
             0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe,
             0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31,
             0x2cd99e8b, 0x5bdeae1d, 0x9b64c2b0, 0xec63f226, 0x756aa39c,
             0x026d930a, 0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
             0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b,
             0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242,
             0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1,
             0x18b74777, 0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
             0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45, 0xa00ae278,
             0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7,
             0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc, 0x40df0b66,
             0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
             0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605,
             0xcdd70693, 0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8,
             0x5d681b02, 0x2a6f2b94, 0xb40bbe37, 0xc30c8ea1, 0x5a05df1b,
             0x2d02ef8d
    );

    $crc = 0xffffffff;
    $len = length($arg);
    @args = unpack "c*", $arg;
    for ($i = 0; $i < $len; $i++) {
        $index = ($crc ^ $args[$i]) & 0xff;
        $crc = $crc_table[$index] ^ (($crc >> 8) & 0x00ffffff);
    }
    return $crc;
}

sub _SSLify_Initialise {
  my $data = "-----BEGIN DH PARAMETERS-----\nMEYCQQD9eJtH5rywhI/PGD+RaFvEptXwGrqtjm4Jw+GSniG72OLThcOcb29iEIcp\nXgrpPtClVGHYs4lNZbpwFz1ufNnjAgEC\n-----END DH PARAMETERS-----\n";
  my $ctx = Net::SSLeay::CTX_new() or die_now( "Failed to create SSL_CTX $!" );
  Net::SSLeay::CTX_set_cipher_list( $ctx, 'ADH') or die_now( " Failed to set cipher list $!" );
  my $bio = Net::SSLeay::BIO_new( Net::SSLeay::BIO_s_mem() ) or die_now( "Failed to create BIO: $!" );
  my $retval = Net::SSLeay::BIO_write( $bio, $data );
  my $dh = Net::SSLeay::PEM_read_bio_DHparams( $bio ) or die_now( "Failed to read DHparams: $!" );
  Net::SSLeay::BIO_free( $bio );
  Net::SSLeay::CTX_set_tmp_dh( $ctx, $dh ) or die_now( "Failed to set tmp DH: $!" );
  Net::SSLeay::DH_free( $dh );
  return $ctx;
}

'POE it';

__END__

=pod

=head1 NAME

POE::Component::Server::NRPE - A POE Component implementation of NRPE Daemon.

=head1 VERSION

version 0.18

=head1 SYNOPSIS

  use strict;
  use POE;
  use POE::Component::Server::NRPE;
  use POE::Component::Server::NRPE::Constants qw(NRPE_STATE_OK);

  my $port = 5666;

  my $nrped = POE::Component::Server::NRPE->spawn(
	port => $port;
  );

  $nrped->add_command( command => 'meep', program => \&_meep );

  $poe_kernel->run();
  exit 0;

  sub _meep {
	print STDOUT "OK meep\n";
	exit NRPE_STATE_OK;
  }

=head1 DESCRIPTION

POE::Component::Server::NRPE is a L<POE> component that implements an NRPE (Nagios Remote Plugin Executor)
daemon supporting both version 1 and version 2 protocols. It also supports SSL encryption using L<Net::SSLeay> and a hacked version of L<POE::Component::SSLify>.

Access is controlled by specifying L<Net::Netmask> objects to the constructor. The default behaviour is to allow access from any IP address.

=head1 CONSTRUCTOR

=over

=item spawn

Takes a number of parameters, which are optional:

  'address', bind the listening socket to a particular address, default is IN_ADDR_ANY;
  'port', specify a port to listen on, default is 5666;
  'version', the NRPE protocol version to use, default is 2;
  'usessl', set this to 0 to disable SSL support with NRPE Version 2, default is 1;
  'time_out', specify a time out in seconds for socket connections and commands, default is 10;
  'access', an arrayref of Net::Netmask objects that will be granted access, default is 'any';

Returns a POE::Component::Server::NRPE object.

=back

=head1 METHODS

=over

=item session_id

Returns the POE::Session ID of the component.

=item shutdown

Terminates the component. Shuts down the listener and disconnects connected clients.

=item getsockname

Access to the L<POE::Wheel::SocketFactory> method of the underlying listening socket.

=item add_command

This will add a command that can be run. Takes a number of parameters:

  'command', a label for the command. This is what clients will request, mandatory;
  'program', the program to run. Can be a coderef, mandatory;
  'args', the command line arguments to pass to the above program, must be an arrayref;

The 'command' should behave like an NRPE plugin: It should print a
status message to STDOUT and exit() with the test's outcome.
POE::Component::Server::NRPE::Constants defines constants for the
valid exit() values.

add_command() eturns 1 if successful, undef otherwise.

=item del_command

Removes a previously defined command. Takes one argument, the previously defined label to remove.

Returns 1 if successful, undef otherwise.

=back

=head1 INPUT EVENTS

These are events from other POE sessions that our component will handle:

=over

=item register_command

This will register the sending session with given command. Takes a number of parameters:

   'command', a label for the command. This is what clients will request, mandatory;
   'event', the name of the event in the registering session that will be triggered, mandatory;
   'context', a scalar containing any reference data that your session demands;

The component will increment the refcount of the calling session to make sure it hangs around for events.
Therefore, you should use either C<unregister_command> or C<shutdown> to terminate registered sessions.

Whenever clients request the given command, the component will send the indicated event to the registering session with the following parameters:

  ARG0, a unique id of the client;
  ARG1, the context ( if any );

Your session should then do any necessary processing and use C<return_result> event to return the status and output to the component.

=item unregister_command

This will unregister the sending session with the given command. Takes one parameter:

   'command', a previously registered command, mandatory;

=item return_result

After processing a command your session must use this event to return the status and output to the component. Takes three values:

   The unique id of the client;
   The status which should be 0, 1 , 2 or 3, indicating OK, WARNING, CRITICAL or UNKNOWN, respectively;
   A string with some meaning output;

   $kernel->post( 'nrped', 'return_result', $id, 0, 'OK Everything was cool' );

=item shutdown

Terminates the component. Shuts down the listener and disconnects connected clients.

=back

=head1 CAVEATS

Due to problems with L<Net::SSLeay> mixing of client and server SSL is not encouraged unless fork() is employed.

=head1 TODO

Add a logging capability.

=head1 SEE ALSO

L<POE>

L<POE::Component::SSLify>

L<http://www.nagios.org/>

=head1 KUDOS

This module uses code derived from L<http://www.stic-online.de/stic/html/nrpe-generic.html>
Copyright (C) 2006, 2007 STIC GmbH, http://www.stic-online.de

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Rocco Caputo <rcaputo@cpan.org>

=item *

Olivier Raginel <github@babar.us>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Williams, Rocco Caputo, Olivier Raginel and STIC GmbH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
