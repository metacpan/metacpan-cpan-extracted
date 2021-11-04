use Test::More;

use strict;
use warnings;

use PDL;
use PDL::DSP::Windows qw( window chebpoly ) ;

my $HAVE_LinearAlgebra = eval { require PDL::LinearAlgebra::Special };
my $HAVE_BESSEL        = eval { require PDL::GSLSF::BESSEL };

use lib 't/lib';
use MyTest::Helper qw( dies is_approx );

# Most of these were checked with Octave
subtest 'explict values of windows.' => sub {
    is_approx
        window( 4, 'hamming' ),
        [ 0.08, 0.77, 0.77, 0.08 ],
        'hamming';

    is_approx
        window( 4, 'hann' ),
        [ 0, 0.75, 0.75, 0 ],
        'hann';

    is_approx
        window( 4, 'hann_matlab' ),
        [ 0.3454915,  0.9045085,  0.9045085,  0.3454915 ],
        'hann_matlab';

    is_approx
        window( 6, 'bartlett_hann' ),
        [ 0, 0.35857354, 0.87942646, 0.87942646, 0.35857354, 0 ],
        'bartlett_hann';

    is_approx
        window( 6, 'bohman' ),
        [ 0, 0.17912389, 0.83431145, 0.83431145, 0.17912389, 0 ],
        'bohman',
        6;

    is_approx
        window( 6, 'triangular' ),
        [ 0.16666667, 0.5, 0.83333333, 0.83333333, 0.5, 0.16666667 ],
        'triangular';

    is_approx
        window( 6, 'welch' ),
        [ 0, 0.64, 0.96, 0.96, 0.64, 0 ],
        'welch';

    is_approx
        window( 6, 'blackman_harris4' ),
        [ 6e-05, 0.10301149, 0.79383351, 0.79383351, 0.10301149, 6e-05 ],
        'blackman_harris4';

    is_approx
        window( 6, 'blackman_nuttall' ),
        [ 0.0003628, 0.11051525, 0.7982581, 0.7982581, 0.11051525, 0.0003628 ],
        'blackman_nuttall';

    is_approx
        window( 6, 'flattop' ),
        [ -0.000421051, -0.067714252, 0.60687215, 0.60687215, -0.067714252, -0.000421051 ],
        'flattop',
        6;

    SKIP: {
        skip 'PDL::GSLSF::BESSEL not installed', 1 unless $HAVE_BESSEL;
        is_approx
            window( 6, 'kaiser', 0.5 / 3.1415926 ),
            [ 0.94030619, 0.97829624, 0.9975765, 0.9975765, 0.97829624, 0.94030619 ],
            'kaiser',
            7;
    }

    is_approx
        window( 10, 'tukey', 0.4 ),
        [ 0, 0.58682409, 1, 1, 1, 1, 1, 1, 0.58682409, 0 ],
        'tukey',
        6;

    is_approx
        window( 10, 'parzen' ),
        [ 0, 0.021947874, 0.17558299, 0.55555556, 0.93415638, 0.93415638, 0.55555556, 0.17558299, 0.021947874, 0],
        'parzen',
        7;

    is_approx
        window( 10, 'parzen_octave' ),
        [ 0.002, 0.054, 0.25, 0.622, 0.946, 0.946, 0.622, 0.25, 0.054, 0.002 ],
        'parzen';

    is_approx
        window( 8, 'chebyshev', 10 ),
        [ 1, 0.45192476, 0.5102779, 0.54133813, 0.54133813, 0.5102779, 0.45192476, 1 ],
        'chebyshev',
        6;

    is_approx
        window( 9, 'chebyshev', 10 ),
        [ 1, 0.39951163, 0.44938961, 0.48130908, 0.49229345, 0.48130908, 0.44938961, 0.39951163, 1 ],
        'chebyshev',
        6;
};

