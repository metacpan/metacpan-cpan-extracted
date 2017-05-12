#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
BEGIN {
    eval "use Test::Output;";
    plan skip_all => "Test::Output is required for this test" if $@;
    plan tests => 2;
}

package MyApp;
use Moose;
use MooseX::Aliases;

has this => (
    isa   => 'Str',
    is    => 'rw',
    alias => 'that',
);

sub foo { my $self = shift; print $self->that }
alias bar => 'foo';

my $o = MyApp->new();
$o->this('Hello World');


package MyApp::Role;
use Moose::Role;
use MooseX::Aliases;

has this => (
    isa   => 'Str',
    is    => 'rw',
    traits => [qw(Aliased)],
    alias => 'that',
);

sub foo { my $self = shift; print $self->that }
alias bar => 'foo';

package MyApp::Role::Test;
use Moose;
with 'MyApp::Role';

my $o2 = MyApp::Role::Test->new();
$o2->this('Hello World');

package main;
stdout_is { $o->bar } "Hello World", "correct output";
stdout_is { $o2->bar } "Hello World", "correct output";
