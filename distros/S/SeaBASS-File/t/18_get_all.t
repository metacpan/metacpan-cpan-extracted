#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 24;
use Test::Trap qw(:default);
use Clone qw(clone);

use SeaBASS::File qw(STRICT_READ STRICT_WRITE STRICT_ALL INSERT_BEGINNING INSERT_END);

my @DATA = split(m"<BR/>\s*", join('', <DATA>));
my @depth = qw(3.4 19.1 38.3 59.6);
my @wt    = qw(20.7320 20.7350 20.7400 20.7450);
my @date_time = ('19920109 16:30:00','19920109 16:30:00','19920109 16:30:00','19920109 16:30:00');

my @depth2 = qw(3.4 19.1 59.6);
my @wt2    = qw(20.7320 20.7350 20.7450);

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    my $ret = $sb_file->get_all('l');
};
like($trap->die, qr/Field l does not exist/, 'get_all die 1');
is($trap->leaveby, 'die', "get_all die trap 1");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    my $ret = $sb_file->get_all('wt','l');
};
like($trap->die, qr/Field l does not exist/, 'get_all die 2');
is($trap->leaveby, 'die', "get_all die trap 2");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    my $ret = $sb_file->get_all('l', 'wt');
};
like($trap->die, qr/Field l does not exist/, 'get_all die 3');
is($trap->leaveby, 'die', "get_all die trap 3");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    my $ret = $sb_file->get_all('depth');
    is_deeply($ret, \@depth, 'single scalar ret');
    my @ret = $sb_file->get_all('depth');
    is_deeply(\@ret, \@depth, 'single array ret');
};
is($trap->leaveby, 'return', "get_all trap 2");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    my $ret = $sb_file->get_all('depth', 'WT');
    is_deeply($ret, [\@depth, \@wt], 'multi scalar ret');
    my @ret = $sb_file->get_all('depth', 'wt');
    is_deeply(\@ret, [\@depth, \@wt], 'multi array ret');
    my ($ga_d, $ga_wt) = $sb_file->get_all('depth', 'wt');
    is_deeply($ga_d, \@depth, 'multi list ret 1');
    is_deeply($ga_wt, \@wt, 'multi list ret 2');
};
is($trap->leaveby, 'return', "get_all trap 3");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[1], {missing_data_to_undef => 0, preserve_case => 0});
    my $ret = $sb_file->get_all('depth', 'WT', {delete_missing => 1});
    is_deeply($ret, [\@depth2, \@wt2], 'multi scalar ret del_missing');
    my ($ga_d, $ga_wt) = $sb_file->get_all('depth', 'wt', {delete_missing => 1});
    is_deeply($ga_d, \@depth2, 'multi list ret 1 del_missing');
    is_deeply($ga_wt, \@wt2, 'multi list ret 2 del_missing');
};
is($trap->leaveby, 'return', "get_all trap 4");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[1], {missing_data_to_undef => 1, preserve_case => 0});
    my $ret = $sb_file->get_all('depth', 'WT', {delete_missing => 1});
    is_deeply($ret, [\@depth2, \@wt2], 'multi scalar ret del_missing missing_to_undef');
    my ($ga_d, $ga_wt) = $sb_file->get_all('depth', 'wt', {delete_missing => 1});
    is_deeply($ga_d, \@depth2, 'multi list ret 1 del_missing missing_to_undef');
    is_deeply($ga_wt, \@wt2, 'multi list ret 2 del_missing missing_to_undef');
};
is($trap->leaveby, 'return', "get_all trap 5");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[1], {missing_data_to_undef => 1, preserve_case => 0, fill_ancillary_data => 1});
    my $ret = $sb_file->get_all('date_time', {delete_missing => 1});
    is_deeply($ret, \@date_time, 'ancillary field');
};
is($trap->leaveby, 'return', "get_all trap 6");

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
<BR/>
/missing=-999
/fields=date,time,lat,lat,lon,depth,Wt,sal
/end_header
19920109 16:30:00 31.389 32.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 32.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 32.389 -64.702 38.3 -999 -999
19920109 16:30:00 31.389 32.389 -64.702 59.6 20.7450 -999
<BR/>
/missing=-998
/units=date,time,lat,lon,depth,Wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999
<BR/>
/missing=-998
/delimiter=notspace
/fields=date,time,lat,lon,depth,Wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999
