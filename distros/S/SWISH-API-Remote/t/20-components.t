# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 20-components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::Simple tests => 4;

BEGIN { 
	use SWISH::API::Remote; 
	use SWISH::API::Remote::Results; 
	use SWISH::API::Remote::Result; 
};
my $remote;
my ($results, $props);
my $res;
ok( $remote = new SWISH::API::Remote("http://nosuchserverllk.com/perltest/swished", "index1"));

my $res2;
ok ( $res2 = SWISH::API::Remote::Result::New_From_Query_String("0=that&1=b&2=bob&99=hello&1000=Q", [ qw(this that) ]) );
ok( $res2->Property("this") eq "that" );
ok( $res2->Property("that") eq "b" );


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

