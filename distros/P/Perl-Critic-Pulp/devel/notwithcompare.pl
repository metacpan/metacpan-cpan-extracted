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
use Data::Dumper;

{
  sub func1     { print "func1 $_[0]\n" }
  sub func2 ($) { print "func2 $_[0]\n" }
  my $x = 0;
  if (! func1 $x != 123) { print "yes\n"; } else { print "no\n"; }
  if (! func2 $x != 123) { print "yes\n"; } else { print "no\n"; }
  exit 0;
}

{ my $x = 'b';
  if (! $x eq 'a') { print "yes\n"; } else { print "no\n"; }
}

{ my $attribs = 1;
  my $x = !( $attribs & 1 ) << 1;

  $x = !( $attribs & 1 );
  $x = $x << 1;

#   $attribs = 0;
#   $x = $attribs & 1;
#   $x = ($x) << 1;
  print Dumper($x);
}

# use Test::More tests => 1;
# Test::More::eq_array(123, 456);
# Test::More::is_deeply([123], [456]);

{ my $x = 'a';
  if (! $x =~ /b/) { print "yes\n"; } else { print "no\n"; }
}

# ! $x + $y == 1

exit 0;
