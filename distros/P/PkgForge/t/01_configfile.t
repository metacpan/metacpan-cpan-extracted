#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

package PkgForge::Test1;
use Moose;
with 'MooseX::Getopt', 'PkgForge::ConfigFile';

has '+configfile' => ( default => sub { ['t/foo.yml'] } );

package PkgForge::Test2;
use Moose;
with 'MooseX::Getopt', 'PkgForge::ConfigFile';

has '+configfile' => ( default => sub { ['t/foo.yml','t/bar.yml'] } );

package main;

my $test1 = PkgForge::Test1->new_with_config();
isa_ok( $test1, 'PkgForge::Test1' );

my $test2 = PkgForge::Test2->new_with_config();
isa_ok( $test2, 'PkgForge::Test2' );

done_testing;

