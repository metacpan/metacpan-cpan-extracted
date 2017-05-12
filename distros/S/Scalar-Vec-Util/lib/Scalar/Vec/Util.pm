package Scalar::Vec::Util;

use strict;
use warnings;

use Carp qw<croak>;

=head1 NAME

Scalar::Vec::Util - Utility routines for vec strings.

=head1 VERSION

Version 0.08

=cut

our $VERSION;
BEGIN {
 $VERSION = '0.08';
 eval {
  require XSLoader;
  XSLoader::load(__PACKAGE__, $VERSION);
  1;
 } or do {
  *SVU_PP   = sub () { 1 };
  *SVU_SIZE = sub () { 1 };
  *vfill    = *vfill_pp;
  *vcopy    = *vcopy_pp;
  *veq      = *veq_pp;
 }
}

=head1 SYNOPSIS

    use Scalar::Vec::Util qw<vfill vcopy veq>;

    my $s;
    vfill $s, 0, 100, 1; # Fill with 100 bits 1 starting at 0.
    my $t;
    vcopy $s, 20, $t, 10, 30; # Copy 30 bits from $s, starting at 20,
                              #                to $t, starting at 10.
    vcopy $t, 10, $t, 20, 30; # Overlapping areas DWIM.
    if (veq $t, 10, $t, 20, 30) { ... } # Yes, they are equal now.

=head1 DESCRIPTION

This module provides a set of utility routines that efficiently manipulate bits in vec strings.
Highly optimized XS functions are used whenever possible, but straightforward pure Perl replacements are also available for platforms without a C compiler.

Note that this module does not aim at reimplementing bit vectors : all its functions can be used on any Perl string, just like L<perlfunc/vec>.

=head1 CONSTANTS

=head2 C<SVU_PP>

True when pure Perl fallbacks are used instead of XS functions.

=head2 C<SVU_SIZE>

The size (in bits) of the unit used for bit operations.
The higher this value is, the faster the XS functions are.
It is usually C<CHAR_BIT * $Config{alignbytes}>, except on non-little-endian architectures where it currently falls back to C<CHAR_BIT> (e.g. SPARC).

=head1 FUNCTIONS

=head2 C<vfill>

    vfill $vec, $start, $length, $bit;

Starting at C<$start> in C<$vec>, fills C<$length> bits with ones if C<$bit> is true and with zeros if C<$bit> is false.

C<$vec> is upgraded to a string and extended if necessary.
Bits that are outside of the specified area are left untouched.

=cut

sub vfill_pp ($$$$) {
 my ($s, $l, $x) = @_[1 .. 3];
 return unless $l;
 croak 'Invalid negative offset' if $s < 0;
 croak 'Invalid negative length' if $l < 0;
 $x = ~0 if $x;
 my $SIZE = 32;
 my $t = int($s / $SIZE) + 1;
 my $u = int(($s + $l) / $SIZE);
 if ($SIZE * $t < $s + $l) { # implies $t <= $u
  vec($_[0], $_, 1)     = $x for $s .. $SIZE * $t - 1;
  vec($_[0], $_, $SIZE) = $x for $t .. $u - 1;
  vec($_[0], $_, 1)     = $x for $SIZE * $u .. $s + $l - 1;
 } else {
  vec($_[0], $_, 1) = $x for $s .. $s + $l - 1;
 }
}

=head2 C<vcopy>

    vcopy $from => $from_start, $to => $to_start, $length;

Copies C<$length> bits starting at C<$from_start> in C<$from> to C<$to_start> in C<$to>.

C<$from> and C<$to> are allowed to be the same scalar, and the given areas can rightfully overlap.

C<$from> is upgraded to a string if it isn't one already.
If C<$from_start + $length> goes out of the bounds of C<$from>, then the extra bits are treated as zeros.
C<$to> is upgraded to a string and extended if necessary.
The content of C<$from> is not modified, except when it is equal to C<$to>.
Bits that are outside of the specified area are left untouched.

This function does not need to allocate any extra memory.

=cut

sub vcopy_pp ($$$$$) {
 my ($fs, $ts, $l) = @_[1, 3, 4];
 return unless $l;
 croak 'Invalid negative offset' if $fs < 0 or $ts < 0;
 croak 'Invalid negative length' if $l  < 0;
 my $step = $ts - $fs;
 if ($step <= 0) {
  vec($_[2], $_ + $step, 1) = vec($_[0], $_, 1) for $fs .. $fs + $l - 1;
 } else { # There's a risk of overwriting if $_[0] and $_[2] are the same SV.
  vec($_[2], $_ + $step, 1) = vec($_[0], $_, 1) for reverse $fs .. $fs + $l - 1;
 }
}

