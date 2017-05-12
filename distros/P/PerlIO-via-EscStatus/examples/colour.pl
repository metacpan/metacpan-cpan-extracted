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


# Usage: ./colour.pl
#
# This is an example of including ANSI SGR escapes in the status lines.
# EscStatus recognises ANSI escapes as taking no width.  You can create the
# escapes any way you want, here Term::ANSIColor is used to do it by name
# (instead of the escape code numbers).
#
# Obviously how such escapes actually display depends on the terminal.  If
# it's a non-ANSI terminal, or it's only black-and-white, or something, then
# printing such escapes might be bad.
#

use strict;
use warnings;
use Term::ANSIColor;
use PerlIO::via::EscStatus qw(print_status);

binmode (STDOUT, ':via(EscStatus)')
  or die $!;

print_status ("Colour ", colored("some red", 'red'));
sleep 1;
print_status ("Colour ", colored("some green", 'green')," ...");
sleep 1;
print "This\nordinary\noutput is not coloured\n";
print_status ("Colour ", colored("a bit of blue", 'blue'),"!");
sleep 1;
print_status ("Colour ", colored("some blue",'blue'),
              " and ",
              colored("some bold",'bold'));
sleep 1;
print "The end.\n";
exit 0;
