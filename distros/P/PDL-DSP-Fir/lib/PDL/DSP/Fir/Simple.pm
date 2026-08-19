package PDL::DSP::Fir::Simple;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.005';

use base 'Exporter';

use PDL::LiteF;
use PDL::ImageND('convolveND');
use PDL::NiceSlice;

# first line is compat. with older pdl.
use constant PI    => 4 * atan2(1, 1);
#use PDL::Constants qw(PI);

use PDL::DSP::Fir;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( filter testdata );

$PDL::onlinedoc->scan(__FILE__) if $PDL::onlinedoc;

=head1 NAME

PDL::DSP::Simple - Simple interface to windowed sinc filters.

=head1 SYNOPSIS

       use PDL::LiteF;
       use PDL::DSP::Fir::Simple;

=head1 DESCRIPTION

At present, this module provides one filtering
routine. The main purpose is to provide an easy-to-use
lowpass filter that only requires the user to provide the
data and the cutoff frequency. However, the routines take
options to give the user more control over the
filtering. The module implements the filters via convolution
with a kernel representing a finite impulse response
function, either directly or with fft. The filter kernel is
constructed from windowed sinc functions. Available filters
are lowpass, highpass, bandpass, and bandreject. All window
functions in L<PDL::DSP::Windows> are available.

See L<PDL::DSP::Iir/moving_average> for a moving average filter.

Some of this functionality is already available in the PDL core.
The modules L<PDL::Audio> and L<PDL::Stats:TS> (time series) also have
filtering functions.

Below, the word B<order> refers to the number of elements in the filter
kernel. The default value is equal to the number of elements in the data
to be filtered.

No functions are exported by default.

=head1 FUNCTIONS

=head2 filter

  $xf = filter($x, {OPTIONS});

       or

  $xf = filter($x, $kern);

=head3 Examples

=for example

Apply lowpass filter to signal $x with a cutoff frequency of 90% of the
Nyquist frequency (i.e. 45% of the sample frequency).

 $xf = filter($x, { fc => 0.9 });


Apply a highpass filter rather than the default lowpass filter

  $xf = filter($x, {fc => 0.9 , type => 'highpass' });


Apply a lowpass filter of order 20 with a blackman window, rather than the default hamming window.

  $xf = filter($x, {fc => 0.9 , window => 'blackman' , N => 20 });

Apply a 10 point moving average. Note that this moving averaging is implemented via
convolution. This is a relatively inefficient implementation.

  $xf = filter($x, {window => 'rectangular', type => 'window', N => 10 });

Return the kernel used in the convolution.

  ($xf, $kern)  = filter($x, { fc => 0.9 });


Apply a lowpass filter of order 20 with a tukey window with parameter I<alpha> = 0.5.

  $xf = filter($x, {fc => 0.9 , 
    window => { name => 'tukey', params => 0.5 } , N => 20 });

=head3 OPTIONS

=over

=item N    

Order of filter. I.e. the number of points in the filter kernel.
If this option is not given, or is undefined, or false, or less than
zero, then the order of the filter is equal to the number of points
in the data C<$x>.
 
=item  kern  

A kernel to use for convolution rather than calculating a kernel
from other parameters.

=item boundary   

Boundary condition passed to C<convolveND>. Must be one of
'extend', 'truncate', 'periodic'. See L<PDL::ImageND>.

=back

All other options to C<filter> are passed to the function L<PDL::DSP::Fir/firwin> which creates the filter kernel.
L<PDL::DSP::Fir/firwin> in turn passes options to L<PDL::DSP::Windows:window>.
The option C<window> is either a string giving the name of the window function, or
an anonymous hash of options to pass to  L<PDL::DSP::Windows:window>.
For example C<< { name => 'window_name', ... } >>.

If the second argument is not a hash of options then it is interpreted as a
kernel C<$kern> to be convolved with the C<$data>.

If called in a list context, the filtered data and kernel ($dataf,$kern)
are returned.

=cut

sub filter {
    my ($dat,$iopts) = @_;
    my ($kern, $boundary);
    if (ref $iopts eq 'HASH') {
        $boundary = delete $iopts->{boundary} || 'periodic';
        $iopts->{N} = ($iopts->{N} and $iopts->{N} > 0) ? $iopts->{N} : $dat->nelem;
        $kern = defined $iopts->{kern} ? $iopts->{kern} : PDL::DSP::Fir::firwin($iopts);
    }
    else {
        $kern = $iopts;
    }
    my $fdat = convolveND($dat, $kern, { boundary => $boundary});
    return wantarray ? ($fdat,$kern) : $fdat;
}

# hmm, this is almost like exporting. maybe don't do it.
# *PDL::filter = \&filter;

=head2 testdata

  $x = testdata($Npts, $freqs, $amps)

For example:

  $x = testdata(1000, [5,100], [1, .1] );

Generate a signal by summing sine functions of differing
frequencies. The signal has $Npts
elements. $freqs is an array of frequencies, and $amps an
array of amplitudes for each frequency. The frequencies should
be between 0 and 1, with 1 representing the nyquist frequency.

=cut

sub testdata {
    my ($M, $f, $amp) = @_;
    my $x = zeroes($M); 
    my $n = sequence($M);
    foreach (@$f) {
        $x = $x + (shift @$amp)*sin(PI*$n*($_)); 
    }
    return $x;
}

=head1 AUTHOR

John Lapeyre, C<< <jlapeyre at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 John Lapeyre.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of PDL::DSP::Fir::Simple
