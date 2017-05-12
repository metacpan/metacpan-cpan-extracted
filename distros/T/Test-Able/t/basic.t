#!/usr/bin/perl

package Basic;

use strict;
use Test::More tests => 49;
use warnings;

use_ok( 'Test::Able' );

my $t = Basic->new;

isa_ok( $t, 'Basic' );
isa_ok( $t->meta, 'Moose::Meta::Class' );
isa_ok( $t->meta->builder, 'Test::Builder' );
ok(
    $t->meta->meta->does_role( 'Test::Able::Role::Meta::Class' ),
    'meta->meta does "meta(class)role"'
);

can_ok( $t->meta, 'test_objects' );
can_ok( $t->meta, 'run_tests' );

cmp_ok( @{ $t->meta->test_objects }, '==', 0, 'no test objects' );
ok( ! defined $t->meta->current_test_object, 'no current test object' );
ok( ! defined $t->meta->current_test_method, 'no current test method' );
cmp_ok( @{ $t->meta->method_types }, '>', 0, 'has method types' );

# populate method lists
{
    my $i;
    for ( @{ $t->meta->method_types } ) {
        my $accessor_name = $_ . '_methods';
        my @methods;
        for ( 1 .. ++$i ) {
            my $name = $accessor_name . $_;
            my $method = Class::MOP::Method->wrap(
                sub {}, ( name => $name, package_name => 'Yay', ),
            );
            $method->attach_to_class( $t->meta );
            push( @methods, $method, );
        }
        $t->meta->$accessor_name( \@methods );
    }
}

# check method lists
{
    my $i;
    for ( @{ $t->meta->method_types } ) {
        my $accessor_name = $_ . '_methods';
        cmp_ok(
            @{ $t->meta->$accessor_name }, '==', ++$i,
            "$accessor_name has $i elements"
        );
    }
}

# empty all method lists
$t->meta->clear_all_methods;
for ( @{ $t->meta->method_types } ) {
    my $accessor_name = $_ . '_methods';
    eval { $t->meta->$accessor_name; };
    ok( $@, "$accessor_name dies after clear_all_methods" );
}

# build and run Test::Able test object
{
    my $t = Basic->new;
    $t->meta->clear_all_methods;

    my @method_exec = (
        'startup_methods1',

        'setup_methods1',    'setup_methods2',
        'test_methods1',
        'teardown_methods1', 'teardown_methods2',
        'teardown_methods3', 'teardown_methods4',

        'setup_methods1',    'setup_methods2',
        'test_methods2',
        'teardown_methods1', 'teardown_methods2',
        'teardown_methods3', 'teardown_methods4',

        'setup_methods1',    'setup_methods2',
        'test_methods3',
        'teardown_methods1', 'teardown_methods2',
        'teardown_methods3', 'teardown_methods4',

        'shutdown_methods1', 'shutdown_methods2',
        'shutdown_methods3', 'shutdown_methods4',
        'shutdown_methods5'
    );

    my $i;
    for ( @{ $t->meta->method_types } ) {
        my $accessor_name = $_ . '_methods';
        for ( 1 .. ++$i ) {
            my $method_name = $accessor_name . $_;
                my $method      = sub {
                is(
                    shift @method_exec, $method_name,
                    "correct method ($method_name)"
                );
                $_ = undef;
            };

            my ( $type ) = $method_name =~ /^(.*)_/;
            Test::Able::__add_method(
                type => $type, 'Basic', plan => 1, $method_name, $method,
            );
        }
    }

    $t->meta->test_objects( [ $t, ], );
    $t->meta->run_tests;
    cmp_ok( @method_exec, '==', 0, 'ran all methods' );
}
