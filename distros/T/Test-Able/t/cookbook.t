#!/usr/bin/perl

use lib 't/lib';

use Bar ();
use Foo ();
use strict;
use Test::More 'no_plan';
use warnings;

# Correcting plan that's wrong (on purpose for other tests).
Bar->meta->get_method( 'test_4' )->plan( 4 );

# Ensuring things goes exactly as planned.
Bar->meta->on_method_plan_fail( 'die' );
Foo->meta->on_method_plan_fail( 'die' );

# Dumping execution plan
{
    local $ENV{ 'TEST_VERBOSE' } = 1;
    my $t = Bar->new;
    $t->meta->dry_run( 1 );
    $t->run_tests;
    $t->meta->dry_run( 0 );
    is( $t->meta->builder->current_test, 0, 'no tests ran' );
}

# Remove superclass methods
{
    package Foo;

    use Test::Able::Helpers qw( prune_super_methods );

    my $t = Foo->new;
    # Setting to -1 to account for the is() at the end of the "Dumping
    # execution plan" code that is outside of the Test::Able Classes.
    $t->meta->last_runner_plan( -1 );
    $t->prune_super_methods;
    $t->run_tests;
}

# Explicit set
{
    my $t = Bar->new;
    my @methods = sort { $a->name cmp $b->name } $t->meta->get_all_methods;
    $t->meta->startup_methods(  [ grep { $_->name =~ /^shutdown_/ } @methods ] );
    $t->meta->setup_methods(    [ grep { $_->name =~ /^teardown_/ } @methods ] );
    $t->meta->test_methods(     [ grep { $_->name =~ /^test_bar[14]/ } @methods ] );
    $t->meta->teardown_methods( [ grep { $_->name =~ /^setup_/    } @methods ] );
    $t->meta->shutdown_methods( [ grep { $_->name =~ /^startup_/  } @methods ] );
    $t->run_tests;
    # Dumping the unusual method lists.
    $t->meta->clear_all_methods;
}

# Ordering
{
    package Bar;

    use Test::Able::Helpers qw( shuffle_methods );

    my $t = Bar->new;
    for ( 1 .. 10 ) {
        $t->shuffle_methods;
        $t->run_tests;
    }
}

# Filtering
{
    my $t = Bar->new;
    $t->meta->test_methods(
        [ grep { $_->name !~ /bar/; } @{ $t->meta->test_methods } ]
    );
    $t->run_tests;
    # Dumping the altered test method list.
    $t->meta->clear_test_methods;
}

# Setting method plan during test run
{
    eval '
        package Bar;
        test plan => "no_plan", new_test_method => sub {
            $_[ 0 ]->meta->current_method->plan( 7 );
            ok( 1 ) for 1 .. 7;
        };
    ';
    my $t = Bar->new;
    $t->run_tests;
}

# Explicit setup & teardown for "Loop-Driven testing"
{
    eval q[
        package Bar;

        use Test::Able::Helpers qw( get_loop_plan );

        test do_setup => 0, do_teardown => 0, test_on_x_and_y_and_z => sub {
            my ( $self, ) = @_;

            my @x = qw( 1 2 3 );
            my @y = qw( a b c );
            my @z = qw( foo bar baz );

            $self->meta->current_method->plan(
                $self->get_loop_plan( 'test_bar1', @x * @y * @x, ),
            );

            for my $x ( @x ) {
                for my $y ( @y ) {
                    for my $z ( @z ) {
                        $self->meta->run_methods( 'setup' );
                        $self->{ 'args' } = { x => $x, y => $y, z => $z, };
                        $self->test_bar1;
                        $self->meta->run_methods( 'teardown' );
                    }
                }
            }

            return;
        };
    ];

    # Dumping the test methods list so the new method gets picked up on build.
    Bar->meta->clear_test_methods;
    my $t = Bar->new;
    $t->run_tests;
}
