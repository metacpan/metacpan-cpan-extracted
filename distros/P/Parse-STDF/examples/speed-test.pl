#!/usr/bin/env perl
#  Copyright (C) 2014 Erick Jordan <ejordan@cpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Reads each record of an input STDF file and spits out the elapsed time

package main;

BEGIN {
  chdir 'example' if -d 'example';
  use lib '../lib';
  eval "use blib";
}

use strict;
use warnings;
use Benchmark;
use Parse::STDF;

( $#ARGV == 0 ) || die "Usage: $0 stdf\n";
my $stdf = $ARGV[0];

my $t0 = Benchmark->new;

my $s = Parse::STDF->new ( $stdf );

while ( $s->get_record() ) {};

my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);

printf STDERR ("Elapsed time: %s\n", timestr($td) );

exit;