subtest 'relations between windows.' => sub {
    is_approx
        window( 6, 'rectangular' ),
        window( 6, 'cos_alpha', 0 ),
        'rectangular window is equivalent to cos_alpha 0';

    is_approx
        window( 6, 'cosine' ),
        window( 6, 'cos_alpha', 1 ),
        'cosine window is equivalent to cos_alpha 1';

    is_approx
        window( 6, 'hann' ),
        window( 6, 'cos_alpha', 2 ),
        'hann window is equivalent to cos_alpha 2';
};

subtest 'enbw of windows.' => sub {
    my $Nbw = 16384;
    my $win = PDL::DSP::Windows->new;

    for (
        # The following agree with Thomas Cokelaer's python package
        [ [ $Nbw, 'hamming'           ], 1.36288567 ],
        [ [ $Nbw, 'rectangular'       ], 1.0        ],
        [ [ $Nbw, 'triangular'        ], 4 / 3      ],
        [ [ $Nbw * 10, 'hann'         ], 1.5  =>  4 ],
        [ [ $Nbw, 'blackman'          ], 1.72686277 ],
        [ [ $Nbw, 'blackman_harris4'  ], 2.00447524 ],
        [ [ $Nbw, 'bohman'            ], 1.78584988 ],
        [ [ $Nbw, 'cauchy', 3         ], 1.48940773 ],
        [ [ $Nbw, 'poisson', 2        ], 1.31307123 ],
        [ [ $Nbw, 'hann_poisson', 0.5 ], 1.60925592 ],
        [ [ $Nbw, 'lanczos'           ], 1.29911200 ],
        [ [ $Nbw, 'tukey', 0.25       ], 1.10210808 ],
        [ [ $Nbw, 'parzen'            ], 1.91757736 ],
        [ [ $Nbw, 'parzen_octave'     ], 1.91746032 ],
        # These agree with other values found on web
        [ [ $Nbw, 'flattop'           ], 3.77 =>  3 ],
    ) {
        my ( $args, $expected, $precision ) = @{$_};
        my ( undef, $name ) = @{$args};
        is_approx $win->init( @{$args} )->enbw, $expected, $name, $precision;
    }

    SKIP: {
        skip 'PDL::GSLSF::BESSEL not installed', 1 unless $HAVE_BESSEL;
        is_approx
            $win->init( $Nbw, 'kaiser', 8.6 / 3.1415926 )->enbw,
            1.72147863,
            'kaiser',
            5;
    }
};

subtest 'scalloping loss of windows.' => sub {
    my $win = PDL::DSP::Windows->new;

    # Test data taken from https://www.recordingblogs.com/wiki/scalloping-loss
    for (
        [ bartlett_hann             => -1.51 ],
        [ blackman                  => -1.09 ],
        [ blackman_ex               => -1.15 ],
        [ blackman_gen      => 0.05 => -1.33 ],
        [ blackman_gen      => 0.20 => -1.00 ],
        [ blackman_gen      => 0.35 => -0.53 ],
        [ blackman_harris           => -0.82 ],
        [ blackman_nuttall          => -0.85 ],
        [ bohman                    => -1.02 ],
        [ chebyshev         =>  0.1 => -1.44 ],
        [ chebyshev         =>  0.2 => -1.28 ],
        [ chebyshev         =>  0.3 => -1.23 ],
        [ flattop                   => -0.01 ],
        [ gaussian          =>  0.3 => -0.95 ],
        [ gaussian          =>  0.5 => -2.12 ],
        [ gaussian          =>  0.7 => -2.84 ],
        [ hamming                   => -1.75 ],
        [ hann                      => -1.42 ],
        [ hann_poisson      =>  0.3 => -1.32 ],
        [ hann_poisson      =>  0.5 => -1.25 ],
        [ hann_poisson      =>  0.7 => -1.19 ],
        [ lanczos                   => -1.88 ],
        [ nuttall                   => -0.81 ],
        [ parzen                    => -2.57 ],
        [ poisson           =>  0.2 => -3.69 ],
        [ poisson           =>  0.5 => -3.36 ],
        [ poisson           =>  0.8 => -3.05 ],
        [ cos_alpha         =>  1.0 => -2.09 ],
        [ cos_alpha         =>  2.0 => -1.42 ],
        [ cos_alpha         =>  3.0 => -1,07 ],
        [ rectangular               =>  3.92 ],
        [ cosine                    => -2.09 ],
        [ triangular                => -1.82 ],
        [ tukey             =>  0.3 => -1.81 ],
        [ tukey             =>  0.5 => -2.23 ],
        [ tukey             =>  0.7 => -2.79 ],
        [ welch                     => -2.23 ],
    ) {
        my @args     = @{$_};
        my $expected = pop @args;

        is_approx $win->init( 1000, @args )->scallop_loss, $expected, join(' ', @args), 3;
    }

    SKIP: {
        skip 'PDL::GSLSF::BESSEL not installed', 3 unless $HAVE_BESSEL;
        is_approx $win->init( 1000, 'kaiser', 0.5 )->scallop_loss, -3.31, 'kaiser 0.5', 3;
        is_approx $win->init( 1000, 'kaiser', 1.0 )->scallop_loss, -2.42, 'kaiser 1.0', 3;
        is_approx $win->init( 1000, 'kaiser', 5.0 )->scallop_loss, -1.05, 'kaiser 5.0', 3;
    }
};

