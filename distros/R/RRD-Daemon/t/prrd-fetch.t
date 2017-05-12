#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec::Functions  qw( catfile );
use FindBin  qw( $Bin );

use lib   $Bin;
use test  ( tests => 2, 
            qw( test_capture ));

use constant FETCH_EXPECT => <<'FETCH';
Intvl:	[1279173720 Thu Jul 15 06:02:00 2010 GMT] --- [1279177440 Thu Jul 15 07:04:00 2010 GMT]
Step:	120s
DS:	sda
Data#:	31
Data:
  [1279175520 Thu Jul 15 06:32:00 2010 GMT]	  27.1
  [1279175640 Thu Jul 15 06:34:00 2010 GMT]	  28.1
  [1279175760 Thu Jul 15 06:36:00 2010 GMT]	  29.1
  [1279175880 Thu Jul 15 06:38:00 2010 GMT]	  30.1
  [1279176000 Thu Jul 15 06:40:00 2010 GMT]	  31.0
  [1279176120 Thu Jul 15 06:42:00 2010 GMT]	  31.1
  [1279176240 Thu Jul 15 06:44:00 2010 GMT]	  32.0
  [1279176360 Thu Jul 15 06:46:00 2010 GMT]	  32.1
  [1279176480 Thu Jul 15 06:48:00 2010 GMT]	  33.1
  [1279176600 Thu Jul 15 06:50:00 2010 GMT]	  34.0
  [1279176720 Thu Jul 15 06:52:00 2010 GMT]	  34.0
  [1279176840 Thu Jul 15 06:54:00 2010 GMT]	  34.0
  [1279176960 Thu Jul 15 06:56:00 2010 GMT]	  35.0
  [1279177080 Thu Jul 15 06:58:00 2010 GMT]	  35.0
  [1279177200 Thu Jul 15 07:00:00 2010 GMT]	  36.0
  [1279177320 Thu Jul 15 07:02:00 2010 GMT]	  36.0
FETCH

use constant PRRD       => catfile test::BIN_DIR, 'prrd';
use constant RRD_FN     => catfile test::DATA_DIR, 'sda.rrd';

use constant TEST_COUNT => 2;

test_capture([ $^X, PRRD, fetch => RRD_FN,
                     -s => '20100715 06:00',
                     -e => '20100715 07:00' ], FETCH_EXPECT, 'fetch');
