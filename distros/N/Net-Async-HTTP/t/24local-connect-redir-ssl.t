#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

eval {
   require IO::Async::SSL;
   IO::Async::SSL->VERSION( '0.12' );
} or plan skip_all => "No IO::Async::SSL";

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers
);

$loop->add( $http );

my $redir_url;

my $port;
$loop->SSL_listen(
   host    => "127.0.0.1",
   service => 0,
   socktype => "stream",

   SSL_key_file  => "t/privkey.pem",
   SSL_cert_file => "t/server.pem",

   on_listen => sub {
      $port = shift->sockport;
   },

   on_stream => sub {
      my ( $stream ) = @_;

      $stream->configure(
         on_read => sub {
            my ( $self, $buffref ) = @_;
            return 0 unless $$buffref =~ s/^(.*?)$CRLF$CRLF//s;

            my $header = $1;

            my $response = ( $header =~ m{^GET /redir} )
               ? "HTTP/1.1 301 Moved Permanently$CRLF" .
                 "Content-Length: 0$CRLF" .
                 "Location: $redir_url$CRLF" .
                 "Connection: Keep-Alive$CRLF" .
                 "$CRLF"
               : "HTTP/1.1 200 OK$CRLF" .
                 "Content-Type: text/plain$CRLF" .
                 "Content-Length: 2$CRLF" .
                 "Connection: Keep-Alive$CRLF" .
                 "$CRLF" .
                 "OK";

            $self->write( $response );

            return 1;
         },
      );

      $loop->add( $stream );
   },

   on_listen_error => sub { die "Test failed early - $_[-1]" },
   on_resolve_error => sub { die "Test failed early - $_[-1]" },
   on_ssl_error     => sub { die "Test failed early - $_[-1]" },
)->get;

$redir_url = "https://127.0.0.1:$port/moved";

my $response = $http->do_request(
   uri => URI->new( "https://127.0.0.1:$port/redir" ),

   SSL_verify_mode => 0,

   on_error => sub { die "Test failed early - $_[-1]" },
)->get;

is( $response->content_type, "text/plain", '$response->content_type' );
is( $response->content, "OK", '$response->content' );

# require_SSL
{
   $http->configure( require_SSL => 1 );

   $redir_url = "http://127.0.0.1:$port/moved_to_plaintext";

   my $f = $http->GET( "https://127.0.0.1:$port/redir" );

   wait_for_future( $f );

   ok( $f->failure, '->GET on http with require_SSL fails' );
   like( scalar $f->failure, qr/require_SSL/, 'require_SSL failure' );
}

done_testing;
