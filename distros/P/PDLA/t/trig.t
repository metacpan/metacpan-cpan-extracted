# -*-perl-*-

use strict;
use warnings;

use Test::More tests => 4;

use PDLA::LiteF;
use PDLA::Math;

kill 'INT',$$ if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

sub tapprox {
    my($pa,$pb) = @_;
    all approx $pa, $pb, 0.01;
}

ok( tapprox(sinh(0.3),0.3045) && tapprox(acosh(42.1),4.43305) );
ok( tapprox(acos(0.3),1.2661) && tapprox(tanh(0.4),0.3799) );
ok( tapprox(cosh(2.0),3.7621) && tapprox(atan(0.6),0.54041) );

{
# inplace
my $pa = pdl(0.3);
$pa->inplace->sinh;
ok( tapprox($pa, pdl(0.3045)) );
}
