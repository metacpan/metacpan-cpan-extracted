use lib 't/lib';

use Test::Monitis agent => 1, tests => 13;

note 'Action addPingMonitor (ping->add)';

my $response = api->ping->add(
    userAgentId  => agent->{id},
    maxLost      => 2,
    packetsCount => 5,
    packetsSize  => 32,
    timeout      => 20000,
    url          => 'google.com',
    name         => 'google.com',
    tag          => 'test_from_api'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{testId}, qr/^\d+$/, 'API returned test id';

my $monitor_id = $response->{data}{testId};

note 'Action editPingMonitor (ping->edit)';

$response = api->ping->edit(
    testId       => $monitor_id,
    maxLost      => 3,
    packetsCount => 5,
    packetsSize  => 32,
    timeout      => 1000,
    name         => 'google.com',
    tag          => 'test_from_api'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action agentPing (ping->get)';

$response = api->ping->get(agentId => agent->{id});

isa_ok $response, 'ARRAY', 'JSON response ok';
my ($exists) =
  grep { $_->{id} == $monitor_id } @$response;

ok $exists, 'monitor exists';

$monitor_id ||= $response->[0]{id};

note 'Action PingInfo (ping->get_info)';

$response = api->ping->get_info(monitorId => $monitor_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{id}, $monitor_id, 'response id ok';

note 'Action pingResult (ping->get_results)';

$response = api->ping->get_results(
    monitorId => $monitor_id,
    day       => (localtime)[3],
    month     => (localtime)[4] + 1,
    year      => (localtime)[5] + 1900
);

isa_ok $response, 'HASH', 'JSON response ok';
isa_ok $response->{data}, 'ARRAY', 'response data ok';

note 'Cleanup';

$response = api->internal_monitors->delete(testIds => $monitor_id, type => 5);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'monitor deleted';
