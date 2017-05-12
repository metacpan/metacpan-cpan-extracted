#!/usr/bin/perl -T

use strict;
use warnings;
use Parallel::PreForkManager;
use English;

use Test::More;
use Test::Exception;

use List::Util;

plan tests => 8;

my $Worker = Parallel::PreForkManager->new({
    'ChildHandler'      => sub{},
    'ChildCount'        => 100,
    'Timeout'           => 101,
    'WaitComplete'      => 0,
    'ParentCallback'    => sub{},
    'ProgressCallback'  => sub{},
    'JobsPerChild'      => 10,
    'ChildSetupHook'    => sub{},
    'ChildTeardownHook' => sub{},

});

is( $Worker->{ 'ChildCount' },   100, 'ChildCount set' );
is( $Worker->{ 'Timeout' },      101, 'Timeout set' );
is( $Worker->{ 'WaitComplete' }, 0,   'WaitComplete set' );

foreach my $Arg ( qw { ParentCallback ProgressCallback JobsPerChild ChildSetupHook ChildTeardownHook } ) {
    is ( exists( $Worker->{ $Arg } ), 1, "$Arg set" );

}

