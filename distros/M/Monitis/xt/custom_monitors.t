use lib 't/lib';
use Test::Monitis tests => 17, live => 1;

note 'Action addMonitor (custom_monitors->add)';

my $response = api->custom_monitors->add(
    resultParams => 'position:Position:N/A:2;difference:Difference:N/A:3;',
    name         => 'simple_custom_monitor',
    tag          => 'test'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok',      'status ok';
like $response->{data}, qr/^\d+$/, 'data ok';

my $id = $response->{data};

note 'Action getMonitor (custom_monitors->get)';
$response = api->custom_monitors->get;

isa_ok $response, 'ARRAY', 'JSON response ok';
ok @$response > 0, 'Monitor added';
my ($monitor) = grep { $_->{id} == $id } @$response;
isa_ok $monitor, 'HASH', 'monitor found';

unless ($monitor) { $id = $response->[0]->{id}; }


note 'Action editMonitor (custom_monitors->edit)';
$response = api->custom_monitors->edit(
    monitorId => $id,
    name      => 'test from api',
    tag       => 'test'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'Monitor added';

note 'Action getMonitorInfo (custom_monitors->get_info)';
$response = api->custom_monitors->get_info(monitorId => $id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{id}, $id, 'Right ID';
is $response->{name}, 'test from api';

note 'Action addResult (custom_monitors->add_results)';
$response = api->custom_monitors->add_results(
    monitorId => $id,
    checktime => time,
    results   => 'position:3;difference:1'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action getMonitorResults (custom_monitors->get_results)';
$response = api->custom_monitors->get_results(
    monitorId => $id,
    day       => (localtime)[3],
    month     => (localtime)[4] + 1,
    year      => (localtime)[5] + 1900
);

isa_ok $response, 'ARRAY', 'JSON response ok';
is $response->[0]{position}, '3', 'status ok';

note 'Action deleteMonitor (custom_monitors->delete)';
$response = api->custom_monitors->delete(monitorId => $id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
