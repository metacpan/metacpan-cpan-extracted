#! /usr/bin/perl
# $Id: 98_pod.t,v 1.1 2010/01/13 22:07:14 dk Exp $

use strict;
use warnings;

use Test::More;
eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $@;
all_pod_files_ok(all_pod_files('blib'));
