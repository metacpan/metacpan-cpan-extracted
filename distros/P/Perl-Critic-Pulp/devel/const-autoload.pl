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

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use TestAutoload ('BAR');

sub AUTOLOAD {
  { no strict;
    print "create $AUTOLOAD\n"; }
  *FOO = sub () { return 123; };
  goto &FOO;
}

{ no strict;
  if (FOO < 456) { print "yes\n"; } else { print "no\n"; }
}
if (FOO() < 456) { print "yes\n"; } else { print "no\n"; }
print "FOO is ",FOO(),"\n";


BEGIN {
  print "BAR is ",BAR(),"\n";
}
if (BAR < 456) { print "yes\n"; } else { print "no\n"; }
if (BAR() < 456) { print "yes\n"; } else { print "no\n"; }
print "BAR is ",BAR(),"\n";
exit 0
