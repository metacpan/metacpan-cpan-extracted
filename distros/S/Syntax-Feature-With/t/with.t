#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

# We are testing a PadWalker-based implementation of:
#
#   with(\%hash, sub { ... });
#
# Contract:
#   - First arg: hashref
#   - Second arg: coderef
#   - Lexicals to be aliased (e.g. $a, $x) must be declared
#	 in the *outer* scope and closed over by the coderef.
#
# Example:
#   my %h = ( a => 'b' );
#   my ($a);
#   with(\%h, sub { print $a });   # $a aliases $h{a}
#
# This is required because PadWalker::closed_over only sees
# lexicals that are closed over, not those declared inside
# the coderef itself.

use_ok('Syntax::Feature::With');

# ----------------------------------------------------------------------
# Basic aliasing: $a should alias $h{a}
# ----------------------------------------------------------------------

{
	my %h = ( a => 'b' );

	# Declare the lexical in the outer scope so the coderef closes over it.
	my $a;

	my $result = with(\%h, sub {
		# $a is *not* declared here; it is closed over from outside.
		return $a;
	});

	is($result, 'b', 'basic aliasing: $a aliases $h{a}');
}

# ----------------------------------------------------------------------
# Read/write aliasing: assignments should write back into the hash
# ----------------------------------------------------------------------

{
	my %h = ( x => 10, y => 20 );

	my ($x, $y);

	with(\%h, sub {
		$x += 5;   # should update $h{x}
		$y = 99;   # should update $h{y}
	});

	is($h{x}, 15, 'writeback: $x += 5 updates $h{x}');
	is($h{y}, 99, 'writeback: $y = 99 updates $h{y}');
}

# ----------------------------------------------------------------------
# Only valid Perl identifiers should be aliased
# Keys like "1abc" or "foo-bar" should be ignored
# ----------------------------------------------------------------------

{
	my %h = (
		good	  => 'ok',
		'1bad'	=> 'no',
		'foo-bar' => 'nope',
	);

	my $good;   # only this one is a valid identifier

	my $seen;

	with(\%h, sub {
		$seen = $good;
	});

	is($seen, 'ok', 'only valid identifiers are aliased');
}

# ----------------------------------------------------------------------
# Undeclared lexicals should NOT be auto-created or aliased.
# They simply remain undef.
# ----------------------------------------------------------------------

{
	my %h = ( a => 123 );

	my $value;

	with(\%h, sub {
		# $a is not declared anywhere
		# It should remain undef
		$value = $a;
	});

	ok(!defined $value, 'undeclared lexical remains undef (not auto-created)');
}

# ----------------------------------------------------------------------
# Return value: with() should return whatever the coderef returns
# ----------------------------------------------------------------------

{
	my %h = ( a => 5, b => 7 );

	my ($a, $b);

	my $sum = with(\%h, sub {
		return $a + $b;
	});

	is($sum, 12, 'with() returns the coderef result');
}

# ----------------------------------------------------------------------
# Error handling: first argument must be a hashref
# ----------------------------------------------------------------------

{
	my $error;

	eval { with([], sub {}) };
	$error = $@;

	like($error, qr/hashref/, 'dies if first argument is not a hashref');
}

# ----------------------------------------------------------------------
# Error handling: second argument must be a coderef
# ----------------------------------------------------------------------

{
	my %h = ( a => 1 );
	my $error;

	eval { with(\%h, 'not a coderef') };
	$error = $@;

	like($error, qr/coderef/, 'dies if second argument is not a coderef');
}

done_testing();
