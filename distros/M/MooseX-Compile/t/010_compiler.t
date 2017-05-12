#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'MooseX::Compile::Compiler';

my $comp = MooseX::Compile::Compiler->new();

isa_ok( $comp, "MooseX::Compile::Compiler" );
