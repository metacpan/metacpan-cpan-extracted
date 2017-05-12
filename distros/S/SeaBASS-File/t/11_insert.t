#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 29;
use Test::Trap qw(:default);
use List::MoreUtils qw(firstidx each_array);
use Clone qw(clone);

use SeaBASS::File qw(STRICT_READ STRICT_WRITE STRICT_ALL INSERT_BEGINNING INSERT_END);

my @DATA = split(m"<BR/>\s*", join('', <DATA>));
my (@data_rows, @data_rows_sal_undef, @data_rows_case_preserved);
my @depth = qw(3.4 19.1 38.3 59.6);
my @wt    = qw(20.7320 20.7350 20.7400 20.7450);

my $iter = each_array(@depth, @wt);
while (my ($depth, $wt) = $iter->()) {
    push(@data_rows,                {'date' => '19920109', 'time' => '16:30:00', 'lat' => '31.389', 'lon' => '-64.702', 'depth' => $depth, 'wt' => $wt, 'sal' => '-999'});
    push(@data_rows_case_preserved, {'date' => '19920109', 'time' => '16:30:00', 'lat' => '31.389', 'lon' => '-64.702', 'depth' => $depth, 'Wt' => $wt, 'sal' => '-999'});
    push(@data_rows_sal_undef,      {'date' => '19920109', 'time' => '16:30:00', 'lat' => '31.389', 'lon' => '-64.702', 'depth' => $depth, 'wt' => $wt, 'sal' => undef});
}

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {});
    $sb_file->insert(-2, {});
};
like($trap->die, qr/Index must be positive integer/, 'insert -2');
is($trap->leaveby, 'die', "insert trap 1");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {});
    $sb_file->insert(200, {});
};
like($trap->die, qr/Index out of bounds/, 'insert 200');
is($trap->leaveby, 'die', "insert trap 2");

trap {
    my $new_row = {date => '20000101'};
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    $sb_file->insert(1, $new_row);
    is_deeply(scalar($sb_file->next()), $data_rows[0], 'insert next 0');
    is_deeply(scalar($sb_file->next()), $new_row,      'insert next 1');
    is_deeply(scalar($sb_file->next()), $data_rows[1], 'insert next 2');

    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    splice(@new_rows, 1, 0, $new_row);

    is_deeply(scalar($sb_file->all()), \@new_rows, 'insert data 1');
};
is($trap->leaveby, 'return', "insert trap 1");

trap {
    my $new_row = {date => '20000101'};
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    is_deeply(scalar($sb_file->data(2)), $data_rows[2], 'insert arbitrary 1');
    $sb_file->insert(1, $new_row);
    is_deeply(scalar($sb_file->next()), $data_rows[3], 'insert arbitrary 2');

    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    splice(@new_rows, 1, 0, $new_row);

    is_deeply(scalar($sb_file->all()), \@new_rows, 'insert data 2');
};
is($trap->leaveby, 'return', "insert trap 2");

trap {
    my $new_row = {date => '20000101'};
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    is_deeply(scalar($sb_file->data(2)), $data_rows[2], 'insert beginning 1');
    $sb_file->insert(INSERT_BEGINNING, $new_row);
    is_deeply(scalar($sb_file->next()), $data_rows[3], 'insert beginning 2');

    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    splice(@new_rows, 0, 0, $new_row);

    is_deeply(scalar($sb_file->all()), \@new_rows, 'insert data 3');
};
is($trap->leaveby, 'return', "insert trap 3");

trap {
    my $new_row = {date => '20000101'};
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    is_deeply(scalar($sb_file->data(2)), $data_rows[2], 'insert end 1');
    $sb_file->insert(INSERT_END, $new_row);
    is_deeply(scalar($sb_file->next()), $data_rows[3], 'insert end 2');

    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    push(@new_rows, $new_row);

    is_deeply(scalar($sb_file->all()), \@new_rows, 'insert data 4');
};
is($trap->leaveby, 'return', "insert trap 4");

trap {
    my $new_row = {date => '20000101'};
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    is_deeply(scalar($sb_file->data(2)), $data_rows[2], 'prepend 1');
    $sb_file->prepend($new_row);
    is_deeply(scalar($sb_file->next()), $data_rows[3], 'prepend 2');

    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    splice(@new_rows, 0, 0, $new_row);

    is_deeply(scalar($sb_file->all()), \@new_rows, 'prepend data 1');
};
is($trap->leaveby, 'return', "prepend trap 1");

trap {
    my $new_row = {date => '20000101'};
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    is_deeply(scalar($sb_file->data(2)), $data_rows[2], 'append 1');
    $sb_file->append($new_row);
    is_deeply(scalar($sb_file->next()), $data_rows[3], 'append 2');

    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    push(@new_rows, $new_row);

    is_deeply(scalar($sb_file->all()), \@new_rows, 'append data 1');
};
is($trap->leaveby, 'return', "append trap 1");

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
<BR/>
/units=date,time,lat,lon,depth,Wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999
<BR/>
/delimiter=notspace
/fields=date,time,lat,lon,depth,Wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999
