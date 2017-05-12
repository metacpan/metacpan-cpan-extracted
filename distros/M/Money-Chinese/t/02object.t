#########################

use Test::More "no_plan";

#########################

use Money::Chinese;

my $object = Money::Chinese->new;
isa_ok($object, "Money::Chinese");
can_ok($object, $_) for qw(convert);

