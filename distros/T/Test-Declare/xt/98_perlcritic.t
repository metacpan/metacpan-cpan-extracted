use strict;
use warnings;
use Test::More;
plan skip_all => "this test requires Test::Perl::Critic" unless eval q{use Test::Perl::Critic;1;};

Test::Perl::Critic->import();
all_critic_ok("lib");

