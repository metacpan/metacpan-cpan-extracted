#!/usr/bin/perl

# Create an ORLite class, passing through all command line parameters

use strict;

unless ( $ORLite::VERSION eq '1.28' ) {
	die('Failed to load correct ORLite version');
}

unless ( Foo->can('sqlite') ) {
	die('Failed to generate Foo package');
}

package Foo;

use ORLite::Array +{ @ARGV };
