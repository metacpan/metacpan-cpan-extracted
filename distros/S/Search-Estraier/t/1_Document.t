#!/usr/bin/perl -w

use strict;
use blib;

use Test::More tests => 60;
use Test::Exception;
use Data::Dumper;

BEGIN { use_ok('Search::Estraier') };

#print Search::Estraier::Document::_s('foo');

#cmp_ok(Search::Estraier::Document::_s("  this  is a  text  "), 'eq', 'this is a text', '_s - strip spaces');

my $debug = shift @ARGV;

my $attr_data = {
	'@uri' => 'http://localhost/Search-Estraier/',
	'size' => 42,
	'zero' => 0,
	'foo' => 'bar',
	'empty' => '',
};

my @test_texts = (
	'This is a test',
	'of pure-perl bindings',
	'for HyperEstraier'
);

my $vectors = {
	'foo' => 42,
	'bar' => 100,
	'baz' => 0,
};

ok(my $doc = new Search::Estraier::Document, 'new');

isa_ok($doc, 'Search::Estraier::Document');

cmp_ok($doc->id, '==', -1, 'id');

ok($doc->delete, "delete");

ok($doc = new Search::Estraier::Document, 'new');

foreach my $a (keys %{$attr_data}) {
	my $d = $attr_data->{$a};
	ok($doc->add_attr($a, $d), "add_attr $a = $d");
	#diag "draft:\n",$doc->dump_draft,Dumper($doc->{attrs});
	cmp_ok($doc->attr($a), 'eq', $d, "attr $a = $d");
}

foreach my $t (@test_texts) {
	ok($doc->add_text($t), "add_text: $t");
}

ok($doc->add_hidden_text('This is hidden text'), 'add_hidden_text');

ok($doc->add_vectors( %{ $vectors } ), 'add_vectors');

diag "current doc: ", Dumper($doc) if ($debug);

ok(my @texts = $doc->texts, 'texts');

ok(my $draft = $doc->dump_draft, 'dump_draft');

foreach my $a (keys %{$attr_data}) {
	my $regex = $a . '=' . $attr_data->{$a};
	like($draft, qr/$regex/, "draft has $regex");
}

diag "dump_draft:\n$draft" if ($debug);

ok(my $doc2 = new Search::Estraier::Document($draft), 'new from draft');
diag "doc from draft: ", Dumper($doc2) if ($debug);
cmp_ok($doc2->dump_draft, 'eq', $draft, 'drafts same');

cmp_ok($doc->id, '==', -1, 'id');
cmp_ok($doc2->id, '==', -1, 'id');

ok(my @attr = $doc->attr_names, 'attr_names');
diag "attr_names: ", join(',',@attr), "\n" if ($debug);

cmp_ok(scalar @attr, '==', keys %{$attr_data}, 'attr_names');

ok(! $doc->attr('foobar'), "non-existant attr");

foreach my $a (keys %{$attr_data}) {
	cmp_ok($doc->attr($a), 'eq', $attr_data->{$a}, "attr $a = ".$attr_data->{$a});
	ok($doc->add_attr($a, undef), "delete attribute");
}

@attr = $doc->attr_names;
diag "attr_names left: ", join(',',$doc->attr_names), "\n" if ($debug);
cmp_ok(@attr, '==' , 0, "attributes removed");

diag "texts: ", join(',',@texts), "\n" if ($debug);
ok(eq_array(\@test_texts, \@texts), 'texts');

ok(my $cat_text = $doc->cat_texts, 'cat_text');
diag "cat_texts: $cat_text" if ($debug);

ok($doc = new Search::Estraier::Document, 'new empty');
ok(! $doc->texts, 'texts');
cmp_ok($doc->dump_draft, 'eq', "\n", 'dump_draft');
cmp_ok($doc->id, '==', -1, 'id');
ok(! $doc->attr_names, 'attr_names');
ok(! $doc->attr(undef), 'attr');
ok(! $doc->cat_texts, 'cat_texts');

ok($doc = new Search::Estraier::Document, 'new empty');
cmp_ok($doc->score, '==', -1, 'no score');
ok($doc->set_score(12345), 'set_score');
cmp_ok($doc->score, '==', 12345, 'score');
like($doc->dump_draft, qr/%SCORE\s+12345/, 'dump_draft has %SCORE');

