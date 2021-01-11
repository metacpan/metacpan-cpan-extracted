#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);
use utf8;  # required to parse UTF-8 bytes in this file as characters

my $driver;
use Neo4j::Test;
BEGIN {
	unless ($driver = Neo4j::Test->driver) {
		print qq{1..0 # SKIP no connection to Neo4j server\n};
		exit;
	}
}


# The purpose of these tests is to confirm that Unicode data is treated
# correctly by the JSON decoders.

# see also:
# https://github.com/majensen/rest-neo4p/pull/19/commits/227b94048a1d0277f1d5700c6934ba26fe7bfc1e

use Test::More 0.96 tests => 7 + 2;
use Test::Exception;
use Test::Warnings;
my $transaction = $driver->session->begin_transaction;
$transaction->{return_stats} = 0;  # optimise sim


my ($r);


sub to_hex ($) {
	return unless defined $_[0];
	join ' ', map { sprintf "%02x", ord $_ } split m//, shift;
}

my %props = (
	singlebyte => "\N{U+0025}",   # '%' PERCENT SIGN = 0x25
	supplement => "\N{U+00E4}",   # 'ä' LATIN SMALL LETTER A WITH DIAERESIS = 0xc3a4
	extension  => "\N{U+0100}",   # 'Ā' LATIN CAPITAL LETTER A WITH MACRON = 0xc480
	threebytes => "\N{U+D55C}",   # '한' HANGUL SYLLABLE HAN = 0xed959c
	smp        => "\N{U+1F600}",  # '😀' GRINNING FACE = 0xf09f9880
	decomposed => "o\N{U+0302}",  # 'ô' LATIN SMALL LETTER O + COMBINING CIRCUMFLEX ACCENT = 0x6fcc82
	mixed      => "%äĀ한😀ô",  # 0x25c3a4c480ed959cf09f98806fcc82
);
my @keys = sort keys %props;
my (@id, $smp_r, $mixed_r, $node);


lives_ok {
	$smp_r = $driver->session->run('RETURN {smp}', smp => $props{smp})->list->[0]->get(0);
} 'get smp';
is to_hex $smp_r, to_hex $props{smp}, 'smp';


# store test data
lives_ok {
	$r = $transaction->run('CREATE (n) RETURN id(n) AS id');
} 'create node';
lives_ok {
	@id = ( id => $r->list->[0]->get('id') );
} 'get node id';
lives_ok {
	$transaction->run("MATCH (n) WHERE id(n) = {id} SET n = {props}", @id, props => \%props);
} 'write props';


subtest 'read single property' => sub {
	plan tests => 3;
	lives_ok {
		$r = $transaction->run('MATCH (n) WHERE id(n) = {id} RETURN n.mixed', @id);
	} 'read mixed';
	lives_ok {
		$mixed_r = $r->list->[0]->get(0);
	} 'get mixed_r';
	is to_hex $mixed_r, to_hex $props{mixed}, "mixed_r";
};


subtest 'read full property list' => sub {
	plan tests => 3 + @keys;
	# This strategy depends on the implementation detail that Neo4j
	# returns exactly the property map in JSON when a node is requested.
	lives_ok {
		$r = undef;
		$r = $transaction->run('MATCH (n) WHERE id(n) = {id} RETURN n', @id);
	} 'read props';
	lives_ok {
		$node = $r->list->[0]->get(0);
	} 'get node';
	is ref $node, 'Neo4j::Driver::Type::Node', '$node is blessed node';
	foreach my $key (@keys) {
		is to_hex $node->get($key), to_hex $props{$key}, "prop: $key";
	}
};


CLEANUP: {
	lives_ok { $transaction->rollback } 'rollback';
}

done_testing;
