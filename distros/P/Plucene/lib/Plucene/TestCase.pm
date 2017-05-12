package Plucene::TestCase;

=head1 NAME

Plucene::TestCase - Handy functions when testing Plucene

=head1 SYNOPSIS

	use Test::More tests => 10;
	use Plucene::TestCase;

	new_index {
		add_document( foo => "bar" );
	};

	re_index {
		add_document( foo => "baz" );
	}

	with_reader {
		$READER->whatever;
	}

	my $hits = search("foo:ba*");

=head1 EXPORTS

=cut

use strict;
use warnings;

use base 'Exporter';

use Plucene::Index::Reader;
use Plucene::Index::Writer;
use Plucene::Document;
use Plucene::Document::Field;
use Plucene::Analysis::SimpleAnalyzer;
use Plucene::QueryParser;
use Plucene::Search::IndexSearcher;

our (@EXPORT, $DIR, $DEBUG, $WRITER, $READER, $ANALYZER);
@EXPORT = qw($DIR $WRITER $READER $ANALYZER new_index re_index
	with_reader add_document search);

$ANALYZER = "Plucene::Analysis::SimpleAnalyzer";

=over 3

=item C<$DIR>

A directory which is created for the purposes of this test, in which the
index will be placed. It will normally be cleaned up at the end of the
test, unless C<$Plucene::TestCase::DEBUG> is set to allow you to peruse
the entrails.

=cut

use File::Temp qw(tempdir);
$DIR = tempdir(CLEANUP => !$DEBUG);

=item C<$WRITER>

A variable holding the current C<Index::Writer> object, if there is one.

=item C<$READER>

A variable holding the current C<Index::Reader> object, if there is one.

=item C<$ANALYZER>

A variable holding the class name of the desired C<Analysis::Analyzer>
class.

=item new_index BLOCK (Analyzer)

Create a new index, and do the following stuff in the block before
closing the index writer. C<$WRITER> is set for the duration of the
block.

The optional parameter should be the class name of the analyzer to use;
if not specified, the value from C<$ANALYZER>, which in turn defaults to
C<Plucene::Analysis::SimpleAnalyzer>, will be used.

=cut

sub new_index(&;$) {
	my ($block, $analyzer) = @_;
	$analyzer ||= $ANALYZER;

	# UNIVERSAL::require loads UNIVERSAL->import, which won't do.
	eval "require $analyzer";
	die "Couldn't require $analyzer" if $@;
	$WRITER = Plucene::Index::Writer->new($DIR, $analyzer->new, 1);
	$block->();
	undef $WRITER;
}

=item re_index BLOCK (Analyzer)

Same as C<new_index>, but doesn't create a new index, rather re-uses an
old one.

=cut

sub re_index(&;$) {
	my ($block, $analyzer) = @_;
	$analyzer ||= $ANALYZER;
	eval "require $analyzer";
	die "Couldn't require $analyzer" if $@;
	$WRITER = Plucene::Index::Writer->new($DIR, $analyzer->new, 0);
	$block->();
	undef $WRITER;
}

=item add_document( field1 => value1, ...)

Add a new document to the index, with the given fields and values

=cut

sub add_document {
	my @args = @_;
	my $doc  = Plucene::Document->new;
	while (my ($k, $v) = splice(@args, 0, 2)) {
		$doc->add(Plucene::Document::Field->Text($k, $v));
	}
	$WRITER->add_document($doc);
}

=item with_reader BLOCK

Opens an index reader in C<$READER> and runs the block.

=cut

sub with_reader (&) {
	$READER = Plucene::Index::Reader->open($DIR);
	shift->();
	$READER->close;
	undef $READER;
}

=item search

Searches for the query given. If any fields are not specified, they will
be assumed to be the default C<text>. Returns a C<Plucene::Search::Hits>
object. The value of C<$ANALYZER> will be used to construct an analyzer
for the query string.

=cut

sub search {
	eval "require $ANALYZER";
	my $parser = Plucene::QueryParser->new({
			analyzer => $ANALYZER->new(),
			default  => "text"
		});
	Plucene::Search::IndexSearcher->new($DIR)->search($parser->parse(shift));
}

1;
