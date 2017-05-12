#!/usr/bin/perl

# Copyright 2011 Kevin Ryde

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

foreach my $p ('perl-5.003',
               'perl-5.004',
               'perl-5.005',
               'perl-5.6.0',
               'perl-5.8.0',
               'perl-5.8.3',
               'perl5.10.1',
              ) {
  print "$p\n";
  system ($p, '-e', 'use strict; use constant _foo => 123; print "foo=",_foo(); exit 21');
  print "$?\n";
  system ($p, '-e', 'print 123');
  print "$?\n";
  print "\n";
}
