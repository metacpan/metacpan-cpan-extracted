#!/usr/bin/perl -w

# Copyright 2009, 2010, 2012 Kevin Ryde

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


# Usage: perl grep-pod-synopsis.pl
#
# Look for SYNOPSIS without any verbatim paragraph.
#
# Sometimes C<> on whole ...

use strict;
use warnings;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

my $verbose = 0;

my $l = MyLocatePerl->new;
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  pos($str) = 0;
  $str =~ /^=head1 SYNOPSIS/mg
    or next;
  my $beg = pos($str);

  if ($str !~ /^(=head1)|^[ \t]+[^ \t\r\n]/mg
      || $1) {
    my $pos = $beg;
    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);

    print "$filename:$line:$col: no verbatim in synopsis\n",
      MyStuff::line_at_pos($str, $pos);
  }
}

exit 0;
