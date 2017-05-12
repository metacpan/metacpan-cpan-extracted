# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Statistics-Suggest.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
BEGIN { use_ok('Statistics::Suggest') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(my $s = new Statistics::Suggest);

ok($s->load_trans([
 [1, 1], [1, 2], [1, 3], [1, 4],
 [2, 1], [2, 2], [2, 3], [2, 4],
 [3, 1], [3, 2], [3, 3], [3, 4],
 [4, 3], [4, 5], [4, 8],
 [5, 3], [5, 5], [5, 8]
]));
is($s->{nusers}, 5);
is($s->{nitems}, 8);
is(scalar @{$s->{userid}}, 18);
is(scalar @{$s->{itemid}}, 18);

ok($s->init);

my $rcmds;
ok($s->top_n([1, 2], 2, \$rcmds));
is(scalar @$rcmds, 2);
ok(($$rcmds[0] == 3 and $$rcmds[1] == 4)
   or ($$rcmds[0] == 4 and $$rcmds[1] == 3));

