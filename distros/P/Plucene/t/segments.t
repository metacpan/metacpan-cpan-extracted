#!/usr/bin/perl -w

=head1 NAME 

t/segments - tests Plucene/Index/SegmentsReader.pm

=cut

use strict;
use warnings;

use Plucene::Search::HitCollector;
use Plucene::Search::IndexSearcher;

use Plucene::Analysis::SimpleAnalyzer;

use Plucene::Document;
use Plucene::Document::Field;

use Plucene::Index::Writer;
use Plucene::Index::Reader;
use Plucene::Index::SegmentInfos;
use Plucene::Index::SegmentReader;
use Plucene::Index::SegmentsReader;
use Plucene::Index::Term;

use Test::More tests => 11;
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

my $sis = Plucene::Index::SegmentInfos->new;
$sis->read(DIRECTORY);

my @si     = $sis->segments;
my $reader = Plucene::Index::SegmentReader->new($si[0]);

isa_ok my $s_reader =
	Plucene::Index::SegmentsReader->new(DIRECTORY, $reader) =>
	'Plucene::Index::SegmentsReader';

{    # num_docs
	my $num_docs = $s_reader->num_docs;
	is $num_docs => 9, "Correct number of documents";
}

{    # document
	isa_ok my $doc = $s_reader->document(1) => 'Plucene::Document';
	my @as_string = map $_->string, map $_->fields, $doc;
	is scalar @as_string => 1,     "Testing one document...";
	is $as_string[0]     => 'rap', "...correct document";
}

{
	is $s_reader->num_docs, 9, "Correct number of documents";
	isa_ok $s_reader->document(1) => 'Plucene::Document';
	is $s_reader->is_deleted(1), 0, "First document not deleted";
	ok $s_reader->norms('name'), "Got norms";
	isa_ok $s_reader->term_docs      => 'Plucene::Index::SegmentsTermDocs';
	isa_ok $s_reader->term_positions => 'Plucene::Index::SegmentsTermPositions';
}
