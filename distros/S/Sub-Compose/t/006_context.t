use strict;

use Test::More tests => 3;

use_ok( 'Sub::Compose', 'compose' );

sub factory {
    my $offset = shift;
    return sub {
        wantarray ?  $_[0] * $offset : $_[0] + $offset
    };
}

my $by_two = factory( 2 );
my $by_three = factory( 3 );

my $by_six = Sub::Compose::compose( $by_two, $by_three );
my @x = $by_six->( 4 );
is( $x[0], 24 );
is( $by_six->( 4 ), 9 );
