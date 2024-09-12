package PDL::DSP::Windows;

our $VERSION = '0.101';

use strict;
use warnings;

use PDL::Bad ();
use PDL::Basic ();
use PDL::Core ();
use PDL::FFT ();
use PDL::Math ();
use PDL::MatrixOps ();
use PDL::Ops ();
use PDL::Options ();
use PDL::Primitive ();
use PDL::Ufunc ();

# These constants are deleted at the end of this package
use constant {
    HAVE_LinearAlgebra => eval { require PDL::LinearAlgebra::Special } || 0,
    HAVE_BESSEL        => eval { require PDL::GSLSF::BESSEL }          || 0,
    HAVE_GNUPLOT       => eval { require PDL::Graphics::Gnuplot }      || 0,
    USE_FFTW_DIRECTION => version->parse($PDL::VERSION) <= v2.007,
    I => version->parse($PDL::VERSION) > v2.054 ? PDL::Core::pdl('i') : do {
        require PDL::Complex; # Deprecated in 2.055
        PDL::Complex::i();
    },
};

# These constants are left in our namespace for historical reasons
use constant PI  => 4 * atan2(1, 1);
use constant TPI => 2 * PI;

use Exporter 'import';

my %symmetric_windows = (
    bartlett         => 1,
    bartlett_hann    => 1,
    blackman         => 1,
    blackman_bnh     => 1,
    blackman_ex      => 1,
    blackman_gen     => 1,
    blackman_gen3    => 1,
    blackman_gen4    => 1,
    blackman_gen5    => 1,
    blackman_harris  => 1,
    blackman_harris4 => 1,
    blackman_nuttall => 1,
    bohman           => 1,
    cauchy           => 1,
    chebyshev        => 1,
    cos_alpha        => 1,
    cosine           => 1,
    dpss             => 1,
    exponential      => 1,
    flattop          => 1,
    gaussian         => 1,
    hamming          => 1,
    hamming_ex       => 1,
    hamming_gen      => 1,
    hann             => 1,
    hann_matlab      => 1,
    hann_poisson     => 1,
    kaiser           => 1,
    lanczos          => 1,
    nuttall          => 1,
    nuttall1         => 1,
    parzen           => 1,
    parzen_octave    => 1,
    poisson          => 1,
    rectangular      => 1,
    triangular       => 1,
    tukey            => 1,
    welch            => 1,
);

# These are not exported
my %periodic_windows = (
    bartlett         => 1,
    bartlett_hann    => 1,
    blackman         => 1,
    blackman_bnh     => 1,
    blackman_ex      => 1,
    blackman_gen     => 1,
    blackman_gen3    => 1,
    blackman_gen4    => 1,
    blackman_gen5    => 1,
    blackman_harris  => 1,
    blackman_harris4 => 1,
    blackman_nuttall => 1,
    bohman           => 1,
    cauchy           => 1,
    cos_alpha        => 1,
    cosine           => 1,
    dpss             => 1,
    exponential      => 1,
    flattop          => 1,
    gaussian         => 1,
    hamming          => 1,
    hamming_ex       => 1,
    hamming_gen      => 1,
    hann             => 1,
    hann_poisson     => 1,
    kaiser           => 1,
    lanczos          => 1,
    nuttall          => 1,
    nuttall1         => 1,
    parzen           => 1,
    poisson          => 1,
    rectangular      => 1,
    triangular       => 1,
    tukey            => 1,
    welch            => 1,
);

my %window_aliases = (
    bartlett_hann    => [ 'Modified Bartlett-Hann' ],
    bartlett         => [ 'fejer' ],
    blackman_harris4 => [ 'Blackman-Harris' ],
    blackman_harris  => [ 'Minimum three term (sample) Blackman-Harris' ],
    cauchy           => [ 'Abel', 'Poisson' ],
    chebyshev        => [ 'Dolph-Chebyshev' ],
    cos_alpha        => [ 'Power-of-cosine' ],
    cosine           => [ 'sine' ],
    dpss             => [ 'sleppian' ],
    gaussian         => [ 'Weierstrass' ],
    hann             => [ 'hanning' ],
    kaiser           => [ 'Kaiser-Bessel' ],
    lanczos          => [ 'sinc' ],
    parzen           => [ 'Jackson', 'Valle-Poussin' ],
    rectangular      => [ 'dirichlet', 'boxcar' ],
    tukey            => [ 'tapered cosine' ],
    welch            => [ 'Riez', 'Bochner', 'Parzen', 'parabolic' ],
);

my %window_parameters = (
    blackman_gen  => [ '$alpha' ],
    blackman_gen3 => [ '$a0', '$a1', '$a2' ],
    blackman_gen4 => [ '$a0', '$a1', '$a2', '$a3' ],
    blackman_gen5 => [ '$a0', '$a1', '$a2', '$a3', '$a4' ],
    cauchy        => [ '$alpha' ],
    chebyshev     => [ '$at' ],
    cos_alpha     => [ '$alpha' ],
    dpss          => [ '$beta' ],
    gaussian      => [ '$beta' ],
    hamming_gen   => [ '$a' ],
    hann_poisson  => [ '$alpha' ],
    kaiser        => [ '$beta' ],
    poisson       => [ '$alpha' ],
    tukey         => [ '$alpha' ],
);

my %window_names = (
    bartlett_hann    => 'Bartlett-Hann',
    blackman_bnh     => '*An improved version of the 3-term Blackman-Harris window given by Nuttall (Ref 2, p. 89).',
    blackman_ex      => q!'exact' Blackman!,
    blackman_gen     => '*A single parameter family of the 3-term Blackman window. ',
    blackman_gen3    => '*The general form of the Blackman family. ',
    blackman_gen4    => '*The general 4-term Blackman-Harris window. ',
    blackman_gen5    => '*The general 5-term Blackman-Harris window. ',
    blackman_harris4 => 'minimum (sidelobe) four term Blackman-Harris',
    blackman_harris  => 'Blackman-Harris',
    blackman_nuttall => 'Blackman-Nuttall',
    blackman         => q!'classic' Blackman!,
    dpss             => 'Digital Prolate Spheroidal Sequence (DPSS)',
    flattop          => 'flat top',
    hamming_ex       => q!'exact' Hamming!,
    hamming_gen      => 'general Hamming',
    hann_matlab      => '*Equivalent to the Hann window of N+2 points, with the endpoints (which are both zero) removed.',
    hann_poisson     => 'Hann-Poisson',
    nuttall1         => '*A window referred to as the Nuttall window.',
    parzen_octave    => 'Parzen',
);

my %window_print_names = (
    blackman_bnh => 'Blackman-Harris (bnh)',
    blackman_gen => 'General classic Blackman',
    hann_matlab  => 'Hann (matlab)',
    nuttall1     => 'Nuttall (v1)',
);

our @EXPORT_OK = (
    keys %symmetric_windows,
    qw( window list_windows chebpoly cos_mult_to_pow cos_pow_to_mult ),
);

$PDL::onlinedoc->scan(__FILE__) if $PDL::onlinedoc;

=encoding utf8

=head1 NAME

PDL::DSP::Windows - Window functions for signal processing

=head1 SYNOPSIS

    use PDL;
    use PDL::DSP::Windows 'window';

    # Get a piddle with a window's samples with the helper
    my $samples = window( 10, tukey => { params => .5 });

    # Or construct a window object with the same parameters
    my $window = PDL::DSP::Windows->new( 10, tukey => { params => .5 });

    # These two are equivalent
    $samples = $window->samples;

    # The window object gives access to additional methods
    print $window->coherent_gain, "\n";

    $window->plot; # Requires PDL::Graphics::Gnuplot

=head1 DESCRIPTION

This module provides symmetric and periodic (DFT-symmetric) window functions
for use in filtering and spectral analysis. It provides a high-level access
subroutine L</window>. This functional interface is sufficient for getting
the window samples. For analysis and plotting, etc. an object oriented
interface is provided. The functional subroutines must be either explicitly
exported, or fully qualified. In this document, the word I<function> refers
only to the mathematical window functions, while the word I<subroutine> is
used to describe code.

