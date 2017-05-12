#!/sw/bin/perl

use strict;
use warnings;
use Test::More;

eval 'use Test::Perl::Critic (-severity => 3) ';
if ($@) {
  plan skip_all => 'Test::Perl::Critic required to criticize code';
}

if ($INC{'Devel/Cover.pm'}) {
  plan skip_all => 'running under Devel::Cover, skipping Perl::Critic tests'
}

if ($ENV{USER} ne 'coneill' and not defined $ENV{TEST_AUTHOR}) {
  plan skip_all => 'Test::Perl::Critic only run for author tests';
}

all_critic_ok();
