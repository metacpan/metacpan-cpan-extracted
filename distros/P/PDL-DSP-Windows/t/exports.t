use Test::More;

use strict;
use warnings;

use PDL::DSP::Windows qw(
    chebpoly
    cos_mult_to_pow
    cos_pow_to_mult
    window
    list_windows

    bartlett
    bartlett_hann
    blackman
    blackman_bnh
    blackman_ex
    blackman_gen
    blackman_gen3
    blackman_gen4
    blackman_gen5
    blackman_harris
    blackman_harris4
    blackman_nuttall
    bohman
    cauchy
    chebyshev
    cos_alpha
    cosine
    dpss
    exponential
    flattop
    gaussian
    hamming
    hamming_ex
    hamming_gen
    hann
    hann_matlab
    hann_poisson
    kaiser
    lanczos
    nuttall
    nuttall1
    parzen
    parzen_octave
    poisson
    rectangular
    triangular
    tukey
    welch
);

pass 'Exports OK';

done_testing;
