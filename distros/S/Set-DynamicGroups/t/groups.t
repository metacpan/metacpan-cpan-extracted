# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Set::DynamicGroups';
eval "require $mod" or die $@;

my $set = new_ok($mod);

$set->add(g1 => 'm1');
is_deeply($set->groups, {g1 => [qw(m1   )]}, 'group added string');

$set->add(g1 => ['m2']);
is_deeply($set->groups, {g1 => [qw(m1 m2)]}, 'group added array');

$set->set(g1 => [qw(m2 m3)]);
is_deeply($set->groups, {g1 => [qw(m2 m3)]}, 'group reset');

$set->add(g2 => {items => [qw(m5 m6)]});
is_deeply($set->groups, {g1 => [qw(m2 m3)], g2 => [qw(m5 m6)]}, 'add group');

$set->add(g2 => {items => [qw(m5)]});
is_deeply($set->groups, {g1 => [qw(m2 m3)], g2 => [qw(m5 m6)]}, 'ignore unique item');

$set->set(g1 => 'm2');
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)]}, 'group reset');

$set->set(g1 => [qw(m2)]);
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)]}, 'group reset');

$set->add(g1 => 'm2');
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)]}, 'ignore unique item');

$set->add(g2 => [qw(m5 m6)]);
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)]}, 'ignore unique items');

$set->set(g3 => {in => [qw(g1 g2)]});
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m2 m5 m6)]}, 'include from group');

$set->set(g3 => {not_in => [qw(g1)]});
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m5 m6)]}, 'exclude from group');

is_deeply($set->groups(qw(g2 g3)), {g2 => [qw(m5 m6)], g3 => [qw(m5 m6)]}, 'limit groups() by names');
is_deeply($set->groups(qw(g2)), {g2 => [qw(m5 m6)]}, 'limit groups() by names');
is_deeply($set->groups(qw(g1 g2 g3)), $set->groups, 'limit groups() by names');
is_deeply($set->groups('g2')->{g2}, [$set->group('g2')], 'group() matches groups()');
is_deeply([$set->group('g2')], [qw(m5 m6)], 'group() returns expected list');

is(eval { $set->group('idunno'); 1 }, undef, 'unknown group() dies');
like($@, qr/Group .+ is not defined/, 'unknown group() died with expected message');

is_deeply([sort $set->items], [qw(m2 m5 m6)],       'all items');
$set->add_items(qw(m6 m7));
is_deeply([sort $set->items], [qw(m2 m5 m6 m7)],    'all items (no duplicates)');
$set->add_items(qw(m6 m7 m8));
is_deeply([sort $set->items], [qw(m2 m5 m6 m7 m8)], 'all items (no duplicates)');

$set->set(g3 => {in => [qw(g1 g2)]});
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m2 m5 m6)]}, 'include from group');

$set->set(g3 => {not_in => [qw(g1)]});
# m5 is last b/c items come first (see add_items above)
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m6 m7 m8 m5)]}, 'exclude from group');

$set->set_items(qw(m7));
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m7 m5 m6)]}, 'reset items and exclude from group');

$set->set_items(qw(m6));
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m6 m5)]}, 'reset items and exclude from group');

# reference a group that doesn't exist
$set->set(g3 => {not_in => [qw(g1 g0)]});
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m6 m5)]}, 'exclude from group (ignore non-existent)');

$set->set(g4 => {in => [qw(g0)]});
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m6 m5)], g4 => []}, 'include from group (ignore non-existent)');

$set->set(g4 => {not_in => [qw(g0)]});
# I can't guarantee the order here, so sort it
is_deeply([sort @{$set->groups->{g4}}], [qw(m2 m5 m6)], 'include from group (ignore non-existent)');

# TODO: include 1 but exclude the rest of a group
# b => [qw(hi there)], a => {not_in => 'b', include => 'hi'}

# TODO: test the minimum require to define that a group includes 'all'
# c => {} OR c => {exclude => []}

# TODO: use one group to get all and the other group to get all minus group plus specific
# d => {not_in => 'f', in => 'e', include => 'boo'}, e => {not => ''}, f => [qw(did ley)]

done_testing;
