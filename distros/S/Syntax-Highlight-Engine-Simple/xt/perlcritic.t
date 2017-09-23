#!perl

use strict;
use Test::More;

eval {
    require Test::Perl::Critic;
    Test::Perl::Critic->import(-profile => "xt/perlcriticrc")
};

if ($@) {
    
    plan skip_all => "Test::Perl::Critic is not installed.";
}

elsif (version->new($Perl::Critic::VERSION) lt "1.088") {
    
    plan skip_all => "Perl::Critic 1.088 required for the test.";
}

all_critic_ok("lib");
