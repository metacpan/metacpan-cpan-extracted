# -*- perl -*-

# t/030_operators.t - check overloads

use Test::More tests => 9;

use SeeAlso::Identifier::PND;

# new
my $object = SeeAlso::Identifier::PND->new ("15617913X");

is("$object", "http://d-nb.info/gnd/15617913X", "stringification");

my $object2 = SeeAlso::Identifier::PND->new ("119653826");
my $object3 = SeeAlso::Identifier::PND->new ("1011171872");

ok($object == SeeAlso::Identifier::PND->new ("15617913X"), "object ==");
ok($object2 != SeeAlso::Identifier::PND->new ("15617913X"), "object !=");

ok($object eq SeeAlso::Identifier::PND->new ("15617913X"), "object eq");
ok($object2 ne SeeAlso::Identifier::PND->new ("15617913X"), "object ne");

# object2 < object < object3
is($object <=> $object2,  1, "object <=>");
is($object <=> $object3, -1, "object <=>");
is($object cmp $object2,  1, "object cmp");
is($object cmp $object3, -1, "object cmp");

