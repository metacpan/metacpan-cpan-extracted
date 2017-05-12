#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

my $verbose = 0;

my $l = MyLocatePerl->new (include_pod => 1);
my $count = 0;
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  while ($str =~ /\b(then\s+then)\b/sg) {
    # while ($str =~ /\b(note\s+sure)\b/sg) {

    my $bad = $1;
    my $pos = $-[1];
    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col: \"$bad\"\n",
      MyStuff::line_at_pos($str, $pos);
    $count++;
  }
}
print "total $count\n";

exit 0;
