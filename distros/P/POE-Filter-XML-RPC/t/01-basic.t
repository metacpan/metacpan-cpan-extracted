use warnings;
use strict;

use Test::More tests => 79;

BEGIN
{
    use_ok('POE::Filter::XML');
    use_ok('POE::Filter::XML::RPC');
    use_ok('POE::Filter::XML::RPC::Value');
}

my $filter = POE::Filter::XML::RPC->new();

my $request = POE::Filter::XML::RPC::Request->new
(
    'MYMETHODNAME',
    [
        POE::Filter::XML::RPC::Value->new(42),
        POE::Filter::XML::RPC::Value->new(1),
        POE::Filter::XML::RPC::Value->new('ABCDEF0123456789'),
        POE::Filter::XML::RPC::Value->new(22.22),
        POE::Filter::XML::RPC::Value->new('19980717T14:08:55'),
        POE::Filter::XML::RPC::Value->new('mtfnpy'),
        POE::Filter::XML::RPC::Value->new({'key1' => 'value1', 'key2' => 'value2'}),
        POE::Filter::XML::RPC::Value->new([43, 0, 'strval'])
    ]
);

my $response_okay = POE::Filter::XML::RPC::Response->new
(
    POE::Filter::XML::RPC::Value->new('Okay!')
);

my $response_fault = POE::Filter::XML::RPC::Response->new
(
    POE::Filter::XML::RPC::Fault->new
    (
        '100',
        'MY FAULT'
    )
);

my $forced_type_val = POE::Filter::XML::RPC::Value->new(42, +STRING);
is($forced_type_val->type(), +STRING, 'Forced type value 1/2');

$forced_type_val->value('1234', +INT);
is($forced_type_val->type(), +INT, 'Forced type value 2/2');

is($request->method_name(), 'MYMETHODNAME', 'Method name');

$request->add_parameter(POE::Filter::XML::RPC::Value->new('New Parameter'));

is($request->get_parameter(9)->value(), 'New Parameter', 'Add parameter');

$request->insert_parameter(POE::Filter::XML::RPC::Value->new(2), 1);
is($request->get_parameter(1)->value(), 2, 'Insert parameter');

$request->delete_parameter(1);
$request->delete_parameter(9);

is(scalar(@{$request->parameters()}), 8, 'Delete parameters');

$filter->get_one_start(bless($request, 'POE::Filter::XML::Node'));
my $filtered_request = $filter->get_one()->[0];

is($filtered_request->toString(), $request->toString(), 'Round trip of request');
isa_ok($filtered_request, 'POE::Filter::XML::RPC::Request');

is_deeply($filtered_request->parameters(), $request->parameters(), 'parameters() method check');

is($filtered_request->get_parameter(1)->value(), $request->get_parameter(1)->value(), 'Parameter 0.1/7');
is($request->get_parameter(1)->type(), +INT, 'Parameter 0.2/7');
is($filtered_request->get_parameter(1)->type(), +INT, 'Parameter 0.3/7');
is($filtered_request->get_parameter(2)->value(), $request->get_parameter(2)->value(), 'Parameter 1.1/7');
is($request->get_parameter(2)->type(), +BOOL, 'Parameter 1.2/7');
is($filtered_request->get_parameter(2)->type(), +BOOL, 'Parameter 1.3/7');
is($filtered_request->get_parameter(3)->value(), $request->get_parameter(3)->value(), 'Parameter 2.1/7');
is($request->get_parameter(3)->type(), +BASE64, 'Parameter 2.2/7');
is($filtered_request->get_parameter(3)->type(), +BASE64, 'Parameter 2.3/7');
is($filtered_request->get_parameter(4)->value(), $request->get_parameter(4)->value(), 'Parameter 3.1/7');
is($request->get_parameter(4)->type(), +DOUBLE, 'Parameter 3.2/7');
is($filtered_request->get_parameter(4)->type(), +DOUBLE, 'Parameter 3.3/7');
is($filtered_request->get_parameter(5)->value(), $request->get_parameter(5)->value(), 'Parameter 4.1/7');
is($request->get_parameter(5)->type(), +DATETIME, 'Parameter 4.2/7');
is($filtered_request->get_parameter(5)->type(), +DATETIME, 'Parameter 4.3/7');
is($filtered_request->get_parameter(6)->value(), $request->get_parameter(6)->value(), 'Parameter 5.1/7');
is($request->get_parameter(6)->type(), +STRING, 'Parameter 5.2/7');
is($filtered_request->get_parameter(6)->type(), +STRING, 'Parameter 5.3/7');

is_deeply($filtered_request->get_parameter(7)->value(), $request->get_parameter(7)->value(), 'Parameter 6.1/7');
is($request->get_parameter(7)->type(), +STRUCT, 'Parameter 6.2/7');
is($filtered_request->get_parameter(7)->type(), +STRUCT, 'Parameter 6.3/7');
is_deeply($filtered_request->get_parameter(8)->value(), $request->get_parameter(8)->value(), 'Parameter 7.1/7');
is($request->get_parameter(8)->type(), +ARRAY, 'Parameter 7.2/7');
is($filtered_request->get_parameter(8)->type(), +ARRAY, 'Parameter 7.3/7');

$filter->get_one_start(bless($response_okay, 'POE::Filter::XML::Node'));
my $fil_response_okay = $filter->get_one()->[0];
isa_ok($fil_response_okay, 'POE::Filter::XML::RPC::Response');

is($fil_response_okay->toString(), $response_okay->toString(), 'Round trip of response');
is_deeply($fil_response_okay->return_value()->value(), $response_okay->return_value()->value(), 'Return value');