Window functions are also known as apodization functions or tapering functions.
In this module, each of these functions maps a sequence of C<$N> integers to
values called a B<samples>. (To confuse matters, the word I<sample> also has
other meanings when describing window functions.) The functions are often
named for authors of journal articles. Be aware that across the literature
and software, some functions referred to by several different names, and some
names refer to several different functions. As a result, the choice of window
names is somewhat arbitrary.

The L</kaiser($N,$beta)> window function requires L<PDL::GSLSF::BESSEL>. The
L</dpss($N,$beta)> window function requires L<PDL::LinearAlgebra>. But the
remaining window functions may be used if these modules are not installed.

The most common and easiest usage of this module is indirect, via some
higher-level filtering interface, such as L<PDL::DSP::Fir::Simple>. The next
easiest usage is to return a pdl of real-space samples with the subroutine
L</window>. Finally, for analyzing window functions, object methods, such as
L</new>, L</plot>, L</plot_freq> are provided.

In the following, first the functional interface (non-object oriented) is
described in L</'FUNCTIONAL INTERFACE'>. Next, the object methods are
described in L</METHODS>. Next the low-level subroutines returning samples
for each named window are described in  L</'WINDOW FUNCTIONS'>. Finally, some
support routines that may be of interest are described in
L</'AUXILIARY SUBROUTINES'>.

=head1 FUNCTIONAL INTERFACE

=head2 window

    $win = window({ OPTIONS });
    $win = window( $N, { OPTIONS });
    $win = window( $N, $name, { OPTIONS });
    $win = window( $N, $name, $params, { OPTIONS });
    $win = window( $N, $name, $params, $periodic );

Returns an C<$N> point window of type C<$name>. The arguments may be passed
positionally in the order C<$N, $name, $params, $periodic>, or they may be
passed by name in the hash C<OPTIONS>.

=head3 EXAMPLES

    # Each of the following return a 100 point symmetric hamming window.

    $win = window(100);
    $win = window( 100, 'hamming' );
    $win = window( 100, { name => 'hamming' });
    $win = window({ N => 100, name => 'hamming' });

    # Each of the following returns a 100 point symmetric hann window.

    $win = window( 100, 'hann' );
    $win = window( 100, { name => 'hann' });

    # Returns a 100 point periodic hann window.

    $win = window( 100, 'hann', { periodic => 1 });

    # Returns a 100 point symmetric Kaiser window with alpha = 2.

    $win = window( 100, 'kaiser', { params => 2 });

=head3 OPTIONS

The options follow default PDL::Options rules. They may be abbreviated, and
are case-insensitive.

=over

=item B<name>

(string) name of window function. Default: C<hamming>. This selects one of
the window functions listed below. Note that the suffix '_per', for periodic,
may be ommitted. It is specified with the option C<< periodic => 1 >>

=item B<params>

ref to array of parameter or parameters for the  window-function subroutine.
Only some window-function subroutines take parameters. If the subroutine takes
a single parameter, it may be given either as a number, or a list of one
number. For example C<3> or C<[3]>.

=item B<N>

number of points in window function (the same as the order of the filter).
As of 0.102, throws exception if the value for C<N> is undefined or zero.

=item B<periodic>

If value is true, return a periodic rather than a symmetric window function.
Defaults to false, meaning "symmetric".

=back

=cut

sub window { PDL::DSP::Windows->new(@_)->samples }

=head2 list_windows

    list_windows
    list_windows STR

C<list_windows> prints the names all of the available windows.
C<list_windows STR> prints only the names of windows matching the string C<STR>.

=cut

