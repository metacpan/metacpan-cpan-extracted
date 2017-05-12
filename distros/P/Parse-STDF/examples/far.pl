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

# Just print the FAR record

package main;

BEGIN {
  chdir 'example' if -d 'example';
  use lib '../lib';
  eval "use blib";
}

use strict;
use warnings;
use Parse::STDF;

( $#ARGV == 0 ) || die "Usage: $0 stdf\n";
my $stdf = $ARGV[0];

my $s = Parse::STDF->new ( $stdf );

# FAR record is always the 1st record

$s->get_record(); 

my $far = $s->far();

printf ("Record FAR ( %d, %d ) %d bytes:\n", $far->{header}->{REC_TYP}, $far->{header}->{REC_SUB}, $far->{header}->{REC_LEN} );
printf ("\tCPU_TYPE: %s\n", $far->{CPU_TYPE} );
printf ("\tSTDF_VER: %s\n", $far->{STDF_VER} );

exit;

