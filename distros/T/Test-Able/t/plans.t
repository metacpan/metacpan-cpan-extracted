#!/usr/bin/perl

use lib 't/lib';

use Bar ();
use Baz ();
use strict;
use Test::Able ();
use Test::More 'no_plan';
use warnings;

# This whole test script is also a test for Test::Builder "integration".

my @methods_no_plan = qw(
    startup_bar2
    startup_bar4
    setup_bar1
    setup_bar3
    test_4
    test_bar2
    test_bar4
    teardown_0
    teardown_bar2
    shutdown_
    shutdown_bar3
);

# Method plan defaults.
{
    my $t = Bar->new;
    is(
        $t->meta->get_method( 'startup_bar2' )->plan, 0,
        'non-test method default to 0'
    );
    is(
        $t->meta->get_method( 'test_bar2' )->plan, 0,
        'test method default to 0'
    );
}

# Object has no_plan if any method has no_plan.
{
    my $t = Baz->new;
    $t->meta->test_objects( [ $t, ] );
    ok( $t->meta->plan eq 'no_plan', 'obj no_plan if any meth no_plan' );
}

# Object has plan up front if all methods do.
{
    my $t = Bar->new;
    $t->meta->test_objects( [ $t, ] );
    set_plan_on_no_plan_methods( $t, @methods_no_plan, );
    ok( $t->meta->plan == 114, 'obj has plan before run' );
}

# Object can have deferred plan
# which implies that object plan changes
# on any method plan change.
{
    my $t = Baz->new;
    cmp_ok( $t->meta->plan, 'eq', 'no_plan', 'obj has no_plan before' );
    set_plan_on_no_plan_methods( $t, @methods_no_plan, );
    is( $t->meta->plan, 177, 'obj has plan after' );
}

# object plan changes when any of the method lists change.
{
    my $t = Bar->new;
    $t->meta->last_runner_plan( -8 );
    set_plan_on_no_plan_methods( $t, @methods_no_plan, );
    ok( $t->meta->plan == 114, 'obj has plan' );
    $t->meta->setup_methods( [] );
    ok( $t->meta->plan == 58, 'obj plan changes after method list change' );
    $t->run_tests;
}

sub set_plan_on_no_plan_methods {
    my ( $t, @methods_no_plan, ) = @_;

    for ( @{ $t->meta->method_types } ) {
        my $accessor = $_ . '_methods';
        for my $method ( @{ $t->meta->$accessor } ) {
            if ( grep { $method->name eq $_; } @methods_no_plan ) {
                if ( $method->name eq 'test_4' ) {
                    $method->plan( 4 );
                }
                else {
                    $method->plan( 0 );
                }
            }
        }
    }

    return;
}

sub END {
    my $tb = Test::Builder->new;
    die 'bad plan (' . $tb->expected_tests . ')'
      unless $tb->expected_tests == 66;
}
