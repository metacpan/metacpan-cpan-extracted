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
use PerlIO::via::EscStatus::ShowAll;

binmode (STDOUT, ':via(EscStatus::ShowAll)')
  or die $!;

print_status ("Working ... one");
sleep 1;
print_status ("Working ... two");
sleep 1;
print "This is a message\n";
sleep 1;
print_status ("Working ... three");
sleep 1;
print "The end.\n";
exit 0;
