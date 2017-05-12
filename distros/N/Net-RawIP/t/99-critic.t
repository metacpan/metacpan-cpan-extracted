use strict;
use warnings;
use Test::More;


plan skip_all => "Author tests" unless $ENV{AUTHOR_MODE};
plan skip_all => "Test::Perl::Critic required to criticise code"
    unless eval "use Test::Perl::Critic; 1";

all_critic_ok('blib');
#all_critic_ok('blib', 't');

