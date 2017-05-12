#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use Test::Trap qw(:default);

use SeaBASS::File;

my @DATA = split(m"<BR/>\s*", join('', <DATA>));


my $sb_file_no_to_undef = SeaBASS::File->new(\$DATA[0], {missing_data_to_undef => 1, strict => 0, preserve_detection_limits => 1});

is($sb_file_no_to_undef->data(0)->{'wt'}, undef, "undef missing 1");
is($sb_file_no_to_undef->data(1)->{'wt'}, -888, "no bdl missing 1");
is($sb_file_no_to_undef->data(2)->{'wt'}, -777, "no adl missing 1");

__DATA__
/begin_header
/missing=-999
/below_detection_limit=-888
/above_detection_limit=-777
/delimiter=space
/fields=date,time,lat,lon,depth,wt,sal
/end_header
19920109 16:30:00 31.389 -64.702 3.4 -999 -111
19920109 16:30:00 31.389 -64.702 3.4 -888 -111
19920109 16:30:00 31.389 -64.702 3.4 -777 -111
