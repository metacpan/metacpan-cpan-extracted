use Test::More;

plan tests => 2;

use MIME::Base64 ();

use Net::WebSocket::Handshake::Client ();
use Net::WebSocket::Handshake::Server ();

is(
    Net::WebSocket::Handshake::Server->new( key => 'dGhlIHNhbXBsZSBub25jZQ==')->get_accept(),
    's3pPLMBiTxaQ9kYGzzhZRbK+xOo=',
    'create_accept()',
);

my $client = Net::WebSocket::Handshake::Client->new( uri => 'ws://haha.tld' );

like(
    MIME::Base64::decode_base64( $client->get_key() ),
    qr<\A.{16}\z>s,
    'create_key()',
);
