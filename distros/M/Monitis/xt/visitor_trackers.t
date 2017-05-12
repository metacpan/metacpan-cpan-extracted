use lib 't/lib';
use Test::Monitis tests => 3, live => 1;

note 'Action visitorTrackingTests (visitor_trackers->get)';

my $response = api->visitor_trackers->get;

isa_ok $response, 'ARRAY', 'JSON response ok';
my $site_id = $response->[0][0];

SKIP: {
    skip "Need monitor ID for this test", 2 unless $site_id;

    note 'Action visitorTrackingInfo (visitor_trackers->get_info)';

    $response = api->visitor_trackers->get_info(siteId => $site_id);

    isa_ok $response, 'ARRAY', 'JSON response ok';
    like $response->{id}, qr/^\d+$/, 'API returned id';

    note 'Action visitorTrackingResults (visitor_trackers->get_results)';

    $response = api->visitor_trackers->get_results(
        siteId => $site_id,
        day    => '29',
        month  => '5',
        year   => '2011'
    );

    isa_ok $response, 'HASH', 'JSON response ok';
}
