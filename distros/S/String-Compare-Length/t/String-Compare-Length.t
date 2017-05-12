# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl String-Compare-Length.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('String::Compare::Length') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @test1 = ("one");
my %test3 = ('a'=>\@test1);

ok(!compare_array("one", @test1));
ok(@test1 == compare_array("on", @test1));
ok(!compare_arrays(@test1, @test1));
ok(ref compare_hoa("one", %test3) eq 'HASH');
ok(compare_hoa("one", %test3)->{'a'} == 0);
