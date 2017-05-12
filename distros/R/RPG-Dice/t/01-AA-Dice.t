#########################

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('RPG::Dice') }
my $d1 = new RPG::Dice('1d6');
my $d2 = new RPG::Dice('2d6');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
    my $inrange = 1;
    foreach my $i ( 0 .. 999 ) {
        my $roll = $d1->roll();
        if ( ( 1 <= $roll ) && ( $roll <= 6 ) ) {
        }
        else {
            $inrange = 0;
        }
    }
    ok( $inrange, "Single dice test" );
}
{
    my $inrange = 1;
    foreach my $i ( 0 .. 999 ) {
        my $roll = $d2->roll();
        if ( ( 2 <= $roll ) && ( $roll <= 12 ) ) {
        }
        else {
            $inrange = 0;
        }
    }
    ok( $inrange, "Single dice test" );
}

