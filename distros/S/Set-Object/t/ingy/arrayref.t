#  -*- perl -*-

use Set::Object qw(set);
use Test::More tests => 15;

my $bob = bless {}, "Bob";
my $bert = bless {}, "Bert";

my $set = set(0, 1, 2, 3, $bob);

isa_ok($set, "Set::Object", "set()");

is(@$set, 5, "scalar list context");
push @$set, 13;
ok($set->includes(13), "tied array PUSH");
unshift @$set, 17;
ok($set->includes(17), "tied array UNSHIFT");

is(@$set, 7, "size right");
is(shift(@$set), 0, "shift off in right order");
is(pop(@$set), $bob, "pop off in right order");
is(@$set, 5, "size still right");
$#$set = 1;
is($set->size, 2, "array STORESIZE");
$set->[0] = 17;
ok($set->includes(17), "array STORE");
is($set->size, 2, "array STORE doesn't increase size");
ok(!exists $set->[2], "array EXISTS");
is($set->size, 2, "array EXISTS didn't increase size");
delete($set->[1]);
is($set->size, 1, "array DELETE");

$set = set( 1..9 );
splice @$set, 0, 2;
is_deeply([@$set], [3..9], "splice (and list context)");


