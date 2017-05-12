use strict;
use warnings;

use Test::More tests => 16;

BEGIN { require_ok('Mixin::ExtraFields'); }

use lib 't/lib';

my $test_class;

BEGIN {
  $test_class = 'Object::HasExtraFields';
  use_ok($test_class);
}

my $object = $test_class->new;

isa_ok($object, $test_class);

can_ok(
  $object,
  map { "$_\_mini" } qw(get get_all set exists delete delete_all),
);

ok( ! $object->exists_mini('datum'), "there exists no mini/datum yet");
is($object->get_mini('datum'), undef, "mini/datum shows undef value");
ok( ! $object->exists_mini('datum'), "get mini/datum value doesn't autoviv");

$object->set_mini(datum => 10);

ok($object->exists_mini('datum'), "mini/datum exists now");
is($object->get_mini('datum'), 10, "mini/datum has the value we supplied");

$object->set_mini(doomed => 20);
$object->delete_mini(doomed => 20);

ok(
  ! $object->exists_mini('doomed'),
  "there exists no mini/doomed after set and delete"
);
is($object->get_mini('doomed'), undef, "mini/doomed shows undef value");

is_deeply(
  [ $object->get_all_mini_names ],
  [ qw(datum) ],
  "get_all_mini_names gets the one name that it should",
);

is_deeply(
  [ $object->get_all_mini ],
  [ datum => 10 ],
  "get_all_mini gets the one pair that it should",
);

is_deeply(
  [ $object->get_detailed_mini('datum') ],
  [ { value => 10 } ],
  "get_detailed_mini gets the hashref that it should",
);

is_deeply(
  [ $object->get_all_detailed_mini ],
  [ datum => { value => 10 } ],
  "get_all_detailed_mini gets the one pair that it should",
);

$object->delete_all_mini;

is_deeply(
  [ $object->get_all_mini ],
  [ ],
  "get_all_mini gets an empty list after delete_all_mini",
);

