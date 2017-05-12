# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01init.t'

#########################

use lib './t';
use Test::More;
my $Num_Tests = 7;

our $host;
require "testinfo.pm";
if (defined($host)) {
	plan tests => $Num_Tests;

	use_ok('SystemManagement::GSP'); # test
}
else {
	plan skip_all => 'No host specified in t/testinfo.pm';
}

my $manage = new SystemManagement::GSP(
			host => $host,
			user => 'bad user',
#			debug => 1,
		);
isa_ok($manage,"SystemManagement::GSP"); # test
is($manage->establish_session(),undef,"fail authentication"); # test
is($manage->errmsg,"Bad 'user' or 'password'","error code"); # test
undef $manage;

$manage = new SystemManagement::GSP(
			host => $host,
#			debug => 1,
		);
isa_ok($manage,"SystemManagement::GSP"); # test
is($manage->establish_session(),1,"authenticated"); # test
is($manage->errmsg,"Logged in","happy error code"); # test
undef $manage;


#########################
