#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('MOP');
}

{
    package Foo;
    use Moxie;

    extends 'Moxie::Object';

    has foo => sub { 'FOO' };
    has bar => sub { 'BAR' };

    my sub foo : private;
    my sub bar : private;

    sub change_bar {
        my $self = shift; # we are safe even with modifications to @_
        my ($value) = @_;
        bar = $value;
        $self;
    }

    sub to_string {
        my ($self) = @_;
        join ', ' => foo, bar;
    }
}

ok(!Foo->can('foo'), '... no public foo method');
ok(!Foo->can('bar'), '... no public foo method');

is(Foo->new->to_string, 'FOO, BAR', '... got the expected default values');
is(Foo->new( foo => 'foo' )->to_string, 'foo, BAR', '... got the expected changed values');
is(Foo->new( foo => 'foo', bar => 'bar' )->to_string, 'foo, bar', '... got the expected changed values again');
is(Foo->new( foo => 'foo')->change_bar( 'BARRR' )->to_string, 'foo, BARRR', '... values changed with the rw accessor now');

done_testing;

