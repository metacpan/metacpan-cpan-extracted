# -*- perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..23\n"; }
END {print "not ok 1\n" unless $loaded;}
use Struct::Compare;
$loaded = 1;
print "ok 1\n";

my $testnum = 2;

sub assert($$) {
  my $mesg = shift;
  my $test = shift;

  print "\n$mesg\n";
  if ($test) {
    print "ok $testnum\n";
  } else {
    print "not ok $testnum\n";
  }

  $testnum++;
}

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

############################################################
# Simple Scalars

assert("Simple scalar diff must return true  when two numbers are the same",
       compare(1, 1));
assert("Simple scalar diff must return true  when two strings are the same",
       compare("1", "1"));
assert("Simple scalar diff must return false when two numbers differ",
       ! compare(1, 2));
assert("Simple scalar diff must return false when two strings differ",
       ! compare("1", "12"));
assert("Simple scalar diff must return false the LHS value is undef",
       ! compare(undef, 1));
assert("Simple scalar diff must return false the RHS value is undef",
       ! compare(1, undef));

############################################################
# Array Refs:

assert("Simple array refs must return true when they are both empty",
       compare([], []));
assert("Simple array refs must return false when they are differing sizes",
       ! compare([1, 2, 3], [1, 2]));
assert("Simple array refs must return false when they are differing order",
       ! compare([1, 2, 3], [3, 2, 1]));
assert("Simple array refs must return false when they are differing values",
       ! compare([1, 2, 3], [3, 2, 0]));
assert("Simple array refs must return true when they are the same",
       compare([1, 2, 3], [1, 2, 3]));

############################################################
# Hash Refs:

assert("Simple hash refs must return true when they are both empty",
       compare({}, {}));
assert("Simple hash refs must return false when they are differing sizes",
       ! compare({'a' => 1}, {'a' => 1, 'b' => 2}));
assert("Simple hash refs must return false when they are differing values",
       ! compare({'a' => 1, 'b' => 2}, {'a' => 1, 'b' => 3}));
assert("Simple hash refs must return true  when they are the same",
       compare({'a' => 1, 'b' => 2}, {'a' => 1, 'b' => 2}));

############################################################
# Complex(er) types:

my $a = {'a' => [ 1, 2, [ 3 ], { 'b' => 4 } ],
	 'c' => 42,
	 'd' => { 'e' => { 'f' => [] } } };

my $b = {'a' => [ 1, 2, [ 3 ], { 'b' => 4 } ],
	 'c' => 42,
	 'd' => { 'e' => { 'f' => [] } } };

my $c = {'a' => [ 1, 2, [ 3 ], { 'b' => 4 } ],
	 'c' => 42,
	 'd' => { 'e' => { 'f' => [ "this is different" ] } } };

assert("This is a quicky, I think it will work",
       compare($a, $b));
assert("This is a quicky, I think it will work",
       compare($b, $a));
assert("This is a quicky, I think it will work",
       ! compare($a, $c));
assert("This is a quicky, I think it will work",
       ! compare($c, $a));

############################################################
# Differing types:
assert("Simple scalar diff must return true if string and number are the same",
       compare(1, "1"));
assert("Empty hash and array refs must return false when they are both empty",
       ! compare({}, []));

############################################################
# TEMPLATE: copy only
assert("Array refs must return XXX when they are both empty",
       compare([], []));
