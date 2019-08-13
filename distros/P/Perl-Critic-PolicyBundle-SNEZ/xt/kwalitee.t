#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN { plan skip_all => 'TEST_AUTHOR not enabled' if not $ENV{TEST_AUTHOR}; }

use Test::Kwalitee 'kwalitee_ok';
kwalitee_ok();

done_testing;
