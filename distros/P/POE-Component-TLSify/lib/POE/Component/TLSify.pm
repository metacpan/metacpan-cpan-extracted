package POE::Component::TLSify;
$POE::Component::TLSify::VERSION = '0.02';
#ABSTRACT: Makes using SSL/TLS in the world of POE easy!

use strict;
use warnings;

use Symbol qw[gensym];
use Scalar::Util qw[weaken];
use POE::Component::TLSify::ClientHandle;
use POE::Component::TLSify::ServerHandle;

use parent 'Exporter';
our @EXPORT_OK = qw[
  Client_TLSify Server_TLSify TLSify_GetSocket TLSify_GetCipher
];

sub Server_TLSify {
  my ($socket,$args,$callback) = @_;

  if ( ! defined $socket ) {
    die 'Did not get a defined socket';
  }

  if ( ! defined $socket->blocking( 0 ) ) {
    die "Unable to set nonblocking mode on socket: $!";
  }

  if ( defined $callback && ref $callback ne 'CODE' ) {
    undef $callback;
  }

  my $newsock = gensym();
  tie( *$newsock, 'POE::Component::TLSify::ServerHandle', $socket, $args, $callback ) or die "Unable to tie to our subclass: $!";

  if ( defined $callback ) {
    tied( *$newsock )->{'orig_socket'} = $newsock;
    weaken ( tied( *$newsock )->{'orig_socket'} );
  }

  return $newsock;
}

sub Client_TLSify {
  my ($socket,$args,$callback) = @_;

  if ( ! defined $socket ) {
    die 'Did not get a defined socket';
  }

  if ( ! defined $socket->blocking( 0 ) ) {
    die "Unable to set nonblocking mode on socket: $!";
  }

  if ( defined $callback && ref $callback ne 'CODE' ) {
    undef $callback;
  }

  my $newsock = gensym();
  tie( *$newsock, 'POE::Component::TLSify::ClientHandle', $socket, $args, $callback ) or die "Unable to tie to our subclass: $!";

  if ( defined $callback ) {
    tied( *$newsock )->{'orig_socket'} = $newsock;
    weaken ( tied( *$newsock )->{'orig_socket'} );
  }

  return $newsock;
}

sub TLSify_GetSocket {
  my $sock = shift;
  return tied( *$sock )->{'socket'};
}

sub TLSify_GetCipher {
  my $sock = shift;
  return tied( *$sock )->{'socket'}->get_cipher;
}

qq[I TLSify!];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::TLSify - Makes using SSL/TLS in the world of POE easy!

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # look at the DESCRIPTION for client and server example code

=head1 DESCRIPTION

This component is a method to simplify the TLSification of a socket before it is passed
to a L<POE::Wheel::ReadWrite> wheel in your application.

Based on L<POE::Component::SSLify>, instead of directly wrapping L<Net::SSLeay> it uses
L<IO::Socket::SSL> and has slight differences in API as a result.

=head2 Client usage

        # Import the module
        use POE::Component::TLSify qw( Client_TLSify );

        # Create a normal SocketFactory wheel and connect to a TLS-enabled server
        my $factory = POE::Wheel::SocketFactory->new;

        # Time passes, SocketFactory gives you a socket when it connects in SuccessEvent
        # Convert the socket into a TLS socket POE can communicate with
        my $socket = shift;
        eval { $socket = Client_TLSify( $socket ) };
        if ( $@ ) {
                # Unable to TLSify it...
        }

        # Now, hand it off to ReadWrite
        my $rw = POE::Wheel::ReadWrite->new(
                Handle  =>   $socket,
                # other options as usual
        );

=head2 Server usage

        # !!! Make sure you have a public key + certificate
        # excellent howto: http://www.akadia.com/services/ssh_test_certificate.html

        # Import the module
        use POE::Component::TLSify qw( Server_TLSify );

        # Create a normal SocketFactory wheel to listen for connections
        my $factory = POE::Wheel::SocketFactory->new;

        # Time passes, SocketFactory gives you a socket when it gets a connection in SuccessEvent
        # Convert the socket into a SSL socket POE can communicate with
        my $socket = shift;

        # Set the key + certificate file options to pass to IO::Socket::SSL
        my $io_socket_ssl_args = {
            SSL_cert_file => 'server.crt',
            SSL_key_file  => 'server.key',
        };
        eval { $socket = Server_TLSify( $socket, $io_socket_ssl_args ) };
        if ( $@ ) {
                # Unable to TLSify it...
        }

        # Now, hand it off to ReadWrite
        my $rw = POE::Wheel::ReadWrite->new(
                Handle  =>   $socket,
                # other options as usual
        );

=head1 FUNCTIONS

=head2 Client_TLSify