$filter->get_one_start(bless($response_fault, 'POE::Filter::XML::Node'));
my $fil_response_fault = $filter->get_one()->[0];
isa_ok($fil_response_fault, 'POE::Filter::XML::RPC::Response');

is($fil_response_fault->toString(), $response_fault->toString(), 'Round trip of response fault');
is($fil_response_fault->fault()->code(), $response_fault->fault()->code(), 'Fault code');
is($fil_response_fault->fault()->string(), $response_fault->fault()->string(), 'Fault code');

# Fault 101
my $method_call_fail0 = POE::Filter::XML::Node->new('foo');
$filter->get_one_start($method_call_fail0);
my $method_call_fail0_filtered = $filter->get_one()->[0];

isa_ok($method_call_fail0_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_call_fail0_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_call_fail0_filtered->fault()->code, '101', 'Fault 101');

# Fault 102
my $method_call_fail1 = POE::Filter::XML::Node->new('methodCall');
$method_call_fail1->appendChild('methodName');

$filter->get_one_start($method_call_fail1);
my $method_call_fail1_filtered = $filter->get_one()->[0];

isa_ok($method_call_fail1_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_call_fail1_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_call_fail1_filtered->fault()->code, '102', 'Fault 102');


# Fault 103
my $method_call_fail2 = POE::Filter::XML::Node->new('methodCall');

$filter->get_one_start($method_call_fail2);
my $method_call_fail2_filtered = $filter->get_one()->[0];

isa_ok($method_call_fail2_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_call_fail2_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_call_fail2_filtered->fault()->code, '103', 'Fault 103');

# Fault 104
my $method_response_fail1 = POE::Filter::XML::Node->new('methodResponse');

$filter->get_one_start($method_response_fail1);
my $method_response_fail1_filtered = $filter->get_one()->[0];

isa_ok($method_response_fail1_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_response_fail1_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_response_fail1_filtered->fault()->code, '104', 'Fault 104');

# Fault 105
my $method_response_fail2 = POE::Filter::XML::Node->new('methodResponse');
$method_response_fail2->appendChild('params');

$filter->get_one_start($method_response_fail2);
my $method_response_fail2_filtered = $filter->get_one()->[0];

isa_ok($method_response_fail2_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_response_fail2_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_response_fail2_filtered->fault()->code, '105', 'Fault 105');

# Fault 106
my $method_response_fail3 = POE::Filter::XML::Node->new('methodResponse');
$method_response_fail3->appendChild('fault');

$filter->get_one_start($method_response_fail3);
my $method_response_fail3_filtered = $filter->get_one()->[0];

isa_ok($method_response_fail3_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_response_fail3_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_response_fail3_filtered->fault()->code, '106', 'Fault 106');

# Fault 106
my $method_response_fail4 = POE::Filter::XML::Node->new('methodResponse');
$method_response_fail4->appendChild('fault')->appendChild('value');

$filter->get_one_start($method_response_fail4);
my $method_response_fail4_filtered = $filter->get_one()->[0];

isa_ok($method_response_fail4_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_response_fail4_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_response_fail4_filtered->fault()->code, '106', 'Fault 106');

# Fault 107
my $method_response_fail5 = POE::Filter::XML::Node->new('methodResponse');
my $member5 = $method_response_fail5->appendChild('fault')->appendChild('value')->appendChild('struct')->appendChild('member');
$member5->appendChild('name')->appendText('faultCode');
$member5->appendChild('value')->appendChild('int')->appendText('999');

$filter->get_one_start($method_response_fail5);
my $method_response_fail5_filtered = $filter->get_one()->[0];

isa_ok($method_response_fail5_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_response_fail5_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_response_fail5_filtered->fault()->code, '107', 'Fault 107');

# Fault 107
my $method_response_fail6 = POE::Filter::XML::Node->new('methodResponse');
my $member6 = $method_response_fail6->appendChild('fault')->appendChild('value')->appendChild('struct')->appendChild('member');
$member6->appendChild('name')->appendText('faultString');
$member6->appendChild('value')->appendChild('string')->appendText('NO CODE');

$filter->get_one_start($method_response_fail6);
my $method_response_fail6_filtered = $filter->get_one()->[0];

isa_ok($method_response_fail6_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_response_fail6_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_response_fail6_filtered->fault()->code, '107', 'Fault 107');

# Fault 108
my $method_response_fail7 = POE::Filter::XML::Node->new('methodResponse');
my $params7 = $method_response_fail7->appendChild('params');
$params7->appendChild('param');
$params7->appendChild('foo');

$filter->get_one_start($method_response_fail7);
my $method_response_fail7_filtered = $filter->get_one()->[0];

isa_ok($method_response_fail7_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_response_fail7_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_response_fail7_filtered->fault()->code, '108', 'Fault 108');

# Fault 109
my $method_response_fail8 = POE::Filter::XML::Node->new('methodResponse');
$method_response_fail8->appendChild('params')->appendChild('param');

$filter->get_one_start($method_response_fail8);
my $method_response_fail8_filtered = $filter->get_one()->[0];

isa_ok($method_response_fail8_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_response_fail8_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_response_fail8_filtered->fault()->code, '109', 'Fault 109');

# Fault 110
my $method_call_fail9 = POE::Filter::XML::Node->new('methodCall');
$method_call_fail9->appendChild('methodName')->appendText('MyMethod');
$method_call_fail9->appendChild('params')->appendChild('param');

$filter->get_one_start($method_call_fail9);
my $method_call_fail9_filtered = $filter->get_one()->[0];

isa_ok($method_call_fail9_filtered, 'POE::Filter::XML::RPC::Response');
isa_ok($method_call_fail9_filtered->fault(), 'POE::Filter::XML::RPC::Fault');
is($method_call_fail9_filtered->fault()->code, '110', 'Fault 110');

