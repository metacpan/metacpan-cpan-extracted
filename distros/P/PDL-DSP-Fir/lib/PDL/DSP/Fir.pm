package PDL::DSP::Fir;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.005';

use base 'Exporter';

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::Options;
use constant PI    => 4 * atan2(1, 1);
#use PDL::Constants qw(PI);
use PDL::DSP::Windows;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( firwin ir_sinc ir_hisinc spectral_inverse spectral_reverse );

$PDL::onlinedoc->scan(__FILE__) if $PDL::onlinedoc;

=head1 NAME

PDL::DSP::Fir - Finite impulse response filter kernels.

=head1 SYNOPSIS

  use PDL;
  use PDL::DSP::Fir qw( firwin );

  # return a 10 sample lowpass filter kernel 
  # with a cutoff at 90% of the Nyquist frequency.
  $kernel = firwin( N => 10, fc => 0.9 );

  # Equivalent way of calling.
  $kernel = firwin( { N => 10, fc => 0.9 } );

=head1 DESCRIPTION

This module provides routines to create  one-dimensional finite impulse
response (FIR) filter kernels.  This distribution inlcudes
a simple interface for filtering in L<PDL::DSP::Fir::Simple>.

The routine L</firwin> returns a filter kernel constructed
from windowed sinc functions. Available filters are lowpass,
highpass, bandpass, and bandreject. The window functions are
in the module L<PDL::DSP::Windows>.

Below, the word B<order> refers to the number of elements in the filter
kernel.

No functions are exported be default.

=head1 FUNCTIONS

=head2 firwin


=head3 Usage

=for usage

 $kern = firwin({OPTIONS});
 $kern = firwin(OPTIONS);

=for ref

Returns a filter kernel (a finite impulse response function)
to be convolved with data. 

The kernel is built from windowed sinc functions. With the
option C<type =E<gt> 'window'> no sinc is used, rather the
kernel is just the window. The options may be passed as
a list of key-value pairs, or as an anonymous hash.

=head3 OPTIONS

=over

=item N 

order of filter. This is the number of elements in
the returned kernel pdl.

=item type

Filter type. One of C<lowpass>, C<highpass>, C<bandpass>, 
C<bandstop>, C<window>. Aliases for C<bandstop> are C<bandreject> and C<notch>.
Default is C<lowpass>. For C<bandpass> and C<bandstop> the number of samples
L</N> must be odd.
If B<type> is C<window>, then the kernel returned is just the window function.

=item fc

Cutoff frequency for low- and highpass filters as a fraction of
the Nyquist frequency. Must be a number between
C<0> and C<1>. No default value.

=item fclo, fchi

Lower and upper cutoff frequencies for bandpass and bandstop filters.
No default values.

=back

All other options to L</firwin> are passed to the function 
L<PDL::DSP::Windows/window>.

=cut

