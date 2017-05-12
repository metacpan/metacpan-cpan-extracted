use strict;

use Test::More tests => 3;

use_ok( 'Sub::Compose' );

my @x;
{
    my $counter = 1;
    sub inc_mult { $_[0] * $counter++ }
}

my $d = Sub::Compose::compose( \&inc_mult, \&inc_mult );

@x = $d->( 2 );
is( $x[0], 4 );

@x = $d->( 2 );
is( $x[0], 24 );
