#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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
use Devel::Mallinfo;
use POSIX;

package Foo;
package Bar;
package Quux;

my ($x, $y);
my $n = 0;
sub packname { ++$n; return "Pack$n" }

foreach (1 .. 10) {
  my $package = packname();
  eval "package $package;our \$VERSION = 1";
  $x = Devel::Mallinfo::mallinfo()->{'uordblks'};
  eval "package $package;use POSIX";
  $y = Devel::Mallinfo::mallinfo()->{'uordblks'};
  print "$package adds @{[$y-$x]}\n";
}

foreach (1 .. 10) {
  my $package = packname();
  eval "package $package;our \$VERSION = 1";
  $x = Devel::Mallinfo::mallinfo()->{'uordblks'};
  eval "package $package;use POSIX ()";
  $y = Devel::Mallinfo::mallinfo()->{'uordblks'};
  print "$package adds @{[$y-$x]}\n";
}


package Bar;
use constant FOO => 123;
BEGIN { print $x = Devel::Mallinfo::mallinfo()->{'uordblks'},"\n"; }
use POSIX;
BEGIN { print $y = Devel::Mallinfo::mallinfo()->{'uordblks'},"\n"; }
BEGIN { print __PACKAGE__." adds ", $y-$x,"\n"; }

print "Bar count ",scalar(keys %Bar::),"\n";
#{ local $, = "\n"; print keys %Bar::,"\n"; }

package Quux;
BEGIN { print $x = Devel::Mallinfo::mallinfo()->{'uordblks'},"\n"; }
use POSIX;
BEGIN { print $y = Devel::Mallinfo::mallinfo()->{'uordblks'},"\n"; }
BEGIN { print __PACKAGE__." adds ", $y-$x,"\n"; }
print "Quux count ",scalar(keys %Quux::),"\n";

package Four;
use constant FOO => 123;
BEGIN { print $x = Devel::Mallinfo::mallinfo()->{'uordblks'},"\n"; }
use POSIX qw(dup);
BEGIN { print $y = Devel::Mallinfo::mallinfo()->{'uordblks'},"\n"; }
BEGIN { print __PACKAGE__." adds ", $y-$x,"\n"; }

package Five;
use constant FOO => 123;
BEGIN { print $x = Devel::Mallinfo::mallinfo()->{'uordblks'},"\n"; }
use POSIX ();
BEGIN { print $y = Devel::Mallinfo::mallinfo()->{'uordblks'},"\n"; }
BEGIN { print __PACKAGE__." adds ", $y-$x,"\n"; }

package Six;
use constant FOO => 123;
BEGIN { print $x = Devel::Mallinfo::mallinfo()->{'uordblks'},"\n"; }
use POSIX qw(dup EBADF);
BEGIN { print $y = Devel::Mallinfo::mallinfo()->{'uordblks'},"\n"; }
BEGIN { print __PACKAGE__." adds ", $y-$x,"\n"; }

print "POSIX EXPORT ",scalar(@POSIX::EXPORT),"\n";
#{ local $, = "\n"; print keys %Bar::,"\n"; }

exit 0;
