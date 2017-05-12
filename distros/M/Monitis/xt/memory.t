use lib 't/lib';
use Test::Monitis tests => 14, agent => 1;

note 'Action addMemoryMonitor (memory->add)';

my $response = api->memory->add(
    agentkey      => agent->{key},
    tag           => 'test_from_api',
    name          => 'test',
    platform      => 'LINUX',
    freeLimit     => 100,
    freeSwapLimit => 100,
    bufferedLimit => 100,
    cachedLimit   => 100
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{testId}, qr/^\d+$/, 'API returned test id';

my $monitor_id = $response->{data}{testId};

note 'Action editMemoryMonitor (memory->edit)';

$response = api->memory->edit(
    testId        => $monitor_id,
    tag           => 'test_from_api',
    name          => 'test-modified',
    platform      => 'LINUX',
    freeLimit     => 200,
    freeSwapLimit => 200,
    bufferedLimit => 200,
    cachedLimit   => 200
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action agentMemory (memory->get)';

$response = api->memory->get(agentId => agent->{id});

isa_ok $response, 'ARRAY', 'JSON response ok';

my ($exists) =
  grep { $_->{id} == $monitor_id } @$response;
ok $exists, 'monitor exists';

$monitor_id ||= $response->[0]{id};

note 'Action MemoryInfo (memory->get_info)';

$response = api->memory->get_info(monitorId => $monitor_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{id}, $monitor_id, 'response id ok';

note 'Action memoryResult (memory->get_results)';

$response = api->memory->get_results(
    monitorId => $monitor_id,
    day       => '29',
    month     => '5',
    year      => '2011'
);

isa_ok $response, 'ARRAY', 'JSON response ok';

note 'Action topmemory (memory->get_top_results)';

$response = api->memory->get_top_results;

isa_ok $response, 'HASH', 'JSON response ok';
isa_ok $response->{tags}, 'ARRAY', 'tags response ok';

note 'Cleanup';

$response = api->internal_monitors->delete(testIds => $monitor_id, type => 3);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'monitor deleted';
