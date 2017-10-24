use Test::More;

plan tests => 3;

use HTTP::Request ();

use MIME::Base64 ();

use Net::WebSocket::Handshake::Client ();
use Net::WebSocket::Handshake::Server ();
use Net::WebSocket::Handshake::Extension ();

my $ext_a = Net::WebSocket::Handshake::Extension->new( 'extension-a' );
my $ext_b = Net::WebSocket::Handshake::Extension->new(
    'extension-b',
    param1 => undef,
    param2 => '42 42',
);

my $client = Net::WebSocket::Handshake::Client->new(
    uri => 'ws://haha.tld',
    subprotocols => [ 'sub1', 'sub2' ],
    extensions => [ $ext_a, $ext_b ],
    origin => 'http://some.where',
);

my $req = HTTP::Request->parse( $client->to_string() );

#----------------------------------------------------------------------

is(
    $req->header('Origin'),
    'http://some.where',
    '“Origin” header',
);

#----------------------------------------------------------------------

my @extensions = HTTP::Headers::Util::split_header_words(
    $req->header('Sec-WebSocket-Extensions'),
);

is_deeply(
    \@extensions,
    [
        [ 'extension-a' => undef ],
        [
            'extension-b' => undef,
            param1 => undef,
            param2 => '42 42',
        ],
    ],
    'extensions',
) or diag explain \@extensions;

#----------------------------------------------------------------------

my @protocols = HTTP::Headers::Util::split_header_words(
    $req->header('Sec-WebSocket-Protocol'),
);

is_deeply(
    \@protocols,
    [ [ 'sub1' => undef ], [ 'sub2' => undef ] ],
    'protocols',
) or diag explain \@protocols;
