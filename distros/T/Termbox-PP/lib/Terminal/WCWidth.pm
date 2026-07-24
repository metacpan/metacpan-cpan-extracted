# ------------------------------------------------------------------------
#
#   WCWidth - determine columns needed for a wide character
#
#   Code based on Terminal::WCWidth (a Raku port), 2026
#
#   Copyright (c) 2007 Markus Kuhn (Unicode 5.0)
#                 2014 Jeff Quast <contact@jeffquast.com>
#                 2015-2017 +merlan #flirora <http://flirora.xyz/>
#                 2020,2024 Raku Community
#
# ------------------------------------------------------------------------
#   Author: 2024-2026 J. Schneider
# ------------------------------------------------------------------------

package Terminal::WCWidth;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

# version '...'
use version;
our $version = version->declare('v0.1.5');
our $VERSION = version->declare('v0.5.3');

# authority '...'
our $authority = 'github:raku-community-modules';
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Imports ----------------------------------------------------------------
# ------------------------------------------------------------------------

use Unicode::Normalize qw( NFC );
use Terminal::WCWidth::Tables;

# ------------------------------------------------------------------------
# Exports ----------------------------------------------------------------
# ------------------------------------------------------------------------

=head1 EXPORTS

Nothing per default, but can export the following per request:

  :all
    wcwidth
    wcswidth

=cut

use Exporter qw( import );

our @EXPORT_OK = qw(
  wcwidth
  wcswidth
);

our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

# ------------------------------------------------------------------------
# Functions --------------------------------------------------------------
# ------------------------------------------------------------------------

# Auxiliary function for binary search in interval table
sub _bisearch {    # $result ($ucs, \@table)
  my ($ucs, $table) = @_;
  my $lower = 0;
  my $upper = scalar(@$table) - 1;
  return 0 if $ucs < $table->[0][0] || $ucs > $table->[$upper][1];
  while ($upper >= $lower) {
    my $mid = ($lower + $upper) >> 1;
    if ($ucs > $table->[$mid][1]) {
      $lower = $mid + 1;
    } elsif ($ucs < $table->[$mid][0]) {
      $upper = $mid - 1;
    } else {
      return 1;
    }
  }
  return 0;
}

my %cache = ();

sub wcwidth {    # $result ($ucs)
  my ($ucs) = @_;

  return -1 
    if !defined $ucs || ref $ucs;

  return -1 
    if ($ucs < 0 || $ucs > 0x10ffff) 
    || ($ucs >= 0xD800 && $ucs <= 0xDFFF);

  return $cache{$ucs} if exists $cache{$ucs};

  return ($cache{$ucs} = 0)
    if $ucs == 0
    || $ucs == 0x034f
    || $ucs == 0x2028
    || $ucs == 0x2029
    || (0x200b <= $ucs && $ucs <= 0x200f)
    || (0x202a <= $ucs && $ucs <= 0x202e)
    || (0x2060 <= $ucs && $ucs <= 0x2063);

  return ($cache{$ucs} = -1) 
    if $ucs < 32 || (0x07f <= $ucs && $ucs < 0x0a0);

  return ($cache{$ucs} = 0) if _bisearch($ucs, ZERO_WIDTH);
  return ($cache{$ucs} = 2) if _bisearch($ucs, WIDE_EASTASIAN);

  return ($cache{$ucs} = 1);
}

sub wcswidth {    # $result ($str)
  my ($str) = @_;
  $str = NFC($str);
  my $res = 0;
  my $prev_w = 0;
  for (split //, $str) {
    my $cp = ord($_);
    if ($cp == 0xfe0f && $prev_w == 1) {
      $res += 1;
      $prev_w = 0;
      next;
    }
    my $w = wcwidth($cp);
    return -1 if $w < 0;
    $res += $w;
    $prev_w = $w;
  }
  return $res;
}

1;

__END__

=encoding utf-8

=head1 NAME

Terminal::WCWidth - determine columns needed for a wide character

=head1 DESCRIPTION

This module is mainly for console/tty programs that carefully produce output 
for Terminals, or make pretend to be an emulator.

=head1 SYNOPSIS

  sub print_right_aligned {
    my ($s) = @_;
    print " " x (80 - wcswidth($s));
    say $s;
  }
  print_right_aligned("this is right-aligned");
  print_right_aligned("another right-aligned string");

=head1 SUBROUTINES

=head2 C<wcwidth>

Takes a single I<codepoint> and outputs its width:

  wcwidth(0x3042) # "あ" - returns 2

Returns:

=over

=item C<-1> for a control character

=item C<0> for a character that does not advance the cursor (NULL or combining)

=item C<1> for most characters

=item C<2> for full width characters

=back

=head2 C<wcswidth>

Takes a I<string> and outputs its total width:

    wcswidth("*ウルヰ*") # returns 8 = 2 + 6

Returns -1 if any control characters are found.

Unlike the original version, this module does not support getting the width of
only the first C<n> characters of a string, as you can use the C<substr>
method.

=head1 COPYRIGHT AND LICENCE

 This code was originally derived from C code with the name wcwidth.c.

 Copyright (c) 2007 by Markus Kuhn

 This library content was taken from the Terminal::WCWidth implementation of 
 Raku (a Python port) which is licensed under MIT license.

 Copyright (c) 2014 Jeff Quast
               2015-2017 +merlan #flirora
               2020,2024 Raku Commuity
               2024-2026 J. Schneider

 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

=head1 AUTHORS

=over

=item * Markus Kuhn

=item * Jeff Quast

=item * +merlan #flirora

=item * José Joaquín Atria

=item * Raku Community

=item * J. Schneider L<https://github.com/brickpool/>

=back

=head1 DISCLAIMER OF WARRANTIES

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

=head1 REQUIRES

L<5.010|https://metacpan.org/release/DAPM/perl-5.10.1>

=head1 SEE ALSO

L<Text::CharWidth>

L<Text::VisualWidth::PP>

L<wcwidth.c|https://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c>

L<Terminal::WCWidth|https://github.com/raku-community-modules/Terminal-WCWidth>

=cut
