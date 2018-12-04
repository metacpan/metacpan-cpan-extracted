#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

my $driver;
use Neo4j::Test;
BEGIN {
	unless ($driver = Neo4j::Test->driver) {
		print qq{1..0 # SKIP no connection to Neo4j server\n};
		exit;
	}
}
my $s = $driver->session;


# The following tests are for details of the Record class.

use Test::More 0.96 tests => 2;
use Test::Exception;
use Test::Warnings qw(warnings :no_end_test);


my $t = $s->begin_transaction;
my ($q, $r);


subtest 'wrong/missing field names for get()' => sub {
	plan tests => 7;
	TODO: {
		local $TODO = 'fix to not simply return the first field';
		throws_ok {
			warnings { $t->run('RETURN 1, 2')->single->get; }
		} qr/\bambiguous\b.*\bget\b.*\bfield/i, 'ambiguous get without field';
	}
	lives_ok { is 1, $t->run('RETURN 1')->single->get; } 'unambiguous get without field';
	dies_ok { $t->run('RETURN 0')->single->get({}); } 'non-scalar field';
	dies_ok { $t->run('RETURN 0')->single->get(1); } 'index out of bounds';
	dies_ok { $t->run('RETURN 0')->single->get(-1); } 'index negative';
	dies_ok { $t->run('RETURN 1 AS a')->single->get('b'); } 'field not present';
};


subtest 'hashref' => sub {
	plan tests => 4;
	my $fields = {
		first  => 17,
		second => 19,
		third  => 23,
	};
	$q = 'RETURN {first} AS first, {second} AS second, {third} AS third';
	lives_ok { $r = $t->run($q, $fields)->single->data; } 'get hashref';
	foreach my $key ( sort keys %$fields ) {
		is $r->{$key}, $fields->{$key}, "hashref key $key";
	}
};


done_testing;
