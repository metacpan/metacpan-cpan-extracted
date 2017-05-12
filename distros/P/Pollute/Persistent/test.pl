#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package The_Package_Where_The_Test_Runs;

use Test;
BEGIN { plan tests => 8 };
BEGIN{
	*Persistent_Test::ok = 
	*Pollute::Persistent::Test2::ok = 
	*Pollute::Persistent::Test3::ok = 
	\&ok 
};

use Persistent_Test;
ok(4);
carp "This line is printed by carp, imported via Pollute\n";
ok(5);

package Pollute::Persistent::Test2;

eval { carp( "don't know how to carp in this package") };
# print $@;
$@ =~ /^Undefined subroutine .+carp called at/ and ok(6);

package Pollute::Persistent::Test3;

use Persistent_Test;

if ($Persistent_Test::Runs == 1){
	ok(2)

}else{
	print STDERR "Persistent_Test::Runs  is $Persistent_Test::Runs \n";

};

ok(7);

carp ("This line is printed by carp, imported via Persistent_Test's import function\n");
ok(8);


