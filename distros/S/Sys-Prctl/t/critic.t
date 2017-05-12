use strict;
use warnings;

use Test::More;

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

eval { 
    require Test::Perl::Critic;
    import  Test::Perl::Critic(-profile => 't/perlcriticrc');
};
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;

all_critic_ok('blib');
