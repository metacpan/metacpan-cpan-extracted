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

# Print a typical summary report

package main;

BEGIN {
  chdir 'example' if -d 'example';
  use lib '../lib';
  eval "use blib";
}

use strict;
use warnings;
use Time::localtime;
use Parse::STDF qw( xU1_array_ref );

( $#ARGV == 0 ) || die "Usage: $0 stdf\n";
my $stdf = $ARGV[0];

my $s = Parse::STDF->new ( $stdf );

while ( $s->get_record() )
{
  if ( $s->recname() eq "MIR" )
  {
    my $mir = $s->mir();
	printf ("Started At: %s\n", ctime($mir->{START_T}) );
	printf ("Station Number: %s\n", $mir->{STAT_NUM} );
  	printf ("Station Mode: %s\n", $mir->{MODE_COD} );
	printf ("Retst Code: %s\n", $mir->{RTST_COD} );
	printf ("Lot: %s\n", $mir->{LOT_ID} );
	printf ("Part Type: %s\n", $mir->{PART_TYP} );
	printf ("Node Name: %s\n", $mir->{NODE_NAM} );
	printf ("Tester Type: %s\n", $mir->{TSTR_TYP} );
	printf ("Program: %s\n", $mir->{JOB_NAM} );
	printf ("Version: %s\n", $mir->{JOB_REV} );
	printf ("Sublot: %s\n", $mir->{SBLOT_ID} );
	printf ("Operator: %s\n", $mir->{OPER_NAM} );
	printf ("Executive: %s\n", $mir->{EXEC_TYP} );
	printf ("Test Code: %s\n", $mir->{TEST_COD} );
	printf ("Test Temprature: %s\n", $mir->{TST_TEMP} );
	printf ("Package Type: %s\n", $mir->{PKG_TYP} );
	printf ("Facility ID: %s\n", $mir->{FACIL_ID} );
	printf ("Design Revision: %s\n", $mir->{DSGN_REV} );
  }

  if ( $s->recname() eq "SDR" )
  {
    my $sdr = $s->sdr(); 
	printf ("Head: %s\n", $sdr->{HEAD_NUM} );
	printf ("Site Count: %s\n", $sdr->{SITE_CNT} );
    print "Active Sites: ", join(", ", @{ xU1_array_ref($sdr->{SITE_NUM}, $sdr->{SITE_CNT}) } ) ,"\n";	
	printf ("Handler/Prober: %s\n", $sdr->{HAND_TYP} );
	printf ("DIB Type: %s\n", $sdr->{DIB_TYP} );
	printf ("DIB_ID: %s\n", $sdr->{DIB_ID} );
  }

  if ( $s->recname() eq "PCR" )
  {
    my $pcr = $s->pcr();
	if ( $pcr->{HEAD_NUM} == 255 )
	{
	  printf ("Total bin1 count: %s\n", $pcr->{GOOD_CNT} );
	  printf ("Total number of devices binned: %s\n", $pcr->{PART_CNT} );
	}
  }

  if ( $s->recname() eq "MRR" )  
  {
    my $mrr = $s->mrr();
	printf ("Finish At: %s\n", ctime($mrr->{FINISH_T}) );
  }


}

exit;

