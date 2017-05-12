#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'POE::Component::ResourcePool::Resource::Collection';

my $res  = POE::Component::ResourcePool::Resource::Collection->new( values => [ 1 .. 3 ] );

my @got = $res->try_allocating( undef, undef, 2 );

is_deeply( \@got, [ 1, 2 ], "try" );

is_deeply( [ $res->finalize_allocation( undef, undef, @got ) ], [ [ @got ] ], "finalize" );

is_deeply( [ $res->try_allocating( undef, undef, 2 ) ], [ ], "try failed" );

is_deeply( [ $res->try_allocating( undef, undef, 1 ) ], [ 3 ], "try succeeded" );

