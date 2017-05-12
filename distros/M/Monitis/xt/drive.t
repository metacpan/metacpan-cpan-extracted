use lib 't/lib';
use Test::Monitis tests => 13, agent => 1;

note 'Action addDriveMonitor (drive->add)';

my $response = api->drive->add(
    agentkey    => agent->{key},
    driveLetter => 'C',
    freeLimit   => '10',
    name        => 'testdrive',
    tag         => 'test'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{testId}, qr/^\d+$/, 'API returned test id';

my $monitor_id = $response->{data}{testId};

note 'Action editDriveMonitor (drive->edit)';

$response = api->drive->edit(
    testId    => $monitor_id,
    freeLimit => '9',
    name      => 'testdrive',
    tag       => 'test'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action agentDrive (drive->get)';

$response = api->drive->get(agentId => agent->{id});

isa_ok $response, 'ARRAY', 'JSON response ok';

my ($exists) =
  grep { $_->{id} == $monitor_id } @$response;
ok $exists, 'monitor ' . $monitor_id . ' exists';

$monitor_id ||= $response->[0]{id};

note 'Action DriveInfo (drive->get_info)';

$response = api->drive->get_info(monitorId => $monitor_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{id}, $monitor_id, 'response id ok';

note 'Action driveResult (drive->get_results)';

$response = api->drive->get_results(
    monitorId => $monitor_id,
    day       => (localtime)[3],
    month     => (localtime)[4] + 1,
    year      => (localtime)[5] + 1900
);

isa_ok $response, 'ARRAY', 'JSON response ok';

note 'Action topdrive (drive->get_top_results)';

$response = api->drive->get_top_results;

isa_ok $response, 'HASH', 'JSON response ok';

note 'Cleanup';

$response = api->internal_monitors->delete(testIds => $monitor_id, type => 2);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'monitor deleted';
