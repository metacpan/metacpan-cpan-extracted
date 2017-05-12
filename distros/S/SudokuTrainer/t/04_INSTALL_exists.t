#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

ok(-f 'INSTALL', "file INSTALL exists") or BAIL_OUT('file INSTALL not found');

