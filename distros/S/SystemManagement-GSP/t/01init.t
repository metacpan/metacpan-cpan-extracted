# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01init.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('SystemManagement::GSP') }; # test

my $manage;
$manage = new SystemManagement::GSP(debug=>1);
is($manage,undef,"requires host"); # test

$manage = new SystemManagement::GSP(
		host => "127.0.0.1",
	);
isa_ok($manage,"SystemManagement::GSP"); # test

can_ok($manage,qw(
	new
	establish_session
	is_powered_on
	power_on
	power_off
	power_cycle
	errmsg
	DESTROY
)); # test

undef $manage;

#########################
