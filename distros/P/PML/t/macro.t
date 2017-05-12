#!perl
###### Test PML macro function

use strict;
use Test;

BEGIN{plan test => 3};

use PML;

my $parser = new PML;

my @code = <DATA>;

$parser->parse(\@code);
ok(1);

my $tmp = $parser->execute;
ok(1);

# now check for 1 2
if ($tmp =~ /1/ and $tmp =~ /2/)
{
	ok(1);
}
else
{
	ok(0);
}

__END__
# this is test PML CODE

#
# first check a predeclared macro
#
@macro("TEST_MACRO", "test_variable")
{
	${test_variable}
}

@TEST_MACRO(1)
#
# now call a macro before it is defined
#
@TEST_MACRO2(2)

@macro("TEST_MACRO2", "another_test_variable")
{
	${another_test_variable}
}
