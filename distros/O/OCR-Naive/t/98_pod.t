#! /usr/bin/perl
# $Id: 98_pod.t,v 1.1 2007/08/20 15:19:01 dk Exp $

use strict;
use warnings;

use Test::More;
eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $@;
all_pod_files_ok(all_pod_files('blib'));
