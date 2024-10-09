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
