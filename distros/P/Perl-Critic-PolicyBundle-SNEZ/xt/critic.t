#!/usr/bin/perl
use strict;
use warnings;
use File::Spec;
use Test::More;

BEGIN { plan skip_all => 'TEST_AUTHOR not enabled' if not $ENV{TEST_AUTHOR}; }

use Test::Perl::Critic;

all_critic_ok();
