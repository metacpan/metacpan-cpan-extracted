#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $@;

pod_file_ok('Mmap.pm');
done_testing();
