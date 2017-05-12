#!/usr/bin/perl

# Test POD correctness
#
# $Id: 2-pod.t 223 2008-02-12 23:41:36Z davidp $

use strict;
use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

