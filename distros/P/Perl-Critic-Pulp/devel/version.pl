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
use warnings;

# uncomment this to run the ### lines
use Smart::Comments;


use Test::Without::Module 'version::vxs';
use blib "$ENV{HOME}/perl/version/version-0.88/blib";
# use version::vxs;
# use version::vpp;

my $vpp = version::vpp->VERSION;
### $vpp

{
  require version;
  print "version.pm ", version->VERSION, "\n";

  # my $v = version->new('1.234.567');
  my $v = version->new('1e6');
  print "v $v\n";
  print "done\n";
  exit 0;
}
{
  use Perl::Critic::Utils 1.0;
  use Perl::Critic::Utils 1.0 'precedence_of';
  print Perl::Critic::Utils->VERSION,"\n";
  exit 0;
}

{
  my $x = '1e6';
  print ($x > 2);
  exit 0;
}


{
  require AptPkg::Policy;
  print AptPkg::Policy->VERSION,"\n";
  exit 0;
}
