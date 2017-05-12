#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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


# Usage: ./fracs.pl
#
# This is some status lines with extended chars for fractions 1/4, 1/2 and
# 3/4 which are in latin1 and unicode.
#
# When doing this you have to push any necessary ":encoding" transformation
# layer yourself, EscStatus doesn't do that.  The code below assumes the tty
# uses the charset from langinfo(CODESET), which is almost certainly true.
# PerlIO::locale can do that codeset setup for you, and the "use open"
# pragma can make it the default for new tty opens.
#

use strict;
use warnings;
use Encode;
use I18N::Langinfo qw(langinfo CODESET);
use PerlIO::encoding;
use charnames ':full';

use PerlIO::via::EscStatus qw(:all);

my $charset = langinfo (CODESET);
print "locale charset for output is $charset\n";
binmode (STDOUT, ":encoding($charset)")
  or die $!;

binmode (STDOUT, ":via(EscStatus)")
  or die Encode::decode($charset, "$!");

print_status ("Job \N{VULGAR FRACTION ONE QUARTER} finished");
sleep 1;
print_status ("Job \N{VULGAR FRACTION ONE HALF} finished");
sleep 1;
print_status ("Job \N{VULGAR FRACTION THREE QUARTERS} finished");
sleep 1;
print_status ("Job finished");
sleep 1;
exit 0;
