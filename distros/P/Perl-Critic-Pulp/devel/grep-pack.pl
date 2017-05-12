#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Regexp::Common qw /delimited/;

use FindBin;
my $progname = $FindBin::Script;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

my $verbose = 0;
my $count = 0;

my $string_re = qr/$RE{delimited}{-delim=>q{'"}}/o;
# ($string_re)

my $l = MyLocatePerl->new;
OUTER: while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }
  $count++;

  while ($str =~ /\b(?:un)?pack
                  [\t (]+
                  ['"]([^'"]*)['"]
                 /gsxo) {
    my $pos = pos($str);
    my $format = $1;

    next if ($format =~ /\$/);  # interpolations

    #     # 5.002 supported
    #     next if ($format =~ /^[%*0-9 AabBhHcCsSiIlLnNvVfdpPuxX\@]*$/);

    #     # 5.004 supported
    #     next if ($format =~ /^[%*0-9 AabBhHcCsSiIlLnNvVfdpPuxX\@w]*$/);

    # 5.006 supported
    next if ($format =~ /^[%*0-9! AabBhHcCsSiIlLnNvVfdpPuxX\@wqQZ]*$/);

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col: pack $format\n  ",
      MyStuff::line_at_pos($str, $pos);
  }
}

print "looked at $count\n";
exit 0;



__END__



# 5.002
#     %NUM for unpack
#
#     A	An ascii string, will be space padded.
#     a	An ascii string, will be null padded.
#     b	A bit string (ascending bit order, like vec()).
#     B	A bit string (descending bit order).
#     h	A hex string (low nybble first).
#     H	A hex string (high nybble first).
#
#     c	A signed char value.
#     C	An unsigned char value.
#     s	A signed short value.
#     S	An unsigned short value.
#     i	A signed integer value.
#     I	An unsigned integer value.
#     l	A signed long value.
#     L	An unsigned long value.
#
#     n	A short in "network" order.
#     N	A long in "network" order.
#     v	A short in "VAX" (little-endian) order.
#     V	A long in "VAX" (little-endian) order.
#
#     f	A single-precision float in the native format.
#     d	A double-precision float in the native format.
#
#     p	A pointer to a null-terminated string.
#     P	A pointer to a structure (fixed-length string).
#
#     u	A uuencoded string.
#
#     x	A null byte.
#     X	Back up a byte.
#     @	Null fill to absolute position.
#
# 5.004
#     w	A BER compressed integer.  Its bytes represent an unsigned
# 	integer in base 128, most significant digit first, with as few
# 	digits as possible.  Bit eight (the high bit) is set on each
# 	byte except the last.
#
# 5.6.0
#     q	A signed quad (64-bit) value.
#     Q	An unsigned quad value.
# 	  (Quads are available only if your system supports 64-bit
# 	   integer values _and_ if Perl has been compiled to support those.
#            Causes a fatal error otherwise.)
#
#     Z	A null terminated (asciz) string, will be null padded.
#
# 5.8.0
#     F	A floating point value in the native native format
#            (a Perl internal floating point value, NV).
#     D	A long double-precision float in the native format.
# 	  (Long doubles are available only if your system supports long
# 	   double values _and_ if Perl has been compiled to support those.
#            Causes a fatal error otherwise.)
#
#     j   A signed integer value (a Perl internal integer, IV).
#     J   An unsigned integer value (a Perl internal unsigned integer, UV).

