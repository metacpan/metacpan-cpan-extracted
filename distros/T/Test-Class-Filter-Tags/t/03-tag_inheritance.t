package Base;

use strict;
use warnings;

use Test::Class::Filter::Tags;
use Test::More;

use base qw( Test::Class );

our @run;

sub startup : Test( startup ) {
    diag( "startup run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, 'startup';
}

sub setup : Test( setup ) {
    diag( "--> setup run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, 'setup';
}

sub teardown : Test( teardown ) {
    diag( "--> teardown run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, 'teardown';
}

sub shutdown : Test( shutdown ) {
    diag( "shutdown run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, 'shutdown';
}

sub foo : Tests Tags( foo ) {
    diag( "---- foo run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, "foo";
}

package Subclass;

use Test::More;

use base qw( Base );

sub bar : Tests Tags( bar ) {
    diag( "---- Subclass::bar run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @Base::run, "Subclass::bar";
}

package main;

use Test::More tests => 3;

# no filter
{
    @Base::run = ();
    Subclass->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup Subclass::bar teardown setup foo teardown shutdown ) ],
        "expected run, when no filters specified, runs superclass methods",
    );
}

# tags honour subclassing
{
    $ENV{ TEST_TAGS } = 'foo';

    @Base::run = ();
    Subclass->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup foo teardown shutdown ) ],
        "tags honour subclassing, parent class ones run"
    );
}

# subclass tags run
{
    $ENV{ TEST_TAGS } = 'bar';

    @Base::run = ();
    Subclass->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup Subclass::bar teardown shutdown ) ],
        "tags defined in subclass are honoured"
    );
}
