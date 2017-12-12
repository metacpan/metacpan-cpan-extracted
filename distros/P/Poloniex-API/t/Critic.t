#!/usr/bin/perl
use strict;
use warnings;
use English;
use File::Spec;
use Test::More;
use Cwd;

$ENV{TEST_AUTHOR} = 'vladislav.mirkos';

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

my $test_param = 1;
my $rcfile = File::Spec->catfile( Cwd->getcwd(), 'lib' );
Test::Perl::Critic->import( -profile => $rcfile );

TODO: {
    todo_skip 'critic', 1 if $test_param == 1;

    all_critic_ok();
}

done_testing();
