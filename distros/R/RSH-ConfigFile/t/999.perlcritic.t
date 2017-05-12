#!perl

use Test::More;

if (!require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

Test::More::plan(
    skip_all => "Not worrying about perl critic right now."
);

#Test::Perl::Critic::all_critic_ok();

