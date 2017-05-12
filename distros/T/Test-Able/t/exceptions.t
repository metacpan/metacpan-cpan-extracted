#!/usr/bin/perl

use lib 't/lib';

use Bar ();
use strict;
use Test::Able::FatalException;
use Test::More tests => 273;
use warnings;

my $t = Bar->new;
$t->meta->on_method_plan_fail( 'die' );
Test::Able::__add_method(
    type => 'test', 'Bar', test_4 => sub { die "t oops"; }
);

# clear - nothing terribly special
{
    $t->meta->clear_on_method_exception;
    eval { $t->run_tests; };
    like( $@, qr/t oops.*14/, 'threw exception' );
}

# continue - record and ignore
{
    $t->meta->on_method_exception( 'continue' );
    $t->run_tests;
    is( @{ $t->meta->method_exceptions }, 1, 'recorded exception' );
    my $e = $t->meta->method_exceptions->[ 0 ];
    like( $e->{ 'exception' }, qr/t oops.*14/, 'got exception' );
    is( $e->{ 'method' }->name, 'test_4', 'got method' );
}

Test::Able::__add_method(
    type => 'setup', 'Bar', se => sub { die "se oops"; }
);
push( @{ $t->meta->setup_methods }, $t->meta->get_method( 'se' ), );

# continue_at_level (setup) - record, ignore,
# and skip lower level (test)
{
    $t->meta->clear_method_exceptions;
    $t->meta->on_method_exception( 'continue_at_level' );
    $t->run_tests;
    is( @{ $t->meta->method_exceptions }, 4, 'recorded exceptions' );
    my $e = $t->meta->method_exceptions->[ 0 ];
    like( $e->{ 'exception' }, qr/se oops.*35/, 'got exception' );
    is( $e->{ 'method' }->name, 'se', 'got method' );
}

Test::Able::__add_method(
    type => 'startup', 'Bar', st => sub { die "st oops"; }
);
push( @{ $t->meta->startup_methods }, $t->meta->get_method( 'st' ), );

# continue_at_level (startup) - record, ignore,
# and skip lower levels (setup,test,teardown)
{
    $t->meta->clear_method_exceptions;
    $t->meta->on_method_exception( 'continue_at_level' );
    $t->run_tests;
    is( @{ $t->meta->method_exceptions }, 1, 'recorded exception' );
    my $e = $t->meta->method_exceptions->[ 0 ];
    like( $e->{ 'exception' }, qr/st oops.*52/, 'got exception' );
    is( $e->{ 'method' }->name, 'st', 'got method' );
}

Test::Able::__add_method(
    type => 'startup', 'Bar', st => sub {
        Test::Able::FatalException->throw( 'die for real!' );
    }
);

# continue but fatal
{
    $t->meta->clear_method_exceptions;
    $t->meta->on_method_exception( 'continue' );
    eval { $t->run_tests; };
    is( @{ $t->meta->method_exceptions }, 1, 'recorded exception' );
    my $e = $t->meta->method_exceptions->[ 0 ];
    like( $e->{ 'exception' }, qr/die for real!/, 'got exception' );
    is( $e->{ 'method' }->name, 'st', 'got method' );
}
