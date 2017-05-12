#!perl

use strict;
use warnings;
use Test::More;

if (!eval { require Test::Perl::Critic } )
{
    plan( skip_all => "Test::Perl::Critic required for testing PBP compliance" );
}

if ( !$ENV{'AUTHOR_TEST'} && !$ENV{'AUTHOR_TEST_NET_ROUTE'} )
{
    plan( skip_all => 'This test is only run when AUTHOR_TEST is set' );
}

Test::Perl::Critic->import(
        -profile => 't/perlcriticrc',
        -verbose => 8,
);

Test::Perl::Critic::all_critic_ok();
