use strict;
use warnings;

use Test::More;
use Test::Exception;

use Sensu::API::Client;

SKIP: {
    skip '$ENV{SENSU_API_URL} not set', 5 unless $ENV{SENSU_API_URL};

    my $api = Sensu::API::Client->new(
        url => $ENV{SENSU_API_URL},
    );

    throws_ok { $api->health() } qr/required/, 'Dies without parameters';
    throws_ok { $api->health(consumers => 1) } qr/required/, 'Dies without messages';
    throws_ok { $api->health(messages  => 1) } qr/required/, 'Dies without consumers';

    my $r;
    lives_ok { $r = $api->health(consumers => 1, messages => 1) } 'Correct call ok';
    ok($r, 'Health ok');

    lives_ok { $r = $api->health(consumers => 50, messages => 50) } 'Correct call ko';
    ok(not($r), 'Health ko');
}

done_testing();
