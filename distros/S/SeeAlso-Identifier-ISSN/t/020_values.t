# -*- perl -*-

# t/020_values.t - check illegal values

use Test::More tests => 31;

use SeeAlso::Identifier::ISSN;

# new
my $object = SeeAlso::Identifier::ISSN->new ();

# get value
is($object->parse("1948-8351"), "1948-8351", "valid");
is($object->parse("19488351"), "1948-8351", "valid no dash");
is($object->parse("1948 8351"), "1948-8351", "valid with spaces");
is($object->parse("urn:ISSN:1948-8351"), "1948-8351", "valid URI");

is($object->parse("1948-835"), "", "too short");
is($object->parse("1948835"), "", "too short, no dash");
is($object->parse("1948 835"), "", "too short, with spaces");
is($object->parse("urn:ISSN:1948-835"), "", "too short, URI");

is($object->parse("1948-83512"), "", "too long");
is($object->parse("194883512"), "", "too long, no dash");
is($object->parse("1948 83512"), "", "too long, with spaces");
is($object->parse("urn:ISSN:1948-83512"), "", "too long URI");

is($object->parse("1948-8352"), "", "wrong checksum");
is($object->parse("19488352"), "", "wrong checksum, no dash");
is($object->parse("1948 8352"), "", "wrong checksum, with spaces");
is($object->parse("urn:ISSN:1948-8352"), "", "wrong checksum URI");

is($object->parse("0000-0000"), "0000-0000", "valid zero");
is($object->parse("0"), "", "invalid zero");
is($object->parse(""), "", "empty string");
is($object->parse(undef), "", "undef");
is($object->parse(), "", "emtpy arg");

is($object->parse("1022-100X"), "1022-100X", "valid checksum X");
is($object->parse("1022-100x"), "1022-100X", "valid checksum x");
is($object->parse("1022-100Y"), "", "invalid checksum Y");
is($object->parse("1022100-"), "", "invalid checksum -");

is($object->parse("102-2100X"), "1022-100X", "misplaced dash");
is($object->parse("10221-00X"), "1022-100X", "misplaced dash");
is($object->parse("1022100-X"), "1022-100X", "misplaced dash");
is($object->parse("1022-100-X"), "1022-100X", "many dashes");
is($object->parse("10-22-100X"), "1022-100X", "many dashes");
is($object->parse("10-2210-0X"), "1022-100X", "many dashes");

