#!/usr/bin/perl -T

use strict;
use warnings;
use Parallel::PreForkManager;
use English;

use Test::More;
use Test::Exception;

use List::Util;

plan tests => 3;

my $Worker = Parallel::PreForkManager->new({
    'ChildHandler'   => sub{},
});

is_deeply( $Worker->{ 'JobQueue' }, [], 'Queue begins empty' );

$Worker->AddJob( 'First Item' );
is_deeply( $Worker->{ 'JobQueue' }, [ 'First Item' ], 'Queue has one item' );

$Worker->AddJob( 'Second Item' );
is_deeply( $Worker->{ 'JobQueue' }, [ 'First Item', 'Second Item' ], 'Queue has two items' );

