#!/usr/bin/perl -T

use strict;
use warnings;
use Parallel::PreForkManager;
use English;

use Test::More;

use List::Util;

plan tests => 1;

my @Results;

my $Worker = Parallel::PreForkManager->new({
    'ChildHandler'   => \&WorkHandler,
    'ParentCallback' => \&CallbackHandler,
    'ProgressCallback' => {
        'Log' => \&LogCallback,
    },
    'ChildCount'     => 2,
    'JobsPerChild'    => 2,
});

for ( my $i=0;$i<20;$i++ ) {
    $Worker->AddJob({ 'Value' => $i });
}

$Worker->RunJobs();

@Results = sort @Results;
my @Expected = (
    'CallbackHandler:WorkHandler:Return:0',
    'CallbackHandler:WorkHandler:Return:1',
    'CallbackHandler:WorkHandler:Return:10',
    'CallbackHandler:WorkHandler:Return:11',
    'CallbackHandler:WorkHandler:Return:12',
    'CallbackHandler:WorkHandler:Return:13',
    'CallbackHandler:WorkHandler:Return:14',
    'CallbackHandler:WorkHandler:Return:15',
    'CallbackHandler:WorkHandler:Return:16',
    'CallbackHandler:WorkHandler:Return:17',
    'CallbackHandler:WorkHandler:Return:18',
    'CallbackHandler:WorkHandler:Return:19',
    'CallbackHandler:WorkHandler:Return:2',
    'CallbackHandler:WorkHandler:Return:3',
    'CallbackHandler:WorkHandler:Return:4',
    'CallbackHandler:WorkHandler:Return:5',
    'CallbackHandler:WorkHandler:Return:6',
    'CallbackHandler:WorkHandler:Return:7',
    'CallbackHandler:WorkHandler:Return:8',
    'CallbackHandler:WorkHandler:Return:9',
    'LogCallback: WorkHandler:ProgressCallback:0',
    'LogCallback: WorkHandler:ProgressCallback:1',
    'LogCallback: WorkHandler:ProgressCallback:10',
    'LogCallback: WorkHandler:ProgressCallback:11',
    'LogCallback: WorkHandler:ProgressCallback:12',
    'LogCallback: WorkHandler:ProgressCallback:13',
    'LogCallback: WorkHandler:ProgressCallback:14',
    'LogCallback: WorkHandler:ProgressCallback:15',
    'LogCallback: WorkHandler:ProgressCallback:16',
    'LogCallback: WorkHandler:ProgressCallback:17',
    'LogCallback: WorkHandler:ProgressCallback:18',
    'LogCallback: WorkHandler:ProgressCallback:19',
    'LogCallback: WorkHandler:ProgressCallback:2',
    'LogCallback: WorkHandler:ProgressCallback:3',
    'LogCallback: WorkHandler:ProgressCallback:4',
    'LogCallback: WorkHandler:ProgressCallback:5',
    'LogCallback: WorkHandler:ProgressCallback:6',
    'LogCallback: WorkHandler:ProgressCallback:7',
    'LogCallback: WorkHandler:ProgressCallback:8',
    'LogCallback: WorkHandler:ProgressCallback:9',
);

is_deeply( \@Results, \@Expected, 'Data correct' );

sub LogCallback {
    my ( $Self, $Data ) = @_;
    push @Results, "LogCallback: $Data";
    return;
}

sub WorkHandler {
        my ( $Self, $Thing ) = @_;
        my $Val = $Thing->{'Value'};
        $Self->ProgressCallback( 'Log', "WorkHandler:ProgressCallback:$Val" );
        return "WorkHandler:Return:$Val";
}

sub CallbackHandler {
        my ( $Self, $Val ) = @_;
        push @Results, "CallbackHandler:$Val";
        return;
};

