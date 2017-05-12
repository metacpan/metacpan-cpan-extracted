use t::locale_hack;
use strict;
use Test;
use Statistics::Basic qw(:all toler=0.000_001);

plan tests => (my $t = 4);

unless( eval 'use Math::BigFloat; 1' ) {
    warn " [skipping all Math::BigFloat tests, as it does't appear to load]\n";
    skip(1,1,1) for 1 .. $t;
    exit 0;
}

my $v = $Math::BigFloat::VERSION;
warn " [M::BF version: $v]\n";
if( $v < 1.60 ) {
    warn " [skipping all Math::BigFloat tests, mysterious problems crop up without recent versions of M::BF]\n";
    skip(1,1,1) for 1 .. $t;
    exit 0;
}

my  $corr = new Statistics::Basic::Correlation([1 .. 10], [1 .. 10]);
ok( $corr == 1 );

    $corr->insert( 11, 7 );
ok( $corr == ( (129/20) / (sqrt(609/100) * sqrt(165/20))));

$corr = new Statistics::Basic::Correlation([map {Math::BigFloat->new($_)} 1 .. 10], [map {Math::BigFloat->new($_)} 1 .. 10]);
ok( $corr == 1 );

$corr->insert( map {Math::BigFloat->new($_)} 11, 7 );
my $tv = ((Math::BigFloat->new(129)/20) / (sqrt(Math::BigFloat->new(609)/100) * sqrt(Math::BigFloat->new(165)/20)));
#my $d  = $corr - $tv;
#warn " d: $d"; # 0.0000362452

$Statistics::Basic::TOLER = 0.000_1;
ok( $corr == $tv );
