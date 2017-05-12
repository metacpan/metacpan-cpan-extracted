#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

is scalar(<DATA>), "aggregation!\n", 'data handle is accessible';

__DATA__
aggregation!
