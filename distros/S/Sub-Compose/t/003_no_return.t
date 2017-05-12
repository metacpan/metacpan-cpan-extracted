use strict;

use Test::More tests => 3;

use_ok( 'Sub::Compose' );

my $a = sub { $_[0] * 2 };

my $b = Sub::Compose::compose( $a );
isa_ok( $b, 'CODE' );

my @v = $b->( 2 );
is( $v[0], 4 );
