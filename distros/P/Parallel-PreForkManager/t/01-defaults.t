#!/usr/bin/perl -T

use strict;
use warnings;
use Parallel::PreForkManager;
use English;

use Test::More;
use Test::Exception;

use List::Util;

plan tests => 9;

dies_ok { my $Worker = Parallel::PreForkManager->new({}); } 'ChildHandler is required';

my $Worker = Parallel::PreForkManager->new({
    'ChildHandler'   => sub{},
});

is( $Worker->{ 'ChildCount' },   10, 'ChildCount default' );
is( $Worker->{ 'Timeout' },      0,  'Timeout default' );
is( $Worker->{ 'WaitComplete' }, 1,  'WaitComplete default' );

foreach my $Arg ( qw { ParentCallback ProgressCallback JobsPerChild ChildSetupHook ChildTeardownHook } ) {
    is ( exists( $Worker->{ $Arg } ), '' , "$Arg not set" );
}

