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
        encoding  => 'application/json',
        payload   => $payload,
        path      => 'post',
    ), 'new');

is( $c->payload, $payload_encoded, 'payload encoded properly');

done_testing();
