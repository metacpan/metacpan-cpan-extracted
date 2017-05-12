#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

unless ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}) {
  plan(skip_all => 'AUTHOR_TESTING or RELEASE_TESTING is not set; skipping');
}

eval 'use Test::Perl::Critic'; ## no critic
plan skip_all => 'Test::Perl::Critic required' if $@;

all_critic_ok(qw(lib t));
