use strict;
use warnings;

use Test::More;


plan skip_all => 'This test is only run for the module author'
    unless -d '.svn' || $ENV{IS_MAINTAINER};

eval 'use Test::Perl::Critic ( -severity => 4 )';
plan skip_all => 'Test::Perl::Critic required for testing POD' if $@;

all_critic_ok();
