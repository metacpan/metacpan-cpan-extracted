#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;


plan skip_all => 'Set RELEASE_TESTING to enable this test (developer only)'
	unless $ENV{RELEASE_TESTING};
plan skip_all => 'Test::CPAN::Changes required for this test'
	unless eval('use Test::CPAN::Changes; 1');

changes_ok();


done_testing;
