#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use Test::More tests => 2;
use ok 'MooseX::Types::Buf';

package Foo;
use Moose;
use MooseX::Types::Buf;

has 'raw_data' => ( is => 'rw', isa => 'Buf', coerce => 1 );

package main;
my $x = Foo->new(raw_data => '測試');
is(length $x->raw_data, 6, 'Coercion works');
