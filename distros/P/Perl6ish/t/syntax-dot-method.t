#!/usr/bin/env perl

use strict;
use warnings;

package TestDotMethod;
use Perl6ish::Syntax::DotMethod;

sub new { bless {}, shift }

sub dummy { "dumb" }

package main;
use Test::More tests => 1;

my $obj = new TestDotMethod;

is( $obj.dummy(), "dumb", ".dummy() gets dumb" );


   
