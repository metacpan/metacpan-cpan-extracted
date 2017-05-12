use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
	use_ok("Object::Capsule");
}

my $scalar = 5;

my $capsule = encapsulate($scalar);

isa_ok($capsule,  'Object::Capsule');

is(ref $$capsule, '', "encapsulated scalar is not a ref");

__END__

my $capsule = Object::Capsule::encapsulate($widget);

isa_ok($capsule,  'Object::Capsule');
isa_ok($$capsule, 'Widget');

cmp_ok($capsule->size, '==', 10, "size method goes through capsule");
cmp_ok($capsule->grow, '==', 11, "grow method goes through capsule");
cmp_ok($capsule->grow, '==', 12, "grow method again");
cmp_ok($capsule->wane, '==', 11, "wane method");
cmp_ok($capsule->size, '==', 11, "final checkup");

is($capsule->encapsulate, '!',   "encapsulate passes through on object");

