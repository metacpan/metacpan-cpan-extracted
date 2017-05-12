#!/usr/bin/perl

use strict;

use Test::More( tests => 10 );

BEGIN { 
	use_ok( 'String::Escape', qw( printable unprintable qprintable unqprintable ) ) 
}

{ 
	# Backslash escapes for newline and tab characters

	my $original = "\tNow is the time\nfor all good folk\nto party.\n";
	my $expected = '\\tNow is the time\\nfor all good folk\\nto party.\\n';

	is( printable( $original ) => $expected );
	is( unprintable( $expected ) => $original );
}

{ 
	# Backslash escapes for newline and tab characters

	my $original = "\tNow is the time\nfor all good folk\nto party.\n";
	my $expected = '"\\tNow is the time\\nfor all good folk\\nto party.\\n"';

	is( qprintable( $original ) => $expected );
	is( unqprintable( $expected ) => $original );
}

{ 
	# Handles empty strings

	my $original = "";

	is( printable( $original ) => $original );
	is( unprintable( $original ) => $original );
}

{ 
	# Handles undef

	my $original = undef;
	my $expected = "";

	is( printable( $original ) => $expected );
	is( unprintable( $original ) => $expected );
}

{ 
	# Should work for high-bit characters as well

	my $original = " this\nis a¼ ªtest.º \\quote\\ endquote.";

	is( unprintable( printable( $original ) ) => $original );
}
