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

package PostModule;
use strict;
use warnings;
use TestConstFoo ('MYCONST');

BEGIN {
  print "PostModule MYCONST is ",TestConstFoo::MYCONST(),"\n";
  my $proto = prototype(\&MYCONST);
  print "proto '",(defined $proto ? $proto : 'undef'),"'\n";
}

# bad unless MYCONST()
if (MYCONST < 10) { print "yes\n"; } else { print "no\n"; }

1;
