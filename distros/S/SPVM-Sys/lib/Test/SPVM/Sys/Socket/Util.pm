package Test::SPVM::Sys::Socket::Util;

use strict;
use warnings;
use Carp ();

use Socket;
use IO::Socket::IP;
use IO::Socket::UNIX;
use Errno qw/ECONNREFUSED/;

sub get_available_port {
  
  # System will select an unused port
  my $socket = IO::Socket::IP->new(
    Listen => 5,
    # In Windows, SO_REUSEADDR works differently In Linux. The feature that corresponds to SO_REUSEADDR in Linux is enabled by default in Windows.
    (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
  );
  my $port = $socket->sockport;
  
  $socket->close;
  
  return $port;
}

# Copied from https://metacpan.org/dist/Test-TCP/source/lib/Net/EmptyPort.pm
sub can_bind {
    my ($host, $port, $proto) = @_;
    # The following must be split across two statements, due to
    # https://rt.perl.org/Public/Bug/Display.html?id=124248
    my $s = _listen_socket($host, $port, $proto);
    return defined $s;
}
 
sub _listen_socket {
    my ($host, $port, $proto) = @_;
    $port  ||= 0;
    $proto ||= 'tcp';
    IO::Socket::IP->new(
        (($proto eq 'udp') ? () : (Listen => 5)),
        LocalAddr => $host,
        LocalPort => $port,
        Proto     => $proto,
        V6Only    => 1,
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    );
}

1;

=head1 Name

Test::SPVM::Sys::Socket::Util - Socket Utility Functions for SPVM::Sys::Socket

=head1 Description

Test::SPVM::Sys::Socket::Util module has functions for socket utilities for SPVM::Sys::Socket.

=head1 Usage

  use  Test::SPVM::Sys::Socket::Util;
  
  my $port = Test::SPVM::Sys::Socket::Util::get_available_port;

=head1 Functions

=head2 get_available_port

  my $port = Test::SPVM::Sys::Socket::Util::get_available_port;

Gets an available port and returns it.

=head2 can_bind

  my $can_bind = Test::SPVM::Sys::Socket::Util::::can_bind($host, $port, $proto);

Checks if bind system call succeeds given the host $host, the port $port, the protocal $proto.

If it succeeds, returns 1, otherwise returns 0.
