use lib 't/lib';
use Test::Monitis tests => 12, agent => 1;

note 'Action addProcessMonitor (process->add)';

my $response = api->process->add(
    agentkey           => agent->{key},
    cpuLimit           => '30',
    memoryLimit        => '40',
    virtualMemoryLimit => '50',
    name               => 'testname',
    processName        => 'crond',
    tag                => 'test'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{testId}, qr/^\d+$/, 'API returned test id';

my $monitor_id = $response->{data}{testId};

note 'Action editProcessMonitor (process->edit)';

$response = api->process->edit(
    testId             => $monitor_id,
    cpuLimit           => '50',
    memoryLimit        => '100',
    virtualMemoryLimit => '200',
    name               => 'testname',
    tag                => 'test_from_api'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action agentProcesses (process->get)';

$response = api->process->get(agentId => agent->{id});

isa_ok $response, 'ARRAY', 'JSON response ok';

my ($exists) =
  grep { $_->{id} == $monitor_id } @$response;
ok $exists, 'monitor exists';

$monitor_id ||= $response->[0]{id};

note 'Action ProcessInfo (process->get_info)';

$response = api->process->get_info(monitorId => "$monitor_id");

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{id}, $monitor_id, 'response id ok';

note 'Action processResult (process->get_results)';

$response = api->process->get_results(
    monitorId => $monitor_id,
    day       => (localtime)[3],
    month     => (localtime)[4] + 1,
    year      => (localtime)[5] + 1900
);

isa_ok $response, 'ARRAY', 'JSON response ok';

note 'Cleanup';

$response = api->internal_monitors->delete(testIds => $monitor_id, type => 1);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'monitor deleted';
