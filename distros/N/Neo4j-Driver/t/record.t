#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

my $driver;
use Neo4j_Test;
BEGIN {
	unless ( $driver = Neo4j_Test->driver() ) {
		print qq{1..0 # SKIP no connection to Neo4j server\n};
		exit;
	}
}
my $s = $driver->session;


# The following tests are for details of the Record class.

use Test::More 0.94;
use Test::Exception;
use Test::Warnings 0.010 qw(warning :no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

plan tests => 2 + $no_warnings;


my ($q, $r, $w);


subtest 'wrong/ambiguous field names for get()' => sub {
	plan tests => 1 + 4 + 5 + 7;
	lives_ok { $r = 0; $r = $s->run('RETURN 1, 0, 2 AS NaN')->single; } 'query lives';
	# index/key collisions
	is $r->get( 0 ), 1, 'get( 0 )';
	is $r->get("0"), 0, 'get("0")';
	is $r->get( 1 ), 0, 'get( 1 )';
	is $r->get("1"), 1, 'get("1")';
	# other possibly ambiguous cases
	dies_ok { $r->get("2"); } 'get("2") dies';
	lives_ok { $w = warning { $r->get; }; } 'get without field lives';
	(like $w, qr/\bambiguous\b.*\bget\b.*\bfield/i, 'get without field ambiguous') or diag 'got warning(s): ', explain($w);
	dies_ok { $r->get("nAn"); } 'field treated as case sensitive';
	# The string representation of numeric NaN differs by OS and by
	# Perl version. See <https://en.wikipedia.org/wiki/NaN#Display>.
	# Actually observed values include 'NaN', 'nan', '1.#QNAN'.
	# That any NaN or Inf is treated as a string is all we care about.
	use Neo4j::Driver::Record;
	ok ! Neo4j::Driver::Record::_looks_like_int(0+"NaN"), 'NaN is string';
	# unambiguous cases
	lives_and { is $r->get( 2.0 ), 2 } 'get(2.0)';
	$q = 'RETURN 1 AS a';
	lives_and { is $s->run($q)->single->get(), 1 } 'unambiguous get without field';
	dies_ok { $s->run($q)->single->get({}); } 'non-scalar field';
	dies_ok { $s->run($q)->single->get(1); } 'index out of bounds';
	dies_ok { $s->run($q)->single->get(-1); } 'index negative';
	dies_ok { $s->run($q)->single->get(.1); } 'index not integer';
	dies_ok { $s->run($q)->single->get("\N{U+0100}"); } 'field not present';
};


subtest 'hashref' => sub {
	plan tests => 2 + 3;
	my $fields = {
		first  => 17,
		second => 19,
		third  => 23,
	};
	$q = 'RETURN {first} AS first, {second} AS second, {third} AS third';
	lives_ok { $r = $s->run($q, $fields)->single->data; } 'get hashref';
	is ref $r, 'HASH', '$r is HASH ref';
	foreach my $key ( sort keys %$fields ) {
		is $r->{$key}, $fields->{$key}, "hashref key $key";
	}
};


done_testing;
