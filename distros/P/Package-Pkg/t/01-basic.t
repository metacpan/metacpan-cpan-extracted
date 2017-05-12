#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

package Apple;

use Package::Pkg;

pkg->export( xyzzy => sub { 'apple' } );

package Xyzzy;

Apple->import;

package main;

is( Xyzzy->xyzzy, 'apple' );

1;
