use strict; use warnings;
use Test::More 0.96;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::DSP::Windows qw( window chebpoly ) ;

eval { require PDL::LinearAlgebra::Special };
my $HAVE_LinearAlgebra = 1 if !$@;

eval { require PDL::GSLSF::BESSEL; };
my $HAVE_BESSEL = 1 if !$@;


sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-7;
  my $diff;
  if ( ref($a) ) {
      $b = pdl $b;
      $diff = abs($a-$b)->sum;
  }
  else {
      $diff = abs($a-$b);
  }
  return $diff < $eps;
}

# Most of these were checked with Octave
subtest 'explict values of windows.' => sub {
    ok( tapprox( window(4, 'hamming'), [0.08, 0.77, 0.77, 0.08]));
    ok( tapprox( window(4,'hann'), [0, 0.75, 0.75, 0]));
    ok( tapprox( window(4,'hann_matlab'), [ 0.3454915,  0.9045085,  0.9045085,  0.3454915]));
    ok( tapprox( window(6,'bartlett_hann'), [0, 0.35857354, 0.87942646, 0.87942646, 0.35857354, 0]));
    ok( tapprox( window(6,'bohman'), [0, 0.17912389, 0.83431145, 0.83431145, 0.17912389, 0]));
    ok( tapprox( window(6,'triangular'), [qw(0.16666667 0.5 0.83333333 0.83333333 0.5 0.16666667)]));
    ok( tapprox( window(6,'welch'), [qw(0 0.64 0.96 0.96 0.64 0)]));
    ok( tapprox( window(6,'blackman_harris4'), [qw(6e-05 0.10301149 0.79383351 0.79383351 0.10301149 6e-05)]));
    ok( tapprox( window(6,'blackman_nuttall'), [qw(0.0003628 0.11051525  0.7982581  0.7982581 0.11051525  0.0003628)]));
    ok( tapprox( window(6,'flattop'), [qw(-0.000421051 -0.067714252 0.60687215 0.60687215 -0.067714252 -0.000421051)]));
    ok(tapprox(window(6,'kaiser',.5/3.1415926), 
               [qw(0.94030619 0.97829624  0.9975765  0.9975765 0.97829624 0.94030619)])) if $HAVE_BESSEL;
    ok( tapprox( window(10,'tukey',.4), 
                 [qw(0 0.58682409 1 1 1 1 1 1 0.58682409 0)]));
    ok( tapprox( window(8,'chebyshev',10), 
                 [qw(1 0.45192476  0.5102779 0.54133813 0.54133813  0.5102779 0.45192476 1)]));
    ok( tapprox( window(9,'chebyshev',10), 
                 [qw(1 0.39951163 0.44938961 0.48130908 0.49229345 0.48130908 0.44938961 0.39951163 1)]));
};

subtest 'relations between windows.' => sub {
    ok( tapprox(  window(6,'hann'), window(6,'cos_alpha',2)));
    ok( tapprox(  window(6,'cosine'), window(6,'cos_alpha',1)));
    ok( tapprox(  window(6,'rectangular'), window(6,'cos_alpha',0)));
};

# The following agree with Thomas Cokelaer's python package.

subtest 'enbw of windows.' => sub {
    my $Nbw = 16384;
    my $eps = 1e-5;
    my $win = new PDL::DSP::Windows();
    ok( tapprox($win->init($Nbw,'hamming')->enbw, 1.36288566, $eps));
    ok( tapprox( $win->init($Nbw,'rectangular')->enbw, 1.0, $eps));
    ok( tapprox( $win->init($Nbw,'triangular')->enbw, 4/3, $eps));
    ok( tapprox( $win->init(10*$Nbw,'hann')->enbw, 1.5, $eps));
    ok( tapprox( $win->init($Nbw,'blackman')->enbw, 1.72686276895347, $eps));
    ok( tapprox( $win->init($Nbw,'kaiser',8.6/3.1415926)->enbw, 1.72147863, $eps)) if $HAVE_BESSEL;;
    ok( tapprox( $win->init($Nbw,'blackman_harris4')->enbw, 2.0044752407, $eps));
    ok( tapprox( $win->init($Nbw,'bohman')->enbw, 1.78584987506, $eps));
    ok( tapprox( $win->init($Nbw,'cauchy',3)->enbw, 1.489407730, $eps));
    ok( tapprox( $win->init($Nbw,'poisson',2)->enbw, 1.31307123, $eps));
    ok( tapprox( $win->init($Nbw,'hann_poisson',.5)->enbw, 1.6092559, $eps));
    ok( tapprox( $win->init($Nbw,'lanczos')->enbw, 1.29911199, $eps));
    ok( tapprox( $win->init($Nbw,'tukey',0.25)->enbw, 1.1021080, $eps));
    ok( tapprox( $win->init($Nbw,'parzen')->enbw, 1.917577, $eps));
    
# These agree with other values found on web
    $eps = 1e-3;
    ok( tapprox( $win->init($Nbw,'flattop')->enbw, 3.77, $eps));
};


# Test relation between periodic and symmetric for each window type.

subtest 'relation between periodic and symmetric.' => sub {
    foreach my $N (100,101) {
        my $Nm = $N-1;
        foreach my $win ( qw(bartlett_hann bartlett blackman blackman_bnh blackman_ex
             blackman_harris blackman_harris4 blackman_nuttall bohman
             cosine exponential flattop hamming
             hamming_ex hann lanczos nuttall parzen rectangular
             triangular welch ),
                          ([blackman_gen3 => [.42, .5, .08]], [blackman_gen4 => [0.35875,0.48829,0.14128,0.01168]],
                           [blackman_gen5 => [0.21557895,0.41663158,0.277263158,.083578947,0.006947368]],
                           [blackman_gen => [.5] ] , [ cauchy => [3] ], [kaiser => [.5]],
                           [cos_alpha => [2]], [hamming_gen => [.5] ], [gaussian => [1]],
                           [poisson => [1]], [ tukey => [.4] ], [dpss => [4] ]   )) {            
            my $name = ref($win) ? shift @$win : $win;
#    print STDERR $name,"\n";
            next if $name eq 'kaiser' and not $HAVE_BESSEL;
            next if $name eq 'dpss' and not $HAVE_LinearAlgebra;
            if (ref($win)) {
                ok( tapprox( window($N+1,$name, {params => $win->[0]} )->slice("0:$Nm"),window($N,$name,{per => 1, params => $win->[0] })));
            }
            else {
                ok( tapprox( window($N+1,$name)->slice("0:$Nm"),window($N,$name,{per => 1})));
            }
        }                                                                      
    }
};
    
subtest 'chebpoly.' => sub {
    ok( tapprox( chebpoly( 3  , pdl([.5,1,1.2]) ) , [-1, 1, 3.312] ));
    ok( tapprox( chebpoly( 3  , [.5,1,1.2] ) , [-1, 1, 3.312] ));
    ok( chebpoly( 3, 1.2 ) == 3.312  );
};

subtest 'modfreqs.' => sub {
        ok( new PDL::DSP::Windows({N=>10})->modfreqs->nelem == 1000 );
        ok( new PDL::DSP::Windows({N=>10})->modfreqs({min_bins => 100})->nelem == 100 );
};

done_testing;


