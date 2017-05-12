package Base;

use strict;
use warnings;

use Test::Class::Filter::Tags;
use Test::More;

use base qw( Test::Class );

our @run;

sub startup : Test( startup ) Tags( bar ) {
    diag( "startup run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, 'startup';
}

sub setup : Test( setup ) Tags( bar ) {
    diag( "--> setup run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, 'setup';
}

sub teardown : Test( teardown ) Tags( bar ) {
    diag( "--> teardown run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, 'teardown';
}

sub shutdown : Test( shutdown ) Tags( bar ) {
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

sub foo : Tests Tags( bar ) {
    diag( "---- Subclass::foo run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @Base::run, "Subclass::foo";
}

package main;

use Test::More tests => 3;

# no filter
{
    @Base::run = ();
    Subclass->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup Subclass::foo teardown shutdown ) ],
        "expected run, when no filters specified, honours method overrides"
    );
}

# tags honour subclassing
{
    $ENV{ TEST_TAGS } = 'foo';

    @Base::run = ();
    Subclass->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup Subclass::foo teardown shutdown ) ],
        "tags are inherited from parent, in addition to any it specified"
    );
}

# subclass tags run
{
    $ENV{ TEST_TAGS } = 'bar';

    @Base::run = ();
    Subclass->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup Subclass::foo teardown shutdown ) ],
        "subclass tags are also checked"
    );
}
