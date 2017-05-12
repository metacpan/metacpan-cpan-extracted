# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Autoconfig.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 29;
BEGIN { use_ok('Net::Autoconfig::Device::Cisco', 'Net::Autoconfig::Device') };

# XXX
use Data::Dumper;

#########################
# Test all of methods
my @methods = qw(new connect discover_dev_type get_admin_rights disable_paging);
foreach my $method (@methods) {
	can_ok("Net::Autoconfig::Device::Cisco", $method);
}

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#
#

my $device;
my $device2;
my %parameters;  # parameters to pass when creating a new device
my $message;     # messages returned from some functions.

ok(Net::Autoconfig::Device::Cisco->new(), "Testing for empty Device object creation"); 

$device = Net::Autoconfig::Device::Cisco->new("ip_addr" => "192.168.0.1");

# Testing get behavior
is($device->get("ip_addr"), "192.168.0.1", "Testing get with specified parameter");
is(ref($device->get()), "HASH", "Testing get with undef parameter");
is($device->get("asdf"), undef, "Testing get with non-existant parameter");

# Testing set behavior
ok( ! $device->set("asdf", "fdsa"), "Testing single attribute assignment.");
is($device->get("asdf"), "fdsa", "Testing single attribute assignment");

%parameters = ( asdf => "fdsa", abc => "def", fu => "bar" );
ok( ! $device->set(%parameters), "Testing multi attribute assignment.");
is_deeply(scalar($device->get(qw(asdf abc fu))), \%parameters, "Testing multi attribe assignment using the get method");

# Testing using a hash instead of an array...should work...
my $hash_data = { hash_key1	=> 'data1',	hash_key2 => "data2" };
ok( ! $device->set(%$hash_data), "Testing multi attribute assignment.");
is($device->get('hash_key1'), "data1", "Testing multi attribe assignment using the get method");
is($device->get('hash_key2'), "data2", "Testing multi attribe assignment using the get method");

# Failure = error message
ok( $device->connect(), "Testing failed connection - The method should have failed");

# For some reason, connecting on a live device causes test::more to freak out and fail the next
# test.  Even if the next test is ok(1, "always pass").  So...that's a little weird.
# Maybe expect does something funny with STDIN,STDOUT, etc.



ok( $device->discover_dev_type, "Discovering device type from configuration.");
ok( $device->get_admin_rights, "Get admin rights, a true value indicates failure.");
$device->session("bogus");
ok( ! $device->admin_status(1), "Setting admin rights status.");
ok( $device->admin_status, "Getting admin rights status (should be true).");
ok( ! $device->get_admin_rights, "Get admin rights, should succeed based off already having rights");
$device->admin_status(undef);
ok( ! $device->get_admin_rights, "Get admin rights, should succeed because setting status to undef shouldn't change the value.");
$device->admin_status(0);
ok( ! $device->admin_status, "Getting admin rights status (should be false).");

$device->session("");
ok( $device->disable_paging, "Disabling paging, should return true based on no session defined.");
$device->session("bogus");
ok( $device->disable_paging, "Disabling paging, should return true based on command timeout.");

####################
# configure
####################
my $template = {};
ok($device->configure(), "Should fail - no template");
ok($device->configure($template), "Should fail - no session");
