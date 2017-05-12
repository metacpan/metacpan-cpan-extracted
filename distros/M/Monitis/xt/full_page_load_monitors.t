use lib 't/lib';
use Test::Monitis tests => 11, live => 1;

my $unique_name = 'test_monitor';

my @chars = split //, 'abcdefgh0123456789';
my $size = rand(15);

for (0 .. $size) {
    $unique_name .= uc $chars[rand(scalar @chars)];
}

note 'Action addFullPageLoadMonitorsMonitor (full_page_load_monitors->add)';

my $response = api->full_page_load_monitors->add(
    name          => $unique_name,
    tag           => 'test_from_api',
    locationIds   => '1',
    checkInterval => 3,
    url           => 'google.com',
    timeout       => 1000
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{testId}, qr/^\d+$/, 'API returned test id';

my $test_id = $response->{data}{testId};

SKIP: {

    skip "Monitor ID required for this tests", 2 unless $test_id;

    note
      'Action editFullPageLoadMonitorsMonitor (full_page_load_monitors->edit)';

    $response = api->full_page_load_monitors->edit(
        monitorId     => $test_id,
        name          => $unique_name,
        tag           => 'test',
        locationIds   => '1,5',
        checkInterval => '10',
        url           => 'google.com',
        timeout       => '5'
    );
    isa_ok $response, 'HASH', 'JSON response ok';

  TODO: {
        local $TODO =
          'This test should pass when Monitis fix urlencode issue';
        is $response->{status}, 'ok', 'status ok';
    }


    note
      'Action editFullPageLoadMonitorsMonitor (full_page_load_monitors->edit)';

    $response = api->full_page_load_monitors->edit(
        monitorId     => $test_id,
        name          => $unique_name,
        tag           => 'test',
        locationIds   => '5',
        checkInterval => '10',
        url           => 'google.com',
        timeout       => '5'
    );
}

note 'Action suspendFullPageLoadMonitor (full_page_load_monitors->suspend)';

$response = api->full_page_load_monitors->suspend(tag => 'test');

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action activateFullPageLoadMonitor (full_page_load_monitors->activate)';

$response = api->full_page_load_monitors->activate(tag => 'test');

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action deleteFullPageLoadMonitor (full_page_load_monitors->delete)';

SKIP: {
    skip "Monitor ID required for this test", 2 unless $test_id;

    $response = api->full_page_load_monitors->delete(monitorIds => $test_id);

    isa_ok $response, 'HASH', 'JSON response ok';
  TODO: {
        local $TODO = 'This action is not implemented by Monitis yet';
        is $response->{status}, 'ok', 'status ok';
    }
}
