#!perl

use strict;
use warnings;
use Test::More;

unless ($ENV{AUTHOR_TESTING}) {
    plan(skip_all => "Author tests not required for installation");
}

if (!require Test::Perl::Critic) {
    plan(skip_all => "Test::Perl::Critic required for testing PBP compliance");
}

Test::Perl::Critic::all_critic_ok();
