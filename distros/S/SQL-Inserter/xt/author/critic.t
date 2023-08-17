#!perl -T
use 5.006;
use strict;
use warnings;

use Test::Perl::Critic;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

critic_ok('lib/SQL/Inserter.pm');

done_testing;
