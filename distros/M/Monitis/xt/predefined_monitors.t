use lib 't/lib';
use Test::Monitis tests => 1, live => 1;

note 'Action report (internal_monitors->get_monitor_info)';

my $response = api->predefined_monitors->custom_report(
    type   => 'cpu',
    period => 'Last30Days'
);

isa_ok $response, 'ARRAY', 'JSON response ok';
