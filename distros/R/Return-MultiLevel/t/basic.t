#!perl

use Test::More tests => 5;

use warnings FATAL => 'all';
use strict;

use Return::MultiLevel qw(with_return);

is with_return {
    my ($ret) = @_;
    42
}, 42;

is with_return {
    my ($ret) = @_;
    $ret->(42);
    1
}, 42;

is with_return {
    my ($ret) = @_;
    sub {
        $ret->($_[0]);
        2
    }->(42);
    3
}, 42;

sub foo {
    my ($f, $x) = @_;
    $f->('a', $x, 'b');
    return 'x';
}

is_deeply [with_return {
    my ($ret) = @_;
    sub {
        foo $ret, "$_[0] lo";
    }->('hi');
    ()
}], ['a', 'hi lo', 'b'];

is_deeply [scalar with_return {
    my ($ret) = @_;
    sub {
        foo $ret, "$_[0] lo";
    }->('hi');
    ()
}], ['b'];
