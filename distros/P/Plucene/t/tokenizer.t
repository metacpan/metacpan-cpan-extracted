#!/usr/bin/perl -w

=head1 NAME 

t/tokenizer.t - tests Plucene/Analysis/Tokenizer.pn

=cut

use strict;
use warnings;

use Plucene::Search::HitCollector;
use Plucene::Search::IndexSearcher;
use Plucene::Analysis::SimpleAnalyzer;
use Plucene::Document;
use Plucene::Document::Field;
use Plucene::Index::Writer;
use Plucene::Analysis::LowerCaseTokenizer;
use Plucene::Analysis::CharTokenizer;
use Plucene::Analysis::Standard::StandardTokenizer;

use Test::More tests => 13;
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

{
	isa_ok my $tokenizer =
		Plucene::Analysis::Tokenizer->new({ reader => $reader }) =>
		'Plucene::Analysis::Tokenizer';
}

{    # normalizing with lowercase tokenizer
	isa_ok my $tokenizer =
		Plucene::Analysis::LowerCaseTokenizer->new({ reader => $reader }) =>
		'Plucene::Analysis::Tokenizer';
	isa_ok $tokenizer => 'Plucene::Analysis::LowerCaseTokenizer';
	my $norm = $tokenizer->normalize('SHOUT');
	is $norm => 'shout', "string normalized correctly (lowercase tokenizer)";
	ok $tokenizer->close, "closed lowercase tokenizer";
}

{    # normalizing with character tokenizer
	isa_ok my $tokenizer =
		Plucene::Analysis::CharTokenizer->new({ reader => $reader }) =>
		'Plucene::Analysis::Tokenizer';
	isa_ok $tokenizer => 'Plucene::Analysis::CharTokenizer';
	my $norm = $tokenizer->normalize('SHOUT');
	is $norm => 'SHOUT', "string normalized correctly (character tokenizer)";
	ok $tokenizer->close, "closed character tokenizer";
}

{    # normalize with standard tokenizer
	isa_ok my $tokenizer =
		Plucene::Analysis::Standard::StandardTokenizer->new(
		{ reader => $reader }) => 'Plucene::Analysis::Tokenizer';
	isa_ok $tokenizer => 'Plucene::Analysis::Standard::StandardTokenizer';
	my $norm = $tokenizer->normalize('SHOUT');
	is $norm => 'SHOUT', "string normalized correctly (standard tokenizer)";
	ok $tokenizer->close, "closed standard tokenizer";

}
