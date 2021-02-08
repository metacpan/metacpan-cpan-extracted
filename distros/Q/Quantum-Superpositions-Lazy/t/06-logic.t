use v5.24;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy qw(superpos every_state any_state one_state);
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

ok any_state { $pos1 == 1 }, 'any state == ok';
ok any_state { $pos1 != 2.5 }, 'any state != ok';
ok any_state { $pos1 != 0 }, 'any state != 2 ok';
ok any_state { $pos1 != 1 }, 'any state != 3 ok';

ok every_state { $pos1 != 20 }, 'every state != ok';
ok !every_state { $pos1 != 2 }, '!every state != ok';
ok !every_state { $pos1 == 2 }, '!every state == ok';
ok every_state { $pos1 != $pos3 }, 'every state != superpos ok';
ok !every_state { $pos2 != $pos3 }, '!every state != superpos ok';

ok one_state { $pos1 == $pos2 }, 'one state == superpos ok';
ok !one_state { $pos1 != $pos2 }, '!one state != superpos ok';
ok one_state { $pos1 == 2 }, 'one state == ok';
ok !one_state { $pos1 != 2 }, '!one state != ok';
ok !one_state { $pos2 == $pos3 }, '!one state == superpos ok';
ok !one_state { $pos1 == $pos3 }, '!one state == superpos 2 ok';
ok !one_state { $pos2 != $pos3 }, '!one state != superpos 2 ok';

done_testing;
