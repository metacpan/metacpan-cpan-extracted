#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 18;
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
    $sb_file->update();
};
like($trap->die, qr/No rows read yet/, 'update no read rows');
is($trap->leaveby, 'die', "update trap 1");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {});
    $sb_file->next();
    $sb_file->update();
};
like($trap->die, qr/Error parsing inputs/, 'update no args');
is($trap->leaveby, 'die', "update trap 2");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {cache => 0});
    $sb_file->next();
    $sb_file->update({});
};
like($trap->die, qr/Caching must be enabled to write/, 'update no cache');
is($trap->leaveby, 'die', "update trap 3");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {});
    $sb_file->next();
    $sb_file->update(1, 2, 3);
};
like($trap->die, qr/Error parsing inputs/, 'update invalid args');
is($trap->leaveby, 'die', "update trap 4");

trap {
    my $new_row = {date => '20000101'};
    my $sb_file = SeaBASS::File->new(\$DATA[0], {});
    $sb_file->next();
    $sb_file->update($new_row);
    $sb_file->rewind();
    my $row = $sb_file->next();
    is_deeply($row, $new_row, 'update 1');

    my $row2 = $sb_file->d(0);
    is_deeply($row2, $new_row, 'update 2');
};
is($trap->leaveby, 'return', "update trap 5");

trap {
    my $new_row = {date => '20000101'};
    my $sb_file = SeaBASS::File->new(\$DATA[0], {});
    $sb_file->next();
    $sb_file->update(%$new_row);
    $sb_file->rewind();
    my $row = $sb_file->next();
    is_deeply($row, $new_row, 'update hash 1');

    my $row2 = $sb_file->d(0);
    is_deeply($row2, $new_row, 'update hash 2');
};
is($trap->leaveby, 'return', "update trap 6");

trap {
    #/fields=date,time,lat,lon,depth,Wt,sal
    my $new_row = {'date' => '20000101', 'time' => '00:00:00', 'lat' => 10, 'lon' => 15, 'depth' => 5, 'wt' => '20.7320', 'sal' => '32'};
    my $sb_file = SeaBASS::File->new(\$DATA[0], {preserve_case => 0});
    $sb_file->next();
    $sb_file->update([qw(20000101 00:00:00 10 15 5 20.7320 32)]);
    $sb_file->next();
    $sb_file->update("20000101 00:00:00 10 15 5 20.7320 32");

    my $new_rows = clone(\@data_rows_sal_undef);
    my @new_rows = @$new_rows;
    splice(@new_rows, 0, 2, $new_row, $new_row);

    is_deeply(scalar($sb_file->all()), \@new_rows, 'update arrayref/line test all 1');
};
is($trap->leaveby, 'return', "update trap 7");

trap {
    #/fields=date,time,lat,lon,depth,Wt,sal
    my $new_row1 = {'date' => '20000101', 'time' => '00:00:00', 'lat' => 10, 'lon' => 15, 'depth' => 5, 'wt' => '20.7320', 'sal' => '32', 'test' => 1};
    my $new_row2 = {'date' => '20000101', 'time' => '00:00:00', 'lat' => 10, 'lon' => 15, 'depth' => 5, 'wt' => '20.7320', 'sal' => '32', 'test' => undef};
    my $sb_file = SeaBASS::File->new(\$DATA[0], {preserve_case => 0});
    $sb_file->add_field('test');
    $sb_file->next();
    $sb_file->update([qw(20000101 00:00:00 10 15 5 20.7320 32 1)]);
    $sb_file->next();
    $sb_file->update("20000101 00:00:00 10 15 5 20.7320 32 1");
    $sb_file->next();
    $sb_file->update([qw(20000101 00:00:00 10 15 5 20.7320 32)]);
    $sb_file->next();
    $sb_file->update("20000101 00:00:00 10 15 5 20.7320 32");

    my @new_rows = ($new_row1, $new_row1, $new_row2, $new_row2);

    is_deeply(scalar($sb_file->all()), \@new_rows, 'update arrayref/line test all 2');
};
is($trap->leaveby, 'return', "update trap 8");

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