subtest 'relation between periodic and symmetric.' => sub {
    for my $N (100, 101) {
        my $Nm = $N - 1;

        my %tests = (
            bartlett_hann    => [],
            bartlett         => [],
            blackman         => [],
            blackman_bnh     => [],
            blackman_ex      => [],
            blackman_harris  => [],
            blackman_harris4 => [],
            blackman_nuttall => [],
            bohman           => [],
            cosine           => [],
            exponential      => [],
            flattop          => [],
            hamming          => [],
            hamming_ex       => [],
            hann             => [],
            hann_poisson     => [ 0.5 ],
            lanczos          => [],
            nuttall          => [],
            nuttall1         => [],
            parzen           => [],
            rectangular      => [],
            triangular       => [],
            welch            => [],
            blackman_gen3    => [ 0.42, 0.5, 0.08 ],
            blackman_gen4    => [ 0.35875, 0.48829, 0.14128, 0.01168 ],
            blackman_gen     => [ 0.5 ],
            cauchy           => [ 3 ],
            kaiser           => [ 0.5 ],
            cos_alpha        => [ 2 ],
            hamming_gen      => [ 0.5 ],
            gaussian         => [ 1 ],
            poisson          => [ 1 ],
            tukey            => [ 0.4 ],
            dpss             => [ 4 ],
            blackman_gen5    => [
                0.21557895, 0.41663158, 0.277263158, 0.083578947, 0.006947368
            ],
        );

        for my $name ( keys %tests ) {
            SKIP: {
                skip 'PDL::GSLSF::BESSEL not installed', 1
                    if $name eq 'kaiser' and not $HAVE_BESSEL;

                skip 'PDL::LinearAlgebra::Special not installed', 1
                    if $name eq 'dpss' and not $HAVE_LinearAlgebra;

                my %args;
                $args{params} = $tests{$name} if @{ $tests{$name} };

                my $window = window( $N + 1, $name, { %args } );
                is_approx
                    $window->slice("0:$Nm"),
                    window( $N, $name, { per => 1, %args } ),
                    $name;
            }
        }
    }
};

subtest 'modfreqs.' => sub {
    is +PDL::DSP::Windows->new({ N => 10 })->modfreqs->nelem, 1000,
        'modfreqs defaults to 1000 bins';

    is +PDL::DSP::Windows->new({ N => 10 })
        ->modfreqs({ min_bins => 100 })->nelem, 100,
        'can pass bin number to modfreqs with hashref';
};

