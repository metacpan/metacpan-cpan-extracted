use Test::More;

use strict;
use warnings;

use PDL::DSP::Windows;
use Try::Tiny;

use lib 't/lib';
use MyTest::Helper qw( dies );

dies { PDL::DSP::Windows->new( 10, 'foobar' ) }
    qr/^window: unknown .* window 'foobar'/i,
    'Dies if window is unknown';

is ref PDL::DSP::Windows->new, 'PDL::DSP::Windows', 'Has constructor';

subtest 'Default window' => sub {
    my $window = PDL::DSP::Windows->new(10);
    is_deeply [ $window->get( 'N', 'name', 'periodic' ) ],
        [ 10, 'hamming', 0 ],
        'Defaults to symmetric hamming window';
};

subtest 'Empty constructor' => sub {
    is +PDL::DSP::Windows->new->init(10)->samples->nelem, 10,
        'Can initialise windows late';

    is +PDL::DSP::Windows->new(100)->init(10)->samples->nelem, 10,
        'Can override construction parameters with init';

    is +PDL::DSP::Windows->new(100)->new(10)->samples->nelem, 10,
        'Constructor called from instance creates new instance';

    try {
        PDL::DSP::Windows->new->samples;
        fail 'Did not die';
    }
    catch {
        like $_, qr/(?:undefined value|string .*) as a subroutine ref(?:erence)?/,
            'Calling ->samples on uninitialised window dies';
    };

    try {
        PDL::DSP::Windows->new->init;
        fail 'Did not die';
    }
    catch {
        like $_, qr/undefined value/,
            "Can't construct incomplete window";
    };
    try {
        PDL::DSP::Windows->new->init(0);
        fail 'Did not die';
    }
    catch {
        like $_, qr/zero/,
            "Can't construct 0-sized window";
    };
};

subtest 'Simple accesors' => sub {
    is +PDL::DSP::Windows->new(10)->get_N, 10,
        '->get_N returns number of elements';

    is_deeply +PDL::DSP::Windows->new(10)->get_param_names,
        undef,
        '->get_param_names returns undef when parameters do not exist';

    is_deeply +PDL::DSP::Windows->new( 10, 'cauchy' )->get_param_names,
        ['$alpha'],
        '->get_param_names returns param names when they exist';

    is_deeply +PDL::DSP::Windows->new( 10, 'cauchy' )->get_params, undef,
        '->get_params returns undef with no params';

    is_deeply +PDL::DSP::Windows->new( 10, 'cauchy', 3 )->get_params, [3],
        '->get_params returns array ref if window has params';

    is_deeply +PDL::DSP::Windows->new( 10, 'cauchy', 3 )->format_param_vals,
        'alpha = 3',
        '->format_param_vals stringifies params with values';

    is_deeply +PDL::DSP::Windows->new(
            10, 'blackman_gen3', [1, 2, 3]
        )->format_param_vals,
        'a0 = 1, a1 = 2, a2 = 3',
        '->format_param_vals stringifies multiple params with values';

    is +PDL::DSP::Windows->new( 10, 'hamming' )->get_name, 'Hamming window',
        '->get_name returns name from sub name';

    is +PDL::DSP::Windows->new( 10, 'hann_matlab' )->get_name,
        'Hann (matlab) window',
        '->get_name returns alternate short name when provided';

    is +PDL::DSP::Windows->new( 10, 'blackman_gen3' )->get_name,
        '*The general form of the Blackman family. ',
        '->get_name returns long name if no short name is available';

    is +PDL::DSP::Windows->new( 10, 'blackman_nuttall' )->get_name,
        'Blackman-Nuttall window',
        '->get_name returns short name if available';

    my $window = PDL::DSP::Windows->new(10);

    is $window->coherent_gain,
        $window->get_samples->sum / $window->get_samples->nelem,
        '->coherent_gain is average of window samples';

    is $window->process_gain, 1 / $window->enbw,
        '->process_gain is inverse of enbw';
};

subtest 'Samples accesors' => sub {
    my $window = PDL::DSP::Windows->new(10);

    is $window->{samples}, undef,
        'Samples begins as undef';

    delete $window->{samples};
    is ref $window->get_samples, 'PDL',
        '->get_samples defines value';

    delete $window->{samples};
    is ref $window->get('samples'), 'PDL',
        '->get("samples") defines value';

    delete $window->{samples};
    is ref $window->samples, 'PDL',
        '->samples defines value';

    $window->{samples} = [];

    is ref $window->get_samples, 'ARRAY',
        '->get_samples does not redefine value';

    is ref $window->get('samples'), 'ARRAY',
        '->get("samples") does not redefine value';

    is ref $window->samples, 'PDL',
        '->samples redefines value';

    is ref $window->get_samples, 'PDL',
        '->get_samples does not die if samples is already a piddle';
};

subtest 'Modfreqs accesors' => sub {
    my $window = PDL::DSP::Windows->new(10);

    is $window->{modfreqs}, undef,
        'Modfreqs begins as undef';

    delete $window->{modfreqs};
    is ref $window->get_modfreqs, 'PDL',
        '->get_modfreqs defines value';

    delete $window->{modfreqs};
    is ref $window->get('modfreqs'), 'PDL',
        '->get("modfreqs") defines value';

    delete $window->{modfreqs};
    is ref $window->modfreqs, 'PDL',
        '->modfreqs defines value';

    $window->{modfreqs} = [];

    is ref $window->get_modfreqs, 'ARRAY',
        '->get_modfreqs does not redefine value';

    is ref $window->get('modfreqs'), 'ARRAY',
        '->get("modfreqs") does not redefine value';

    is ref $window->modfreqs, 'PDL',
        '->modfreqs redefines value';

    {
        $window->{modfreqs} = [];
        my $freq = $window->get_modfreqs( min_bins => 10_000 );
        is ref $freq, 'PDL',
            '->get_modfreqs redefines values if given parameters';
        # TODO Should this have warned?
        is $freq->nelem, 1_000,
            '->get_modfreqs ignores parameters if not in hashref';
    }

    is ref $window->get_modfreqs, 'PDL',
        '->get_modfreqs does not die if modfreqs is already a piddle';

    {
        $window->{modfreqs} = [];
        my $freq = $window->get_modfreqs({ min_bins => 10_000 });
        is ref $freq, 'PDL',
            '->get_modfreqs redefines values if given parameters';
        is $freq->nelem, 10_000,
            '->get_modfreqs accepts parameters if in hashref';
    }
};

done_testing;
