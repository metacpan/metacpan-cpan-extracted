# -*- perl -*-

# t/010_methods.t - check all SeeAlso::Identifier methods

use Test::More tests => 29;

use SeeAlso::Identifier::ISSN;

# new
my $object = SeeAlso::Identifier::ISSN->new ();
ok(defined ($object), "true object");

# other methods
can_ok($object, qw(value canonical normalized as_string hash indexed valid parse));

# get value
ok(! $object, "empty object");
is($object->value(), "", "empty value");

my $object2 = SeeAlso::Identifier::ISSN->new ("1948-8351");
ok(defined ($object2), "true object");
ok($object2, "non empty object");
is($object2->value(), "1948-8351", "nonempty value");

# assign/override value
$object->value("1948-8351");
is($object->value(), "1948-8351", "ISSN in canonical form");

$object2->value("19488351");
is($object, $object2, "ISSN without dash");

$object2->value("urn:ISSN:19488351");
is($object, $object2, "ISSN URI");


# canonical
is($object->canonical(), "urn:ISSN:1948-8351", "canonical");
my $obj = $object->canonical;
is($object->normalized(), $object->canonical(), "normalized as alias for canonical");

# as_string
is($object->as_string(), "urn:ISSN:1948-8351", "ISSN URI as string");

# pretty
is($object->pretty(), "1948-8351", "ISSN URI as string");

# hash
is($object->hash(), "1948835", "hash");
is($object->indexed(), $object->hash(), "indexed as alias for hash");

# valid
ok($object->valid, "valid");
ok($object->valid('abc'), "valid");

# parse
my $parsed = SeeAlso::Identifier::ISSN::parse("1022-100x");
is($parsed, "1022-100X", "parse string, function syntax");
is(SeeAlso::Identifier::ISSN::parse("urn:issn:1022-100X"), "1022-100X", "parse URI, method syntax");

my $issnobj = Business::ISSN->new("1022-100X");
is(SeeAlso::Identifier::ISSN::parse($issnobj), "1022-100X", "parse ISSN object, function syntax");

is($object2->parse("1022-100X"), "1022-100X", "parse string, method syntax");
is($object2->parse("urn:ISSN:1022-100X"), "1022-100X", "parse URI, method syntax");
is($object2->parse($issnobj), "1022-100X", "parse object, method syntax");

my $object3 = SeeAlso::Identifier::ISSN->new ($parsed);


# cmp
SKIP: {
skip "because generic cmp method employs wrong objects", 2;
ok($object->cmp("1948-8351") == 0, "cmp equal string");
ok(not($object->cmp("1819-1819") == 0), "cmp not equal string");
}
ok($object->cmp($object2) == 0, "cmp object");

# pretty
is($object->pretty(), "1948-8351", "pretty");
is($object3->pretty(), "1022-100X", "pretty");

