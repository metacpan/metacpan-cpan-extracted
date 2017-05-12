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

    my $r;
    lives_ok { $r = $api->clients } 'Call to clients lives';
    is(ref $r, 'ARRAY', 'Array returned');
    cmp_ok(scalar @$r, '>=', 1, 'At least one client');

    my $client = $r->[0];
    throws_ok { $api->client } qr/required/, 'Call without params dies';
    lives_ok { $r = $api->client($client->{name}) } 'Call to client lives';
    is(ref $r, 'HASH', 'Hash returned');
    is($r->{name}, $client->{name}, 'Correct client returned');

    throws_ok { $api->client_history } qr/required/, 'Call without params dies';
    lives_ok { $r = $api->client_history($client->{name}) } 'Call to history lives';
    is(ref $r, 'ARRAY', 'Array returned');
    ok(exists $r->[0]->{history}, 'Key history exists');

    throws_ok { $api->delete_client } qr/required/, 'Call without params dies';
    lives_ok  { $api->delete_client($client->{name}) } 'Call to delete_client lives';
}

done_testing();
