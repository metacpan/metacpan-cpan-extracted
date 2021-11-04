#!/usr/bin/env perl

use Test::More;
use PDL::DSP::Windows;

# FIXME: Why does this appear when running on 5.10?
# See https://perldoc.perl.org/Exporter#Managing-Unknown-Symbols
delete $PDL::DSP::Windows::{EXPORT_FAIL};

is_deeply [ sort keys %PDL::DSP::Windows:: ], [qw(
    BEGIN
    EXPORT
    EXPORT_OK
    PI
    TPI
    VERSION
    bartlett
    bartlett_hann
    bartlett_hann_per
    bartlett_per
    blackman
    blackman_bnh
    blackman_bnh_per
    blackman_ex
    blackman_ex_per
    blackman_gen
    blackman_gen3
    blackman_gen3_per
    blackman_gen4
    blackman_gen4_per
    blackman_gen5
    blackman_gen5_per
    blackman_gen_per
    blackman_harris
    blackman_harris4
    blackman_harris4_per
    blackman_harris_per
    blackman_nuttall
    blackman_nuttall_per
    blackman_per
    bohman
    bohman_per
    cauchy
    cauchy_per
    chebpoly
    chebyshev
    coherent_gain
    cos_alpha
    cos_alpha_per
    cos_mult_to_pow
    cos_pow_to_mult
    cosine
    cosine_per
    dpss
    dpss_per
    enbw
    exponential
    exponential_per
    flattop
    flattop_per
    format_param_vals
    format_plot_param_vals
    gaussian
    gaussian_per
    get
    get_N
    get_modfreqs
    get_name
    get_param_names
    get_params
    get_samples
    hamming
    hamming_ex
    hamming_ex_per
    hamming_gen
    hamming_gen_per
    hamming_per
    hann
    hann_matlab
    hann_per
    hann_poisson
    hann_poisson_per
    import
    init
    kaiser
    kaiser_per
    lanczos
    lanczos_per
    list_windows
    modfreqs
    new
    nuttall
    nuttall1
    nuttall1_per
    nuttall_per
    parzen
    parzen_octave
    parzen_per
    plot
    plot_freq
    poisson
    poisson_per
    process_gain
    rectangular
    rectangular_per
    samples
    scallop_loss
    triangular
    triangular_per
    tukey
    tukey_per
    welch
    welch_per
    window
)] => 'No unexpected methods in namespace';

done_testing;
