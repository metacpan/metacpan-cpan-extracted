#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

package PkgForge::Test;
use Moose;
extends 'PkgForge::Daemon';

package main;

my $daemon = PkgForge::Test->new( progname => 'test' );

isa_ok( $daemon, 'PkgForge::Test' );

done_testing();
