# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Autoconfig.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 139;
BEGIN { use_ok('Net::Autoconfig::Device') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#
#

my $device;

ok(Net::Autoconfig::Device->new(), "Testing for empty Device object creation"); 

$device = Net::Autoconfig::Device->new("ip_addr" => "192.168.0.1");

# Testing get behavior
is($device->get("ip_addr"), "192.168.0.1", "Testing get with specified parameter");
is(ref($device->get()), "HASH", "Testing get with undef parameter");
is($device->get("asdf"), undef, "Testing get with non-existant parameter");

# Testing set behavior
ok( ! $device->set("asdf", "fdsa"), "Testing single attribute assignment.");
is($device->get("asdf"), "fdsa", "Testing single attribute assignment");

my %parameters = ( asdf => "fdsa", abc => "def", fu => "bar" );
ok( ! $device->set(%parameters), "Testing multi attribute assignment.");
is_deeply(scalar($device->get(qw(asdf abc fu))), \%parameters, "Testing multi attribute assignment using the get method");

# Testing using a hash instead of an array...should work...
my $hash_data = { hash_key1	=> 'data1',	hash_key2 => "data2" };
ok( ! $device->set(%$hash_data), "Testing multi attribute assignment.");
is($device->get('hash_key1'), "data1", "Testing multi attribute assignment using the get method");
is($device->get('hash_key2'), "data2", "Testing multi attribute assignment using the get method");


####################
# Accessor/Mutator Methods
####################
$device = Net::Autoconfig::Device->new();

my @methods = qw(
	model
	vendor
	hostname
	username
	password
	provision
	admin_status
	console_username
	console_password
	enable_password
	snmp_community
	snmp_version
	session
    paging_disabled
);

can_ok( 'Net::Autoconfig::Device',
        'invalid_cmd_regex',
        'paging_disabled',
        'replace_command_variables',
        '_eval',
        @methods,
        );

foreach my $method (@methods)
{
	if ($method =~ /snmp_version/)
    {
		is($device->$method(""), undef, "Setting snmp_version to ''");
	}

    if ($method =~ /model/)
    {
        ok( ! $device->$method(), "'$method' - 1 - should have returned a FALSE value.");
        is(ref($device->$method("test")), ref([]), "'$method' - 2 - should have returned an array ref");
        is($device->$method(), "test", "'$method' - 3 - should have returned 'test' value.");
        is($device->$method(undef), "test", "'$method' - 4 - should have returned 'test'.");
        is(ref($device->$method("")), ref([]), "'$method' - 5 - should have returned an array ref.");
        ok( ! $device->$method(), "'$method' - 6 - should have returned a FALSE value.");
        next;
    }

	ok( ! $device->$method(), "'$method' - 1 - should have returned a FALSE value.");
	is($device->$method("test"), undef, "'$method' - 2 - should have returned undef");
	is($device->$method(), "test", "'$method' - 3 - should have returned 'test' value.");
	is($device->$method(undef), "test", "'$method' - 4 - should have returned 'test'.");
	is($device->$method(""), undef, "'$method' - 5 - should have returned undef.");
	ok( ! $device->$method(), "'$method' - 6 - should have returned a FALSE value.");
}


# Handle special mutator/accessor data
$device = Net::Autoconfig::Device->new();

# Access method testing
# Defaults
is($device->access_method, "ssh", "Testing for default access_method assignment.");
# Telnet
is($device->access_method("telnet"), undef, "Testing for snmp_medthod assignment to telnet");
is($device->access_method, "telnet", "Testing for access_method = telnet.");
# ssh
is($device->access_method("ssh"), undef, "Testing for snmp_medthod assignment to ssh");
is($device->access_method, "ssh", "Testing for access_method = ssh.");
# user defined
is($device->access_method("asdf"), undef, "Testing for snmp_medthod assignment to 'asdf'");
is($device->access_method, "user_defined", "Testing for access_method = user_defined.");

# Access cmd testing
# Defaults
is($device->access_cmd, "/usr/bin/ssh", "Testing for default access_cmd assignment.");
# Telnet
is($device->access_cmd("/usr/bin/telnet"), undef, "Testing for snmp_medthod assignment to telnet");
is($device->access_method, "telnet", "Testing for access_method = telnet.");
is($device->access_cmd, "/usr/bin/telnet", "Testing for access_cmd = telnet.");
# ssh
is($device->access_cmd("/usr/binssh"), undef, "Testing for snmp_medthod assignment to ssh");
is($device->access_cmd, "/usr/binssh", "Testing for access_cmd = ssh.");
is($device->access_method, "ssh", "Testing for access_method = ssh.");
# user defined
is($device->access_cmd("/usr/local/rsh"), undef, "Testing for snmp_medthod assignment to 'asdf'");
is($device->access_cmd, "/usr/local/rsh", "Testing for access_cmd = user_defined.");
is($device->access_method, "user_defined", "Testing for access_method = user_defined.");

####################
# host_not_reachable private method
####################
is(Net::Autoconfig::Device::_host_not_reachable(), 1, "An empty host should not be reachable.");
is(Net::Autoconfig::Device::_host_not_reachable("asdfasdf"), 1, "A bogus host should not be reachable.");
is(Net::Autoconfig::Device::_host_not_reachable("127.0.0.1"), 0, "Localhost should be reachable.");

####################
# connect method
####################
$device = Net::Autoconfig::Device->new();
ok($device->connect(), "Connecting to this device should fail.");
ok($device->console_connect(), "Console connecting to this device should fail.");

$device->hostname("bogus");
ok($device->connect(), "Connecting to this device should fail.");
ok($device->console_connect(), "Console connecting to this device should fail.");

$device->hostname('tty@some_console');
ok($device->console_connect(), "Console connecting to this device should fail.");

$device->username("username");
$device->console_username("console_username");
ok($device->connect(), "Connecting to this device should fail.");
ok($device->console_connect(), "Console connecting to this device should fail.");

$device->hostname("bogus");
ok($device->connect(), "Connecting to this device should fail.");
ok($device->console_connect(), "Console connecting to this device should fail.");

$device->hostname('tty@some_console');
ok($device->console_connect(), "Console connecting to this device should fail.");


####################
# configure method
####################

my $template = {};
ok($device->configure(), "Should fail - no template defined");
ok($device->configure($template), "Should fail - no valid session");

####################
# invalid cmd regex
####################

is($device->invalid_cmd_regex, '[iI]nvalid input', "Default invalid cmd regex");
is($device->invalid_cmd_regex('hello'), undef, "Setting invalid cmd regex");
is($device->invalid_cmd_regex(), 'hello', "Getting user defined invalid cmd regex");

####################
# replace command variables
####################

my $cmd = {};

ok( $device->replace_command_variables, "No command passed, should return an error message");
is( $device->replace_command_variables( $cmd ), undef, "No command in hash ref, should return undef");

$cmd->{cmd} = "test";
is( $device->replace_command_variables( $cmd ), undef, "Command passed, should return undef");

$cmd->{cmd} = '$test $test';
is( $device->replace_command_variables( $cmd ), undef, "Invalid, but not required  variables passed, should return undef");

$cmd->{required} = 1;
ok( $device->replace_command_variables( $cmd ), "Invalid variables passed, this should return an error message");

####################
# private _eval function
####################

my $eval_string = '[ "a", "b", "c"]';

is_deeply( Net::Autoconfig::Device::_eval($eval_string, undef), [ "a", "b", "c"], "Error in private _eval function.  Did not return the correct result.");
