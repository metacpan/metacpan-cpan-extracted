#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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


# Prima::MDI
# p-class.pl

use 5.005;
use strict;
use warnings;
use Regexp::Common 'comment';

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

my $verbose = 0;

my $l = MyLocatePerl->new;
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  # strip comments
  $str =~ s/$RE{comment}{Perl}/\n/og;

  while ($str =~ /\n[ \t]*\}[ \t]*if[ \t]/g) {
    my $pos = pos($str) - 3;
    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    my $s = MyStuff::line_at_pos($str, $pos);
    print "$filename:$line:$col: ifif\n  $s";
  }
}

exit 0;
