#!/usr/bin/perl -w

=head1 NAME 

t/search_hits.t - tests Plucene/Search/Hits.pm

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

my $plucy = Plucene::Search::IndexSearcher->new(DIRECTORY);

my $p = Plucene::QueryParser->new({
		analyzer => Plucene::Analysis::SimpleAnalyzer->new,
		default  => "text"
	});
my $query = $p->parse("name:perl");

isa_ok my $hits = $plucy->search($query) => 'Plucene::Search::Hits';

{    # get_more_docs doesn't exist
	eval { $hits->get_more_docs };
	like $@, qr/object method/, "No such call as get_more_docs";
}

{    # try an invalid hit doc
	eval { $hits->hit_doc($hits->length + 10) };
	like $@, qr/Not a valid hit number/,
		"Can't get a hit_doc beyond the number of hits!";
}

{    # score one of the hits
	my $score = $hits->score($hits->length - 1);
	is $score, 1.15625, "Correct score";
}
