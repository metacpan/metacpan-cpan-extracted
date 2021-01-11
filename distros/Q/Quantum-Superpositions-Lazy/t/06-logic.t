use v5.28;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy qw(every_state any_state one_state);
use Data::Dumper;

##############################################################################
# This test checks if comparison operators are returning the right thing when
# used on superpos states.
##############################################################################

my $pos1 = superpos(1, 2, 3);
my $pos2 = superpos(3, 4, 5);
my $pos3 = superpos(4, 5, 6);

ok $pos1 == $pos2, "numeric eq ok";
ok $pos1 != $pos3, "numeric ne ok";
ok $pos3 > $pos1, "numeric gt ok";
ok $pos2 >= $pos1, "numeric ge ok";
ok $pos1 < $pos3, "numeric lt ok";
ok $pos2 <= $pos1, "numeric le ok";

ok $pos1 eq $pos2, "eq ok";
ok $pos1 ne $pos3, "ne ok";
ok $pos3 gt $pos1, "gt ok";
ok $pos2 ge $pos1, "ge ok";
ok $pos1 lt $pos3, "lt ok";
ok $pos2 le $pos1, "le ok";

ok !!$pos1, "negation ok";
ok !superpos(0), "negation ok";
ok !!superpos(0, 1), "negation ok";

ok any_state { $pos1 == 1 };
ok any_state { $pos1 != 2.5 };
ok any_state { $pos1 != 0 };

ok every_state { $pos1 != 20 };
ok !every_state { $pos1 == 2 };
ok every_state { $pos1 != $pos3 };

ok one_state { $pos1 == $pos2 };
ok !one_state { $pos1 != $pos2 };
ok one_state { $pos1 == 2 };
ok !one_state { $pos1 != 2 };
ok !one_state { $pos2 == $pos3 };
ok !one_state { $pos1 == $pos3 };
ok !one_state { $pos2 != $pos3 };

done_testing;
