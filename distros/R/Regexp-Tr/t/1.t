# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Regexp::Tr') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $trier = Regexp::Tr->new("a-z","za-y");
ok(defined $trier, "New method returned an object");
ok($trier->isa("Regexp::Tr"), "New object is correct class");

my $control = my $swapped = "foobar";
$trier->bind(\$swapped);               # $swapped is now "gppcbs"
$control =~ tr/a-z/za-y/;
is($swapped,$control,"Binding method works");

$control = $swapped = "barfoo";
my $tred = $trier->trans($swapped);    # $tred is "cbsgpp"
$control =~ tr/a-z/za-y/;
is($tred,$control,"Trans method works");

