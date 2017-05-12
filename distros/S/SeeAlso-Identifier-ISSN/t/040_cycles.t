# -*- perl -*-

# t/040_cycles.t - try to yield initial values

use Test::More tests => 4;

use SeeAlso::Identifier::ISSN;

# new
my $object1 = SeeAlso::Identifier::ISSN->new('1426-8981');
is($object1->value(), '1426-8981', "value");
is($object1->hash(), 1426898, "hash from value");

my $object2 = SeeAlso::Identifier::ISSN->new();
$object2->hash(1426898);
is($object2->value(), '1426-8981', "value from hash");
is($object2->pretty(), '1426-8981', "pretty from hash");


