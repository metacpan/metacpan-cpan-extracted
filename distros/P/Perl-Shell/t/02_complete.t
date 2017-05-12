#!/usr/bin/perl

# Tests Perl::Shell's understanding of whether a document is "complete"

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Perl::Shell ();

sub is_complete {
	my $string = shift;
	my $name   = shift || "Document is complete";
	ok(
		Perl::Shell::complete($string),
		$name,
	);
}

sub no_complete {
	my $string = shift;
	my $name   = shift || "Document is not complete";
	ok(
		! Perl::Shell::complete($string),
		$name,
	);
}

is_complete("print 'Hello World!';");
no_complete("print 'Hello World!'");
