use strict;
use warnings;

use Test::More tests => 13;

BEGIN { require_ok('Mixin::ExtraFields'); }

use lib 't/lib';

my $test_class;

BEGIN {
  $test_class = 'Object::HasExtraFieldsRA';
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

