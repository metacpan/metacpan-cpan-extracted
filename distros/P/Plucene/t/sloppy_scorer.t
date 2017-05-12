#!/usr/bin/perl -w

=head1 NAME 

t/sloppy_scorer.t - tests Plucene/Search/PhraseScorer/Sloppy.pm

=cut

use strict;
use warnings;

use Plucene::QueryParser;
use Plucene::Search::HitCollector;
use Plucene::Search::IndexSearcher;
use Plucene::Analysis::SimpleAnalyzer;
use Plucene::Document;
use Plucene::Document::Field;
use Plucene::Index::Writer;
use Plucene::Search::PhraseScorer::Sloppy;
use Plucene::Search::Query;

use Test::More tests => 4;
use File::Path;
use File::Temp qw/tempdir/;

use constant DIRECTORY => tempdir();

END { rmtree DIRECTORY }

#------------------------------------------------------------------------------
# Helper stuff
#------------------------------------------------------------------------------

sub data {
	return [
		wsc => { name => "Writing Solid Code" },
		rap => { name => "Rapid Development" },
		gui => { name => "GUI Bloopers" },
		ora => { name => "Using Oracle 8i" },
		app => { name => "Advanced Perl Programming" },
		aph => { name => "Advanced Perl Hacking" },
		jph => { name => "Advanced Just Another Perl Hacker" },
		xpe => { name => "Extreme Programming Explained" },
		boo => { name => "Boo-Hoo" },
		adv => { name => "Advanced advancement" },
		dbs => { name => "Designing From Both Sides of the Screen" },
		dbi => { name => "Programming the Perl DBI" },
	];
}

#------------------------------------------------------------------------------
# Indexing
#------------------------------------------------------------------------------

sub index_documents_Perl {
	my @data   = @{ data() };
	my $writer =
		Plucene::Index::Writer->new(DIRECTORY,
		Plucene::Analysis::SimpleAnalyzer->new(), 1);
	while (my ($id, $terms) = splice @data, 0, 2) {
		my $doc = Plucene::Document->new;
		$doc->add(Plucene::Document::Field->Keyword(id => $id));
		$doc->add(Plucene::Document::Field->UnStored(%$terms));
		$writer->add_document($doc);
	}
	$writer->optimize();    # THIS IS NOT AN OPTIONAL STEP
}

index_documents_Perl();

#------------------------------------------------------------------------------
# Tests
#------------------------------------------------------------------------------

# construct a phrase query

my $p = Plucene::QueryParser->new({
		analyzer => Plucene::Analysis::SimpleAnalyzer->new,
		default  => "text"
	});
my $query = $p->parse("name:\"perl advanced\"");
$query->slop(1);

# get a searcher
my $plucy = Plucene::Search::IndexSearcher->new(DIRECTORY);
isa_ok my $hits = $plucy->search($query) => 'Plucene::Search::Hits';

# get a reader
my $reader = $plucy->reader;

my $scorer = Plucene::Search::Query->scorer($query, $plucy, $reader);
isa_ok $scorer => 'Plucene::Search::PhraseScorer::Sloppy';

$scorer->score($hits, 100);

isa_ok my $first = $scorer->first => 'Plucene::Search::PhrasePositions';
is $first->doc, 11, "Correct document";
