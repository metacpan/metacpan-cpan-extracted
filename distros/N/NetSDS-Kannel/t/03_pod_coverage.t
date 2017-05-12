#!/usr/bin/env perl
#===============================================================================
#
#         FILE:  03_pod_coverage.t
#
#  DESCRIPTION:  Check POD coverage
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  13.07.2008 23:54:48 EEST
#===============================================================================

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

all_pod_coverage_ok();
