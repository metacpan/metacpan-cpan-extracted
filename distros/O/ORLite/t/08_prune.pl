#!/usr/bin/perl

# Create an ORLite class, passing through all command line parameters

use strict;

our $VERSION = $ORLite::VERSION;

unless ( $ORLite::VERSION eq $VERSION ) {
	die('Failed to load correct ORLite version');
}

unless ( Foo->can('sqlite') ) {
	die('Failed to generate Foo package');
}

package Foo;

use ORLite +{ @ARGV };
