#!perl -wT
# $Id: pod_syntax.t 996 2005-12-03 01:37:51Z claco $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 not installed' if $@;

all_pod_files_ok();
