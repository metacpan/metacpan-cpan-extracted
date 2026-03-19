use strict;
use warnings;
use Test::Most;

use Syntax::Feature::With qw(with_hash);

{
	package Dummy;
	our %H = (
		'http-status' => 200,
		'user_id'	 => 42,
		'foo'		 => 1,
	);
}

my ($status, $user, $foo);

# -------------------------------------------------------------------------
# Basic rename
# -------------------------------------------------------------------------

with_hash
	-rename => {
		'http-status' => 'status',
		'user_id'	 => 'user',
	},
	\%Dummy::H,
	sub {

		is $status, 200, 'rename: $status aliased from http-status';
		is $user,   42,  'rename: $user aliased from user_id';

		$status = 404;
		$user = 99;
	};

is $Dummy::H{'http-status'}, 404, 'rename: write-through for http-status';
is $Dummy::H{'user_id'},	 99,  'rename: write-through for user_id';

# -------------------------------------------------------------------------
# rename + only
# -------------------------------------------------------------------------

with_hash
	-only => [qw/http-status foo/],
	-rename => { 'http-status' => 'status' },
	\%Dummy::H,
	sub {
		is $status, 404, 'rename+only: $status aliased';
		is $foo, 1,   'rename+only: $foo aliased';
	};

# -------------------------------------------------------------------------
# rename + -strict: missing lexical should croak
# -------------------------------------------------------------------------

dies_ok {
	with_hash
		-strict,
		-rename => { 'http-status' => 'missing_lex' },
		\%Dummy::H,
		sub { };
} 'rename + -strict: missing lexical croaks';

done_testing;

