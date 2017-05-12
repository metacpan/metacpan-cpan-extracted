#!/usr/bin/perl -T

use strict;
use warnings;
use Parallel::PreForkManager;
use English;

use Test::More;

use Capture::Tiny ':all';

plan tests => 1;

my @Results;

my $Worker = Parallel::PreForkManager->new({
    'ChildHandler'      => \&WorkHandler,
    'ChildSetupHook'    => \&ChildSetupHook,
    'ChildTeardownHook' => \&ChildTeardownHook,
    'ChildCount'     => 10,
});

for ( my $i=0;$i<50;$i++ ) {
    $Worker->AddJob({ 'Value' => $i });
}

my $StdOut = capture_stdout {
    $Worker->RunJobs();
};

@Results = split /\n/, $StdOut;

is( scalar @Results, 20, 'Up/Down hook count correct' );

sub ChildSetupHook {
    my ( $Self ) = @_;
    print "ChildSetupHook:$PID\n";
    return;
}
sub ChildTeardownHook {
    my ( $Self ) = @_;
    print "ChildTeardownHook:$PID\n";
    return;
}

sub WorkHandler {
    my ( $Self, $Thing ) = @_;
    return $Thing;
}

