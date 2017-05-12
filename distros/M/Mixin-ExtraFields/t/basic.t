use strict;
use warnings;

use Test::More tests => 29;

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
  map { "$_\_extra" } qw(get get_all set exists delete delete_all),
);

is_deeply(
  [ $object->get_all_extra ],
  [ ],
  "when we begin, there are no extras",
);

is_deeply(
  [ $object->get_all_detailed_extra ],
  [ ],
  "...even if we ask for all the details",
);

ok( ! $object->exists_extra('datum'), "there exists no extra 'datum' yet");
is($object->get_extra('datum'), undef, "extra 'datum' shows undef value");
is($object->get_detailed_extra('datum'), undef, "...even with _detailed_");
ok( ! $object->exists_extra('datum'), "getting 'datum' value doesn't autoviv");

$object->set_extra(datum => 10);

ok($object->exists_extra('datum'), "extra 'datum' exists now");
is($object->get_extra('datum'), 10, "extra/datum has the value we supplied");

is(
  $object->{_extra}{datum},
  10,
  "with a fixed hash key, we can go find extras in the hash guts",
);

ok( ! $object->exists_misc('datum'), "there exists no misc 'datum' yet");
is($object->get_misc('datum'), undef, "misc/datum has the value we supplied");

$object->set_misc(datum => 20);

ok($object->exists_misc('datum'), "there now exists misc 'datum'");
is($object->get_misc('datum'), 20, "misc/datum has the value we supplied");

is($object->get_extra('datum'), 10, "extra/datum has the value we supplied");

$object->delete_extra('datum');

ok( ! $object->exists_extra('datum'), "there exists no extra 'datum' again");
is($object->get_extra('datum'), undef, "extra 'datum' shows undef value");

is_deeply(
  [ $object->get_all_misc_names ],
  [ qw(datum) ],
  "get_all_misc_names gets the one name that it should",
);

is_deeply(
  [ $object->get_all_misc ],
  [ datum => 20 ],
  "get_all_misc gets the one pair that it should",
);

is_deeply(
  [ $object->get_detailed_misc('datum') ],
  [ { value => 20 } ],
  "get_detailed_misc gets the hashref that it should",
);

is_deeply(
  [ $object->get_all_detailed_misc ],
  [ datum => { value => 20 } ],
  "get_all_detailed_misc gets the one pair that it should",
);

$object->set_extra(datum => 10);

is_deeply(
  [ $object->get_all_detailed_extra ],
  [ datum => { value => 10 } ],
  "get_all_detailed_extra gets the one pair that it should",
);

my $other = $test_class->new;
is_deeply(
  [ $other->get_all_detailed_misc ],
  [ ],
  "...but gets nothing from a new obj"
);

is_deeply(
  [ $other->get_all_detailed_extra ],
  [ datum => { value => 10 } ],
  "...but get_all_detailed_extra does!  it uses a shared id"
);

$object->delete_all_misc;

is_deeply(
  [ $object->get_all_misc ],
  [ ],
  "after delete_all_misc, get_all_misc gets nothing",
);

eval { (ref $object)->get_all_misc };
like($@, qr/couldn't determine id/, "exception thrown if called on class");