=head2 C<vshift>

    vshift $v, $start, $length => $bits, $insert;

In the area starting at C<$start> and of length C<$length> in C<$v>, shift bits C<abs $bits> positions left if C<< $bits > 0 >> and right otherwise.

When C<$insert> is defined, the resulting gap is also filled with ones if C<$insert> is true and with zeros if C<$insert> is false.

C<$v> is upgraded to a string if it isn't one already.
If C<$start + $length> goes out of the bounds of C<$v>, then the extra bits are treated as zeros.
Bits that are outside of the specified area are left untouched.

This function does not need to allocate any extra memory.

=cut

sub vshift ($$$$;$) {
 my ($start, $length, $bits, $insert) = @_[1 .. 4];
 return unless $length and $bits;
 croak 'Invalid negative offset' if $start  < 0;
 croak 'Invalid negative length' if $length < 0;
 my $left = 1;
 if ($bits < 0) {
  $left = 0;
  $bits = -$bits;
 }
 if ($bits < $length) {
  $length -= $bits;
  if ($left) {
   vcopy($_[0], $start, $_[0], $start + $bits, $length);
   vfill($_[0], $start, $bits, $insert) if defined $insert;
  } else {
   vcopy($_[0], $start + $bits, $_[0], $start, $length);
   vfill($_[0], $start + $length, $bits, $insert) if defined $insert;
  }
 } else {
  vfill($_[0], $start, $length, $insert) if defined $insert;
 }
}

=head2 C<vrot>

    vrot $v, $start, $length, $bits;

In the area starting at C<$start> and of length C<$length> in C<$v>, rotates bits C<abs $bits> positions left if C<< $bits > 0 >> and right otherwise.

C<$v> is upgraded to a string if it isn't one already.
If C<$start + $length> goes out of the bounds of C<$v>, then the extra bits are treated as zeros.
Bits that are outside of the specified area are left untouched.

This function currently allocates an extra buffer of size C<O($bits)>.

=cut

sub vrot ($$$$) {
 my ($start, $length, $bits) = @_[1 .. 3];
 return unless $length and $bits;
 croak 'Invalid negative offset' if $start  < 0;
 croak 'Invalid negative length' if $length < 0;
 my $left = 1;
 if ($bits < 0) {
  $left = 0;
  $bits = -$bits;
 }
 $bits %= $length;
 return unless $bits;
 $length -= $bits;
 my $buf = '';
 if ($left) {
  vcopy($_[0], $start + $length, $buf,  0,              $bits);
  vcopy($_[0], $start,           $_[0], $start + $bits, $length);
  vcopy($buf,  0,                $_[0], $start,         $bits);
 } else {
  vcopy($_[0], $start,           $buf,  0,                $bits);
  vcopy($_[0], $start + $bits,   $_[0], $start,           $length);
  vcopy($buf,  0,                $_[0], $start + $length, $bits);
 }
}

=head2 C<veq>

    veq $v1 => $v1_start, $v2 => $v2_start, $length;

Returns true if the C<$length> bits starting at C<$v1_start> in C<$v1> and C<$v2_start> in C<$v2> are equal, and false otherwise.

C<$v1> and C<$v2> are upgraded to strings if they aren't already, but their contents are never modified.
If C<$v1_start + $length> (respectively C<$v2_start + $length>) goes out of the bounds of C<$v1> (respectively C<$v2>), then the extra bits are treated as zeros.

This function does not need to allocate any extra memory.

=cut

sub veq_pp ($$$$$) {
 my ($s1, $s2, $l) = @_[1, 3, 4];
 croak 'Invalid negative offset' if $s1 < 0 or $s2 < 0;
 croak 'Invalid negative length' if $l  < 0;
 my $i = 0;
 while ($i < $l) {
  return 0 if vec($_[0], $s1 + $i, 1) != vec($_[2], $s2 + $i, 1);
  ++$i;
 }
 return 1;
}

=head1 EXPORT

The functions L</vfill>, L</vcopy>, L</vshift>, L</vrot> and L</veq> are only exported on request.
All of them are exported by the tags C<':funcs'> and C<':all'>.

The constants L</SVU_PP> and L</SVU_SIZE> are also only exported on request.
They are all exported by the tags C<':consts'> and C<':all'>.

