use Test::More;

use strict;
use warnings;

use PDL::DSP::Windows;

use lib 't/lib';
use MyTest::Helper qw( dies );

my %captured;
*PDL::Graphics::Simple::plot = sub { %captured = %{(grep ref() eq 'HASH', @_)[0]} };
$INC{'PDL/Graphics/Simple.pm'} = 1;
sub do_test {
    my ( $method, $win, $args, $checks ) = @_;
    %captured = ();
    $win->$method($args);
    like $captured{$_}, $checks->{$_}, $win->get_name . ": $_" for keys %{$checks};
}

subtest plot => sub {
    do_test( plot => PDL::DSP::Windows->new(10) => {}, {
        title   => qr/Hamming window/,
        xlabel => qr/Time \(samples\)/,
        ylabel => qr/amplitude/,
    });

    do_test( plot => PDL::DSP::Windows->new( 10, 'blackman_gen3', [1, 2, 3] ) => {}, {
        title => qr/Blackman family. : a0 = 1, a1 = 2, a2 = 3/,
    });
};

subtest plot_freq => sub {
    note 'Default';
    do_test( plot_freq => PDL::DSP::Windows->new(10) => {}, {
        title   => qr/Hamming window, frequency response. ENBW=1.468/,
        xlabel => qr/Fraction of Nyquist frequency/,
        ylabel => qr/frequency response \(dB\)/,
    });

    note 'Samples';
    do_test( plot_freq => PDL::DSP::Windows->new(10) => { coord => 'sample' }, {
        title   => qr/Hamming window, frequency response. ENBW=1.468/,
        xlabel => qr/Fraction of sampling frequency/,
        ylabel => qr/frequency response \(dB\)/,
    });

    note 'bin';
    do_test( plot_freq => PDL::DSP::Windows->new(10) => { coord => 'bin' }, {
        title   => qr/Hamming window, frequency response. ENBW=1.468/,
        xlabel => qr/bin/,
        ylabel => qr/frequency response \(dB\)/,
    });

    note 'Nyquist';
    do_test( plot_freq => PDL::DSP::Windows->new(10) => { coord => 'nyquist' }, {
        title   => qr/Hamming window, frequency response. ENBW=1.468/,
        xlabel => qr/Fraction of Nyquist frequency/,
        ylabel => qr/frequency response \(dB\)/,
    });

    note 'Invalid';
    dies { PDL::DSP::Windows->new(10)->plot_freq({ coord => 'foo' }) }
        qr/Unknown ordinate unit specification/i,
        'plot_freq dies with unknown coord spec';

    note 'With params';
    do_test( plot_freq => PDL::DSP::Windows->new( 10, 'blackman_gen3', [1, 2, 3] ) => {}, {
        title => qr/Blackman family. : a0 = 1, a1 = 2, a2 = 3, frequency response. ENBW=/,
    });
};

done_testing;
