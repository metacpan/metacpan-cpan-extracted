#!perl -wT

use strict;
use warnings;

use Test::More;


eval 'use Test::Perl::Critic';
if ( $@ ) {
    plan skip_all => 'Test::Perl::Critic required to test for best-practices';
}
else {
    Test::Perl::Critic::all_critic_ok();
}
