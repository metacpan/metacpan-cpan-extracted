package POE::Component::Client::NRPE;
{
  $POE::Component::Client::NRPE::VERSION = '0.20';
}

#ABSTRACT: A POE Component that implements check_nrpe functionality

use strict;
use warnings;
use POE qw(Wheel::SocketFactory Filter::Stream Wheel::ReadWrite);
use Net::SSLeay;
use POE::Component::SSLify qw( Client_SSLify );
use Carp;
use Socket;
use integer;

sub check_nrpe {
  my $package = shift;
  my %params = @_;
  $params{lc $_} = delete $params{$_} for keys %params;
  croak "$package requires a 'host' argument\n"
	unless $params{host};
  croak "$package requires an 'event' argument\n"
	unless $params{event};
  $params{port} = 5666 unless defined $params{port};
  $params{command} = '_NRPE_CHECK' unless $params{command};
  $params{command} = join( '!', $params{command}, $params{args} ) if defined $params{args};
  $params{version} = 2 unless $params{version} and $params{version} eq '1';
  $params{usessl} = 1 unless defined $params{usessl} and $params{usessl} eq '0';
  $params{timeout} = 10 unless defined $params{timeout} and $params{timeout} =~ /^\d+$/;
  my $options = delete $params{options};
  my $self = bless \%params, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => [ qw(_start _connect _sock_up _sock_err _sock_in _sock_down _send_response _timeout) ],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub _start {
  my ($kernel,$sender,$self) = @_[KERNEL,SENDER,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  $self->{filter} = POE::Filter::Stream->new();
  if ( $kernel == $sender and !$self->{session} ) {
	croak "Not called from another POE session and 'session' wasn't set\n";
  }
  my $sender_id;
  if ( $self->{session} ) {
    if ( my $ref = $kernel->alias_resolve( $self->{session} ) ) {
	$sender_id = $ref->ID();
    }
    else {
	croak "Could not resolve 'session' to a valid POE session\n";
    }
  }
  else {
    $sender_id = $sender->ID();
  }
  $kernel->refcount_increment( $sender_id, __PACKAGE__ );
  $self->{sender_id} = $sender_id;
  $kernel->yield( '_connect' );
  return;
}

sub _connect {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{sockfactory} = POE::Wheel::SocketFactory->new(
	SocketProtocol => 'tcp',
	RemoteAddress => $self->{host},
	RemotePort => $self->{port},
	SuccessEvent => '_sock_up',
	FailureEvent => '_sock_err',
  );
  $kernel->delay( '_timeout', $self->{timeout} );
  return;
}

sub _timeout {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{sockfactory};
  delete $self->{socket};
  $kernel->yield( '_send_response', 'timeout' );
  return;
}

sub _sock_err {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->delay( '_timeout' );
  delete $self->{sockfactory};
  $kernel->yield( '_send_response', 'sockerr', @_[ARG0..ARG2] );
  return;
}

sub _sock_up {
  my ($kernel,$self,$socket) = @_[KERNEL,OBJECT,ARG0];
  $kernel->delay( '_timeout' );
  delete $self->{sockfactory};
  # Only version 2 supports SSL
  if ( $self->{version} == 2 and $self->{usessl} ) {
	my $ctx = Net::SSLeay::CTX_tlsv1_new();
	Net::SSLeay::CTX_set_cipher_list( $ctx, 'ADH');
	eval { $socket = Client_SSLify( $socket, undef, undef, $ctx ); };
	warn "Failed to SSLify the socket: $@\n" if $@;
  }
  $self->{socket} = new POE::Wheel::ReadWrite
    ( Handle     => $socket,
      Filter     => $self->{filter},
      InputEvent => '_sock_in',
      ErrorEvent => '_sock_down',
  );
  my $packet;
  if ( $self->{version} == 1 ) {
     $packet = pack "NNNNa[1024]", 1, 1, 0, length( $self->{command} ), $self->{command};
  }
  else {
     $packet = _gen_packet_ver2( $self->{command} );
  }
  $self->{socket}->put( $packet );
  $kernel->delay( '_timeout', $self->{timeout} );
  return;
}

sub _sock_down {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{socket};
  $kernel->delay( '_timeout' );
  $kernel->yield( '_send_response', 'nodata' ) unless $self->{_data_returned};
  return;
}

sub _sock_in {
  my ($kernel,$self,$input) = @_[KERNEL,OBJECT,ARG0];
  my ($result,$data);
  SWITCH: {
   if ( $self->{version} == 1 ) {
     my $length = length $input;
     if ( $length != 1040 ) {
	$result = 3;
	$data = sprintf "CHECK_NRPE: Received %d bytes (%d expected)", $length, 1040;
	last SWITCH;
     }
     my @args = unpack "NNNNa*", $input;
     if ( $args[0] ne '2' or $args[1] ne '1' or $args[2] !~ /^[0123]$/ ) {
	$result = 3;
	$data = 'CHECK_NRPE: Packet failed sanity checking';
	last SWITCH;
     }
     $args[4] =~ s/\x00*$//g;
     $result = $args[2];
     $data = $args[4] || 'CHECK_NRPE: No output returned from NRPE daemon.';
   }
   else {
     my $length = length $input;
     if ( $length != 1036 ) {
	$result = 3;
	$data = sprintf "CHECK_NRPE: Received %d bytes (%d expected)", $length, 1036;
	last SWITCH;
     }
     my @args = unpack "nnNnZ*", $input;
     if ( $args[0] ne '2' or $args[1] ne '2' or $args[3] !~ /^[0123]$/ ) {
	$result = 3;
	$data = 'CHECK_NRPE: Packet failed sanity checking';
	last SWITCH;
     }
     $args[4] =~ s/\x00*$//g;
     $result = $args[3];
     $data = $args[4] || 'CHECK_NRPE: No output returned from NRPE daemon.';
   }
  }
  $self->{_data_returned} = [ $result, $data ];
  delete $self->{socket};
  $kernel->yield( '_send_response', 'gotdata', $result, $data );
  return;
}

sub _send_response {
  my ($kernel,$self,$type) = @_[KERNEL,OBJECT,ARG0];
  my $response = { };
  $response->{$_} = $self->{$_} for qw(version host command context);
  SWITCH: {
     if ( $type eq 'gotdata' ) {
	$response->{result} = $_[ARG1];
	$response->{data} = $_[ARG2];
	last SWITCH;
     }
     if ( $type eq 'nodata' ) {
	$response->{result} = 3;
	$response->{data} = 'CHECK NRPE: Error receiving data from daemon.';
	last SWITCH;
     }
     if ( $type eq 'sockerr' ) {
	$response->{result} = 3;
	$response->{data} = 'CHECK NRPE: socket error: ' . join(' ', @_[ARG1..$#_]);
	last SWITCH;
     }
     if ( $type eq 'timeout' ) {
	$response->{result} = ( $self->{unknown} ? 3 : 2 );
	$response->{data} = sprintf("CHECK_NRPE: Socket timeout after %d seconds.", $self->{timeout} );
	last SWITCH;
     }
  }
  $kernel->post( $self->{sender_id}, $self->{event}, $response );
  $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
  $kernel->alarm_remove_all();
  return;
}

# These functions are derived from http://www.stic-online.de/stic/html/nrpe-generic.html
# Copyright (C) 2006, 2007 STIC GmbH, http://www.stic-online.de
# Licensed under GPLv2

sub _gen_packet_ver2 {
  my $data = shift;
  for ( my $i = length ( $data ); $i < 1024; $i++ ) {
    $data .= "\x00";
  }
  $data .= "SR";
  my $res = pack "n", 2324;
  my $packet = "\x00\x02\x00\x01";
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

'POE it';

__END__

=pod

=head1 NAME

POE::Component::Client::NRPE - A POE Component that implements check_nrpe functionality

=head1 VERSION

version 0.20

=head1 SYNOPSIS

   # A simple 'check_nrpe' version 2 clone
   use strict;
   use POE qw(Component::Client::NRPE);
   use Getopt::Long;

   $|=1;

   my $command;
   my $hostname;
   my $return_code;

   GetOptions("host=s", \$hostname, "command=s", \$command);

   unless ( $hostname ) {
	$! = 3;
	die "No hostname specified\n";
   }

   POE::Session->create(
	inline_states => {
		_start =>
		sub {
		   POE::Component::Client::NRPE->check_nrpe(
			host    => $hostname,
			command => $command,
			event   => '_result',
		   );
		   return;
		},
		_result =>
		sub {
		   my $result = $_[ARG0];
		   print STDOUT $result->{data}, "\n";
		   $return_code = $result->{result};
		   return;
		},
	}
   );

   $poe_kernel->run();
   exit($return_code);

=head1 DESCRIPTION

POE::Component::Client::NRPE is a L<POE> component that implements version 1 and version 2 of
the nrpe (Nagios Remote Plugin Executor) client, check_nrpe. It also supports SSL encryption
using L<Net::SSLeay> and a hacked version of L<POE::Component::SSLify>.

=head1 NAME

POE::Component::Client::NRPE - a POE Component that implements check_nrpe functionality

=head1 CONSTRUCTOR

=over

=item check_nrpe

Takes a number of parameters:

  'host', the hostname or IP address to connect to, mandatory;
  'event', the event handler in your session where the result should be sent, mandatory;
  'session', optional if the poco is spawned from within another session;
  'port', the port to connect to, default is 5666;
  'version', the NRPE protocol version to use, default is 2;
  'usessl', set this to 0 to disable SSL support with NRPE Version 2, default is 1;
  'command', the command to run remotely, default is '_NRPE_CHECK';
  'args', any arguments to be passed along with the 'command';
  'context', anything you like that'll fit in a scalar, a ref for instance;
  'timeout', number of seconds to wait for socket timeouts, default is 10;
  'unknown', set this to true to make the poco return socket timeouts as UNKNOWN instead of CRITICAL;

The 'session' parameter is only required if you wish the output event to go to a different
session than the calling session, or if you have spawned the poco outside of a session.

The poco does it's work and will return the output event with the result.

=back

=head1 OUTPUT EVENT

This is generated by the poco. ARG0 will be a hash reference with the following keys:

  'version', the NRPE protocol version;
  'host', the hostname given;
  'command', the command that was run;
  'context', anything that you specified;
  'result', the Nagios result code, can be 0,1,2 or 3;
  'data', what the NRPEd gave us by way of output;

=head1 ACKNOWLEDGEMENTS

This module uses code derived from L<http://www.stic-online.de/stic/html/nrpe-generic.html>
Copyright (C) 2006, 2007 STIC GmbH, http://www.stic-online.de

=head1 SEE ALSO

L<POE>

L<POE::Component::SSLify>

L<http://www.nagios.org/>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Williams, Apocalypse, Rocco Caputo and STIC GmbH..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
