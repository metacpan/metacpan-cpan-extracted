#!/usr/bin/env perl

use warnings;
use strict;

# compare window functions between
# PDL::Audio and PDL::DSP::Windows

use PDL;
use PDL::Audio qw( gen_fft_window );
use PDL::DSP::Windows qw( window );

use constant N => 5;

for ( ['hamming', 'hamming_ex'], ['hann'], ['welch'], ['bartlett'] ) {
    my ($name_aud, $name_dsp) = @{$_};
    $name_dsp //= $name_aud;

    print "Name: $name_aud $name_dsp\n";

    my $w = gen_fft_window( N, $name_aud );
    print 'aud: ';
    print $w->nelem, ': ', $w, "\n";

    $w = window( N, $name_dsp, { per => 1 } );
    print 'dsp: ';
    print $w->nelem, ': ', $w, "\n";
}
