#!/usr/bin/perl

use strict;

BEGIN {
	$^W = 1;
}

use Test::More;
use Test::Differences;
use PPI;

BEGIN {
	if ( $PPI::VERSION =~ /_/ ) {
		plan skip_all => "Need released version of PPI. You have $PPI::VERSION";
		exit 0;
	}
}

my @cases = (
	{   code => <<'END_CODE',
use strict; use warnings;
use Abc;

my $global = 42;

sub qwer {
}

END_CODE
		expected => [
			[ 'keyword',    1, 1,  3 ],
			[ 'Whitespace', 1, 4,  1 ],
			[ 'pragma',     1, 5,  6 ],
			[ 'Structure',  1, 11, 1 ],
			[ 'Whitespace', 1, 12, 1 ],
			[ 'keyword',    1, 13, 3 ],
			[ 'Whitespace', 1, 16, 1 ],
			[ 'pragma',     1, 17, 8 ],
			[ 'Structure',  1, 25, 1 ],
			[ 'Whitespace', 1, 26, 1 ],
			[ 'keyword',    2, 1,  3 ],
			[ 'Whitespace', 2, 4,  1 ],
			[ 'Word',       2, 5,  3 ],
			[ 'Structure',  2, 8,  1 ],
			[ 'Whitespace', 2, 9,  1 ],
			[ 'Whitespace', 3, 1,  1 ],
			[ 'keyword',    4, 1,  2 ],
			[ 'Whitespace', 4, 3,  1 ],
			[ 'Symbol',     4, 4,  7 ],
			[ 'Whitespace', 4, 11, 1 ],
			[ 'Operator',   4, 12, 1 ],
			[ 'Whitespace', 4, 13, 1 ],
			[ 'Number',     4, 14, 2 ],
			[ 'Structure',  4, 16, 1 ],
			[ 'Whitespace', 4, 17, 1 ],
			[ 'Whitespace', 5, 1,  1 ],
			[ 'keyword',    6, 1,  3 ],
			[ 'Whitespace', 6, 4,  1 ],
			[ 'Word',       6, 5,  4 ],
			[ 'Whitespace', 6, 9,  1 ],
			[ 'Structure',  6, 10, 1 ],
			[ 'Whitespace', 6, 11, 1 ],
			[ 'Structure',  7, 1,  1 ],
			[ 'Whitespace', 7, 2,  1 ],
			[ 'Whitespace', 8, 1,  1 ],
		],
	},
	{   code => <<'END_CODE',
sub return func method before after around override augment
END_CODE
		expected => [
			[ 'keyword',    1, 1,  3 ],
			[ 'Whitespace', 1, 4,  1 ],
			[ 'keyword',    1, 5,  6 ],
			[ 'Whitespace', 1, 11, 1 ],
			[ 'Word',       1, 12, 4 ],
			[ 'Whitespace', 1, 16, 1 ],
			[ 'Word',       1, 17, 6 ],
			[ 'Whitespace', 1, 23, 1 ],
			[ 'Word',       1, 24, 6 ],
			[ 'Whitespace', 1, 30, 1 ],
			[ 'Word',       1, 31, 5 ],
			[ 'Whitespace', 1, 36, 1 ],
			[ 'Word',       1, 37, 6 ],
			[ 'Whitespace', 1, 43, 1 ],
			[ 'Word',       1, 44, 8 ],
			[ 'Whitespace', 1, 52, 1 ],
			[ 'Word',       1, 53, 7 ],
			[ 'Whitespace', 1, 60, 1 ],

		],
	},
	{   code => <<'END_CODE',
undef shift defined bless
END_CODE
		expected => [
			[ 'core',       1, 1,  5 ],
			[ 'Whitespace', 1, 6,  1 ],
			[ 'core',       1, 7,  5 ],
			[ 'Whitespace', 1, 12, 1 ],
			[ 'core',       1, 13, 7 ],
			[ 'Whitespace', 1, 20, 1 ],
			[ 'core',       1, 21, 5 ],
			[ 'Whitespace', 1, 26, 1 ],
		],
	},
	{   code => <<'END_CODE',
new
END_CODE
		expected => [ [ 'Word', 1, 1, 3 ], [ 'Whitespace', 1, 4, 1 ], ],
	},
	{   code => <<'END_CODE',
use no
END_CODE
		expected => [
			[ 'keyword',    1, 1, 3 ],
			[ 'Whitespace', 1, 4, 1 ],
			[ 'keyword',    1, 5, 2 ],
			[ 'Whitespace', 1, 7, 1 ],
		],
	},
	{   code => <<'END_CODE',
my local our
END_CODE
		expected => [
			[ 'keyword',    1, 1,  2 ],
			[ 'Whitespace', 1, 3,  1 ],
			[ 'keyword',    1, 4,  5 ],
			[ 'Whitespace', 1, 9,  1 ],
			[ 'keyword',    1, 10, 3 ],
			[ 'Whitespace', 1, 13, 1 ],

		],
	},

	{   code => <<'END_CODE',
if else elsif unless for foreach while my
END_CODE
		expected => [
			[ 'keyword',    1, 1,  2 ],
			[ 'Whitespace', 1, 3,  1 ],
			[ 'keyword',    1, 4,  4 ],
			[ 'Whitespace', 1, 8,  1 ],
			[ 'keyword',    1, 9,  5 ],
			[ 'Whitespace', 1, 14, 1 ],
			[ 'keyword',    1, 15, 6 ],
			[ 'Whitespace', 1, 21, 1 ],
			[ 'keyword',    1, 22, 3 ],
			[ 'Whitespace', 1, 25, 1 ],
			[ 'keyword',    1, 26, 7 ],
			[ 'Whitespace', 1, 33, 1 ],
			[ 'keyword',    1, 34, 5 ],
			[ 'Whitespace', 1, 39, 1 ],
			[ 'keyword',    1, 40, 2 ],
			[ 'Whitespace', 1, 42, 1 ],

		],
	},
	{   code => <<'END_CODE',
package
END_CODE
		expected => [ [ 'keyword', 1, 1, 7 ], [ 'Whitespace', 1, 8, 1 ], ],
	},
);

plan tests => @cases * 1;

use PPIx::EditorTools::Lexer;

my @result;
foreach my $c (@cases) {
	@result = ();
	PPIx::EditorTools::Lexer->new->lexer(
		code        => $c->{code},
		highlighter => \&highlighter
	);

	#diag explain @result;
	is_deeply \@result, $c->{expected} or diag explain @result;
}

sub highlighter {
	push @result, [@_];
}

