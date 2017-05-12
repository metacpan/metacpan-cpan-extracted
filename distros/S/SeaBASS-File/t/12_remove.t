#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;
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
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    is_deeply(scalar($sb_file->data(2)), $data_rows[2], 'remove 1');
    $sb_file->remove();
    is_deeply(scalar($sb_file->next()), $data_rows[3], 'remove 2');

    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    splice(@new_rows, 2, 1);
    is_deeply(scalar($sb_file->all()), \@new_rows, 'remove data 1');

    $sb_file->remove(0);
    splice(@new_rows, 0, 1);
    is_deeply(scalar($sb_file->all()), \@new_rows, 'remove data 2');
};
is($trap->leaveby, 'return', "remove 1");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    $sb_file->remove(4);
};
like($trap->die, qr/Index out of bounds/, 'remove die error');
is($trap->leaveby, 'die', "remove die 2");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    $sb_file->remove(2);

    is_deeply(scalar($sb_file->next()), $data_rows[0], 'remove data 0');

    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    splice(@new_rows, 2, 1);
    is_deeply(scalar($sb_file->all()), \@new_rows, 'remove data 3');

};
is($trap->leaveby, 'return', "remove 3");

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
/missing=-998
/fields=date,time,lat,lon,depth,Wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999
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
