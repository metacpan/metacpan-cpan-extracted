#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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


# Usage: perl grep-printf.pl
#
# Look for printf format strings.
#
# %b in new enough perl.
# %ld and %lld modifiers unnecessary?


use 5.010;
use strict;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
#use Smart::Comments;


printf "%z\n", 123;
printf "%ld\n", 123;

my $verbose = 0;
my $l = MyLocatePerl->new;
my $count;

{
  my $filename = 'devel/grep-printf.pl';
  my $content = eval { Perl6::Slurp::slurp ($filename) } || next;
  file ($filename, $content);
}
{
  while (my ($filename, $content) = $l->next) {
    file ($filename, $content);
  }
  exit 0;
}

sub file {
  my ($filename, $str) = @_;

  if ($verbose) {
    print "$filename\n";
  }

  if ($str =~ /^__END__/m) {
    substr ($str, $-[0], length($str), '');
  }

  while ($str =~ /\bs?printf
                  \b[ \t\r\n(]*
                  ( '((\\.|[^'])*)'
                  | "((\\.|[^"])*)"
                  )
                 /xg) {
    my $pos = pos($str);
    my $fmt = $1 // $3;

    $fmt =~ /^[^%]*
             (%[\#v]?[+-]?0?(\*?|[0-9]*)(\.(\*|[0-9]*))?[%csduoxefgXEGbBpniDUOFb]
               [^%]*)*/xg
                 or die;
    my $fpos = pos($fmt);
    if ($fpos != length($fmt)) {
      my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
      my $fend = substr($fmt,$fpos);
      print "$filename:$line:$col:\n";
      print "  $fend\n";
      print MyStuff::line_at_pos($str, $pos);
    }
  }
}

exit 0;
