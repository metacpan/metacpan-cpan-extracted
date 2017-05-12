#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of PerlIO-via-EscStatus.
#
# PerlIO-via-EscStatus is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# PerlIO-via-EscStatus is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PerlIO-via-EscStatus.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./wide.pl
#
# This is an example of how "double-width" east asian characters are
# recognised by EscStatus as taking two columns each.  The status $str is
# 200 chars long, which will print as 400 columns, and it's truncated to fit
# in 80 columns (or however wide your terminal is).
#
# You'll need a unicode tty with asian fonts to see this properly,
# eg. "uxterm".
#

use strict;
use warnings;
use Encode;
use I18N::Langinfo qw(langinfo CODESET);
use PerlIO::encoding;
use Time::HiRes qw(usleep);

use PerlIO::via::EscStatus qw(print_status);

my $charset = langinfo (CODESET);
binmode (STDOUT, ":encoding($charset)")
  or die $!;
print "locale charset for output is $charset\n";

binmode (STDOUT, ':via(EscStatus)')
  or die Encode::decode($charset, "$!");

my $str = ("\x{FF10}\x{FF11}\x{FF12}\x{FF13}\x{FF14}"
           . "\x{FF15}\x{FF16}\x{FF17}\x{FF18}\x{FF19}") x 20;
foreach my $i (0 .. 10) {
  print_status "$i  ", substr($str,$i);
  usleep (500_000);
}

exit 0;
