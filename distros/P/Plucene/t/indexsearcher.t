#!/usr/bin/perl -w

=head1 NAME 

t/indexsearcher.t - tests Plucene/Search/IndexSearcher.pm

=cut

use strict;
use warnings;

use Plucene::Search::HitCollector;
use Plucene::Search::IndexSearcher;
use Plucene::Analysis::SimpleAnalyzer;
use Plucene::Document;
use Plucene::Document::Field;
use Plucene::Index::Writer;
use Plucene::QueryParser;

use Test::More tests => 3;
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
		xpe => { name => "Extreme Programming Explained" },
		boo => { name => "Boo-Hoo" },
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

{                         # non-existant index
	eval { Plucene::Search::IndexSearcher->new('HongKongPhooey') };
	like $@, qr/to turn/, "Can't search over a non-existant index";
}

{
	my $searcher = Plucene::Search::IndexSearcher->new(DIRECTORY);
	my $parser   = Plucene::QueryParser->new({
			analyzer => Plucene::Analysis::SimpleAnalyzer->new(),
			default  => "text"
		});

	my $query = $parser->parse("name:spongebob");
	isa_ok my $hits = $searcher->search($query) => 'Plucene::Search::Hits';
	eval { $searcher->close };
	ok !$@, "close";
}
