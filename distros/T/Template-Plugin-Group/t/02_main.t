#!/usr/bin/perl

# Template::Plugin::Group basic functionality tests

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use Template::Plugin::Group ();

# Prepare
my $TPG = 'Template::Plugin::Group';
my $testdata = [ 'foo', 'bar', 'baz' ];
my $backup   = [ 'foo', 'bar', 'baz' ];
my $grouped  = [ [ 'foo', 'bar' ], [ 'baz' ] ];
my $padded   = [ [ 'foo', 'bar' ], [ 'baz', undef ] ];

# Do a normal grouping
is_deeply( $TPG->new( $testdata, 2 ), $grouped, 'Normal grouping groups correctly' );
is_deeply( $testdata, $backup, 'Normal grouping doesnt break original ARRAY ref' );

# Do a padded grouping
is_deeply( $TPG->new( $testdata, 2, 'pad' ), $padded, 'Padded grouping groups correctly' );
is_deeply( $testdata, $backup, 'Padded grouping doesnt break original ARRAY ref' );
