#!/usr/bin/perl -w

# Copyright 2009, 2010, 2014 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Perl6::Slurp;
use Regexp::Common;
use Iterator::Simple;
use Iterator::Simple::Locate;

use lib::abs '.';
use MyStuff;

my $verbose = 0;

my $it;
if (@ARGV) {
  $it = Iterator::Simple::iter (\@ARGV);
} else {
  # $it = Iterator::Simple::Locate->new (suffix => '.pm');
  $it = Iterator::Simple::Locate->new (glob => '/usr/share/perl5/*.pm');
}
while (my $filename = $it->next) {
  if ($verbose) { print "look at $filename\n"; }

  my $str = eval { Perl6::Slurp::slurp ($filename) }
    || do {
      # print "Cannot read $filename: $!\n";
      next;
    };

  my $count = 0;
  while ($str =~ /^[ \t]*(for(each)?)\b.*\@/mg) {
    my $print = $1;
    my $pos = $-[1];

    my $rest = substr ($str, $pos);
    if ($rest =~ /^}/mg) {
      $rest = substr ($rest, 0, pos($rest));
    }
    next unless $rest =~ /\b(splice\b.*)/m;
    my $spos = $-[1];
    my $sprint = $1;

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col: ``$print''\n",
      MyStuff::line_at_pos($str, $pos);

    my ($sline, $scol) = MyStuff::pos_to_line_and_column ($str, $pos + $spos);
    print "$filename:$sline:$scol: ``$sprint''\n",
      MyStuff::line_at_pos($str, $pos);

    next if ($count++ > 5);
  }
}

exit 0;