sub firwin {
    barf 'PDL::DSP::Fir::firwin() called with no arguments.' unless @_;
    my $iopts;
    if (@_ == 1) {
        barf "PDL::DSP::FIR::firwin: single argument not a hashref"
            unless ref($_[0]) eq 'HASH';
        $iopts = $_[0];
    }
    else {
        my %hash = @_;
        $iopts = \%hash;
    }
    my $opt = new PDL::Options(
        {
            N => undef,
            type => 'lowpass',
            window => undef,
            fc => undef,
            fclo => undef,
            fchi => undef,
        });
    my $opts = $opt->options($iopts);
    my $winopts = { N => $opts->{N} };
    if (defined $opts->{window} ) {
        my $w = $opts->{window};
        if ( ref $w ) {
            foreach my $wkey (keys %{$w}) {
                $winopts->{$wkey} = $w->{$wkey};
            }
        }
        else {
            $winopts->{NAME} = $w;
        }
    }
    my $type = $opts->{type};
    my $win = PDL::DSP::Windows::window($winopts);
    my ($ir,$kernel);
    if ($type eq 'lowpass') {
        $ir = ir_sinc($opts->{fc},$opts->{N});
        $kernel = $ir * $win;
        $kernel /= $kernel->sum;
    }
    elsif ($type eq 'highpass') {
        $ir = ir_sinc($opts->{fc},$opts->{N});
        $kernel = $ir * $win;
        $kernel /= $kernel->sum;
        $kernel = spectral_inverse($kernel);
    }
    elsif ($type eq 'window') {
        $kernel = $win/$win->sum;
    }
    elsif ($type eq 'bandpass') {
        my $ir1 = ir_sinc($opts->{fclo},$opts->{N});
        my $ir2 = ir_sinc($opts->{fchi},$opts->{N});
        my $fir1 = $ir1 * $win;
        $fir1 /= $fir1->sum;
        my $fir2 = $ir2 * $win;
        $fir2 /= $fir2->sum;
        $fir2 = spectral_inverse($fir2);
        $kernel = spectral_inverse($fir1 + $fir2);
    }
    elsif ($type eq 'bandstop' or $type eq 'bandreject' or $type eq 'notch') {
        my $ir1 = ir_sinc($opts->{fclo},$opts->{N});
        my $ir2 = ir_sinc($opts->{fchi},$opts->{N});
        my $fir1 = $ir1 * $win;
        $fir1 /= $fir1->sum;
        my $fir2 = $ir2 * $win;
        $fir2 /= $fir2->sum;
        $fir2 = spectral_inverse($fir2);
        $kernel = $fir1 + $fir2;
    }
    else {
        barf "PDL::DSP::FIR::firwin: Unknown impulse response '$type'\n";
    }
    return $kernel;
}

=pod

The following three functions are called by the C<firwin>, but
may also be useful by themselves, for instance, to construct more
complicated filters.

=head2 ir_sinc

=for usage

  $sinc = ir_sinc($f_cut, $N);

=for ref

Return an C<$N> point sinc function representing a lowpass filter
with cutoff frequency C<$f_cut>.

C<$f_cut> must be between 0 and 1, with 1 being Nyquist freq.
The output pdl is the function C<sin( $f_cut * $x ) / $x> where
$x is pdl of C<$N> uniformly spaced values ranging from
C< - PI * ($N-1)/2> through C<PI * ($N-1)/2>. For what it's
worth, a bit of efficiency is gained by computing the index
at which C<$x> is zero, rather than searching for it.

=cut

sub ir_sinc {
    my ($f_cut,$N) = @_;
    my $lim = PI * ($N-1)/2;
    my $x =  zeroes($N)->xlinvals(-$lim,$lim);
    my $res = sin( $f_cut * $x ) / $x;
    $res->slice(int($N/2)) .= $f_cut if $N % 2; # fix nan at x=0
    $res;
}

=head2 spectral_inverse

=for usage

  $fir_inv = spectral_inverse($fir);

=for ref

Return output kernel whose spectrum is the inverse of the spectrum
of the input kernel.

The number of samples in the input kernel must be odd.
Input C<$fir> and output C<$fir_inv> are real-space fir filter kernels.
The spectrum of the output kernel is the additive inverse
with respect to 1 of the spectrum of the input kernel.

=cut

sub spectral_inverse {
    my ($fir) = @_;
    my $L = $fir->nelem;
    barf "spectral_inverse: L=$L is not odd\n" unless $L % 2;
    my $mid = ($L-1)/2;
    my $ifir = -$fir;
    $ifir->slice($mid) += 1;
    $ifir;
}

=head2 spectral_reverse

=for usage

  $fir_rev = spectral_reverse($fir);

=for ref

Return output kernel whose spectrum is the reverse of the spectrum
of the input kernel.

That is, the spectrum is mirrored about the center frequency.
 
=cut

sub spectral_reverse {
    my ($fir) = @_;
    my $ofir = $fir->copy;
    $ofir->slice('0:-1:2') *= -1;
    $ofir;
}

=head1 AUTHOR

John Lapeyre, C<< <jlapeyre at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 John Lapeyre.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of PDL::DSP::Fir
