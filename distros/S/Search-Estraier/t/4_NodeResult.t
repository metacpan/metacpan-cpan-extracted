#!/usr/bin/perl -w

use strict;
use blib;

use Test::More tests => 10;
use Test::Exception;
use Data::Dumper;

BEGIN { use_ok('Search::Estraier') };

my $data = {
	docs => [ qw/1 2 3 4 5/ ],
	hints => {
		VERSION => 0.42,
		NODE => 'none',
		HIT => 42,
		DOCNUM => 1234,
		WORDNUM => 4321,
	},
};

dies_ok { new Search::Estraier::NodeResult } "new without args";
ok(my $res = new Search::Estraier::NodeResult( %$data ), 'new');
isa_ok($res, 'Search::Estraier::NodeResult');

cmp_ok($res->doc_num, '==', $#{$data->{docs}} + 1, 'doc_num');

for (my $i = 0; $i < $res->doc_num; $i++) {
	ok(my $doc = $res->get_doc($i), "get_doc $i");
}
