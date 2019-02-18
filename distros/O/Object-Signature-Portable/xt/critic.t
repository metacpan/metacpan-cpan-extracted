use strict;
use warnings;

use Test::More;
use Test::Perl::Critic;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

all_critic_ok(qw/ lib /);
