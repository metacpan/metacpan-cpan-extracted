#!/usr/bin/perl

# Create an ORLite class, passing through all command line parameters

use strict;

our $VERSION = '1.98';

unless ( $ORLite::VERSION eq $VERSION ) {
	die('Failed to load correct ORLite version');
}

unless ( Foo->can('sqlite') ) {
	die('Failed to generate Foo package');
}

package Foo;

use ORLite +{ @ARGV };
