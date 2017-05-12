
#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
use vars '$VERSION';
$VERSION = 999;

# uncomment this to run the ### lines
use Data::Dumper 'Dumper';

BEGIN {
  sub mysub () { return 'fufu'; }
}
{
  my %hash = (main
              ->
              VERSION
              =>
              123,

              mysub
              +
              mysub
              =>
              123);
  print Dumper(\%hash);
  exit 0;
}

{
  # use constant CON => 'abc';
  # use constant CON
  #   => 'def';
  print abc();
  exit 0;
}
{
  my @dash = (-POSIX::DBL_MAX());
  print Dumper(\@dash);
  exit 0;
}
{
  my %hash = (andx              => 123);
  print Dumper(\%hash);
  exit 0;
}

{
  my %hash = (__PACKAGE__
              =>
              123);
  ### %hash
  exit 0;
}

{
  my @x = (
           print                         	       => 123
          );
  print @x;
  exit 0;
}
