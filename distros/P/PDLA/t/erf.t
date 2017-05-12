# -*-perl-*-

use Test::More tests => 5;
use strict;
use warnings;

use PDLA::LiteF;
use PDLA::Math;

kill 'INT',$$ if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

sub tapprox {
    my($pa,$pb) = @_;
    all approx $pa, $pb, 0.01;
}

ok( tapprox(erf(0.),0.) && tapprox(erf(30.),1.) );
ok( tapprox(erf(0.5),1.-erfc(0.5)) );
ok( tapprox(erf(erfi(0.5)),0.5) && tapprox(erfi(erf(0.5)),0.5) );

{
# now test inplace
my $pa = pdl(0.0,30.0);
$pa->inplace->erf;
ok( tapprox( $pa, pdl(0.0,1.0) ) );
}

{
my $pa = pdl(0.5);
$pa->inplace->erfc;
ok( tapprox( 1.0-$pa, erf(0.5) ) );
}
