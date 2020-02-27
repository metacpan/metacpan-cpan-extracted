use strict;
use warnings;

use Test::More;
use Test::Requires 'Test::Perl::Critic';

Test::Perl::Critic->import( -profile => 't/perlcriticrc' );
all_critic_ok();
