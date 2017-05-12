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

use strict;
use warnings;
use Perl6::Slurp;
use Regexp::Common;
use Iterator::Simple;
use Iterator::Simple::Locate;

use lib::abs '.';
use MyStuff;

my $verbose = 0;

my $it = Iterator::Simple::Locate->new (suffix => '.t');
while (my $filename = $it->next) {
  if ($verbose) { print "look at $filename\n"; }

  my $str = eval { Perl6::Slurp::slurp ($filename) }
    || do {
      # print "Cannot read $filename: $!\n";
      next;
    };

  $str = comments_to_whitespace($str);
  my $mstr = comments_to_whitespace($str);
  my $count = 0;
  while ($mstr =~ m{(                  # $1
                      (?:^|\s)
                      (?:print|say)
                      \s*
                      (?:[\'\"]|qq?.)
                      ([^\r\n]+)       # $2
                    )}gx) {
    my $match = $1;
    my $print = $2;
    my $pos = $-[2];

    next if ($print =~ /^\d+\.\./);
    next if ($print =~ /^\#/);
    next if ($print =~ /^[ \t]ok /);
    next if ($print =~ /^[ \t]not /);

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col: ``$print''\n",
      MyStuff::line_at_pos($str, $pos);
    next if ($count++ > 5);
  }
}

sub comments_to_whitespace {
  my ($str) = @_;
  $str =~ s/((^|[ \t])$RE{comment}{Perl})/_to_whitespace($1)/emgo;
  return $str;
}
sub _to_whitespace {
  my ($str) = @_;
  $str =~ s/([^[:space:]]+)/' ' x length($1)/ge;
  return $str;
}

exit 0;

# "not|"ok|"#|[.][.]|:[ 	]*#|print STDERR'