=cut

use base qw<Exporter>;

our @EXPORT         = ();
our %EXPORT_TAGS    = (
 'funcs'  => [ qw<vfill vcopy vshift vrot veq> ],
 'consts' => [ qw<SVU_PP SVU_SIZE> ]
);
our @EXPORT_OK      = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = [ @EXPORT_OK ];

=head1 BENCHMARKS

The following timings were obtained by running the C<samples/bench.pl> script.
The C<_pp> entries are the pure Perl versions, whereas C<_bv> are L<Bit::Vector> versions.

=over 4

=item *

This is for perl 5.8.8 on a Core 2 Duo 2.66GHz machine (unit is 64 bits).

    Filling bits at a given position :
                  Rate vfill_pp vfill_bv    vfill
    vfill_pp    80.3/s       --    -100%    -100%
    vfill_bv 1053399/s 1312401%       --     -11%
    vfill    1180792/s 1471129%      12%       --

    Copying bits from a bit vector to a different one :
                 Rate vcopy_pp vcopy_bv    vcopy
    vcopy_pp    112/s       --    -100%    -100%
    vcopy_bv  62599/s   55622%       --     -89%
    vcopy    558491/s  497036%     792%       --

    Moving bits in the same bit vector from a given position
    to a different one :
                 Rate vmove_pp vmove_bv    vmove
    vmove_pp   64.8/s       --    -100%    -100%
    vmove_bv  64742/s   99751%       --     -88%
    vmove    547980/s  845043%     746%       --

    Testing bit equality from different positions of different
    bit vectors :
               Rate  veq_pp  veq_bv     veq
    veq_pp   92.7/s      --   -100%   -100%
    veq_bv  32777/s  35241%      --    -94%
    veq    505828/s 545300%   1443%      --

=item *

This is for perl 5.10.0 on a Pentium 4 3.0GHz (unit is 32 bits).

                 Rate vfill_pp vfill_bv    vfill
    vfill_pp    185/s       --    -100%    -100%
    vfill_bv 407979/s  220068%       --     -16%
    vfill    486022/s  262184%      19%       --

                 Rate vcopy_pp vcopy_bv    vcopy
    vcopy_pp   61.5/s       --    -100%    -100%
    vcopy_bv  32548/s   52853%       --     -83%
    vcopy    187360/s  304724%     476%       --

                 Rate vmove_pp vmove_bv    vmove
    vmove_pp   63.1/s       --    -100%    -100%
    vmove_bv  32829/s   51933%       --     -83%
    vmove    188572/s  298787%     474%       --

               Rate  veq_pp  veq_bv     veq
    veq_pp   34.2/s      --   -100%   -100%
    veq_bv  17518/s  51190%      --    -91%
    veq    192181/s 562591%    997%      --

=item *

This is for perl 5.10.0 on an UltraSPARC-IIi (unit is 8 bits).

                Rate vfill_pp    vfill vfill_bv
    vfill_pp  4.23/s       --    -100%    -100%
    vfill    30039/s  709283%       --     -17%
    vfill_bv 36022/s  850568%      20%       --

                Rate vcopy_pp vcopy_bv    vcopy
    vcopy_pp  2.74/s       --    -100%    -100%
    vcopy_bv  8146/s  297694%       --     -60%
    vcopy    20266/s  740740%     149%       --

                Rate vmove_pp vmove_bv    vmove
    vmove_pp  2.66/s       --    -100%    -100%
    vmove_bv  8274/s  311196%       --     -59%
    vmove    20287/s  763190%     145%       --

              Rate  veq_pp  veq_bv     veq
    veq_pp  7.33/s      --   -100%   -100%
    veq_bv  2499/s  33978%      --    -87%
    veq    19675/s 268193%    687%      --

=back

=head1 CAVEATS

Please report architectures where we can't use the alignment as the move unit.
I'll add exceptions for them.

=head1 DEPENDENCIES

L<perl> 5.6.

A C compiler.
This module may happen to build with a C++ compiler as well, but don't rely on it, as no guarantee is made in this regard.

L<Carp>, L<Exporter> (core modules since perl 5), L<XSLoader> (since perl 5.6.0).

=head1 SEE ALSO

L<Bit::Vector> gives a complete reimplementation of bit vectors.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-scalar-vec-util at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Scalar-Vec-Util>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Scalar::Vec::Util

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/Scalar-Vec-Util>.

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010,2011,2012,2013 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Scalar::Vec::Util
