#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.22;";
plan skip_all => "Test::Pod 1.22 required for testing POD($@)" if $@;

all_pod_files_ok();

