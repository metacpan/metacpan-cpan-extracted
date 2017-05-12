
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('File::MultiCat') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

BEGIN {
my $ob = File::MultiCat->new();
ok(defined multicat);
ok($ob->multicat('xot'));
}

# EXAMPLE FILES:
# After running this, your working directory should have a
#   "1.html", "2.html", and "3.html"
#   built from the example files (top, bottom, 1.txt, 2.txt, and 3.txt).
#   using 'xot' for direction of how to build them.
#   (And, 'xot' would default to 'multicat.dat' if not called by name.)
#   A careful look at these files will help you to understand how
#   the module works.


