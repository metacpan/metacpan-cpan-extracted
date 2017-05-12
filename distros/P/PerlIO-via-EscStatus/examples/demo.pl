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

use strict;
use warnings;
use PerlIO::via::EscStatus qw(print_status);

binmode (STDOUT, ':via(EscStatus)')
  or die $!;

print_status ("Working ... 20%");
sleep 1;
print_status ("Working ... 40%");
sleep 1;
print "This is a two\n line message\n";
sleep 1;
print_status ("Working ... 80%");
sleep 1;
print "The end.\n";
exit 0;
