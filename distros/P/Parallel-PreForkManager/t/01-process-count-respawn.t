#!/usr/bin/perl -T

use strict;
use warnings;
use Parallel::PreForkManager;
use English;

use Test::More;

use List::Util 1.45 qw{ uniq };

plan tests => 3;

my @Results;

{
    @Results = ();

    my $Worker = Parallel::PreForkManager->new({
        'ChildHandler'   => \&WorkHandler,
        'ParentCallback' => \&CallbackHandler,
        'ProgressCallback' => {
            'Log' => \&LogCallback,
        },
        'ChildCount'     => 10,
        'JobsPerChild'    => 1,
    });

    for ( my $i=0;$i<200;$i++ ) {
        $Worker->AddJob({ 'Value' => $i });
    }

    $Worker->RunJobs();

    @Results = uniq sort @Results;

    is( scalar @Results, 400, 'Processes respawning' );
}

{
    @Results = ();

    my $Worker = Parallel::PreForkManager->new({
        'ChildHandler'   => \&WorkHandler,
        'ParentCallback' => \&CallbackHandler,
        'ProgressCallback' => {
            'Log' => \&LogCallback,
        },
        'ChildCount'     => 10,
        'JobsPerChild'    => 2,
    });

    for ( my $i=0;$i<200;$i++ ) {
        $Worker->AddJob({ 'Value' => $i });
    }

    $Worker->RunJobs();

    @Results = uniq sort @Results;

    # Precise number of processes is unknown as the running order is not repeatable
    is( ( scalar @Results ) > 20 , 1,  'Processes respawning after 2 jobs test 1' );
    is( ( scalar @Results ) < 400 , 1, 'Processes respawning after 2 jobs test 2' );
}

sub LogCallback {
    my ( $Self, $Data ) = @_;
    push @Results, "LogCallback:$Data:$PID";
    return;
}

sub WorkHandler {
        my ( $Self, $Thing ) = @_;
        my $Val = $Thing->{'Value'};
        $Self->ProgressCallback( 'Log', "WorkHandler:ProgressCallback:$PID" );
        return "WorkHandler:Return:$PID";
}

sub CallbackHandler {
        my ( $Self, $Val ) = @_;
        push @Results, "CallbackHandler:$Val:PID";
        return;
};