This function tlsifies a client-side socket. You can pass several options to it:

  my $socket = shift;
  $socket = Client_TLSify( $socket, $io_socket_ssl_args, $callback );

  $socket is the non-ssl socket you got from somewhere ( required )
  $io_socket_ssl_args is a hashref of IO::Socket::SSL options to pass to that module
  $callback is the callback hook on success/failure of tlsification

  # This is an example of the callback and you should pass it as Client_SSLify( $socket, ... , \&callback );
  sub callback {
      my( $socket, $status, $errval ) = @_;
      # $socket is the original sslified socket in case you need to play with it
      # $status is either 1 or 0; with 1 signifying success and 0 failure
      # $errval will be defined if $status == 0; it's whatever IO::Socket::SSL returned from errstr

      # The return value from the callback is discarded
  }

The function uses L<IO::Socket::SSL> C<start_SSL> to start tlsification and calls C<connect_SSL>. The hashref of options
passed in are passed to C<start_SSL> so you can adjust the tlsification to taste, such as adding client certificates, etc.

The callback unlike in L<POE::Component::SSLify> must be the third argument. As with L<POE::Component::SSLify> the callback
can be a POE event, see postback/callback stuff in L<POE::Session>.

=head2 Server_TLSify

This function sslifies a server-side socket. You can pass several options to it:

  my $socket = shift;
  my $io_socket_ssl_args = {
     SSL_cert_file => 'server.crt',
     SSL_key_file  => 'server.key',
  };
  $socket = Server_TLSify( $socket, $io_socket_ssl_args, $callback );

  $socket is the non-ssl socket you got from somewhere ( required )
  $io_socket_ssl_args is a hashref of IO::Socket::SSL options to pass to that module
  $callback is the callback hook on success/failure of tlsification

The function uses L<IO::Socket::SSL> C<start_SSL> to start tlsification and calls C<accept_SSL>. The hashref of options
passed in are passed to C<start_SSL> so you can adjust the tlsification to taste. At a minimum for a server you will require
a certificate and key that should be passed with the C<SSL_cert_file> and C<SSL_key_file> options.

Please look at L</Client_SSLify> for more details on the callback hook.

=head2 TLSify_GetSocket

Returns the actual L<IO::Socket::SSL> socket used by the TLSified socket, useful for stuff like getpeername()/getsockname()

  print "Remote IP is: " . inet_ntoa( ( unpack_sockaddr_in( getpeername( SSLify_GetSocket( $sslified_sock ) ) ) )[1] ) . "\n";

and all the other methods that L<IO::Socket::SSL> provides.

=head2 TLSify_GetCipher

Returns the cipher used by the TLSified socket

   print "SSL Cipher is: " . TLSify_GetCipher( $tlsified_sock ) . "\n";

NOTE: Doing this immediately after Client_TLSify or Server_TLSify will result in "(NONE)" because the SSL handshake
is not done yet. The socket is nonblocking, so you will have to wait a little bit for it to get ready.

=head1 NOTES

=head2 Certificate Verification

L<POE::Component::SSLify> did not do certificate validation and verification. L<IO::Socket::SSL> does by default.
It would be useful to make yourself aware of this default behaviour and check out the documentation for the
following options C<SSL_verify_mode>, C<SSL_verify_callback> and C<SSL_ocsp_mode>.

=head2 Socket methods doesn't work

The new socket this module gives you actually is C<tied> socket magic, so you cannot do stuff like
C<getpeername()> or C<getsockname()>. The only way to do it is to use L</TLSify_GetSocket> and then operate on
the L<IO::Socket::SSL> socket it returns.

=head2 Dying to meet you ...

This module will C<die()> if TLSification process fails. So, it is recommended
that you check for errors and not use SSL, like so:

   eval { use POE::Component::TLSify };
   if ( $@ ) {
     $sslavailable = 0;
   }
   else {
     $sslavailable = 1;
   }

   # Make socket SSL!
   if ( $sslavailable ) {
     eval { $socket = POE::Component::TLSify::Client_TLSify( $socket ) };
     if ( $@ ) {
        # Unable to TLSify the socket...
     }
   }

=head2 IO::Socket::SSL methods

The underlying socket is a L<IO::Socket::SSL> so you may use any of the supported methods on the socket object.
Use L</TLSify_GetSocket> to retrieve that object.

=head2 Upgrading a non-ssl socket to SSL

You can have a normal plaintext socket, and convert it to TLS anytime. Just keep in mind that the client and the server must agree to tlsify
at the same time, or they will be waiting on each other forever!

=head2 Downgrading a SSL socket to non-ssl

As of now this is unsupported. If you need this feature please let us know and we'll work on it together!
In theory L<IO::Socket::SSL> does provide a C<stop_SSL> method, so this should be possible.

=head1 ACKNOWLEDGEMENTS

  Original POE::Component::SSLify:

  Original code is entirely Rocco Caputo ( Creator of POE ) -> I (APOCAL) simply
  packaged up the code into something everyone could use and accepted the burden
  of maintaining it :)

  POE::Component::TLSify is based on POE::Component::SSLify, I (BINGOS) simply
  ported the code to use IO::Socket::SSL instead of using Net::SSLeay

  Thanks also to Paul Evans (PEVANS), the IO::Async author, whose IO::Async::SSL
  provided inspiration for using IO::Socket::SSL

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Apocalypse <APOCAL@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Chris Williams, Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
