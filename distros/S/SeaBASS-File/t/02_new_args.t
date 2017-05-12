#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;
use Test::Trap qw(:default);

use SeaBASS::File;

my @DATA = split(m"<BR/>\s*", join('', <DATA>));

trap {my $sb_file = SeaBASS::File->new(\$DATA[0], 'key_without_value');};
like($trap->die, qr/Even sized list/, "invalid number of arguments");

trap {my $sb_file = SeaBASS::File->new(\$DATA[0], 'invalid_option' => 1);};
like($trap->die, qr/Option not understood/, "invalid option");

trap {my $sb_file = SeaBASS::File->new(\$DATA[0], {'invalid_option' => 1});};
like($trap->die, qr/Option not understood/, "invalid option hash");

trap {my $sb_file = SeaBASS::File->new(\$DATA[0], {'headers' => 1});};
like($trap->die, qr/Option headers not of the right type/, "invalid option reference 1");

trap {my $sb_file = SeaBASS::File->new(\$DATA[0], {'preserve_case' => {}});};
like($trap->die, qr/Option .*? not of the right type/, "invalid option reference 2");

trap {my $sb_file = SeaBASS::File->new(\@DATA, {});};
like($trap->die, qr/Invalid parameter, expected file path or file handle./, "invalid file arg");

trap {my $sb_file = SeaBASS::File->new(\$DATA[0], {'headers' => {}, 'default_headers' => []});};
is($trap->leaveby, 'return', "headers/default_headers types");

trap {my $sb_file = SeaBASS::File->new(\$DATA[0], {'preserve_case' => 1});};
is($trap->leaveby, 'return', "preserve_case type");

done_testing();

__DATA__
/begin_header
/investigators=Anthony_Michaels
/affiliations=Bermuda_Biological_Station_for_Research
/contact=rumorr@bbsr.edu
/experiment=BATS
/cruise=bats###
/station=NA
/data_file_name=bats92_hplc.txt
/documents=default_readme.txt
/calibration_files=missing_calibration.txt
/data_type=pigment
/data_status=final
/start_date=19920109
/end_date=19921207
/start_time=14:00:00[GMT]
/end_time=21:47:00[GMT]
/north_latitude=31.819[DEG]
/south_latitude=31.220[DEG]
/east_longitude=-63.978[DEG]
/west_longitude=-64.702[DEG]
/cloud_percent=NA
/measurement_depth=NA
/secchi_depth=NA
/water_depth=NA
/wave_height=NA
/wind_speed=NA
!
! Comments:
!
! 0 value = less than detection limit
! -999 value = no data
!
! This is BATS Core data
! See: http://www.bbsr.edu/cintoo/bats/bats.html for additional information and data
!
/missing=-999
/delimiter=space
/fields=date,time,lat,lon,depth,Wt,sal
/units=yyyymmdd,hh:mm:ss,degrees,degrees,m,degreesC,PSU
/end_header
19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999
