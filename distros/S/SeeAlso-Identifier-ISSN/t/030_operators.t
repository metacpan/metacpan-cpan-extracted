# -*- perl -*-

# t/030_operators.t - check overloads

use Test::More tests => 7;

use SeeAlso::Identifier::ISSN;

# new
my $object = SeeAlso::Identifier::ISSN->new ("1022-100X");

is("$object", "urn:ISSN:1022-100X", "stringification");


my $object2 = SeeAlso::Identifier::ISSN->new ("1819-1819");

ok($object == SeeAlso::Identifier::ISSN->new ("1022-100X"), "object ==");
ok($object2 != SeeAlso::Identifier::ISSN->new ("1022-100X"), "object !=");

ok($object eq SeeAlso::Identifier::ISSN->new ("1022-100X"), "object eq");
ok($object2 ne SeeAlso::Identifier::ISSN->new ("1022-100X"), "object ne");

ok($object <=> $object2, "object <=>");
ok($object cmp $object2, "object cmp");

