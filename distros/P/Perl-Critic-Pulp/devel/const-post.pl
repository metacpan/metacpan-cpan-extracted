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

#use warnings;

print "FOO\n";
(FOO < 456);
if (FOO < 200) { print "yes\n"; } else { print "no\n"; }
if (FOO < 100) { print "yes\n"; } else { print "no\n"; }
use constant FOO => 123;
if (FOO < 200) { print "yes\n"; } else { print "no\n"; }
if (FOO < 100) { print "yes\n"; } else { print "no\n"; }

print "BAR\n";
#sub BAR { return 123; }
print "",BAR,"\n";
if (BAR < -1) { print "yes\n"; } else { print "no\n"; }

print "QUUX\n";
if (QUUX < 200) { print "yes\n"; } else { print "no\n"; }
if (QUUX < 100) { print "yes\n"; } else { print "no\n"; }
#BEGIN
{ *QUUX = sub { return 123; }; }
if (QUUX < 200) { print "yes\n"; } else { print "no\n"; }
if (QUUX < 100) { print "yes\n"; } else { print "no\n"; }

use strict;
use warnings;
print "XYZZY\n";
BEGIN {
#  sub XYZZY { return 150; }
#   if (XYZZY < 300) { print "yes\n"; } else { print "no\n"; }
#   if (XYZZY < 200) { print "yes\n"; } else { print "no\n"; }
#   if (XYZZY < 100) { print "yes\n"; } else { print "no\n"; }
}
if (XYZZY < 300) { print "yes\n"; } else { print "no\n"; }
if (XYZZY < 200) { print "yes\n"; } else { print "no\n"; }
if (XYZZY < 100) { print "yes\n"; } else { print "no\n"; }
use constant XYZZY => 250;
# use constant XYZZY => 150;
if (XYZZY < 300) { print "yes\n"; } else { print "no\n"; }
if (XYZZY < 200) { print "yes\n"; } else { print "no\n"; }
if (XYZZY < 100) { print "yes\n"; } else { print "no\n"; }


exit 0
