# $Id: 1-node.t,v 1.4 2004/12/20 09:46:58 mike Exp $

use strict;
use warnings;
use Test::More tests => 17;
BEGIN { use_ok('Net::Z3950::PQF') };

my $term1 = new Net::Z3950::PQF::TermNode('unix');
ok(defined $term1, "created simple 'term' node");
ok($term1->isa("Net::Z3950::PQF::Node"), "'term' is a node");
my $text = $term1->render(0);
ok($text eq "term: unix\n", "rendered simple 'term' node");

my $term2 = new Net::Z3950::PQF::TermNode('elements',
					  [ "bib-1", 1, 21 ],
					  [ "bib-1", 2, 3 ]);
ok(defined $term2, "created 'term' node with attrs");
$text = $term2->render(0);
ok($text eq "term: elements\n\tattr: bib-1 1=21\n\tattr: bib-1 2=3\n",
	"rendered 'term' node with attrs");

my $rset = new Net::Z3950::PQF::RsetNode('oldRsetName',
					 [ "bib-1", 1, 1003 ]);
ok(defined $rset, "created 'rset' node with attrs");
ok($rset->isa("Net::Z3950::PQF::Node"), "'rset' is a node");
$text = $rset->render(0);
ok($text eq "rset: oldRsetName\n\tattr: bib-1 1=1003\n",
	"rendered 'rset' node with attrs");

my $or = new Net::Z3950::PQF::OrNode($term1, $term2);
ok(defined $or, "created 'or' node");
ok($or->isa("Net::Z3950::PQF::BooleanNode"), "'or' is a boolean node");
ok($or->isa("Net::Z3950::PQF::Node"), "'or' is a node");
$text = $or->render(0);
my $wanted = <<'__EOT__';
or
	term: unix
	term: elements
		attr: bib-1 1=21
		attr: bib-1 2=3
__EOT__
ok($text eq $wanted, "rendered 'or' node");

my $term3 = new Net::Z3950::PQF::TermNode('kerni',
					  [ "bib-1", 1, 1003 ],
					  [ "bib-1", 2, 3 ],
					  [ "bib-1", 5, 1 ]);
ok(defined $term3, "created third 'term' node");
$text = $term3->render(0);
ok($text eq ("term: kerni\n\tattr: bib-1 1=1003\n" .
	     "\tattr: bib-1 2=3\n\tattr: bib-1 5=1\n"),
   "rendered third 'term' node");

my $and = new Net::Z3950::PQF::AndNode($or, $term3);
ok(defined $and, "created 'and' node");
$text = $and->render(0);
$wanted = <<'__EOT__';
and
	or
		term: unix
		term: elements
			attr: bib-1 1=21
			attr: bib-1 2=3
	term: kerni
		attr: bib-1 1=1003
		attr: bib-1 2=3
		attr: bib-1 5=1
__EOT__
ok($text eq $wanted, "rendered 'and' node");