sub list_windows {
    my ($expr) = @_;

    my @match;
    if ($expr) {
        for my $name ( sort keys %symmetric_windows ) {
            if ( $name =~ /$expr/ ) {
                push @match, $name;
                next;
            }

            push @match,
                map "$name (alias $_)",
                grep /$expr/i, @{ $window_aliases{$name} // [] };
        }
    }
    else {
        @match = sort keys %symmetric_windows;
    }

    print join( ', ', @match ), "\n";
}

=head1 METHODS

=head2 new

=for usage

    my $win = PDL::DSP::Windows->new(ARGS);

=for ref

Create an instance of a window object. If C<ARGS> are given, the instance
is initialized. C<ARGS> are interpreted in exactly the same way as arguments
for the L</window> subroutine.

=for example

For example:

    my $win1 = PDL::DSP::Windows->new( 8, 'hann' );
    my $win2 = PDL::DSP::Windows->new({ N => 8, name => 'hann' });

=cut

sub new {
  my $proto = shift;
  my $self  = bless {}, ref $proto || $proto;
  $self->init(@_) if @_;
  return $self;
}

=head2 init

=for usage

    $win->init(ARGS);

=for ref

Initialize (or reinitialize) a window object. C<ARGS> are interpreted in
exactly the same way as arguments for the L</window> subroutine.
As of 0.102, throws exception if the value for C<N> is undefined or zero.

=for example

For example:

    my $win = PDL::DSP::Windows->new( 8, 'hann' );
    $win->init( 10, 'hamming' );

=cut

sub init {
    my $self = shift;

    my ( $N, $name, $params, $periodic );

    $N        = shift unless ref $_[0];
    $name     = shift unless ref $_[0];
    $params   = shift unless ref $_[0] eq 'HASH';
    $periodic = shift unless ref $_[0];

    my $opts = PDL::Options->new({
        name     => 'hamming',
        periodic => 0,          # symmetric or periodic
        N        => undef,      # order
        params   => undef,
    })->options( shift // {} );

    $name     ||= $opts->{name};
    $N        //= $opts->{N};
    $periodic ||= $opts->{periodic};
    $params   //= $opts->{params};
    $params   = [$params] if defined $params && !ref $params;

    $name =~ s/_per$//;

    my $windows = $periodic ? \%periodic_windows : \%symmetric_windows;
    unless ( $windows->{$name}) {
        my $type = $periodic ? 'periodic' : 'symmetric';
        PDL::Core::barf "window: Unknown $type window '$name'.";
    }

    $self->{name}     = $name;
    $self->{N}        = $N // die "Can't continue with undefined value for N";
    die "Can't continue with zero value for N" if !$self->{N};
    $self->{periodic} = $periodic;
    $self->{params}   = $params;
    $self->{code}     = __PACKAGE__->can( $name . ( $periodic ? '_per' : '' ) );
    $self->{samples}  = undef;
    $self->{modfreqs} = undef;

    return $self;
}

=head2 samples

=for usage

    $win->samples;

=for ref

Generate and return a reference to the piddle of C<$N> samples for the window
C<$win>. This is the real-space representation of the window.

The samples are stored in the object C<$win>, but are regenerated every time
C<samples> is invoked. See the method L</get_samples> below.

=for example

For example:

    my $win = PDL::DSP::Windows->new( 8, 'hann' );
    print $win->samples, "\n";

=cut

sub samples {
    my $self = shift;
    my @args = ( $self->{N}, @{ $self->{params} // [] } );
    $self->{samples} = $self->{code}->(@args);
}

=head2 modfreqs

=for usage

    $win->modfreqs;

=for ref

Generate and return a reference to the piddle of the modulus of the fourier
transform of the samples for the window C<$win>.

These values are stored in the object C<$win>, but are regenerated every time
C<modfreqs> is invoked. See the method L</get_modfreqs> below.

=head3 options

=over

=item min_bins => MIN

This sets the minimum number of frequency bins. Defaults to 1000. If necessary,
the piddle of window samples are padded with zeroes before the fourier transform
is performed.

=back

=cut

sub modfreqs {
    my $self = shift;
    my %opts = PDL::Options::iparse( { min_bins => 1000 }, PDL::Options::ifhref(shift) );

    my $data = $self->get_samples;

    my $n = $data->nelem;
    my $fn = $n > $opts{min_bins} ? 2 * $n : $opts{min_bins};

    $n--;

    my $freq = PDL::Core::zeroes($fn);
    $freq->slice("0:$n") .= $data;

    PDL::FFT::realfft($freq);

    my $real = PDL::Core::zeroes($freq);
    my $img  = PDL::Core::zeroes($freq);
    my $mid  = ( $freq->nelem ) / 2 - 1;
    my $mid1 = $mid + 1;

    $real->slice("0:$mid")   .= $freq->slice("$mid:0:-1");
    $real->slice("$mid1:-1") .= $freq->slice("0:$mid");
    $img->slice("0:$mid")    .= $freq->slice("-1:$mid1:-1");
    $img->slice("$mid1:-1")  .= $freq->slice("$mid1:-1");

    return $self->{modfreqs} = $real ** 2 + $img ** 2;
}

=head2 get

=for usage

    my $windata = $win->get('samples');

=for ref

Get an attribute (or list of attributes) of the window C<$win>. If attribute
C<samples> is requested, then the samples are created with the method
L</samples> if they don't exist.

=for example

For example:

    my $win = PDL::DSP::Windows->new( 8, 'hann' );
    print $win->get('samples'), "\n";

=cut

sub get {
    my $self = shift;
    my @res;

    for (@_) {
        if ($_ eq 'samples') {
            push @res, $self->get_samples;
        }
        elsif ($_ eq 'modfreqs') {
            push @res, $self->get_modfreqs;
        }
        else {
            push @res, $self->{$_};
        }
    };

    return wantarray ? @res : $res[0];
}

=head2 get_samples

=for usage

    my $windata = $win->get_samples;

=for ref

Return a reference to the pdl of samples for the Window instance C<$win>. The
samples will be generated with the method L</samples> if and only if they have
not yet been generated.

=cut

sub get_samples {
    my $self = shift;
    return $self->{samples} if defined $self->{samples};
    return $self->samples;
}

=head2 get_modfreqs

=for usage

    my $winfreqs = $win->get_modfreqs;
    my $winfreqs = $win->get_modfreqs(OPTS);

=for ref

Return a reference to the pdl of the frequency response (modulus of the DFT)
for the Window instance C<$win>.

Options passed as a hash reference will be passed to the L</modfreqs>. The
data are created with L</modfreqs> if they don't exist. The data are also
created even if they already exist if options are supplied. Otherwise the
cached data are returned.

=head3 options

=over

=item min_bins => MIN

This sets the minimum number of frequency bins. See L</modfreqs>. Defaults
to 1000.

=back

=cut

sub get_modfreqs {
    my $self = shift;
    return $self->modfreqs(@_) if @_;
    return $self->{modfreqs} if defined $self->{modfreqs};
    return $self->modfreqs;
}

=head2 get_params

=for usage

    my $params = $win->get_params;

=for ref

Create a new array containing the parameter values for the instance C<$win>
and return a reference to the array. Note that not all window types take
parameters.

=cut

sub get_params { shift->{params} }

sub get_N { shift->{N} }

=head2 get_name

=for usage

    print  $win->get_name, "\n";

=for ref

Return a name suitable for printing associated with the window C<$win>. This is
something like the name used in the documentation for the particular window
function. This is static data and does not depend on the instance.

=cut

sub get_name {
    my $self = shift;

    if ( my $name = $window_print_names{ $self->{name} } ) {
        return "$name window";
    }

    if ( my $name = $window_names{ $self->{name} } ) {
        return "$name window" unless $name =~ /^\*/;
        return $name;
    }

    return ucfirst $self->{name} . ' window';
}

sub get_param_names {
    my $self = shift;
    my $params = $window_parameters{ $self->{name} };
    return undef unless $params;
    return [ @{$params} ];
}

sub format_param_vals {
    my $self = shift;

    my @params = @{ $self->{params} || [] };
    return '' unless @params;

    my @names = @{ $self->get_param_names || [] };
    return '' unless @names;

    join ', ', map {
        my $name = $names[$_];
        $name =~ s/^\$//;
        join' = ', $name, $params[$_];
    } 0 .. $#params;
}

sub format_plot_param_vals {
    my $ps = shift->format_param_vals;
    return $ps ? ": $ps" : $ps;
}

=head2 plot

=for usage

    $win->plot;

=for ref

Plot the samples. Currently, only L<PDL::Graphics::Gnuplot> is supported. The
default display type is used.

=cut

sub plot {
    my $self = shift;
    PDL::Core::barf 'PDL::DSP::Windows::plot Gnuplot not available!' unless HAVE_GNUPLOT;

    PDL::Graphics::Gnuplot::plot(
        title  => $self->get_name . $self->format_plot_param_vals,
        xlabel => 'Time (samples)',
        ylabel => 'amplitude',
        $self->get_samples,
    );

    return $self;
}

=head2 plot_freq

=for usage

Can be called like this

    $win->plot_freq;

Or this

    $win->plot_freq({ ordinate => ORDINATE });

=for ref

Plot the frequency response (magnitude of the DFT of the window samples).
The response is plotted in dB, and the frequency (by default) as a fraction of
the Nyquist frequency. Currently, only L<PDL::Graphics::Gnuplot> is supported.
The default display type is used.

=head3 options

=over

=item coord => COORD

This sets the units of frequency of the co-ordinate axis. C<COORD> must be one
of C<nyquist>, for fraction of the nyquist frequency (range C<-1, 1>);
C<sample>, for fraction of the sampling frequncy (range C<-0.5, 0.5>); or
C<bin> for frequency bin number (range C<0, $N - 1>). The default value is
C<nyquist>.

=item min_bins => MIN

This sets the minimum number of frequency bins. See L</get_modfreqs>.
Defaults to 1000.

=back

=cut

sub plot_freq {
    my $self = shift;

    PDL::Core::barf 'PDL::DSP::Windows::plot Gnuplot not available!' unless HAVE_GNUPLOT;

    my $opts = new PDL::Options({
        coord    => 'nyquist',
        min_bins => 1000
    })->options( @_ ? shift : {} );

    my $mf = $self->get_modfreqs({ min_bins => $opts->{min_bins} });
    $mf /= $mf->max;

    my $title = $self->get_name . $self->format_plot_param_vals
        . ', frequency response. ENBW=' . sprintf( '%2.3f', $self->enbw );

    my $coord = $opts->{coord};

    my ( $coordinate_range, $xlab );

    if ($coord eq 'nyquist') {
        $coordinate_range = 1;
        $xlab = 'Fraction of Nyquist frequency';
    }
    elsif ($coord eq 'sample') {
        $coordinate_range = 0.5;
        $xlab = 'Fraction of sampling frequency';
    }
    elsif ($coord eq 'bin') {
        $coordinate_range = $self->{N} / 2;
        $xlab = 'bin';
    }
    else {
        PDL::Core::barf "plot_freq: Unknown ordinate unit specification $coord";
    }

    my $ylab = 'frequency response (dB)';
    my $coordinates = PDL::Core::zeroes($mf)
        ->xlinvals( -$coordinate_range, $coordinate_range );

    PDL::Graphics::Gnuplot::plot(
        title  => $title,
        xmin   => -$coordinate_range,
        xmax   => $coordinate_range,
        xlabel => $xlab,
        ylabel => $ylab,
        with => 'line',
        $coordinates,
        20 * PDL::Ops::log10($mf),
    );

    return $self;
}

=head2 enbw

=for usage

    $win->enbw;

=for ref

Compute and return the equivalent noise bandwidth of the window.

=cut

sub enbw {
    my $w = shift->get_samples;
    $w->nelem * ( $w ** 2 )->sum / $w->sum ** 2;
}

=head2 coherent_gain

=for usage

    $win->coherent_gain;

=for ref

Compute and return the coherent gain (the dc gain) of the window. This is just
the average of the samples.

=cut

sub coherent_gain {
    my $w = shift->get_samples;
    $w->sum / $w->nelem;
}


=head2 process_gain

=for usage

    $win->coherent_gain;

=for ref

Compute and return the processing gain (the dc gain) of the window. This is
just the multiplicative inverse of the C<enbw>.

=cut

sub process_gain { 1 / shift->enbw }

# not quite correct for some reason.
# Seems like 10*log10(this) / 1.154
# gives the correct answer in decibels

=head2 scallop_loss

=for usage

    $win->scallop_loss;

=for ref

Compute and return the scalloping loss of the window.

=cut

sub scallop_loss {
    my $w = shift->samples;

    # Adapted from https://stackoverflow.com/a/40912607
    my $num = $w * exp( -( I()->im * PDL::sequence($w) * PI / $w->nelem ) );

    20 * PDL::Ops::log10( abs( $num->sum ) / abs($w)->sum );
}

=head1 WINDOW FUNCTIONS

These window-function subroutines return a pdl of C<$N> samples. For most
windows, there are a symmetric and a periodic version. The symmetric versions
are functions of C<$N> points, uniformly spaced, and taking values from x_lo
through x_hi. Here, a periodic function of C< $N > points is equivalent to its
symmetric counterpart of C<$N + 1> points, with the final point omitted. The
name of a periodic window-function subroutine is the same as that for the
corresponding symmetric function, except it has the suffix C<_per>. The
descriptions below describe the symmetric version of each window.

The term 'Blackman-Harris family' is meant to include the Hamming family and
the Blackman family. These are functions of sums of cosines.

Unless otherwise noted, the arguments in the cosines of all symmetric window
functions are multiples of C<$N> numbers uniformly spaced from 0 through
2π.

=cut

sub bartlett {
    PDL::Core::barf 'bartlett: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    1 - abs( PDL::Core::zeroes($N)->xlinvals( -1, 1 ) );
}

sub bartlett_per {
    PDL::Core::barf 'bartlett: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    1 - abs( PDL::Core::zeroes($N)->xlinvals( -1, ( -1 + 1 * ( $N - 1 ) ) / $N ) );
}

sub bartlett_hann {
    PDL::Core::barf 'bartlett_hann: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    0.62 - 0.48 * abs( PDL::Core::zeroes($N)->xlinvals( -0.5, 0.5 ) )
        + 0.38 * cos( PDL::Core::zeroes($N)->xlinvals( - PI, PI ) );
}

sub bartlett_hann_per {
    PDL::Core::barf 'bartlett_hann: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    0.62 - 0.48 * abs( PDL::Core::zeroes($N)->xlinvals( -0.5, ( -0.5 + 0.5 * ( $N - 1 ) ) / $N ) )
        + 0.38 * cos( PDL::Core::zeroes($N)->xlinvals( - PI, ( - PI + PI * ( $N - 1 ) ) / $N ) );
}

sub blackman {
    PDL::Core::barf 'blackman: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    0.34 + $cx * ( -0.5 + $cx * 0.16 );
}

sub blackman_per {
    PDL::Core::barf 'blackman: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    0.34 + $cx * ( -0.5 + $cx * 0.16 );
}

sub blackman_bnh {
    PDL::Core::barf 'blackman_bnh: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    0.3461008 + $cx * ( -0.4973406 + $cx * 0.1565586 );
}

sub blackman_bnh_per {
    PDL::Core::barf 'blackman_bnh: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    0.3461008 + $cx * ( -0.4973406 + $cx * 0.1565586 );
}

sub blackman_ex {
    PDL::Core::barf 'blackman_ex: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    0.349742046431642 + $cx * ( -0.496560619088564 + $cx * 0.153697334479794 );
}

sub blackman_ex_per {
    PDL::Core::barf 'blackman_ex: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    0.349742046431642 + $cx * ( -0.496560619088564 + $cx * 0.153697334479794 );
}

sub blackman_gen {
    PDL::Core::barf 'blackman_gen: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $alpha ) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    0.5 - $alpha + $cx * ( -0.5 + $cx * $alpha );
}

sub blackman_gen_per {
    PDL::Core::barf 'blackman_gen: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ($N,$alpha) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    0.5 - $alpha + $cx * ( -0.5 + $cx * $alpha );
}

sub blackman_gen3 {
    PDL::Core::barf 'blackman_gen3: 4 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 4;
    my ($N,$a0,$a1,$a2) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    $a0 - $a2 + ( $cx * ( -$a1 + $cx * 2 * $a2 ) );
}

sub blackman_gen3_per {
    PDL::Core::barf 'blackman_gen3: 4 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 4;
    my ( $N, $a0, $a1, $a2 ) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    $a0 - $a2 + ( $cx * ( -$a1 + $cx * 2 * $a2 ) );
}

sub blackman_gen4 {
    PDL::Core::barf 'blackman_gen4: 5 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 5;
    my ( $N, $a0, $a1, $a2, $a3 ) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    $a0 - $a2 + $cx * ( ( -$a1 + 3 * $a3 ) + $cx * ( 2 * $a2 + $cx * -4 * $a3 ) );
}

sub blackman_gen4_per {
    PDL::Core::barf 'blackman_gen4: 5 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 5;
    my ( $N, $a0, $a1, $a2, $a3 ) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    $a0 - $a2 + $cx * ( ( -$a1 + 3 * $a3 ) + $cx * ( 2 * $a2 + $cx * -4 * $a3 ) );
}

sub blackman_gen5 {
    PDL::Core::barf 'blackman_gen5: 6 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 6;
    my ( $N, $a0, $a1, $a2, $a3, $a4 ) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    $a0 - $a2 + $a4 + $cx * ( ( -$a1 + 3 * $a3 )
        + $cx * ( 2 * $a2 - 8 * $a4 + $cx * ( -4 * $a3 + $cx * 8 * $a4 ) ) );
}

sub blackman_gen5_per {
    PDL::Core::barf 'blackman_gen5: 6 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 6;
    my ( $N, $a0, $a1, $a2, $a3, $a4 ) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    $a0 - $a2 + $a4 + $cx * ( ( -$a1 + 3 * $a3 )
        + $cx * ( 2 * $a2 - 8 * $a4 + $cx * ( -4 * $a3 + $cx * 8 * $a4 ) ) );
}

sub blackman_harris {
    PDL::Core::barf 'blackman_harris: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    0.343103 + $cx * ( -0.49755 + $cx * 0.15844 );
}

sub blackman_harris_per {
    PDL::Core::barf 'blackman_harris: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    0.343103 + $cx * ( -0.49755 + $cx * 0.15844 );
}

sub blackman_harris4 {
    PDL::Core::barf 'blackman_harris4: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    0.21747 + $cx * ( -0.45325 + $cx * ( 0.28256 + $cx * -0.04672 ) );
}

sub blackman_harris4_per {
    PDL::Core::barf 'blackman_harris4: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    0.21747 + $cx * ( -0.45325 + $cx * ( 0.28256 + $cx * -0.04672 ) );
}

sub blackman_nuttall {
    PDL::Core::barf 'blackman_nuttall: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    0.2269824 + $cx * ( -0.4572542 + $cx * ( 0.273199 + $cx * -0.0425644 ) );
}

sub blackman_nuttall_per {
    PDL::Core::barf 'blackman_nuttall: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    0.2269824 + $cx * ( -0.4572542 + $cx * ( 0.273199 + $cx * -0.0425644 ) );
}

sub bohman {
    PDL::Core::barf 'bohman: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $x = abs( PDL::Core::zeroes($N)->xlinvals( -1, 1 ) );
    ( 1 - $x ) * cos( PI * $x ) + ( 1 / PI ) * sin( PI * $x );
}

sub bohman_per {
    PDL::Core::barf 'bohman: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $x = abs( PDL::Core::zeroes($N)->xlinvals( -1, ( -1 + 1 * ( $N - 1 ) ) / $N ) );
    ( 1 - $x ) * cos( PI * $x ) + ( 1 / PI ) * sin( PI * $x );
}

sub cauchy {
    PDL::Core::barf 'cauchy: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $alpha ) = @_;
    1 / ( 1 + ( PDL::Core::zeroes($N)->xlinvals( -1, 1 ) * $alpha ) ** 2 );
}

sub cauchy_per {
    PDL::Core::barf 'cauchy: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $alpha ) = @_;
    1 / ( 1 + ( PDL::Core::zeroes($N)->xlinvals( -1, ( -1 + 1 * ( $N - 1 ) ) / $N ) * $alpha ) ** 2 );
}

sub chebyshev {
    PDL::Core::barf 'chebyshev: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $at ) = @_;

    my ( $M, $M1, $pos, $pos1 );

    my $beta = PDL::Math::cosh( 1 / ( $N - 1 ) * PDL::Math::acosh( 1 / ( 10 ** ( -$at / 20 ) ) ) );
    my $x    = $beta * cos( PI * PDL::Basic::sequence($N) / $N );

    my $cw = chebpoly( $N - 1, $x );

    if ( $N % 2 ) {  # odd
        $M1   = ( $N + 1 ) / 2;
        $M    = $M1 - 1;
        $pos  = 0;
        $pos1 = 1;

        PDL::FFT::realfft($cw);
    }
    else { # half-sample delay (even order)
        my $arg   = PI / $N * PDL::Basic::sequence($N);
        my $cw_im = $cw * sin($arg);
        $cw *= cos($arg);

        if (USE_FFTW_DIRECTION) {
            PDL::FFT::fftnd( $cw, $cw_im );
        }
        else {
            PDL::FFT::ifftnd( $cw, $cw_im );
        }

        $M1   = $N / 2;
        $M    = $M1 - 1;
        $pos  = 1;
        $pos1 = 0;
    }

    $cw /= $cw->at($pos);

    my $cwout = PDL::Core::zeroes($N);

    $cwout->slice("0:$M")   .= $cw->slice("$M:0:-1");
    $cwout->slice("$M1:-1") .= $cw->slice("$pos1:$M");
    $cwout /= PDL::Ufunc::max($cwout);

    $cwout;
}

sub cos_alpha {
    PDL::Core::barf 'cos_alpha: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $alpha ) = @_;
    ( sin( PDL::Core::zeroes($N)->xlinvals( 0, PI ) ) ) ** $alpha ;
}

sub cos_alpha_per {
    PDL::Core::barf 'cos_alpha: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $alpha ) = @_;
    sin( PDL::Core::zeroes($N)->xlinvals( 0, PI * ( $N - 1 ) / $N ) ) ** $alpha ;
}

sub cosine {
    PDL::Core::barf 'cosine: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    sin( PDL::Core::zeroes($N)->xlinvals( 0, PI ) );
}

sub cosine_per {
    PDL::Core::barf 'cosine: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    sin( PDL::Core::zeroes($N)->xlinvals( 0, PI * ( $N - 1 ) / $N ) );
}

sub dpss {
    PDL::Core::barf 'dpss: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $beta ) = @_;

    PDL::Core::barf 'dpss: PDL::LinearAlgebra not installed.' unless HAVE_LinearAlgebra;
    PDL::Core::barf "dpss: $beta not between 0 and $N." unless $beta >= 0 and $beta <= $N;

    $beta /= $N / 2;

    my $k = PDL::Basic::sequence($N);
    my $s = sin( PI * $beta * $k ) / $k;

    $s->slice('0') .= $beta;

    my ( $ev, $e ) = PDL::MatrixOps::eigens_sym( PDL::LinearAlgebra::Special::mtoeplitz($s) );
    my $i = $e->maximum_ind;

    $ev->slice("($i)")->copy;
}

sub dpss_per {
    PDL::Core::barf 'dpss: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $beta ) = @_;
    $N++;

    PDL::Core::barf 'dpss: PDL::LinearAlgebra not installed.' unless HAVE_LinearAlgebra;
    PDL::Core::barf "dpss: $beta not between 0 and $N." unless $beta >= 0 and $beta <= $N;

    $beta /= $N / 2;

    my $k = PDL::Basic::sequence($N);
    my $s = sin( PI * $beta * $k ) / $k;

    $s->slice('0') .= $beta;

    my ( $ev, $e ) = PDL::MatrixOps::eigens_sym( PDL::LinearAlgebra::Special::mtoeplitz($s) );
    my $i = $e->maximum_ind;

    $ev->slice("($i),0:-2")->copy;
}

sub exponential {
    PDL::Core::barf 'exponential: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    2 ** ( 1 - abs( PDL::Core::zeroes($N)->xlinvals( -1, 1 ) ) ) - 1;
}

sub exponential_per {
    PDL::Core::barf 'exponential: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    2 ** ( 1 - abs( PDL::Core::zeroes($N)->xlinvals( -1, ( -1 + 1 * ( $N - 1 ) ) / $N ) ) ) - 1;
}

sub flattop {
    PDL::Core::barf 'flattop: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    -0.05473684 + $cx * ( -0.165894739 + $cx * ( 0.498947372 + $cx * ( -0.334315788 + $cx * 0.055578944 ) ) );
}

sub flattop_per {
    PDL::Core::barf 'flattop: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    -0.05473684 + $cx * ( -0.165894739 + $cx * ( 0.498947372 + $cx * ( -0.334315788 + $cx * 0.055578944 ) ) );
}

sub gaussian {
    PDL::Core::barf 'gaussian: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $beta ) = @_;
    exp( -0.5 * ( $beta * PDL::Core::zeroes($N)->xlinvals( -1, 1 ) ) ** 2);
}

sub gaussian_per {
    PDL::Core::barf 'gaussian: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $beta ) = @_;
    exp( -0.5 * ( $beta * PDL::Core::zeroes($N)->xlinvals( -1, ( -1 + 1 * ( $N - 1 ) ) / $N ) ) ** 2 );
}

sub hamming {
    PDL::Core::barf 'hamming: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    0.54 + -0.46 * cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
}

sub hamming_per {
    PDL::Core::barf 'hamming: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    0.54 + -0.46 * cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
}

sub hamming_ex {
    PDL::Core::barf 'hamming_ex: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    0.53836 + -0.46164 * cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
}

sub hamming_ex_per {
    PDL::Core::barf 'hamming_ex: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    0.53836 + -0.46164 * cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
}

sub hamming_gen {
    PDL::Core::barf 'hamming_gen: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $a ) = @_;
    $a - ( 1 - $a ) * cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
}

sub hamming_gen_per {
    PDL::Core::barf 'hamming_gen: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $a ) = @_;
    $a - ( 1 - $a ) * cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
}

sub hann {
    PDL::Core::barf 'hann: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    0.5 + -0.5 * cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
}

sub hann_per {
    PDL::Core::barf 'hann: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    0.5 + -0.5 * cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
}

sub hann_matlab {
    PDL::Core::barf 'hann_matlab: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    0.5 - 0.5 * cos( PDL::Core::zeroes($N)->xlinvals( TPI / ( $N + 1 ), TPI * $N / ( $N + 1 ) ) );
}

sub hann_poisson {
    PDL::Core::barf 'hann_poisson: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $alpha ) = @_;
    0.5 * ( 1 + cos( PDL::Core::zeroes($N)->xlinvals( - PI, PI ) ) )
        * exp( -$alpha * abs( PDL::Core::zeroes($N)->xlinvals( -1, 1 ) ) );

}

sub hann_poisson_per {
    PDL::Core::barf 'hann_poisson: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $alpha ) = @_;
    0.5 * ( 1 + cos( PDL::Core::zeroes($N)->xlinvals( - PI, ( - PI + PI * ( $N - 1 ) ) / $N ) ) )
        * exp( -$alpha * abs( PDL::Core::zeroes($N)->xlinvals( -1, ( -1 + 1 * ( $N - 1 ) ) / $N ) ) );
}

sub kaiser {
    PDL::Core::barf 'kaiser: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $beta ) = @_;

    PDL::Core::barf 'kaiser: PDL::GSLSF not installed' unless HAVE_BESSEL;

    $beta *= PI;

    my ($n) = PDL::GSLSF::BESSEL::gsl_sf_bessel_In(
        $beta * sqrt( 1 - PDL::Core::zeroes($N)->xlinvals( -1, 1 ) ** 2 ), 0 );

    my ($d) = PDL::GSLSF::BESSEL::gsl_sf_bessel_In( $beta, 0 );

    $n / $d;
}

sub kaiser_per {
    PDL::Core::barf 'kaiser: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ($N,$beta) = @_;

    PDL::Core::barf 'kaiser: PDL::GSLSF not installed' unless HAVE_BESSEL;

    $beta *= PI;

    my ($n) = PDL::GSLSF::BESSEL::gsl_sf_bessel_In(
        $beta * sqrt( 1 - PDL::Core::zeroes($N)->xlinvals( -1, ( -1 + 1 * ( $N - 1 ) ) / $N ) ** 2 ), 0);

    my ($d) = PDL::GSLSF::BESSEL::gsl_sf_bessel_In( $beta, 0 );

    $n / $d;
}

sub lanczos {
    PDL::Core::barf 'lanczos: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;

    my $x   = PI * PDL::Core::zeroes($N)->xlinvals( -1, 1 );
    my $res = sin($x) / $x;

    $res->slice( int( $N / 2 ) ) .= 1 if $N % 2;

    $res;
}

sub lanczos_per {
    PDL::Core::barf 'lanczos: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;

    my $x   = PI * PDL::Core::zeroes($N)->xlinvals( -1, ( -1 + 1 * ( $N - 1 ) ) / $N );
    my $res = sin($x) / $x;

    $res->slice( int( $N / 2 ) ) .= 1 unless $N % 2;

    $res;
}

sub nuttall {
    PDL::Core::barf 'nuttall: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI ) );
    0.2269824 + $cx * ( -0.4572542 + $cx * ( 0.273199 + $cx * -0.0425644 ) );
}

sub nuttall_per {
    PDL::Core::barf 'nuttall: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    0.2269824 + $cx * ( -0.4572542 + $cx * ( 0.273199 + $cx * -0.0425644 ) );
}

sub nuttall1 {
    PDL::Core::barf 'nuttall1: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = (cos(PDL::Core::zeroes($N)->xlinvals(0,TPI)));

    (0.211536) +  ($cx * ((-0.449584) +  ($cx * (0.288464 + $cx * (-0.050416)  ))));
}

sub nuttall1_per {
    PDL::Core::barf 'nuttall1: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    my $cx = cos( PDL::Core::zeroes($N)->xlinvals( 0, TPI * ( $N - 1 ) / $N ) );
    0.211536 + $cx * ( -0.449584 + $cx * ( 0.288464 + $cx * -0.050416 ) );
}

sub parzen {
    PDL::Core::barf 'parzen: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;

    my $x = PDL::Core::zeroes($N)->xlinvals( -1, 1 );

    my $x1 = $x->where( $x <= -0.5 );
    my $x2 = $x->where( ( $x < 0.5 ) & ( $x > -0.5 ) );
    my $x3 = $x->where( $x >= 0.5 );

    $x1 .= 2 * ( 1 - abs($x1) ) ** 3;
    $x2 .= 1 - 6 * $x2 ** 2 * ( 1 - abs($x2) );
    $x3 .= $x1->slice('-1:0:-1');

    $x;
}

sub parzen_per {
    PDL::Core::barf 'parzen: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;

    my $x = PDL::Core::zeroes($N)->xlinvals( -1, ( -1 + ( $N - 1 ) ) / $N);

    my $x1 = $x->where( $x <= -0.5 );
    my $x2 = $x->where( ( $x < 0.5 ) & ( $x > -0.5 ) );
    my $x3 = $x->where( $x >= 0.5 );

    $x1 .= 2 * ( 1 - abs($x1)) ** 3;
    $x2 .= 1 - 6 * $x2 ** 2 * ( 1 - abs($x2) );
    $x3 .= $x1->slice('-1:1:-1');

    $x;
}

sub parzen_octave {
    PDL::Core::barf 'parzen_octave: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;

    my $r  = ( $N - 1 ) / 2;
    my $N2 = $N / 2;
    my $r4 = $r / 2;
    my $n  = PDL::Basic::sequence( 2 * $r + 1 ) - $r;

    my $n1 = $n->where( abs($n) <= $r4 );
    my $n2 = $n->where( $n > $r4 );
    my $n3 = $n->where( $n < -$r4 );

    $n1 .= 1 - 6 * ( abs($n1) / $N2 ) ** 2 + 6 * ( abs($n1) / $N2 ) ** 3;
    $n2 .= 2 * ( 1 - abs($n2) / $N2 ) ** 3;
    $n3 .= 2 * ( 1 - abs($n3) / $N2 ) ** 3;

    $n;
}

sub poisson {
    PDL::Core::barf 'poisson: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $alpha ) = @_;
    exp( -$alpha * abs( PDL::Core::zeroes($N)->xlinvals( -1, 1 ) ) );
}

sub poisson_per {
    PDL::Core::barf 'poisson: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $alpha ) = @_;
    exp( -$alpha * abs( PDL::Core::zeroes($N)->xlinvals( -1, ( -1 + 1 * ( $N - 1 ) ) / $N ) ) );
}

sub rectangular {
    PDL::Core::barf 'rectangular: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    PDL::Core::ones($N);
}

sub rectangular_per {
    PDL::Core::barf 'rectangular: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    PDL::Core::ones($N);
}

sub triangular {
    PDL::Core::barf 'triangular: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    1 - abs( PDL::Core::zeroes($N)->xlinvals( -( $N - 1 ) / $N, ( $N - 1 ) / $N ) );
}

sub triangular_per {
    PDL::Core::barf 'triangular: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    1 - abs( PDL::Core::zeroes($N)->xlinvals( -$N / ( $N + 1 ), -1 / ( $N + 1 ) + ( $N - 1 ) / ( $N + 1 ) ) );
}

sub tukey {
    PDL::Core::barf 'tukey: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $alpha ) = @_;

    PDL::Core::barf('tukey: alpha must be between 0 and 1') unless $alpha >= 0 and $alpha <= 1;

    return PDL::Core::ones($N) if $alpha == 0;

    my $x = PDL::Core::zeroes($N)->xlinvals( 0, 1 );

    my $x1 = $x->where( $x < $alpha / 2 );
    my $x2 = $x->where( ( $x <= 1 - $alpha / 2 ) & ( $x >= $alpha / 2 ) );
    my $x3 = $x->where( $x > 1 - $alpha / 2 );

    $x1 .= 0.5 * ( 1 + cos( PI * ( 2 * $x1 / $alpha - 1 ) ) );
    $x2 .= 1;
    $x3 .= $x1->slice('-1:0:-1');

    return $x;
}

sub tukey_per {
    PDL::Core::barf 'tukey: 2 arguments expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 2;
    my ( $N, $alpha ) = @_;

    PDL::Core::barf 'tukey: alpha must be between 0 and 1' unless $alpha >= 0 && $alpha <= 1;

    return PDL::Core::ones($N) if $alpha == 0;

    my $x = PDL::Core::zeroes($N)->xlinvals( 0, ( $N - 1 ) / $N );

    my $x1 = $x->where( $x < $alpha / 2 );
    my $x2 = $x->where( ( $x <= 1 - $alpha / 2 ) & ( $x >= $alpha / 2 ) );
    my $x3 = $x->where( $x > 1 - $alpha / 2 );

    $x1 .= 0.5 * ( 1 + cos( PI * ( 2 * $x1 / $alpha - 1 ) ) );
    $x2 .= 1;
    $x3 .= $x1->slice('-1:1:-1');

    return $x;
}

sub welch {
    PDL::Core::barf 'welch: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    1 - PDL::Core::zeroes($N)->xlinvals( -1, 1 ) ** 2;
}

sub welch_per {
    PDL::Core::barf 'welch: 1 argument expected. Got ' . scalar(@_) . ' arguments.' unless @_ == 1;
    my ($N) = @_;
    1 - PDL::Core::zeroes($N)->xlinvals( -1, ( -1 + 1 * ( $N - 1 ) ) / $N ) ** 2;
}

=head1 Symmetric window functions

=head2 bartlett($N)

The Bartlett window. (Ref 1). Another name for this window is the fejer window.
This window is defined by

    1 - abs(arr)

where the points in arr range from -1 through 1. See also
L<triangular|/triangular($N)>.

=head2 bartlett_hann($N)

The Bartlett-Hann window. Another name for this window is the Modified
Bartlett-Hann window. This window is defined by

    0.62 - 0.48 * abs(arr) + 0.38 * arr1

where the points in arr range from -1/2 through 1/2, and arr1 are the cos of
points ranging from -PI through PI.

=head2 blackman($N)

The 'classic' Blackman window. (Ref 1). One of the Blackman-Harris family, with coefficients

    a0 = 0.42
    a1 = 0.5
    a2 = 0.08

=head2 blackman_bnh($N)

The Blackman-Harris (bnh) window. An improved version of the 3-term
Blackman-Harris window given by Nuttall (Ref 2, p. 89). One of the
Blackman-Harris family, with coefficients

    a0 = 0.4243801
    a1 = 0.4973406
    a2 = 0.0782793

=head2 blackman_ex($N)

The 'exact' Blackman window. (Ref 1). One of the Blackman-Harris family, with
coefficients

    a0 = 0.426590713671539
    a1 = 0.496560619088564
    a2 = 0.0768486672398968

=head2 blackman_gen($N,$alpha)

The General classic Blackman window. A single parameter family of the 3-term
Blackman window. This window is defined by

    my $cx = arr;
    .5 - $alpha + ($cx * (-.5 + $cx * $alpha));

where the points in arr are the cos of points ranging from 0 through 2PI.

=head2 blackman_gen3($N,$a0,$a1,$a2)

The general form of the Blackman family. One of the Blackman-Harris family,
with coefficients

    a0 = $a0
    a1 = $a1
    a2 = $a2

=head2 blackman_gen4($N,$a0,$a1,$a2,$a3)

The general 4-term Blackman-Harris window. One of the Blackman-Harris family,
with coefficients

    a0 = $a0
    a1 = $a1
    a2 = $a2
    a3 = $a3

=head2 blackman_gen5($N,$a0,$a1,$a2,$a3,$a4)

The general 5-term Blackman-Harris window. One of the Blackman-Harris family,
with coefficients

    a0 = $a0
    a1 = $a1
    a2 = $a2
    a3 = $a3
    a4 = $a4

=head2 blackman_harris($N)

The Blackman-Harris window. (Ref 1). One of the Blackman-Harris family, with
coefficients

    a0 = 0.422323
    a1 = 0.49755
    a2 = 0.07922

Another name for this window is the Minimum three term (sample) Blackman-Harris
window.

=head2 blackman_harris4($N)

The minimum (sidelobe) four term Blackman-Harris window. (Ref 1). One of the
Blackman-Harris family, with coefficients

    a0 = 0.35875
    a1 = 0.48829
    a2 = 0.14128a3 = 0.01168

Another name for this window is the Blackman-Harris window.

=head2 blackman_nuttall($N)

The Blackman-Nuttall window. One of the Blackman-Harris family, with
coefficients

    a0 = 0.3635819
    a1 = 0.4891775
    a2 = 0.1365995
    a3 = 0.0106411

=head2 bohman($N)

The Bohman window. (Ref 1). This window is defined by

    my $x = abs(arr);
    (1 - $x) * cos(PI * $x) + (1 / PI) * sin(PI * $x)

where the points in arr range from -1 through 1.

=head2 cauchy($N,$alpha)

The Cauchy window. (Ref 1). Other names for this window are: Abel, Poisson.
This window is defined by

    1 / (1 + (arr * $alpha) ** 2)

where the points in arr range from -1 through 1.

=head2 chebyshev($N,$at)

The Chebyshev window. The frequency response of this window has C<$at> dB of
attenuation in the stop-band. Another name for this window is the
Dolph-Chebyshev window. No periodic version of this window is defined. This
routine gives the same result as the routine B<chebwin> in Octave 3.6.2.

=head2 cos_alpha($N,$alpha)

The Cos_alpha window. (Ref 1). Another name for this window is the
Power-of-cosine window. This window is defined by

    arr ** $alpha

where the points in arr are the sin of points ranging from 0 through PI.

=head2 cosine($N)

The Cosine window. Another name for this window is the sine window. This
window is defined by

    arr

where the points in arr are the sin of points ranging from 0 through PI.

=head2 dpss($N,$beta)

The Digital Prolate Spheroidal Sequence (DPSS) window. The parameter C<$beta>
is the half-width of the mainlobe, measured in frequency bins. This window
maximizes the power in the mainlobe for given C<$N> and C<$beta>. Another
name for this window is the sleppian window.

=head2 exponential($N)

The Exponential window. This window is defined by

    2 ** (1 - abs arr) - 1

where the points in arr range from -1 through 1.

=head2 flattop($N)

The flat top window. One of the Blackman-Harris family, with coefficients

    a0 = 0.21557895
    a1 = 0.41663158
    a2 = 0.277263158
    a3 = 0.083578947
    a4 = 0.006947368

=head2 gaussian($N,$beta)

The Gaussian window. (Ref 1). Another name for this window is the Weierstrass
window. This window is defined by

    exp (-0.5 * ($beta * arr )**2),

where the points in arr range from -1 through 1.

=head2 hamming($N)

The Hamming window. (Ref 1). One of the Blackman-Harris family, with
coefficients

    a0 = 0.54
    a1 = 0.46

=head2 hamming_ex($N)

The 'exact' Hamming window. (Ref 1). One of the Blackman-Harris family, with
coefficients

    a0 = 0.53836
    a1 = 0.46164

=head2 hamming_gen($N,$a)

The general Hamming window. (Ref 1). One of the Blackman-Harris family, with
coefficients

    a0 = $a
    a1 = (1-$a)

=head2 hann($N)

The Hann window. (Ref 1). One of the Blackman-Harris family, with coefficients

    a0 = 0.5
    a1 = 0.5

Another name for this window is the hanning window. See also
L<hann_matlab|/hann_matlab($N)>.

=head2 hann_matlab($N)

The Hann (matlab) window. Equivalent to the Hann window of N+2 points, with the
endpoints (which are both zero) removed. No periodic version of this window is
defined. This window is defined by

    0.5 - 0.5 * arr

where the points in arr are the cosine of points ranging from 2PI/($N+1)
through 2PI*$N/($N+1). This routine gives the same result as the routine
B<hanning> in Matlab. See also L<hann|/hann($N)>.

=head2 hann_poisson($N,$alpha)

The Hann-Poisson window. (Ref 1). This window is defined by

    0.5 * (1 + arr1) * exp (-$alpha * abs arr)

where the points in arr range from -1 through 1, and arr1 are the cos of points
ranging from -PI through PI.

=head2 kaiser($N,$beta)

The Kaiser window. (Ref 1). The parameter C<$beta> is the approximate
half-width of the mainlobe, measured in frequency bins. Another name for this
window is the Kaiser-Bessel window. This window is defined by

    $beta *= PI;
    my @n = gsl_sf_bessel_In($beta * sqrt(1 - arr ** 2), 0);
    my @d = gsl_sf_bessel_In($beta, 0);
    $n[0] / $d[0];

where the points in arr range from -1 through 1.

=head2 lanczos($N)

The Lanczos window. Another name for this window is the sinc window. This
window is defined by

    my $x = PI * arr;
    my $res = sin($x) / $x;
    my $mid;
    $mid = int($N / 2), $res->slice($mid) .= 1 if $N % 2;
    $res;

where the points in arr range from -1 through 1.

=head2 nuttall($N)

The Nuttall window. One of the Blackman-Harris family, with coefficients

    a0 = 0.3635819
    a1 = 0.4891775
    a2 = 0.1365995
    a3 = 0.0106411

See also L<nuttall1|/nuttall1($N)>.

=head2 nuttall1($N)

The Nuttall (v1) window. A window referred to as the Nuttall window. One of the
Blackman-Harris family, with coefficients

    a0 = 0.355768
    a1 = 0.487396
    a2 = 0.144232
    a3 = 0.012604

This routine gives the same result as the routine B<nuttallwin> in Octave 3.6.2.
See also L<nuttall|/nuttall($N)>.

=head2 parzen($N)

The Parzen window. (Ref 1). Other names for this window are: Jackson,
Valle-Poussin. This function disagrees with the Octave subroutine B<parzenwin>,
but agrees with Ref. 1. See also L<parzen_octave|/parzen_octave($N)>.

=head2 parzen_octave($N)

The Parzen window. No periodic version of this window is defined. This routine
gives the same result as the routine B<parzenwin> in Octave 3.6.2. See also
L<parzen|/parzen($N)>.

=head2 poisson($N,$alpha)

The Poisson window. (Ref 1). This window is defined by

    exp(-$alpha * abs(arr))

where the points in arr range from -1 through 1.

=head2 rectangular($N)

The Rectangular window. (Ref 1). Other names for this window are: dirichlet,
boxcar.

=head2 triangular($N)

The Triangular window. This window is defined by

    1 - abs(arr)

where the points in arr range from -$N/($N-1) through $N/($N-1).
See also L<bartlett|/bartlett($N)>.

=head2 tukey($N,$alpha)

The Tukey window. (Ref 1). Another name for this window is the tapered cosine
window.

=head2 welch($N)

The Welch window. (Ref 1). Other names for this window are: Riez, Bochner,
Parzen, parabolic. This window is defined by

    1 - arr**2

where the points in arr range from -1 through 1.

=head1 AUXILIARY SUBROUTINES

These subroutines are used internally, but are also available for export.

=head2 cos_mult_to_pow

Convert Blackman-Harris coefficients. The BH windows are usually defined via
coefficients for cosines of integer multiples of an argument. The same windows
may be written instead as terms of powers of cosines of the same argument.
These may be computed faster as they replace evaluation of cosines with
multiplications. This subroutine is used internally to implement the
Blackman-Harris family of windows more efficiently.

This subroutine takes between 1 and 7 numeric arguments  a0, a1, ...

It converts the coefficients of this

    a0 - a1 cos(arg) + a2 cos(2 * arg) - a3 cos(3 * arg)  + ...

To the cofficients of this

    c0 + c1 cos(arg) + c2 cos(arg)**2 + c3 cos(arg)**3  + ...

=head2 cos_pow_to_mult

This function is the inverse of L</cos_mult_to_pow>.

This subroutine takes between 1 and 7 numeric arguments  c0, c1, ...

It converts the coefficients of this

    c0 + c1 cos(arg) + c2 cos(arg)**2 + c3 cos(arg)**3  + ...

To the cofficients of this

    a0 - a1 cos(arg) + a2 cos( 2 * arg) - a3 cos( 3 * arg)  + ...

=cut

sub cos_pow_to_mult {
    my @cin = @_;
    PDL::Core::barf 'cos_pow_to_mult: number of args not less than 8.' if @cin > 7;

    my $ex = 7 - @cin;

    my @c = ( @cin, (0) x $ex );

    my @as = (
        10 * $c[6] + 12 * $c[4] + 16 * $c[2] + 32 * $c[0],
        20 * $c[5] + 24 * $c[3] + 32 * $c[1],
        15 * $c[6] + 16 * $c[4] + 16 * $c[2],
        10 * $c[5] +  8 * $c[3],
         6 * $c[6] +  4 * $c[4],
         2 * $c[5],
        $c[6],
    );

    pop @as for 1 .. $ex;

    my $sign = -1;

    foreach (@as) {
        $_ /= -$sign * 32;
        $sign *= -1;
    }

    @as;
}

=head2 chebpoly

=for usage

    chebpoly($n,$x)

=for ref

Returns the value of the C<$n>-th order Chebyshev polynomial at point C<$x>.
$n and $x may be scalar numbers, pdl's, or array refs. However, at least one
of $n and $x must be a scalar number.

All mixtures of pdls and scalars could be handled much more easily as a PP
routine. But, at this point PDL::DSP::Windows is pure perl/pdl, requiring no
C/Fortran compiler.

=cut

sub chebpoly {
    PDL::Core::barf 'chebpoly: Two arguments expected. Got ' .scalar(@_) . "\n" unless @_ == 2;

    my ( $n, $x ) = @_;

    if ( ref $x ) {
        PDL::Core::barf "chebpoly: neither $n nor $x is a scalar number" if ref($n);
        $x = PDL::Core::topdl($x);

        my $tn = PDL::Core::zeroes($x);

        my ( $ind1, $ind2 ) = PDL::Primitive::which_both( abs($x) <= 1 );

        $tn->index($ind1) .= cos(  $n * PDL::Math::acos(  $x->index($ind1) ) );
        $tn->index($ind2) .= PDL::Math::cosh( $n * PDL::Math::acosh( $x->index($ind2) ) );

        return $tn;
    }

    $n = PDL::Core::topdl($n) if ref $n;
    return abs($x) <= 1 ? PDL::Math::cos( $n * PDL::Math::acos($x) ) : PDL::Math::cosh( $n * PDL::Math::acosh($x) );
}


sub cos_mult_to_pow {
    my( @ain )  = @_;
    PDL::Core::barf 'cos_mult_to_pow: number of args not less than 8.' if @ain > 7;

    my $ex = 7 - @ain;

    my @a = ( @ain, (0) x $ex );

    my (@cs) = (
        -$a[6] + $a[4] - $a[2] + $a[0],
         -5 * $a[5] +  3 * $a[3] - $a[1],
         18 * $a[6] -  8 * $a[4] + 2 * $a[2],
         20 * $a[5] -  4 * $a[3],
          8 * $a[4] - 48 * $a[6],
        -16 * $a[5],
         32 * $a[6]
    );

    pop @cs for 1 .. $ex;

    @cs;
}

# Delete internal constants from namespace
delete @PDL::DSP::Windows::{qw(
    HAVE_LinearAlgebra
    HAVE_BESSEL
    HAVE_GNUPLOT
    USE_FFTW_DIRECTION
    I
)};

1;

__END__

=head1 REFERENCES

=over

=item 1

Harris, F.J. C<On the use of windows for harmonic analysis with the discrete
Fourier transform>, I<Proceedings of the IEEE>, 1978, vol 66, pp 51-83.

=item 2

Nuttall, A.H. C<Some windows with very good sidelobe behavior>, I<IEEE
Transactions on Acoustics, Speech, Signal Processing>, 1981, vol. ASSP-29,
pp. 84-91.

=back

=head1 AUTHOR

John Lapeyre, C<< <jlapeyre at cpan.org> >>

=head1 MAINTAINER

José Joaquín Atria, C<< <jjatria at cpan.org> >>

=head1 ACKNOWLEDGMENTS

For study and comparison, the author used documents or output from: Thomas
Cokelaer's spectral analysis software; Julius O Smith III's Spectral Audio
Signal Processing web pages; André Carezia's chebwin.m Octave code; Other code
in the Octave signal package.

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2021 John Lapeyre.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

This software is neither licensed nor distributed by The MathWorks, Inc.,
maker and liscensor of MATLAB.
