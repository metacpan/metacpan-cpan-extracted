# -*- perl -*-

# t/010_methods.t - check all SeeAlso::Identifier methods

use Test::More tests => 28;

use SeeAlso::Identifier::PND;

# new
my $object = SeeAlso::Identifier::PND->new ();
ok(defined ($object), "true object");

# other methods
can_ok($object, qw(value canonical normalized as_string hash indexed valid parse));

# get value
ok(! $object, "empty object");
is($object->value(), "", "empty value");

my $object2 = SeeAlso::Identifier::PND->new ("119653826");
ok(defined ($object2), "true object");
ok($object2, "non empty object");
is($object2->value(), "119653826", "nonempty value");

# assign/override value
$object->value("132010445");
is($object->value(), "132010445", "PND in canonical form");

$object2->value("13201044-5");
is($object2, "", "PND with dash is invalid");

$object2->value("http://d-nb.info/gnd/132010445");
is($object, $object2, "PND URI");


# canonical
is($object->canonical(), "http://d-nb.info/gnd/132010445", "canonical");
my $obj = $object->canonical;
is($object->normalized(), $object->canonical(), "normalized as alias for canonical");

# as_string
is($object->as_string(), "http://d-nb.info/gnd/132010445", "PND URI as string");

# pretty
is($object->pretty(), "132010445", "PND URI as string");

# hash
is($object->hash(), "132010445", "hash");
is($object->indexed(), $object->hash(), "indexed as alias for hash");

# valid
ok($object->valid, "valid");
ok($object->valid('abc'), "valid");
ok($object->valid('15617913X'), "valid");

# parse
my $parsed = SeeAlso::Identifier::PND::parse("137981767");
is($parsed, "137981767", "parse string, function syntax");
is(SeeAlso::Identifier::PND::parse("http://d-nb.info/gnd/137981767"), "137981767", "parse URI, method syntax");

is($object2->parse("137981767"), "137981767", "parse string, method syntax");
is($object2->parse("http://d-nb.info/gnd/137981767"), "137981767", "parse URI, method syntax");

my $object3 = SeeAlso::Identifier::PND->new ($parsed);


# cmp
SKIP: {
skip "because generic cmp method employs wrong objects", 2;
ok($object->cmp("132010445") == 0, "cmp equal string");
ok(not($object->cmp("1819-1819") == 0), "cmp not equal string");
}
ok($object->cmp($object2) == 0, "cmp object");

# pretty
is($object->pretty(), "132010445", "pretty");
is($object3->pretty(), "137981767", "pretty");

