use strict;

use Test::More tests => 3;

use_ok( 'Sub::Compose' );

my $a = sub {
    if ( $_[0] > 5 ) {
        return 2 * $_[0];
    } else {
        return 3 * $_[0];
    }
};

my $b = sub {
    if ( $_[0] > 5 ) {
        return 2 * $_[0];
    } else {
        return 3 * $_[0];
    }
};

my $c = sub {
    if ( $_[0] > 5 ) {
        return 2 * $_[0];
    } else {
        return 3 * $_[0];
    }
};

my $f = Sub::Compose::compose( $a, $b, $c );
isa_ok( $f, 'CODE' );

my @x = $f->( 2 );
is( $x[0], 24 );
