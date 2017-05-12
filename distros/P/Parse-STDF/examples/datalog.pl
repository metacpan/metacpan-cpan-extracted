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

# Print a typical datalog report

package main;

BEGIN {
  chdir 'example' if -d 'example';
  use lib '../lib';
  eval "use blib";
}

use strict;
use warnings;
use Time::localtime;
use Parse::STDF;

( $#ARGV == 0 ) || die "Usage: $0 stdf\n";
my $stdf = $ARGV[0];

my $s = Parse::STDF->new ( $stdf );

while ( $s->get_record() )
{
  if ( $s->recname() eq "DTR" )
  {
    my $dtr = $s->dtr();
	printf ("%s\n", $dtr->{TEXT_DAT} );
  }

  if ( $s->recname() eq "WIR" )
  {
    my $wir = $s->wir(); 
	printf ("\nWafer-Id: %s", $wir->{WAFER_ID} );
	printf ("\tWafer StartTime: %s", ctime($wir->{START_T}) );
	printf ("\tSite Group: %s\n\n", $wir->{SITE_GRP} );
  }

  if ( $s->recname() eq "PRR" )
  {
    my $prr = $s->prr();
	printf ("Device: %s", $prr->{PART_ID});
    printf ("\tBin: %2i", $prr->{HARD_BIN});
	printf ("\tStation: %2i", $prr->{HEAD_NUM});
	printf ("\tSite: %3i", $prr->{SITE_NUM});
	printf ("\t(Software bin: %2i)", $prr->{SOFT_BIN});
	printf ("\tWafer Coordinates: (%3i, %3i)", $prr->{X_COORD}, $prr->{Y_COORD});
	printf ("\tElapsed test time (ms): %6i\n", $prr->{TEST_T});
  }

  if ( $s->recname() eq "PTR" )
  {
    my $ptr = $s->ptr();
	printf ("%-8i ", $ptr->{TEST_NUM} );
	printf ("%-50s ", $ptr->{TEST_TXT} );
	printf ("%f \n", $ptr->{RESULT} );
  }

  if ( $s->recname() eq "PIR" )
  {
    my $pir = $s->pir();
	printf ("\nHead: %s", $pir->{HEAD_NUM});
	printf ("\tSite: %s\n\n", $pir->{SITE_NUM});
  }

}

exit;

