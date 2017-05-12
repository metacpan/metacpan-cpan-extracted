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
    diag( "-> setup run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, 'setup';
}

sub teardown : Test( teardown ) {
    diag( "-> teardown run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, 'teardown';
}

sub shutdown : Test( shutdown ) {
    diag( "shutdown run" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, 'shutdown';
}

sub foo : Tests Tags( foo ) {
    diag( "---- foo ran" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, "foo";
}

sub bar : Tests Tags( bar ) {
    diag( "---- bar ran" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, "bar";
}

sub foo_bar : Tests Tags( foo bar ) {
    diag( "---- foo_bar ran" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, "foo_bar";
}

sub baz : Tests {
    diag( "---- baz ran" ) if $ENV{ TEST_CLASS_TAGS_AUTHOR };
    push @run, "baz";
}
    
package main;

use Test::More tests => 6;

# no filter
{
    @Base::run = ();
    Base->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup bar teardown setup baz teardown setup foo teardown setup foo_bar teardown shutdown ) ],
        "expected run, when no filters specified",
    );
}

# filter matching only one method
{
    local $ENV{ TEST_TAGS } = 'foo';

    @Base::run = ();
    Base->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup foo teardown setup foo_bar teardown shutdown ) ],
        "expected run, when filter specified that matches single tag"
    );
}

# filter matching multiple method
{
    local $ENV{ TEST_TAGS } = 'foo,bar';

    @Base::run = ();
    Base->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup bar teardown setup foo teardown setup foo_bar teardown shutdown ) ],
        "expected run, when filter matches multiple tags"
    );
}

# filter suppressing tags, no inclusion
{
    local $ENV{ TEST_TAGS_SKIP } = 'bar';

    @Base::run = ();
    Base->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup baz teardown setup foo teardown shutdown ) ],
        "expected run, when supressing tag"
    );
}

# filter suppressing tags, and inclusion
{
    local $ENV{ TEST_TAGS } = 'foo';
    local $ENV{ TEST_TAGS_SKIP } = 'bar';

    @Base::run = ();
    Base->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup setup foo teardown shutdown ) ],
        'expected run, when both including and suppressing tags that partially overlap'
    );
}

# filter and including same tag runs no tests
{
    local $ENV{ TEST_TAGS } = 'foo';
    local $ENV{ TEST_TAGS_SKIP } = 'foo';

    @Base::run = ();
    Base->runtests;

    is_deeply(
        \@Base::run,
        [ qw( startup shutdown ) ],
        'expected run, when both including and suppressing, that fully overlap'
    );
}

