use strict;
use t::locale_hack;
use Test;
use Statistics::Basic qw(:all toler=0.000_001);

plan tests => 7;

my  $corr = new Statistics::Basic::Correlation([1 .. 10], [1 .. 10]);
ok( $corr == 1 )
    or warn "\ncorr: $corr";

    $corr->insert( 11, 7 );
ok( $corr == ( (129/20) / (sqrt(609/100) * sqrt(165/20))))
    or warn "\ncorr: $corr";

    $corr->set_vector( [11 .. 13], [11 .. 13] );
ok( $corr == 1 );

    $corr->ginsert( 13, 12 );
ok( $corr == ( (1/2) / (sqrt(11/16) * sqrt(1/2)) ))
    or warn "\ncorr: $corr";




my  $j = new Statistics::Basic::Correlation;

    $j->set_vector( [11 .. 13], [11 .. 13] );
ok( $j == 1 )
    or warn "\ncorr: $j";




my $c = correlation([4,7,7], [4,7,7]);
ok( $c == 1 )
    or warn "\ncorr: $c";

$c->insert(3,4);
ok( $c, correlation([7,7,3], [7,7,4]) );
