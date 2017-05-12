use lib 't/lib';
use Test::Monitis tests => 8, agent => 1;

note 'Add process monitor for testing purposes';

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

note 'Action internalMonitors (internal_monitors->get_monitor_info)';

$response = api->internal_monitors->get_all;

isa_ok $response, 'HASH', 'JSON response ok';
isa_ok $response->{processes}, 'ARRAY', 'pingTests response ok';

my ($exists) = grep { $_->{id} == $monitor_id } @{$response->{processes}};

ok $exists, 'process monitor in list';

SKIP: {
    skip "Monitor ID required for this test", 2 unless $monitor_id;
    note 'Action deleteInternalMonitors (internal_monitors->delete)';

    $response = api->internal_monitors->delete(
        testIds => $monitor_id,
        type    => 1
    );

    isa_ok $response, 'HASH', 'JSON response ok';
    is $response->{status}, 'ok', 'status ok';

}
