use Test::More;

use strict;
use warnings;

use Capture::Tiny 'capture';
use PDL::DSP::Windows qw( list_windows );

my @windows = qw(
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

sub do_test (@);

note 'Can filter windows';
do_test [ grep { /blackman/ } @windows ] => 'blackman';
do_test [ grep { /\d/       } @windows ] => '\d';

note 'Query is inflated to regex';
do_test [ grep { /\d/       } @windows ] => qr/\d/;
do_test \@windows                        => '.';

note 'Defaults to all windows';
do_test \@windows;

note 'Only the first argument is used';
do_test ['tukey'] => qw( tukey nothing else matters welch );

note 'Matches on window aliases';
do_test ['tukey (alias tapered cosine)'] => 'tapered cosine';

sub do_test (@) {
    my $expected = shift;
    my @args = @_;

    my ($stdout) = capture { list_windows(@args) };

    chomp $stdout;

    my $message = @args ? join( ', ', @args ) : 'defaults';

    is $stdout, join( ', ' => @{$expected} ),
        "list_windows using $message";
}

done_testing;
