#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 12;
use Test::Trap qw(:default);

use SeaBASS::File;

my @DATA = split(m"<BR/>\s*", join('', <DATA>));


my $sb_file_no_to_undef = SeaBASS::File->new(\$DATA[1], {missing_data_to_undef => 0, strict => 0});
my $sb_file_no_bdl = SeaBASS::File->new(\$DATA[0], {strict => 0});
my $sb_file_bdl = SeaBASS::File->new(\$DATA[1], {strict => 0});
my $sb_file_bdl_eq_missing = SeaBASS::File->new(\$DATA[2], {strict => 0});


is($sb_file_no_to_undef->data(0)->{'wt'}, -999, "no undef missing 1");
is($sb_file_no_to_undef->data(0)->{'sal'}, -111, "no undef normal 1");

is($sb_file_no_bdl->data(0)->{'wt'}, undef, "undef missing 1");
is($sb_file_no_bdl->data(0)->{'sal'}, -111, "undef no bdl 1");

is($sb_file_bdl->data(0)->{'wt'}, undef, "undef still missing 1");
is($sb_file_bdl->data(0)->{'sal'}, undef, "undef bdl 1");

trap {
	$sb_file_bdl->write();
};
is($trap->leaveby, 'return', "write trap 1");
is($trap->stdout,  $DATA[3], "write has bdl 1");

trap {
	$sb_file_bdl_eq_missing->write();
};
is($trap->leaveby, 'return', "write trap 2");
is($trap->stdout,  $DATA[3], "write has no bdl 2");

trap {
	$sb_file_no_to_undef->write();
};
is($trap->leaveby, 'return', "write trap 3");
is($trap->stdout,  $DATA[1], "write has bdl 3");

__DATA__
/begin_header
/missing=-999
/delimiter=space
/fields=date,time,lat,lon,depth,wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 -999 -111
<BR/>
/begin_header
/missing=-999
/below_detection_limit=-111
/delimiter=space
/fields=date,time,lat,lon,depth,wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 -999 -111
<BR/>
/begin_header
/missing=-999
/below_detection_limit=-999
/delimiter=space
/fields=date,time,lat,lon,depth,wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 -999 -999
<BR/>
/begin_header
/missing=-999
/delimiter=space
/fields=date,time,lat,lon,depth,wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 -999 -999
