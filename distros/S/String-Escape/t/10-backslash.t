#!/usr/bin/perl

use strict;

use Test::More( tests => 22 );

BEGIN { 
	use_ok( 'String::Escape', qw( backslash unbackslash qqbackslash unqqbackslash ) ) 
}

{ 
	# Backslash escapes for newline and tab characters

	my $original = "\tNow is the time\nfor all good folk\nto party.\n";
	my $expected = '\\tNow is the time\\nfor all good folk\\nto party.\\n';

	is( backslash( $original ) => $expected );
	is( unbackslash( $expected ) => $original );
	is( eval( qq{"$expected"} ) => $original );
}

{ 
	# Backslash escapes for newline and tab characters

	my $original = "\tNow is the time\nfor all good folk\nto party.\n";
	my $expected = '"\\tNow is the time\\nfor all good folk\\nto party.\\n"';

	is( qqbackslash( $original ) => $expected );
	is( unqqbackslash( $expected ) => $original );
	is( eval( $expected ) => $original );
}

{ 
	# Handles empty strings

	my $original = "";

	is( backslash( $original ) => $original );
	is( unbackslash( $original ) => $original );
}

{ 
	# Handles backslashes in strings

	my $original = "four \\ three";
	my $expected = '"four \\\\ three"';

	is( eval( $expected ) => $original );
	is( qqbackslash( $original ) => $expected );
	is( unqqbackslash( $expected ) => $original );
	is( eval( qqbackslash( $original ) ) => $original );
}

{ 
	# Support for octal and hex escapes

	my $original = "this\tis\ta\011string\x09with some text\r\n";
	my $expected = '"this\\tis\\ta\\tstring\\twith some text\\r\\n"';

	is( qqbackslash( $original ) => $expected );
	is( unqqbackslash( $expected ) => $original );
	is( eval( $expected ) => $original );
}

{ 
	# Handles undef

	my $original = undef;
	my $expected = "";

	is( backslash( $original ) => $expected );
	is( unbackslash( $original ) => $expected );
}

{ 
	# Should work for high-bit characters as well

	my $original = " this\nis a¼ ªtest.º \\quote\\ endquote.";
	my $expected = '" this\\nis a\xbc \\xaatest.\\xba \\\\quote\\\\ endquote."';

	is( qqbackslash( $original ) => $expected );
	is( unqqbackslash( $expected ) => $original );
	is( unbackslash( backslash( $original ) ) => $original );
	is( eval( $expected ) => $original );
}
