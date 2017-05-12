#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;


plan skip_all => 'Set RELEASE_TESTING to enable this test (developer only)'
	unless $ENV{RELEASE_TESTING};
plan skip_all => 'Test::Pod::Coverage 1.04 required for this test'
	unless eval('use Test::Pod::Coverage 1.04; 1');
plan skip_all => 'Pod::Coverage 0.18 required for this test'
	unless eval('use Pod::Coverage 0.18; 1');

pod_coverage_ok('AnyEvent::Delay::Simple');


done_testing;
