#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 42;
use Test::Trap qw(:default);

use SeaBASS::File qw(STRICT_READ STRICT_WRITE STRICT_ALL INSERT_BEGINNING INSERT_END);

my @DATA = split(m"<BR/>\s*", join('', <DATA>));

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {'missing_data_to_undef' => 0, 'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'time'}, '01:02:03', 'time 1');
    is($sb_file->data(0)->{'second'}, '03', 'field padding 1');
    is($sb_file->data(0)->{'depth'}, undef, 'depth undef 1');
};
is($trap->leaveby, 'return', "trap 1");


trap {
    my $sb_file = SeaBASS::File->new(\$DATA[1], {'missing_data_to_undef' => 0, 'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'time'}, '01:02:03', 'time Second nocase 1');
    is($sb_file->data(0)->{'second'}, '03', 'field padding Second nocase 1');
    is($sb_file->data(0)->{'date'}, '20100101', 'date from julian nocase 1');
    is($sb_file->data(0)->{'depth'}, undef, 'na depth undef nocase 2');
};
is($trap->leaveby, 'return', "trap nocase");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[2], {'missing_data_to_undef' => 0, 'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'depth'}, 5, 'depth from header');
    is($sb_file->data(0)->{'date'}, '19920101', 'date from julian, year from header 1');
};
is($trap->leaveby, 'return', "trap 3");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[3], {'missing_data_to_undef' => 0, 'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'date'}, '19920201', 'year/month from header');
};
is($trap->leaveby, 'return', "trap 4");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[4], {'missing_data_to_undef' => 0, 'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'time'}, '01:02:06', 'seconds from header, no [gmt]');
};
is($trap->leaveby, 'return', "trap 5");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[5], {'missing_data_to_undef' => 0, 'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'date'}, '19920101', 'julian higher priority');
};
is($trap->leaveby, 'return', "trap 6");



trap {
    my $sb_file = SeaBASS::File->new(\$DATA[0], {'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'time'}, '01:02:03', 'missing_data_to_undef time 1');
    is($sb_file->data(0)->{'second'}, '03', 'missing_data_to_undef field padding 1');
    is($sb_file->data(0)->{'depth'}, undef, 'missing_data_to_undef depth undef 1');
};
is($trap->leaveby, 'return', "trap 7");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[1], {'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'time'}, '01:02:03', 'missing_data_to_undef time Second 1');
    is($sb_file->data(0)->{'second'}, '03', 'missing_data_to_undef field padding Second 1');
    is($sb_file->data(0)->{'date'}, '20100101', 'missing_data_to_undef date from julian 1');
    is($sb_file->data(0)->{'depth'}, undef, 'missing_data_to_undef na depth undef 2');
};
is($trap->leaveby, 'return', "trap 8");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[2], {'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'depth'}, 5, 'missing_data_to_undef depth from header');
    is($sb_file->data(0)->{'date'}, '19920101', 'missing_data_to_undef date from julian, year from header 1');
};
is($trap->leaveby, 'return', "trap 9");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[3], {'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'date'}, '19920201', 'missing_data_to_undef year/month from header');
};
is($trap->leaveby, 'return', "trap 10");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[4], {'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'time'}, '01:02:06', 'missing_data_to_undef seconds from header, no [gmt]');
};
is($trap->leaveby, 'return', "trap 11");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[5], {'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'date'}, '19920101', 'missing_data_to_undef julian higher priority');
};
is($trap->leaveby, 'return', "trap 12");


trap {
    my $sb_file = SeaBASS::File->new(\$DATA[6], {'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'time'}, '01:02:06', 'missing_data_to_undef seconds from header, [gmt]');
};
is($trap->leaveby, 'return', "trap 13");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[7], {'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'second'}, '03', 'missing_data_to_undef seconds from time field');
};
is($trap->leaveby, 'return', "trap 14");

trap {
    my $sb_file = SeaBASS::File->new(\$DATA[9], {'fill_ancillary_data' => 1});
    is($sb_file->data(0)->{'depth'}, '0', 'header, 0 measurement depth');
};
is($trap->leaveby, 'return', "trap 15");

done_testing();

__DATA__
/fields=lat,wt,sal,hour,minute,second,julian
31.389 20.7320 -999 1 2 3 1
<BR/>
/fields=lat,wt,sal,hour,minute,Second,year,julian
31.389 20.7320 -999 1 2 3 2010 1
<BR/>
/start_date=19920109
/measurement_depth=5
/fields=lat,wt,sal,hour,minute,Second,julian
31.389 20.7320 -999 1 2 3 1
<BR/>
/start_date=19920209
/fields=lat,wt,sal,hour,minute,Second,day
31.389 20.7320 -999 1 2 3 1
<BR/>
/start_time=04:05:06
/fields=lat,wt,sal,hour,minute,day
31.389 20.7320 -999 1 2 1
<BR/>
/fields=lat,wt,sal,hour,minute,second,year,month,day,julian
31.389 20.7320 -999 1 2 3 1992 1 5 1
<BR/>
/start_time=04:05:06[gmt]
/fields=lat,wt,sal,hour,minute,day
31.389 20.7320 -999 1 2 1
<BR/>
/start_time=04:05:06[gmt]
/fields=lat,wt,sal,time
31.389 20.7320 -999 01:02:03
<BR/>
/fields=date,time
19920102 01:02:03
<BR/>
/measurement_depth=0
/fields=date,time
19920102 01:02:03