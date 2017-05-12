#! /usr/bin/perl
# $Id$

use strict;
use warnings;

use Test::More;
eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required for testing POD coverage'
    if $@;

plan tests => 2;
pod_coverage_ok( 'Prima::OpenGL'   => { trustme => [
	qr/^(context_|dl_|flush)/x 
]});
pod_coverage_ok( 'Prima::GLWidget' => { trustme => [ 
	qr/^(on_|profile_|init|notify|set)/x 
]});

