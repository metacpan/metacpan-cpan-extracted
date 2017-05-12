# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Set::DynamicGroups';
eval "require $mod" or die $@;

my $set = new_ok($mod);

$set->set(a => {in => 'b'});
$set->set(b => {in => 'a'});
is_deeply($set->groups, {a => [], b => []}, 'groups solely dependent on each other are empty');

my $desc = 'dependent group includes items of other';

$set->set(a => {in => 'b'});
$set->set(b => {in => 'a', include => 'badger'});
is_deeply($set->groups, {a => ['badger'], b => ['badger']}, $desc);

$set->set(a => {in => 'b'});
$set->set(b => {in => 'c'});
$set->set(c => {in => [qw(a b)], include => 'cat'});
is_deeply($set->groups, {a => ['cat'], b => ['cat'], c => ['cat']}, $desc);

$desc = 'get complex by mixing include_groups and exclude_groups';

# NOTE: b => {in => 'c'} and c => {not_in => 'b'} should probably not be allowed...
$set->set(a => {in => 'b'});
$set->set(b => {in => 'c'});
$set->set(c => {in => 'a', not_in => 'b', include => 'cat'});
is_deeply($set->groups, {a => ['cat'], b => ['cat'], c => ['cat']}, $desc);

$set->set(a => {in => 'b'});
$set->set(b => {in => 'c', include => 'badger'});
$set->set(c => {in => 'a', not_in => 'b', include => 'cat'});
is_deeply($set->groups, {a => [qw(badger cat)], b => [qw(badger cat)], c => [qw(cat)]}, $desc);

# NOTE: order of inclusion: 'include' then 'include_groups'
$set->set(a => {in => 'b', include => 'alpaca'});
$set->set(b => {in => 'c', include => 'badger'});
$set->set(c => {in => 'a', not_in => 'b', include => 'cat'});
is_deeply($set->groups, {a => [qw(alpaca badger cat)], b => [qw(badger cat alpaca)], c => [qw(cat alpaca)]}, $desc);

done_testing;
