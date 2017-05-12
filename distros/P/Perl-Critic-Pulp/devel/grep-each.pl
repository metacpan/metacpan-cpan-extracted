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


# Usage: perl grep-each.pl
#
# Look for "each %foo".
#

use 5.006;
use strict;
use warnings;
use Perl6::Slurp;
use File::Locate::Iterator;

use FindBin;
my $progname = $FindBin::Script;

my $verbose = 0;

my $it = File::Locate::Iterator->new (globs => [# '*.t',
                                                '*.pm',
                                                '*.pl']);
print "$progname: $it->{'regexp'}\n";
my $count = 0;

while (defined (my $filename = $it->next)) {
  open my $in, '<', $filename or next;
  if ($verbose) { print "$filename\n"; }
  $count++;

  while (<$in>) {
    /\beach\s+%/ or next;
    print "$filename:$.:1:\n  $_";
  }
  close $in or die;
}
print "count $count\n";

sub line_at_pos {
  my ($str, $pos) = @_;
  my $beg = rindex ($str, "\n", $pos) || -1;
  my $end =  index ($str, "\n", $pos) || length($str);
  return substr ($str, $beg+1, $end-($beg+1));
}

__END__
