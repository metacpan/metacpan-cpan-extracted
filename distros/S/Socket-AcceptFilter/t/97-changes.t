#!/usr/bin/env perl -w

use strict;
use Test::More;
use lib::abs;

chdir lib::abs::path '..' or plan skip_all => "Can't chdir to dist: $!";

$ENV{TEST_AUTHOR} or plan skip_all => '$ENV{TEST_AUTHOR} not set';
eval "use Test::CheckChanges ;1"
	or plan skip_all => "Test::CheckChanges  required for testing Changes";

ok_changes();
