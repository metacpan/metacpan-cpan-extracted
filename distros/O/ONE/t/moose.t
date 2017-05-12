use strict;
use warnings;
BEGIN {
    eval q{ require Moose }; # Force Any::Moose to use Moose instead of Mouse
    if ($@) {
        eval q{ use Test::More skip_all => "Can't do Moose tests without Moose" };
        exit;
    }
    else {
        eval q{ use Test::More tests => 5 };
    }
}
use ONE qw( Timer=sleep:sleep_until );

my $after_test;
ONE::Timer->after( .1, sub { $after_test ++ } );

my $at_test;
ONE::Timer->at( AE::time+.2, sub { $at_test ++ } );

my $every_test;
my $every = ONE::Timer->every( .3, sub { $every_test ++ });

sleep(.7);

is( $after_test, 1, "After event emitted" );

is( $at_test, 1, "At event emited" );

is( $every_test, 2, "Every test emitted twice" );

$every->cancel;

sleep_until(AE::time+.3);

is($every_test,2,"No further 'every' timer ticks have occured.");

my $cancel_test;
my $ct = ONE::Timer->after( .1, sub { $cancel_test++ } );
$ct->cancel;
sleep(.2);

isnt( $cancel_test, 1, "Canceled event doesn't occur" );

