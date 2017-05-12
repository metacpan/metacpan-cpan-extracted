#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 15;
use Test::Trap qw(:default);
use List::MoreUtils qw(each_array);

use SeaBASS::File qw(STRICT_READ STRICT_WRITE STRICT_ALL INSERT_BEGINNING INSERT_END);

my @DATA = split(m"<BR/>\s*", join('', <DATA>));
my (@data_rows, @data_rows_sal_undef);
my @depth = qw(3.4 19.1 38.3 59.6);
my @wt    = qw(20.7320 20.7350 20.7400 20.7450);

my $iter = each_array(@depth, @wt);
while (my ($depth, $wt) = $iter->()) {
    push(@data_rows,                {'date' => '19920109', 'time' => '16:30:00', 'lat' => '31.389', 'lon' => '-64.702', 'depth' => $depth, 'wt' => $wt, 'sal' => '-999'});
    push(@data_rows_sal_undef,      {'date' => '19920109', 'time' => '16:30:00', 'lat' => '31.389', 'lon' => '-64.702', 'depth' => $depth, 'wt' => $wt, 'sal' => undef});
}

trap {
    my $sb_file1 = SeaBASS::File->new(\$DATA[0], {preserve_case => 0, cache => 0, missing_data_to_undef => 0});
    my @all1 = $sb_file1->all();
    is_deeply(\@all1, \@data_rows, 'missing to undef 0');
    my $sb_file2 = SeaBASS::File->new(\$DATA[0], {preserve_case => 0, cache => 0, missing_data_to_undef => 1});
    my @all2 = $sb_file2->all();
    is_deeply(\@all2, \@data_rows_sal_undef, 'missing to undef 1');
};
is($trap->leaveby, 'return', "missing to undef trap");

trap {
    my $sb_file1 = SeaBASS::File->new(\$DATA[0], {preserve_comments => 0});
    my @comments1 = $sb_file1->comments();
    is($#comments1, -1, 'preserve_comments off');
    my $sb_file2 = SeaBASS::File->new(\$DATA[0], {preserve_comments => 1});
    my @comments2 = $sb_file2->comments();
    is($#comments2, 8, 'preserve_comments on');

    my $sb_file3 = SeaBASS::File->new(\$DATA[0], {preserve_comments => 1, headers => ['! new comment line!']});
    my @comments3 = $sb_file3->comments();
    is($#comments3, 9, 'preserve_comments on, additional 1');
};
is($trap->leaveby, 'return', "preserve_comments trap");

trap {
    my $sb_file1 = SeaBASS::File->new(\$DATA[0], {delete_missing_headers => 0, preserve_case => 0});
    is($sb_file1->h->{'wind_speed'}, 'na', 'delete_missing_headers off');
    my $sb_file2 = SeaBASS::File->new(\$DATA[0], {delete_missing_headers => 1});
    is($sb_file2->h->{'wind_speed'}, undef, 'delete_missing_headers on');

};
is($trap->leaveby, 'return', "delete_missing_headers trap");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[1], {preserve_case => 1, missing_data_to_undef => 0});
    my @all1 = $sb_file->all();
    is_deeply(\@all1, \@data_rows, 'preserve case');
};
is($trap->leaveby, 'return', "preserve case trap");

trap {
    my $sb_file1 = SeaBASS::File->new(\$DATA[0], {preserve_case => 0, missing_data_to_undef => 0});
    my @all1 = $sb_file1->all();
    is_deeply(\@all1, \@data_rows, 'missing to undef 0');
    my $sb_file2 = SeaBASS::File->new(\$DATA[0], {preserve_case => 0, missing_data_to_undef => 1});
    my @all2 = $sb_file2->all();
    is_deeply(\@all2, \@data_rows_sal_undef, 'missing to undef 1');
};
is($trap->leaveby, 'return', "missing to undef trap");

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
/fields=date,time,lat,lon,depth,Wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999
