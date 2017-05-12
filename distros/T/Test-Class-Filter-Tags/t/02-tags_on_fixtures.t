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

package main;

use Test::More tests => 3;

# no filter
{
    @Base::run = ();
    Base->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup foo teardown shutdown ) ],
        "expected run, when no filters specified",
    );
}

# tags ignored on fixture methods
{
    local $ENV{ TEST_TAGS } = 'foo';

    @Base::run = ();
    Base->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup foo teardown shutdown ) ],
        "tags are ignored on fixture methods"
    );
}

# tags ignored when suppressing tags also
{
    local $ENV{ TEST_TAGS_SKIP } = 'bar';

    @Base::run = ();
    Base->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup foo teardown shutdown ) ],
        "tags are ignored on fixture methods when suppressing also"
    );
}
