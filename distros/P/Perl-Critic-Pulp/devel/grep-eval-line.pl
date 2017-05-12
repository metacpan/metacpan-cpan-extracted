#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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


# Usage: perl grep-ampersand-call.pl
#
# Look for &foo calls, without parens.
#

use 5.010;
use strict;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
#use Smart::Comments;


sub foo {}
&foo;

my $verbose = 0;
my $l = MyLocatePerl->new;
my $count;

{
  my $filename = 'devel/grep-ampersand-call.pl';
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

  while ($str =~ /\beval(\s*[\'\"]|\s+q.)#[ \t]*line/sgo) {
    my $pos = pos($str);

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col: eval #line\n",
      MyStuff::line_at_pos($str, $pos);
  }
}

exit 0;
