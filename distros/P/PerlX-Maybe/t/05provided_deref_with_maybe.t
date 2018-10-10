use strict;
use warnings;
use Test::More tests => 3;

use PerlX::Maybe ':all';

is_deeply(
	[
		provided_deref_with_maybe 0,     { foo   =>     1 },  6,
		provided_deref_with_maybe 1,     { bar   =>     2 },  7,
		provided_deref_with_maybe 0,     { baz   =>     3 },  8,
		provided_deref_with_maybe undef, { quux  =>     4 },  9,
		provided_deref_with_maybe [],    { quuux =>     5 }, 10,
		provided_deref_with_maybe 1,     { quuux => undef }, 11,
	],
	[
		6,
		bar   => 2, 7,
		8,
		9,
		quuux => 5, 10,
		11,
	]
);

is_deeply(
	[
		provided_deref_with_maybe 0,     [ 'foo'  ,     1 ],  6,
		provided_deref_with_maybe 1,     [ 'bar'  ,     2 ],  7,
		provided_deref_with_maybe 0,     [ 'baz'  ,     3 ],  8,
		provided_deref_with_maybe undef, [ 'quux' ,     4 ],  9,
		provided_deref_with_maybe [],    [ 'quuux',     5 ], 10,
		provided_deref_with_maybe 1,     [ 'quuux', undef ], 11,
	],
	[
		6,
		bar   => 2, 7,
		8,
		9,
		quuux => 5, 10,
		11,
	]
);

is_deeply(
	[
##		provided_deref_with_maybe 1,     \"scalar value",  1,
		provided_deref_with_maybe 1,     ["foo", "bar"],   2,
		provided_deref_with_maybe 1,     {"baz", "qux"},   3,
		provided_deref_with_maybe 1,     sub { die("nope") if @_; return blah => "quux" }, 4,
		provided_deref_with_maybe 1,     PerlX::Maybe::Test::Hash->new(  foo => 'bar' ), 5,
		provided_deref_with_maybe 1,     PerlX::Maybe::Test::Hash->new( _baz => 'qux' ), 6,
		provided_deref_with_maybe 1,     PerlX::Maybe::Test::Hash->new(  fuz => undef ), 7
	],
	[
##		"scalar value", 1,
		"foo", "bar",   2,
		"baz", "qux",   3,
		"blah", "quux", 4,
		"foo", "bar",   5,
		6, # skip private
		7, # skip undefined
	],
	"does do DWIM dereferencing"
);

package PerlX::Maybe::Test::Hash;

sub new {
	my $class = shift;
	my %data = @_;
	bless \%data, $class;
}
