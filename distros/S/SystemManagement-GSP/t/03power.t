# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01init.t'

#########################

use lib './t';
use Test::More; 
my $Num_Tests = 3;

our $host;
require "testinfo.pm";
if (defined($host)) {
        plan tests => $Num_Tests;

        use_ok('SystemManagement::GSP'); # test
}
else {
        plan skip_all => 'No host specified in t/testinfo.pm';
}

$manage = new SystemManagement::GSP(
			host => $host,
#			debug => 1,
		);
isa_ok($manage,"SystemManagement::GSP"); # test
is($manage->is_powered_on(),1,"powered on"); # test
undef $manage;


#########################
