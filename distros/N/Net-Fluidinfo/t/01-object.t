use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::Fluidinfo;
use Net::Fluidinfo::TestUtils;

use_ok('Net::Fluidinfo::Object');

my $fin = Net::Fluidinfo->_new_for_net_fluidinfo_test_suite;

my ($about, $object, $object2, $object3);

# creates an object with about
$about = random_about;
$object = Net::Fluidinfo::Object->new(fin => $fin, about => $about);
ok $object->create;
ok $object->has_id;
ok $object->about eq $about;

# fetches that very object by id
$object2 = Net::Fluidinfo::Object->get_by_id($fin, $object->id, about => 1);
ok $object2->id eq $object->id;
ok $object2->about eq $object->about;

# fetches that very object by id
$object3 = Net::Fluidinfo::Object->get_by_about($fin, $about);
ok $object3->id eq $object->id;
ok $object3->about eq $object->about;

# creates an object without about
$object = Net::Fluidinfo::Object->new(fin => $fin);
ok $object->create;
ok $object->has_id;
ok !$object->has_about;

# fetches that very object
$object2 = Net::Fluidinfo::Object->get_by_id($fin, $object->id);
ok $object2->id eq $object->id;
ok !$object2->has_about;

# tag paths
$object = Net::Fluidinfo::Object->new(fin => $fin);
ok @{$object->tag_paths} == 0;
ok $object->create;
ok @{$object->tag_paths} == 0;

$object = Net::Fluidinfo::Object->new(fin => $fin, about => random_about);
ok @{$object->tag_paths} == 0;
ok $object->create;
ok @{$object->tag_paths} == 1;
ok $object->tag_paths->[0] eq 'fluiddb/about';
$object2 = Net::Fluidinfo::Object->get_by_id($fin, $object->id);
ok_sets_cmp $object->tag_paths, $object2->tag_paths;

# Now we are gonna do some variations just in case, but the proper place to
# test them is the suite of the Tag class.

# is_tag_path_present
$object = Net::Fluidinfo::Object->new(fin => $fin);
ok !$object->is_tag_path_present('fxn/rating');
ok !$object->is_tag_path_present('');

$object->_set_tag_paths(['fxn/rating']);
ok $object->is_tag_path_present('fxn/rating');
ok $object->is_tag_path_present('FxN/rating');

$object->_set_tag_paths(['fxn/rating', 'fxn/was-here']);
ok $object->is_tag_path_present('fxn/rating');
ok $object->is_tag_path_present('fxn/was-here');
ok $object->is_tag_path_present('FXN/rating');
ok $object->is_tag_path_present('FXN/was-here');
ok !$object->is_tag_path_present('fxn/RATING');
ok !$object->is_tag_path_present('fxn/WAS-HERE');

done_testing;