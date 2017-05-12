#! /usr/bin/perl
# $Id: 99_pod_coverage.t,v 1.2 2010/01/14 10:05:05 dk Exp $

use strict;
use warnings;

use Test::More;

eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required for testing POD coverage'
     if $@;

plan tests => 1;
pod_coverage_ok( 'MooseX::Lists', { trustme => [qr/^(array_writer|hash_writer|anon_hash|anon_array)$/] });
