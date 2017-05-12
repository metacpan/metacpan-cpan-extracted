#!/usr/bin/perl -w
use strict;

# Test that a simple pipeline made out of segments and a subpipeline
# works correctly (and has a cleanup segment run properly)

use lib './lib';
use lib 'oldt/lib';
use lib 't/lib';

use MyPipe;
use MyPipeCleanup;
use Pipeline;
use Data::Dumper;
use Test::More tests => 8;

my $pipeline  = Pipeline->new();
my $subpipeline = Pipeline->new();

$subpipeline->add_segment( MyPipe->new() );
$pipeline->add_segment( MyPipe->new(), MyPipe->new(), $subpipeline );
print Dumper( $pipeline );

ok($pipeline, "we have a pipeline");
my $production = $pipeline->dispatch();
ok(ref($production) eq 'MyPipe', "valid production received");
ok(
   defined($MyPipe::instance) && $MyPipe::instance == 0,
   "cleanup was executed (instance was set to zero)\n"
  );


my $pipe = Pipeline->new();
my $seg  = MyPipe->new();
is( $pipe->add_segment( $seg ), $pipe, 'add_segment' );
is( $pipe->del_segment( 0 ), $seg,     'del_segment' );
is( $pipe->init, $pipe,                'init' );

my $pipe2 = Pipeline->new();
my $seg2  = MyPipe->new();
$pipe->add_segment( $pipe2->add_segment( $seg2 ) );

is( $pipe->debug_all(1), $pipe, 'debug_all' );
is( $seg2->debug, 1,            'debug set' );