subtest 'argument validation' => sub {
    my %windows = (
        bartlett             => 1,
        bartlett_hann        => 1,
        blackman             => 1,
        blackman_bnh         => 1,
        blackman_ex          => 1,
        blackman_gen         => 2,
        blackman_gen3        => 4,
        blackman_gen4        => 5,
        blackman_gen5        => 6,
        blackman_harris      => 1,
        blackman_harris4     => 1,
        blackman_nuttall     => 1,
        bohman               => 1,
        cauchy               => 2,
        chebyshev            => 2,
        cos_alpha            => 2,
        cosine               => 1,
        exponential          => 1,
        flattop              => 1,
        gaussian             => 2,
        hamming              => 1,
        hamming_ex           => 1,
        hamming_gen          => 2,
        hann                 => 1,
        hann_matlab          => 1,
        hann_poisson         => 2,
        lanczos              => 1,
        nuttall              => 1,
        nuttall1             => 1,
        parzen               => 1,
        parzen_octave        => 1,
        poisson              => 2,
        rectangular          => 1,
        triangular           => 1,
        tukey                => 2,
        welch                => 1,

        bartlett_per         => 1,
        bartlett_hann_per    => 1,
        blackman_per         => 1,
        blackman_bnh_per     => 1,
        blackman_ex_per      => 1,
        blackman_gen_per     => 2,
        blackman_gen3_per    => 4,
        blackman_gen4_per    => 5,
        blackman_gen5_per    => 6,
        blackman_harris_per  => 1,
        blackman_harris4_per => 1,
        blackman_nuttall_per => 1,
        bohman_per           => 1,
        cauchy_per           => 2,
        cos_alpha_per        => 2,
        cosine_per           => 1,
        exponential_per      => 1,
        flattop_per          => 1,
        gaussian_per         => 2,
        hamming_per          => 1,
        hamming_ex_per       => 1,
        hamming_gen_per      => 2,
        hann_per             => 1,
        hann_poisson_per     => 2,
        lanczos_per          => 1,
        nuttall_per          => 1,
        nuttall1_per         => 1,
        parzen_per           => 1,
        poisson_per          => 2,
        rectangular_per      => 1,
        triangular_per       => 1,
        tukey_per            => 2,
        welch_per            => 1,
    );

    if ($HAVE_LinearAlgebra) {
        $windows{dpss}     = 2;
        $windows{dpss_per} = 2;
    }

    if ($HAVE_BESSEL) {
        $windows{kaiser}     = 2;
        $windows{kaiser_per} = 2;
    }

    while ( my ( $name, $args ) = each %windows ) {
        for my $n ( 0 .. $args - 1, $args + 1 ) {
            my $basename = $name;
            $basename =~ s/_per$//;
            dies { PDL::DSP::Windows->can($name)->( (1) x $n ) }
                qr/^$basename: $args arguments? expected. Got $n/,
                "$name dies when called with $n arguments";
        }
    }

    for (qw( tukey tukey_per )) {
        my $basename = $_;
        $basename =~ s/_per$//;
        dies { PDL::DSP::Windows->can($_)->( 1, -1 ) }
            qr/^$basename: alpha must be between 0 and 1/,
            "$_ dies with alpha < 0";

        dies { PDL::DSP::Windows->can($_)->( 1, 2 ) }
            qr/^$basename: alpha must be between 0 and 1/,
            "$_ dies with alpha > 1";
    }
};

subtest 'argument parsing' => sub {
    my $hamming  = window({ N => 10 });
    my $tukey    = window({ N => 10, name => 'tukey', params => 1 });
    my $periodic = window({ N => 10, name => 'tukey', params => 1, per => 1 });

    is_approx window( 10,           'hamming'  ), $hamming;
    is_approx window( 10, { name => 'hamming' }), $hamming;

    is_approx window( 10,           'tukey',              1   ), $tukey;
    is_approx window( 10,           'tukey',             [1]  ), $tukey;
    is_approx window( 10,           'tukey', { params =>  1  }), $tukey;
    is_approx window( 10,           'tukey', { params => [1] }), $tukey;
    is_approx window( 10, { name => 'tukey',   params =>  1  }), $tukey;

    is_approx window( 10, 'tukey',             1,          1  ), $periodic;
    is_approx window( 10, 'tukey',             1, { per => 1 }), $periodic;
    is_approx window( 10, 'tukey', { params => 1,   per => 1 }), $periodic;

    is_approx window( 10, { name => 'tukey', params => 1, per => 1 }),
        $periodic;
};

done_testing;
