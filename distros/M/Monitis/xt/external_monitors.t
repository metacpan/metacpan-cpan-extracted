use lib 't/lib';
use Test::Monitis tests => 22, live => 1;
use Data::Dumper;

note 'Action locations (external_monitors->get_locations)';

my $response = api->external_monitors->get_locations;

isa_ok $response, 'ARRAY', 'JSON response ok';

my @locations = map { $_->{id} } @$response;

note 'Action addExternalMonitor (external_monitors->add)';

=head doesn't work
$response = api->external_monitors->add(
    type        => 'ping',
    name        => 'test_test',
    url         => 'google.com',
    interval    => 5,
    timeout     => 1000,
    locationIds => 1,  # join(',', @locations[0, 1]),
    tag         => 'test_from_api'
);
=cut

$response = api->external_monitors->add(
    type               => 'http',
    name               => 'test_test',
    detailedTestType   => 0,
    url                => 'google.com',
    interval           => 1,
    timeout            => 1000,
    locationIds        => join(',', @locations[0, 1]),
    contentMatchFlag   => 1,
    contentMatchString => 'Google',
    tag                => 'test_from_api'
);
isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status},   'ok',   'status ok';
isa_ok $response->{data}, 'HASH', 'response data ok';
like $response->{data}{testId}, qr/^\d+$/, 'API returned test id';

my $monitor_id = $response->{data}{testId};

note 'Action editExternalMonitor (external_monitors->edit)';

$response = api->external_monitors->edit(
    testId      => $monitor_id,
    name        => 'test_monitor',
    url         => 'google.com',
    locationIds => join(',', @locations[0, 1, 2]),
    timeout     => 100,
    tag         => 'test_from_api'
);

isa_ok $response, 'HASH', 'JSON response ok';
TODO: {
    local $TODO =
      'This is bug related to urlencode (see locationIds). Will pass soon.';
    is $response->{status}, 'ok', 'response status ok';
}

note 'Action tests (external_monitors->get_monitors)';

$response = api->external_monitors->get_monitors;

isa_ok $response, 'HASH', 'JSON response ok';
isa_ok $response->{testList}, 'ARRAY', 'JSON response ok';

my ($exists) =
  grep { $_->{id} == $monitor_id } @{$response->{testList}};

ok $exists, 'monitor exists';

$monitor_id ||= $response->{testList}->[0]{id};

note 'Action suspendExternalMonitor (external_monitors->suspend)';

$response = api->external_monitors->suspend(monitorIds => $monitor_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action activateExternalMonitor (external_monitors->activate)';

$response = api->external_monitors->activate(monitorIds => $monitor_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';


note 'Action testinfo (external_monitors->get_monitor_info)';

$response = api->external_monitors->get_monitor_info(testId => $monitor_id);

isa_ok $response, 'HASH', 'JSON response ok';

note 'Action testresult (external_monitors->get_monitor_results)';

$response = api->external_monitors->get_monitor_results(
    testId => $monitor_id,
    day    => (localtime)[3],
    month  => (localtime)[4] + 1,
    year   => (localtime)[5] + 1900
);

isa_ok $response, 'ARRAY', 'JSON response ok';

note 'Action tagtests (external_monitors->get_by_tag)';

$response = api->external_monitors->get_by_tag(tag => 'test_from_api');

isa_ok $response, 'HASH', 'JSON response ok';

note 'Action testsLastValues (external_monitors->get_snapshot)';

$response = api->external_monitors->get_snapshot;

isa_ok $response, 'ARRAY', 'JSON response ok';

note 'Action topexternal (external_monitors->get_top_results)';

$response = api->external_monitors->get_top_results;

isa_ok $response, 'HASH', 'JSON response ok';

note 'Action tags (external_monitors->get_tags)';

$response = api->external_monitors->get_tags;

isa_ok $response, 'HASH', 'JSON response ok';

note 'Action deleteExternalMonitor (external_monitors->delete)';

$response = api->external_monitors->delete(testIds => $monitor_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
