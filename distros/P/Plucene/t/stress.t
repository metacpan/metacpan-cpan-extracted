#!/usr/bin/perl 

use strict;
use warnings;

use Test::More "no_plan";
use Plucene::TestCase;
use File::Slurp;
use Plucene::Analysis::WhitespaceAnalyzer;

diag "Indexing the entire Odyssey. This may take some time\n";
new_index {
	for my $file (<t/data/*>) {
		next if $file =~ /\,D|CVS$/;    # (Version control)--
		diag "$file\n";
		my $content = read_file($file);
		$file =~ s{t/data/}{};
		add_document(
			text   => $content,
			id     => $file,
			author => "Homer"
		);
	}
	diag "Closing\n";

	#$WRITER->optimize;
};

my @all = ((map { "book$_" } 1 .. 24), "preface");
my %tests = (
	"author:homer" => \@all,

	"-author:homer" => [],
	"author:mwk"    => [],

	"persephone" => [ "book10", "book11" ],
	"aeolus"     => [ "book10", "book11", "book23", "preface" ],

	# Various hapaxes to ensure that all the books are indexed

	"chapman"    => ["preface"],
	"expression" => ["book1"],
	"flour"      => ["book2"],
	"bandying"   => ["book3"],
	"abhor"      => ["book10"],
	"agree"      => ["book11"],
	"liketh"     => ["book12"],
	"leant"      => ["book13"],
	"elbow"      => ["book14"],
	"arybas"     => ["book15"],
	"rejected"   => ["book16"],
	"alders"     => ["book17"],
	"mulius"     => ["book18"],
	"onion"      => ["book19"],
	"undressed"  => ["book20"],
	"agree"      => ["book21"],
	"purged"     => ["book22"],
	"bruit"      => ["book23"],
	"deigned"    => ["book24"],

	"aeol*"                   => [ "book10", "book11", "book23", "preface" ],
	"aeolus OR persephone"    => [ "book10", "book11", "book23", "preface" ],
	"aeolus AND persephone"   => [ "book10", "book11" ],
	"persephone cretheus"     => [ "book10", "book11" ],
	"persephone AND cretheus" => ["book11"],
	"persephone AND NOT cretheus" => ["book10"],
	"persephone -cretheus"        => ["book10"],
	'"wine dark"' => [ map { "book$_" } 1, 2, 3, 4, 5, 6, 7, 12, 19 ],
	'"wine dark" AND penelope' => [ map { "book$_" } 1, 2, 4, 5, 19 ],
	'(author:mwk AND persephone) OR (author:homer AND cretheus)' => ["book11"],
	'(author:mwk persephone) OR author:homer',
	=> \@all,
	'"peisistratus nestor"~4' => [ "book3", "book4", "book15", "preface" ],

);

my $SEARCHER = Plucene::Search::IndexSearcher->new($DIR);
$ANALYZER = "Plucene::Analysis::WhitespaceAnalyzer";

# But only for the searching
while (my ($query, $expected) = each %tests) {
	my $hits = search($query);
	is(scalar @{ $hits->{hit_docs} }, scalar @$expected,
		"Right number of hits");
	my @ids =
		sort map { $SEARCHER->doc($_->{id})->get("id")->string }
		@{ $hits->{hit_docs} };
	is_deeply(\@ids, [ sort @$expected ], "Right documents");
}

