#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 26;
use Test::Trap qw(:default);

use SeaBASS::File qw(STRICT_READ STRICT_WRITE STRICT_ALL INSERT_BEGINNING INSERT_END);

my @DATA = split(m"<BR/>\s*", join('', <DATA>));

trap {
    my $sb_file_orig = SeaBASS::File->new(\$DATA[0], {preserve_case => 1});
    is($sb_file_orig->h->{'investigators'}, 'Anthony_Michaels', 'header check case 1');
    my $sb_file_icase = SeaBASS::File->new(\$DATA[0], {preserve_case => 0});
    my @headers = $sb_file_icase->h('investigators', 'experiment');
    is($headers[0], 'anthony_michaels', 'header check icase 1');
    is($headers[1], 'bats',             'header check icase 2');
    my $headers = $sb_file_icase->h('investigators', 'experiment');
    is_deeply($headers, ['anthony_michaels', 'bats'], 'header check icase 3');
    $sb_file_icase->headers({'investigators' => 'tony'});
    my %headers = $sb_file_icase->h(['investigators', 'experiment']);
    is_deeply(\%headers, {investigators => 'tony', experiment => 'bats'}, 'header check modify 1');

    my $sb_file_slash_orig = SeaBASS::File->new(\$DATA[0], {preserve_case => 1, keep_slashes => 1});
    is($sb_file_slash_orig->h->{'/investigators'}, 'Anthony_Michaels', 'header check slash 1');
    my $sb_file_slash_def = SeaBASS::File->new(\$DATA[1], {preserve_case => 1, keep_slashes => 1, default_headers => ['/investigators=tony']});
    is($sb_file_slash_def->h->{'/investigators'}, 'tony', 'header check slash default array 1');
    my $sb_file_slash_over = SeaBASS::File->new(\$DATA[0], {preserve_case => 1, keep_slashes => 1, headers => ['/investigators=tony']});
    is($sb_file_slash_over->h->{'/investigators'}, 'tony', 'header check slash override array 1');

    my $sb_file_slash_def_hash = SeaBASS::File->new(\$DATA[1], {preserve_case => 1, keep_slashes => 1, default_headers => {investigators => 'tony'}});
    is($sb_file_slash_def_hash->h->{'/investigators'}, 'tony', 'header check slash default hash 1');
    my $sb_file_slash_over_hash = SeaBASS::File->new(\$DATA[0], {preserve_case => 1, keep_slashes => 1, headers => {investigators => 'tony'}});
    is($sb_file_slash_over_hash->h->{'/investigators'}, 'tony', 'header check slash override hash 1');

    my $sb_file_slash_def_hash_w_slash = SeaBASS::File->new(\$DATA[1], {preserve_case => 1, keep_slashes => 1, default_headers => {'/investigators' => 'tony'}});
    is($sb_file_slash_def_hash_w_slash->h->{'/investigators'}, 'tony', 'header check slash default hash with slash 1');
    my $sb_file_slash_over_hash_w_slash = SeaBASS::File->new(\$DATA[0], {preserve_case => 1, keep_slashes => 1, headers => {'/investigators' => 'tony'}});
    is($sb_file_slash_over_hash_w_slash->h->{'/investigators'}, 'tony', 'header check slash override hash with slash 1');

    my $sb_file_noslash_orig = SeaBASS::File->new(\$DATA[0], {preserve_case => 1, keep_slashes => 0});
    is($sb_file_noslash_orig->h->{'investigators'}, 'Anthony_Michaels', 'header check noslash 1');
    my $sb_file_noslash_def = SeaBASS::File->new(\$DATA[0], {preserve_case => 1, keep_slashes => 0, default_headers => ['/investigators=tony']});
    is($sb_file_noslash_def->h->{'investigators'}, 'Anthony_Michaels', 'header check noslash default 1');
    my $sb_file_noslash_over = SeaBASS::File->new(\$DATA[0], {preserve_case => 1, keep_slashes => 0, headers => ['/investigators=tony']});
    is($sb_file_noslash_over->h->{'investigators'}, 'tony', 'header check noslash override 1');

    my $sb_file_noslash_def_hash_w_slash = SeaBASS::File->new(\$DATA[1], {preserve_case => 1, keep_slashes => 0, default_headers => {'/investigators' => 'tony'}});
    is($sb_file_noslash_def_hash_w_slash->h->{'investigators'}, 'tony', 'header check noslash default hash with slash 1');
    my $sb_file_noslash_over_hash_w_slash = SeaBASS::File->new(\$DATA[0], {preserve_case => 1, keep_slashes => 0, headers => {'/investigators' => 'tony'}});
    is($sb_file_noslash_over_hash_w_slash->h->{'investigators'}, 'tony', 'header check noslash override hash with slash 1');
};
is($trap->leaveby, 'return', "header check trap");

trap {my $sb_file = SeaBASS::File->new(\$DATA[0], {headers => ['investigators=tony'], strict => STRICT_ALL});};
is($trap->leaveby, 'die', "header override invalid line 1");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0]);
    $sb_file->add_headers({'investigators' => 'jason_lefler1'});
    is($sb_file->h->{'investigators'}, 'jason_lefler1', 'add_headers hashref');
    $sb_file->add_headers(['/investigators=jason_lefler2']);
    is($sb_file->h->{'investigators'}, 'jason_lefler2', 'add_headers arrayref');
    $sb_file->add_headers('/investigators=jason_lefler3');
    is($sb_file->h->{'investigators'}, 'jason_lefler3', 'add_headers array');
};
is($trap->leaveby, 'return', "add_header trap");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0]);
    is($sb_file->add_headers(['investigators=jason_lefler']), 0, 'add_headers arrayref fail');
    is($sb_file->h->{'investigators'}, 'Anthony_Michaels', 'add_headers arrayref unchanged');
};
is($trap->leaveby, 'return', "add_header trap");

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
