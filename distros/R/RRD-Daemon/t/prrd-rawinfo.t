#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec::Functions  qw( catfile );
use FindBin  qw( $Bin );

use lib   $Bin;
use test  ( tests => 2,
            qw( test_capture ));

use constant RAWINFO_EXPECT => <<'RAWINFO';
---
'ds[sda]':
  last_ds: 29
  max: ~
  min: 0
  minimal_heartbeat: 300
  type: GAUGE
  unknown_sec: 0
  value: 3219
filename: __FILENAME__
last_update: 1279222311
'rra[0]':
  'cdp_prep[0]':
    unknown_datapoints: 0
    value: ~
  cf: MAX
  cur_row: 1301
  pdp_per_row: 1
  rows: 2880
  xff: 0.7
'rra[1]':
  'cdp_prep[0]':
    unknown_datapoints: 0
    value: ~
  cf: MAX
  cur_row: 725
  pdp_per_row: 5
  rows: 1440
  xff: 0.7
'rra[2]':
  'cdp_prep[0]':
    unknown_datapoints: 0
    value: ~
  cf: MAX
  cur_row: 508
  pdp_per_row: 15
  rows: 1440
  xff: 0.7
'rra[3]':
  'cdp_prep[0]':
    unknown_datapoints: 45
    value: ~
  cf: MAX
  cur_row: 18747
  pdp_per_row: 90
  rows: 29280
  xff: 0.7
rrd_version: 0003
step: 120

RAWINFO

use constant PRRD       => catfile test::BIN_DIR, 'prrd';
use constant RRD_FN     => catfile test::DATA_DIR, 'sda.rrd';

use constant TEST_COUNT => 2;

(my $expect = RAWINFO_EXPECT) =~ s/__FILENAME__/RRD_FN/eg;
test_capture([ $^X, PRRD, rawinfo => RRD_FN ], $expect, 'rawinfo');
