#!/usr/bin/env perl
use strict;
use lib 't/lib';
use Test::More;
use Simple;

plan tests => 1;

my $obj = Simple->new;

ok( $obj->can("hello") );

$obj->hello;

