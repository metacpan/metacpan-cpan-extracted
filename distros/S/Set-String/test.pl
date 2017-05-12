# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 7 };
use Set::String;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $s1 = Set::String->new("Hello\n\n");
my $s2 = Set::String->new("Again\n\n");
my $s3 = Set::String->new("World!!!");
my $s4 = Set::String->new("2+2");
my $s5 = Set::String->new("fee fie foe foo");

ok($s1->length == 7);
ok($s1->chop(3)->length == 4);
ok($s2->chomp->length == 6);
ok($s3->defined == 1);
ok($s4->eval == 4);
ok($s1->lc eq 'hell');
ok($s1->uc eq 'HELL');
