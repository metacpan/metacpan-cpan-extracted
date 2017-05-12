use strict;

use Test::More tests => 5;

use_ok( 'Sub::Compose' );

my @x;
sub factory {
    my $mult = shift;
    return sub {
        $_[0] * $mult
    };
}

my $times_two = factory( 2 );
my $times_three = factory( 3 );

my $times_six_1 = Sub::Compose::compose( $times_two, $times_three );
@x = $times_six_1->( 4 );
is( $x[0], 24 );

my $times_six_2 = Sub::Compose::compose( $times_three, $times_two );
@x = $times_six_2->( 6 );
is( $x[0], 36 );

my $times_four = Sub::Compose::compose( $times_two, $times_two );
@x = $times_four->( 6 );
is( $x[0], 24 );

my $times_sixteen = Sub::Compose::compose( ( $times_two ) x 4 );
@x = $times_sixteen->( 6 );
is( $x[0], 96 );
