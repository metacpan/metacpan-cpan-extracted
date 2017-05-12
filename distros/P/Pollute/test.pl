#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 6 };
BEGIN{
	*Pollute::Test::ok = 
	*Pollute::Test2::ok = 
	\&ok 
	};
#use Pollute;
#ok(1); # If we made it this far, we're ok.
use Pollute_Test;
ok(4);
carp "This line is printed by carp, imported via Pollute\n";
ok(5);


package Pollute::Test2;

eval { carp( "don't know how to carp in this package") };

$@ =~ /^Undefined subroutine \&Pollute::Test2::carp called at/ and ok(6);

