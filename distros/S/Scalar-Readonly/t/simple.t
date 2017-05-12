# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Scalar-Readonly.t'

#########################


use Test::More;
use Scalar::Readonly ':all';
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $foo;

eval { $foo = "foo"; };
ok(!$@, "assigning to read/write scalar");

ok(!readonly($foo), "readonly() should return false");

readonly_on($foo);

eval {
	$foo = "bar";
};

ok($@, "shouldn't be able to change variable");

ok(readonly($foo), "readonly() should return true");

readonly_off($foo);

ok(!readonly($foo), "readonly() should return false again");
eval { $foo = 'xyzzy'; };
ok(!$@, "assigning to scalar should succeed again");

done_testing();
