#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::Trap qw(:default);
use Clone qw(clone);

use SeaBASS::File qw(STRICT_READ STRICT_WRITE STRICT_ALL INSERT_BEGINNING INSERT_END);

my @DATA = split(m"<BR/>\s*", join('', <DATA>));

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {preserve_header => 1});
    $sb_file->write();
};
is($trap->stdout, $DATA[0], 'preserve header output 1');
is($trap->leaveby, 'return', 'preserve header trap 1');

done_testing();

__DATA__
/begin_header
/investigators=Anthony_Michaels
/affiliations=Bermuda_Biological_Station_for_Research
/contact=rumorr@bbsr.edu
/experiment=BATS
/cruise=bats###
/station=NA
!
! Comments:
!
! 0 value = less than detection limit
! -999 value = no data
!
/data_file_name=bats92_hplc.txt
/documents=default_readme.txt
/calibration_files=missing_calibration.txt
/data_type=pigment
/data_status=final
/cloud_percent=NA
/measurement_depth=NA
/secchi_depth=NA
/water_depth=NA
/wave_height=NA
/wind_speed=NA
!
! This is BATS Core data
! See: http://www.bbsr.edu/cintoo/bats/bats.html for additional information and data
!
/start_date=19920109
/end_date=19921207
/start_time=14:00:00[GMT]
/end_time=21:47:00[GMT]
/north_latitude=31.819[DEG]
/south_latitude=31.220[DEG]
/east_longitude=-63.978[DEG]
/west_longitude=-64.702[DEG]
/missing=-999
/delimiter=space
/fields=date,time,lat,lon,depth,Wt,sal
/units=yyyymmdd,hh:mm:ss,degrees,degrees,m,degreesC,PSU
/end_header
<BR/>
/missing=-999
/fields=date,time,lat,lat,lon,depth,Wt,sal
/end_header
