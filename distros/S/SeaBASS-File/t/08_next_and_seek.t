#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 48;
use Test::Trap qw(:default);
use List::MoreUtils qw(firstidx each_array);

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
    my $sb_file = SeaBASS::File->new(\$DATA[1], {preserve_case => 0, cache => 1});
    for (my $i = 0; $i <= $#data_rows; $i++) {
        is_deeply(scalar($sb_file->next()), $data_rows[$i], "next cache $i");
    }
    is($sb_file->next(), undef, 'next cache 1 undef');

    $sb_file->rewind();

    for (my $i = 0; $i <= $#data_rows; $i++) {
        is_deeply(scalar($sb_file->next()), $data_rows[$i], "next cache rewind $i");
    }
    is($sb_file->next(), undef, 'next cache 2 undef');
};
is($trap->leaveby, 'return', "cache trap");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[1], {preserve_case => 0, cache => 0});
    for (my $i = 0; $i <= $#data_rows; $i++) {
        is_deeply(scalar($sb_file->next()), $data_rows[$i], "next nocache $i");
    }
    is($sb_file->next(), undef, 'next nocache 1 undef');

    $sb_file->rewind();

    for (my $i = 0; $i <= $#data_rows; $i++) {
        is_deeply(scalar($sb_file->next()), $data_rows[$i], "next nocache rewind $i");
    }
    is($sb_file->next(), undef, 'next nocache 2 undef');
};
is($trap->leaveby, 'return', "nocache trap");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[1], {preserve_case => 0, cache => 0});
    for (my $i = 0; $i <= 1; $i++) {
        is_deeply(scalar($sb_file->next()), $data_rows[$i], "next nocache arbitrary rewind $i");
    }
    $sb_file->rewind();

    for (my $i = 0; $i <= $#data_rows; $i++) {
        is_deeply(scalar($sb_file->next()), $data_rows[$i], "next nocache arbitrary rewind rewind $i");
    }
};
is($trap->leaveby, 'return', "nocache arbitrary rewind trap");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[1], {preserve_case => 0, cache => 1});
    for (my $i = 0; $i <= 1; $i++) {
        is_deeply(scalar($sb_file->next()), $data_rows[$i], "next cache arbitrary rewind $i");
    }

    $sb_file->rewind();

    for (my $i = 0; $i <= $#data_rows; $i++) {
        is_deeply(scalar($sb_file->next()), $data_rows[$i], "next cache arbitrary rewind rewind $i");
    }
};
is($trap->leaveby, 'return', "cache arbitrary rewind trap");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[1], {preserve_case => 0, cache => 1});
    foreach my $index (qw(2 1 3 0)) {
        is_deeply(scalar($sb_file->data($index)), $data_rows[$index], "next cache arbitrary seek($index)");
    }
    is($sb_file->data(4), undef, "cache arbitrary seek undef");
};
is($trap->leaveby, 'return', "next cache arbitrary seek trap");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[1], {preserve_case => 0, cache => 0});
    foreach my $index (qw(2 1 3 0)) {
        is_deeply(scalar($sb_file->data($index)), $data_rows[$index], "next nocache arbitrary seek($index)");
    }
    is($sb_file->data(4), undef, "nocache arbitrary seek undef");
};
is($trap->leaveby, 'return', "next nocache arbitrary seek trap");

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
