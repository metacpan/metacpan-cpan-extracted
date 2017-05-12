use strict;
use warnings;

use Test::More;

use Physics::RayTransfer;

my $sys = Physics::RayTransfer->new;


#units in cm
$sys->add_mirror;
$sys->add_space(5);
$sys->add_mirror(8);

my $equiv = $sys->evaluate;
my $lambda = 523e-7;

my $expected = [1, 10, -0.25, -1.5];
is_deeply($equiv->as_arrayref, $expected, "Equivalent element" );

ok( $equiv->stability($lambda), "Cavity is stable");
ok( $equiv->w($lambda), "Cavity has a spot size at observer");

done_testing;

