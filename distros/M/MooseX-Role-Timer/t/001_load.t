#!/usr/bin/env perl

use Test::More tests => 2;
use warnings;
use strict;

package Demo;
use Moo;

with 'MooseX::Role::Timer';

package main;

my $demo = Demo->new;

ok( $demo->does('MooseX::Role::Timer'), 'role works');

ok( $demo->can('start_timer'), 'method exists');
