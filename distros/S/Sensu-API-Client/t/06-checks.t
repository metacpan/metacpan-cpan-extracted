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
    lives_ok { $r = $api->checks } 'Call to checks lives';
    is(ref $r, 'ARRAY', 'Array returned');
    cmp_ok(scalar @$r, '>=', 1, 'At least one check');
    ok(exists $r->[0]->{command}, 'Key command exists');

    my $check = $r->[0];
    throws_ok { $api->check } qr/required/, 'Call without params dies';
    lives_ok { $r = $api->check($check->{name}) } 'Call to check lives';
    is(ref $r, 'HASH', 'Hash returned');
    is($r->{name}, $check->{name}, 'Correct check returned');

    throws_ok { $api->request } qr/required/, 'Call without params dies';
    throws_ok { $api->request($check->{name}, 'xxx') } qr/arrayref/, 'Wrong param';
    lives_ok  { $api->request($check->{name}, $check->{subscribers}) } 'Call ok lives';
}

done_testing();
