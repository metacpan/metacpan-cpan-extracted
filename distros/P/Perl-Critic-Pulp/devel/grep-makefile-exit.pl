#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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


# exit 0 bad for Module::Depends::Intrusive

use 5.006;
use strict;
use warnings;
use Perl6::Slurp;
use File::Locate::Iterator;

use lib::abs '.';
use MyStuff;

use FindBin;
my $progname = $FindBin::Script;

my $verbose = 0;

my $it = File::Locate::Iterator->new (globs => ['*/Makefile.PL']);
my $count = 0;

while (defined (my $filename = $it->next)) {
  if ($verbose) { print "$filename\n"; }
  my $str = eval { Perl6::Slurp::slurp($filename) } || next;

  while ($str =~ /exit[ \t(]+0/mg) {
    my $pos = pos($str);

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    print "$filename:$line:$col: exit\n";
    print MyStuff::line_at_pos($str, $pos);
  }
}
print "count $count\n";

__END__
