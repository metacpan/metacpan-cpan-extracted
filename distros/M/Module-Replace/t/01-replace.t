use strict;
use warnings;

package mybase;

sub baz
{
    shift;
    join '', map "($_)", @_;
}

package test;
use Module::Replace 'mybase' => qw(baz);

sub baz
{
    my $self = shift;
    join '', map "[$_]", @_
}

package main;
use Test::More tests => 4;
no strict;
no warnings;

is(mybase->baz("foo"), "[foo]", "override existing function");
ok(exists ${mybase::}{SUPER_baz});

Module::Replace::restore('mybase', \'test');
ok(not exists ${mybase::}{SUPER_baz});

isnt(mybase->baz("foo"), "[foo]", "override existing function");

