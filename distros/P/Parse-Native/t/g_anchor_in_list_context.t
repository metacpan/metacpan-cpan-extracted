# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Parse-Native.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# this doesn't test anything in Parse::Native,
# it tests that user has a recent enough version
# of perl installed that they can use \G anchor
# in list context and have \G anchor advance.

my $string = 'alpha bravo charlie alpha bravo charlie';

$string =~ m{charlie}gc;

my $pos;

$pos = pos($string);

is($pos, 19, "assign pos to initial position");

my @matches = $string =~ m{\G (alpha)}gc;

$pos = pos($string);

is($pos, 25, "Installed version of perl advances \\G anchor position during list context");



