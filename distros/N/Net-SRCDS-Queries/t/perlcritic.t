#!perl -T

use Test::More;

if ( $ENV{TEST_CRITIC} || $ENV{TEST_ALL} || !$ENV{HARNESS_ACTIVE} ) {
    eval "require Test::Perl::Critic";
    plan skip_all => "Test::Perl::Critic required for testing PBP compliance"
        if $@;
}
else {
    plan skip_all => 'set TEST_CRITIC for testing PBP compliance';
}

Test::Perl::Critic::all_critic_ok();
