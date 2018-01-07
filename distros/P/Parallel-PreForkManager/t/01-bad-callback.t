#!/usr/bin/perl -T

use strict;
use warnings;
use Parallel::PreForkManager;
use English;

use Test::More;
use Test::Exception;

use List::Util;

plan tests => 2;

{

    my $Worker = Parallel::PreForkManager->new({
        # This sub is shown as not covered, even though it is run in tests
        # Exclude it from coverage reporting
        'ChildHandler'   => sub { # uncoverable statement
            my ( $Self ) = @_; # uncoverable statement
            $Self->ProgressCallback( 'BadLog', "This callback does not exist" ); # uncoverable statement
        }, # uncoverable statement
        'ProgressCallback' => {
            'Log' => \&LogCallback,
        },
        'ChildCount'   => 1,
        'JobsPerChild' => 1,
    });
    $Worker->AddJob({ 'Value' => 1 });
    dies_ok { $Worker->RunJobs(); } 'Unknown callback name';

}

{

    my $Worker = Parallel::PreForkManager->new({
        # This sub is shown as not covered, even though it is run in tests
        # Exclude it from coverage reporting
        'ChildHandler'   => sub { # uncoverable statement
            my ( $Self ) = @_; # uncoverable statement
            $Self->ProgressCallback( 'Log', "This callback cannot be called" ); # uncoverable statement
        }, # uncoverable statement
        'ProgressCallback' => {
            'Log' => 'This callback cannot be called',
        },
        'ChildCount'   => 1,
        'JobsPerChild' => 1,
    });
    $Worker->AddJob({ 'Value' => 1 });

    dies_ok { $Worker->RunJobs(); } 'Missing callback sub';

}

