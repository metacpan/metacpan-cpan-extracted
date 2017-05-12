# Copyright 2008, 2009 Kevin Ryde

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

package PosixUser;
use strict;
use warnings;
use POSIX;
BEGIN {
  print (defined &DBL_MANT_DIG ? "defined\n" : "not defined\n");
  print "digs ",DBL_MANT_DIG(),"\n";
  my $proto = prototype(\&DBL_MANT_DIG);
  print "proto '",(defined $proto ? $proto : 'undef'),"'\n";
}

sub func {
  print "func\n";
  if (DBL_MANT_DIG < 10) { print "yes\n"; } else { print "no\n"; }
}

1;
