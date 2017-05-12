#!/usr/bin/perl -w

# Copyright 2013, 2014, 2015 Kevin Ryde

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

use 5.004;
use strict;

use List::Util ();
print List::Util::first { $_ > 10 } 1 .. 100;
print "\n";

__END__
sub foo {
  my ($self) = @_;

  {
    use TryCatch;
    try {
      print "try\n";
      die 123;
    }
      catch ($err) {
        print "catch $err\n";
      }
  }

  try {
    print "try\n";
    die 456;
  }
    catch ($err) {
      print "catch $err\n";
    };
}
foo();
exit 0;


unless (1) {
  print "unless\n";
} elsif (2) {
  print "elsif\n";
}

unless (1) {
  print "unless\n";
} if (2) {
  print "if\n";
}
exit 0;
