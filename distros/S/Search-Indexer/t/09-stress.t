# test adapted from Plucene's stress.t

use strict;
use warnings;
use Test::More tests => 34 ;

use Search::Indexer;
BEGIN {use_ok("Search::Indexer");}


my $datadir = "t/data";


foreach (<*.bdb>) {
  unlink;
}

my $i = new Search::Indexer(writeMode => 1);


my $n = 1;
$/ = undef;

my %titles;
my @all = ((map { "book$_" } 1 .. 24), "preface");

foreach my $file (@all) {
  print STDERR "indexing $file ... ";
  open F, "$datadir/$file" or die "can't open $datadir/$file";
  my $buf = <F>;
  $i->add($n, $buf);
  close F;
  $titles{$n} = $file;
  $n++;
  print STDERR "done\n";
}


my %tests = (
#	"author:homer" => \@all,
#	"-author:homer" => [],
#	"author:mwk"    => [],

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

#	"aeol*"                   => [ "book10", "book11", "book23", "preface" ],
	"aeolus OR persephone"    => [ "book10", "book11", "book23", "preface" ],
	"aeolus persephone"       => [ "book10", "book11", "book23", "preface" ],
	"aeolus AND persephone"   => [ "book10", "book11" ],
	"+aeolus +persephone"     => [ "book10", "book11" ],
	"persephone cretheus"     => [ "book10", "book11" ],
	"persephone AND cretheus" => ["book11"],
	"+persephone +cretheus"   => ["book11"],
	"persephone AND NOT cretheus" => ["book10"],
	"persephone -cretheus"        => ["book10"],
	'"wine dark"' => [ map { "book$_" } 1, 2, 3, 4, 5, 6, 7, 12, 19 ],
	'"wine dark" AND penelope' => [ map { "book$_" } 1, 2, 4, 5, 19 ],
	'+"wine dark" +penelope' => [ map { "book$_" } 1, 2, 4, 5, 19 ],
#	'(author:mwk AND persephone) OR (author:homer AND cretheus)' => ["book11"],
	'(foobar AND persephone) OR cretheus' => ["book11"],
#	'(author:mwk persephone) OR author:homer',
#	=> \@all,
#	'"peisistratus nestor"~4' => [ "book3", "book4", "book15", "preface" ],

);


foreach my $q (keys %tests) {
  my $r = $i->search($q);

  ok(eq_set([map {$titles{$_}} keys %{$r->{scores}}], $tests{$q}), $q);
}

