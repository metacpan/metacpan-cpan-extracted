#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec::Functions  qw( catfile );
use FindBin  qw( $Bin );

use lib   $Bin;
use test  ( tests => 2,
            qw( test_capture ));

use constant INFO_EXPECT => <<'INFO';
filename    : __FILENAME__
last_update : Thu Jul 15 19:31:51 2010 GMT
rrd_version : 0003
step        : 120
# name	type	min	max	htbeat	last	value	unk_sec
sda	GAUGE	0	-	300	29	3219	0
# num	cf	cur_ruw	pdp/row	rows	xff	row	dur
## cdp	value	unknown
0	MAX	-	1	2880	0.7	 2m	4d
   0	-	-
1	MAX	-	5	1440	0.7	10m	 1w3d
   0	-	-
2	MAX	-	15	1440	0.7	30m	 4w2d
   0	-	-
3	MAX	-	90	29280	0.7	 3h	10y 2w6d
   0	-	-
INFO

use constant PRRD       => catfile test::BIN_DIR, 'prrd';
use constant RRD_FN     => catfile test::DATA_DIR, 'sda.rrd';

use constant TEST_COUNT => 2;

(my $expect = INFO_EXPECT) =~ s/__FILENAME__/RRD_FN/eg;
test_capture([ $^X, PRRD, info => RRD_FN ], $expect, 'info');
