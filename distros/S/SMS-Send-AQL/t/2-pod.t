#!/usr/bin/perl

# Test POD correctness for Finance::PremiumBonds
#
# $Id: 2-pod.t 212 2008-01-19 15:31:33Z davidp $

use strict;
use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

