#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
use ok 'MooseX::Types::UniStr';

package Foo;
use Moose;
use MooseX::Types::UniStr;

has 'name' => ( is => 'rw', isa => 'UniStr', coerce => 1 );

package main;
my $x = Foo->new(name => '測試');
is(length $x->name, 2, 'Coercion works');
