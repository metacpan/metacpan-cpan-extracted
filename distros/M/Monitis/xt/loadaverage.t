use lib 't/lib';
use Test::Monitis tests => 14, agent => 1;

note 'Action addLoadAverageMonitor (load_average->add)';

my $response = api->load_average->add(
    agentkey => agent->{key},
    limit1   => '2.00',
    limit5   => '2.00',
    limit15  => '2.00',
    name     => 'test1',
    tag      => 'test_from_api'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{testId}, qr/^\d+$/, 'API returned test id';

my $monitor_id = $response->{data}{testId};

note 'Action editLoadAverageMonitor (load_average->edit)';

$response = api->load_average->edit(
    testId  => $monitor_id,
    limit1  => '2.00',
    limit5  => '2.00',
    limit15 => '2.00',
    name    => 'test2',
    tag     => 'test_from_api'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action agentLoadAverage (load_average->get)';

$response = api->load_average->get(agentId => agent->{id});

isa_ok $response, 'ARRAY', 'JSON response ok';
my ($exists) =
  grep { $_->{id} == $monitor_id } @$response;

ok $exists, 'monitor exists';

$monitor_id ||= $response->[0]{id};

note 'Action LoadAverageInfo (load_average->get_info)';

$response = api->load_average->get_info(monitorId => "$monitor_id");

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{id}, $monitor_id, 'response id ok';

note 'Action laResult (load_average->get_results)';

$response = api->load_average->get_results(
    monitorId => $monitor_id,
    day       => (localtime)[3],
    month     => (localtime)[4] + 1,
    year      => (localtime)[5] + 1900
);

isa_ok $response, 'ARRAY', 'JSON response ok';

note 'Action topla (load_average->get_top_results)';

$response = api->load_average->topload1;

isa_ok $response, 'HASH', 'JSON response ok';
isa_ok $response->{tests}, 'ARRAY', 'tests response ok';

note 'Cleanup';

$response = api->internal_monitors->delete(testIds => $monitor_id, type => 6);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'monitor deleted';
