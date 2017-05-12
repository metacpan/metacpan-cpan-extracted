#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 38;
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
    $sb_file->remove_field();
};
like($trap->die, qr/Field\(s\) must be specified/, 'remove_field error 1');
is($trap->leaveby, 'die', "remove_field trap 1");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {});
    $sb_file->add_field();
};
like($trap->die, qr/Field must be specified/, 'add_field error 1');
is($trap->leaveby, 'die', "add_field trap 1");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {});
    $sb_file->remove_field('fakefield');
};
like($trap->stderr, qr/Field fakefield does not exist/, 'remove_field error 2');
is($trap->leaveby, 'return', "remove_field trap 2");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    $sb_file->remove_field('time');
    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    foreach my $row (@new_rows) {
        delete($row->{'time'});
    }
    is_deeply(scalar($sb_file->all()), \@new_rows, 'remove field test 1');
};
is($trap->leaveby, 'return', "remove_field trap 3");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    $sb_file->next();
    $sb_file->next();
    $sb_file->remove_field('time');
    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    foreach my $row (@new_rows) {
        delete($row->{'time'});
    }
    is_deeply(scalar($sb_file->all()), \@new_rows, 'remove field arbitrary test 1');
};
is($trap->leaveby, 'return', "remove_field arbitrary trap 1");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    $sb_file->add_field('time2');
    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    foreach my $row (@new_rows) {
        $row->{'time2'} = -999;
    }
    is_deeply(scalar($sb_file->all()), \@new_rows, 'add field test 1');
};
is($trap->leaveby, 'return', "add_field trap 2");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 1, preserve_case => 0});
    $sb_file->add_field('time2');
    my $new_rows = clone(\@data_rows_sal_undef);
    my @new_rows = @$new_rows;
    foreach my $row (@new_rows) {
        $row->{'time2'} = undef;
    }
    is_deeply(scalar($sb_file->all()), \@new_rows, 'add field test undef 1');
};
is($trap->leaveby, 'return', "add_field undef trap 2");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    $sb_file->next();
    $sb_file->next();
    $sb_file->add_field('time2');
    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    foreach my $row (@new_rows) {
        $row->{'time2'} = -999;
    }
    is_deeply(scalar($sb_file->all()), \@new_rows, 'add field arbitrary test 1');
};
is($trap->leaveby, 'return', "add_field arbitrary trap 1");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {});
    $sb_file->add_field('fakefield');
    $sb_file->add_field('fakefield');
};
like($trap->die, qr/Field already exists/, 'add_field error 2');
is($trap->leaveby, 'die', "add_field trap 3");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    $sb_file->add_field('fakefield3', 'unitless3', INSERT_BEGINNING);
    $sb_file->add_field('fakefield4');
    $sb_file->add_field('fakefield2', 'unitless2', 3);
    $sb_file->add_field('fakefield1', 'unitless1', INSERT_END);
    my @actual_fields = qw(fakefield3 date time fakefield2 lat lon depth wt sal fakefield4 fakefield1);
    my @actual_units  = qw(unitless3 yyyymmdd hh:mm:ss unitless2 degrees degrees m degreesc psu unitless unitless1);
    is_deeply(scalar($sb_file->actual_fields()), \@actual_fields, "actual_fields 1");
    is_deeply(scalar($sb_file->actual_units()),  \@actual_units,  "actual_units 1");

    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    foreach my $row (@new_rows) {
        $row->{'fakefield1'} = -999;
        $row->{'fakefield2'} = -999;
        $row->{'fakefield3'} = -999;
        $row->{'fakefield4'} = -999;
    } ## end foreach my $row (@new_rows)

    is_deeply(scalar($sb_file->all()), \@new_rows, "actual fields all test 1");
};
is($trap->leaveby, 'return', "add_field trap 4");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    $sb_file->add_field('fakefield3', 'unitless3', INSERT_BEGINNING);
    $sb_file->add_field('fakefield4');
    $sb_file->add_field('fakefield2', 'unitless2', 3);
    $sb_file->add_field('fakefield1', 'unitless1', INSERT_END);
    $sb_file->next();
    $sb_file->remove_field('fakefield2');
    my @actual_fields = qw(fakefield3 date time lat lon depth wt sal fakefield4 fakefield1);
    my @actual_units  = qw(unitless3 yyyymmdd hh:mm:ss degrees degrees m degreesc psu unitless unitless1);
    is_deeply(scalar($sb_file->actual_fields()), \@actual_fields, "actual_fields 2");
    is_deeply(scalar($sb_file->actual_units()),  \@actual_units,  "actual_units 2");

    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    foreach my $row (@new_rows) {
        $row->{'fakefield1'} = -999;
        $row->{'fakefield3'} = -999;
        $row->{'fakefield4'} = -999;
    }

    is_deeply(scalar($sb_file->all()), \@new_rows, "add and remove field all test 1");
};
is($trap->leaveby, 'return', "add and remove field trap 1");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    my @ret_l = $sb_file->find_fields('lat');
    is_deeply(\@ret_l, [qw(lat)], 'find lat');
    my @ret_lt = $sb_file->find_fields('lat','time');
    is_deeply(\@ret_lt, [[qw(lat)],[qw(time)]], 'find lat time');
    my @ret_cl = $sb_file->find_fields(qr/^l/);
    is_deeply(\@ret_cl, [qw(lat lon)], 'find regex');
    my @ret_ci1 = $sb_file->find_fields(qr/^L/);
    is_deeply(\@ret_ci1, [qw(lat lon)], 'find regex ci');
    my @ret_ci2 = $sb_file->find_fields('LAT');
    is_deeply(\@ret_ci2, [qw(lat)], 'find string ci');
    my $ret_scalar_single = $sb_file->find_fields(qr/L/);
    is($ret_scalar_single, 3, 'find scalar context singular');
    my $ret_scalar_multi = $sb_file->find_fields(qr/L/, 'sal');
    is_deeply($ret_scalar_multi, [[qw(lat lon sal)], [qw(sal)]], 'find scalar context multi');
    
    my ($ls, $times) = $sb_file->find_fields(qr/l/,'time');
    is_deeply($ls, [qw(lat lon sal)], 'find l time list ls');
    is_deeply($times, [qw(time)], 'find l time list times');
};
is($trap->leaveby, 'return', "find fields trap 1");


trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 0, preserve_case => 0});
    $sb_file->remove_field($sb_file->find_fields(qr/^L/));
    my $new_rows = clone(\@data_rows);
    my @new_rows = @$new_rows;
    foreach my $row (@new_rows) {
        delete($row->{'lat'});
        delete($row->{'lon'});
    }
    is_deeply(scalar($sb_file->all()), \@new_rows, 'remove find field test 1');
};
is($trap->leaveby, 'return', "remove find field trap 3");

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
