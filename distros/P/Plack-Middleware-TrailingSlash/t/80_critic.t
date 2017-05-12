use strict;
use warnings;
 
use Test::More;
 
plan skip_all => "These tests are for authors only!" unless $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};

eval "use Test::Perl::Critic ( -severity => 4, -format => '%m in %f, line %l.' );";
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;

all_critic_ok();
