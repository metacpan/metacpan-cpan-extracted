#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 1;
use Template::Tiny ();

sub process {
	my $stash    = shift;
	my $input    = shift;
	my $expected = shift;
	my $message  = shift || 'Template processed ok';
	my $output   = '';
	Template::Tiny->new->process( \$input, $stash, \$output );
	is( $output, $expected, $message );
}





######################################################################
# Main Tests

process( { foo => sub{ return 'World' } }, <<'END_TEMPLATE', <<'END_EXPECTED', 'Coderefs as template values ok' );
Hello [% foo %]!
END_TEMPLATE
Hello World!
END_EXPECTED
