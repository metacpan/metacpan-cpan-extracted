use strict;
use warnings;
use Test::More;
use Test::LWP::UserAgent;
use HTTP::Status qw(:constants :is status_message);

use_ok( 'RestAPI' );

ok(my $c = RestAPI->new(
        scheme      => 'http',
        http_verb   => 'GET',
        server      => 'localhost',
        path        => 'get',
    ), 'new' );

my $payload = {foo => 'bar'};
my $payload_encoded = '{"foo":"bar"}';
my $ua = Test::LWP::UserAgent->new();
$ua->map_response( 
    HTTP::Request->new(
        $c->http_verb, 
        'http://localhost/get',
    ),
    HTTP::Response->new('200','Success', 
        ['Content-Type' => 'application/json'],
        $payload_encoded
    )
);

$c->_set_ua( $ua );
ok( my $data = $c->do(), 'do' );
is( $c->response->code, HTTP_OK, 'request success' );
is( ref $data, 'HASH', 'got right data type back');
is_deeply( $data, $payload, 'got right data back');

done_testing;



