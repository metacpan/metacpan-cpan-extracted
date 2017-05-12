#!/usr/bin/perl -w

# Copyright 2009, 2010, 2012, 2014 Kevin Ryde

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


# Look for a line of spaces and tabs in POD.
#
# Old formatters treat line of spaces and tabs as non-empty.
# Eg pod2text of perl 5.004.

use 5.005;
use strict;
use warnings;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

my $verbose = 0;

my $l = MyLocatePerl->new (exclude_t => 1,
                           include_pod => 1);
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  next if ($filename =~ /\/doc\.pl$/);
  next if ($filename =~ /\/junk\.pl$/);

  my $in_pod = 0;
  my $linenum = 0;
  foreach my $line (split /\n/, $str) {
    $line =~ s/\r$//;
    $linenum++;
    if ($line =~ /^=cut/) { $in_pod = 0; next; }
    if ($line =~ /^=/) { $in_pod = 1; next; }
    next unless $in_pod;

    if ($line =~ /^\s+$/) {
      print "$filename:$linenum:1: blank of whitespace only\n";
      $line =~ s/([^\021-\177])/'['.ord($1).']'/eg;
      print "  xx${line}xx ",length($line),"\n";
    }
  }
}

exit 0;
