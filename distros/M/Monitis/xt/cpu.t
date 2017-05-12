use lib 't/lib';
use Test::Monitis agent => 1;

plan tests => 13;

note 'Action addCPUMonitor (cpu->add)';

my $response = api->cpu->add(
    agentkey  => agent->{key},
    idleMin   => '0',
    ioWaitMax => '100',
    kernelMax => '100',
    niceMax   => '100',
    usedMax   => '100',
    name      => 'test_cpu_monitor',
    tag       => 'test'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{testId}, qr/^\d+$/, 'API returned test id';

my $monitor_id = $response->{data}{testId};

note 'Action editCPUMonitor (cpu->edit)';

$response = api->cpu->edit(
    testId    => $monitor_id,
    kernelMax => '90',
    usedMax   => '90',
    name      => 'test_cpu',
    tag       => 'cpu'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action agentCPU (cpu->get)';

$response = api->cpu->get(agentId => agent->{id});

isa_ok $response, 'ARRAY', 'JSON response ok';
my ($exists) =
  grep { $_->{id} == $monitor_id } @$response;
ok $exists, 'monitor exists';

$monitor_id ||= $response->[0]{id};

note 'Action CPUInfo (cpu->get_info)';

$response = api->cpu->get_info(monitorId => $monitor_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{id}, $monitor_id, 'response id ok';

note 'Action cpuResult (cpu->get_results)';

$response = api->cpu->get_results(
    monitorId => $monitor_id,
    day       => (localtime)[3],
    month     => (localtime)[4] + 1,
    year      => (localtime)[5] + 1900
);

isa_ok $response, 'ARRAY', 'JSON response ok';

note 'Action topcpu (cpu->get_top_results)';

$response = api->cpu->get_top_results;

isa_ok $response, 'HASH', 'JSON response ok';

note 'Cleanup';

$response = api->internal_monitors->delete(testIds => $monitor_id, type => 7);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'monitor deleted';
