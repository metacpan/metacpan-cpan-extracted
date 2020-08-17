use strict;
use warnings;

use Test::More;
use Test::LWP::UserAgent;
use HTTP::Status qw(:constants :is status_message);

use_ok( 'RestAPI' );

my $payload = {foo => 'bar'};
my $payload_encoded = '{"foo":"bar"}';

ok(my $c = RestAPI->new(
        scheme    => 'http',
        server    => 'localhost',
        http_verb => 'POST',
        payload   => $payload,
        path      => 'post',
        encoding  => 'application/json'
    ), 'new');

my $ua = Test::LWP::UserAgent->new();
$ua->map_response( 
    HTTP::Request->new(
        $c->http_verb, 
        'http://localhost/post',
        ['Content-Type' => 'application/json'],
        $payload_encoded),
    HTTP::Response->new('200','Success', 
        ['Content-Type' => 'application/json'],
        $payload_encoded
    )
);

$c->_set_ua( $ua );
ok( my $data = $c->do(), 'do' );
is( $c->response->code, HTTP_OK, 'request success' );
is_deeply( $data, $payload, 'got right data back');

done_testing();
