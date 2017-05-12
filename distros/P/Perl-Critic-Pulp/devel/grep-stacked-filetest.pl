#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

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


# Look for -e -x stacked filetests.
#

use 5.008;
use strict;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
#use Smart::Comments;


if (-e -x -f '/tmp/foo.txt') {
}

my $verbose = 0;
my $l = MyLocatePerl->new;
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  while ($str =~ /[^a-z][ \t(]-[a-z]\s+-[a-z]\s+/ig) {
    my $pos = pos($str);

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col: stacked filetest\n",
      MyStuff::line_at_pos($str, $pos);
  }
}

exit 0;
