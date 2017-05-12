#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 12;

package Foo;

sub new {
    my $class = shift;
    bless { foo_base => $_[0] }, $class;
}

sub foo_base { shift->{foo_base} }

package Foo::Mouse;
use Mouse;
use MouseX::Foreign;
extends 'Foo';

has foo => (
    is => 'rw',
);

sub FOREIGNBUILDARGS {
    my $class = shift;
    my %args = @_;
    return "$args{foo}_base";
}

package Bar::Mouse;
use Mouse;
use MouseX::Foreign;
extends 'Foo';

has bar => (
    is => 'rw',
);

sub FOREIGNBUILDARGS {
    my $class = shift;
    return "$_[0]_base";
}

sub BUILDARGS {
    my $class = shift;
    return { bar => shift };
}

package Baz::Mouse;
use Mouse;
extends 'Bar::Mouse';

has baz => (
    is => 'rw',
);

package main;

my $foo = Foo::Mouse->new(foo => 'bar');
is($foo->foo,  'bar', 'subclass constructor gets the right args');
is($foo->foo_base,  'bar_base', 'subclass constructor gets the right args');
my $bar = Bar::Mouse->new('baz');
is($bar->bar, 'baz', 'subclass constructor gets the right args');
is($bar->foo_base, 'baz_base', 'subclass constructor gets the right args');
my $baz = Baz::Mouse->new('bazbaz');
is($baz->bar, 'bazbaz', 'extensions of extensions of the nonmoose class respect BUILDARGS');
is($baz->foo_base, 'bazbaz_base', 'extensions of extensions of the nonmoose class respect FOREIGNBUILDARGS');
Foo::Mouse->meta->make_immutable;
Bar::Mouse->meta->make_immutable;
Baz::Mouse->meta->make_immutable;
$foo = Foo::Mouse->new(foo => 'bar');
is($foo->foo,  'bar', 'subclass constructor gets the right args (immutable)');
is($foo->foo_base,  'bar_base', 'subclass constructor gets the right args (immutable)');
$bar = Bar::Mouse->new('baz');
is($bar->bar, 'baz', 'subclass constructor gets the right args (immutable)');
is($bar->foo_base, 'baz_base', 'subclass constructor gets the right args (immutable)');
$baz = Baz::Mouse->new('bazbaz');
is($baz->bar, 'bazbaz', 'extensions of extensions of the nonmoose class respect BUILDARGS (immutable)');
is($baz->foo_base, 'bazbaz_base', 'extensions of extensions of the nonmoose class respect FOREIGNBUILDARGS (immutable)');
