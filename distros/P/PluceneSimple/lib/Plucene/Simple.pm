package Plucene::Simple;

=head1 NAME

Plucene::Simple - An interface to Plucene

=head1 SYNOPSIS

	use Plucene::Simple;

	# create an index
	my $plucy = Plucene::Simple->open($index_path);

	# add to the index
	$plucy->add(
		$id1 => { $field => $term1 }, 
		$id2 => { $field => $term2 }, 
	);

	# or ...
	$plucy->index_document($id => $data);

	# search an existing index
	my $plucy = Plucene::Simple->open($index_path);
	my @results = $plucy->search($search_string);

	# optimize the index
	$plucy->optimize;

	# remove something from the index
	$plucy->delete_document($id);

	# is something in the index?
	if ($plucy->indexed($id) { ... }
	
=head1 DESCRIPTION

This provides a simple interface to L<Plucene>. Plucene is large and
multi-featured, and it expected that users will subclass it, and tie
all the pieces together to suit their own needs. Plucene::Simple is,
therefore, just one way to use Plucene. It's not expected that it will
do exactly what *you* want, but you can always use it as an example of
how to build your own interface.

=head1 INDEXING

=head2 open

You make a new Plucene::Simple object like so:

	my $plucy = Plucene::Simple->open($index_path);

If this index doesn't exist, then it will be created for you, otherwise you
will be adding to an exisiting one.
	
Then you can add your documents to the index:

=head2 add

Every document must be indexed with a unique key (which will be returned
from searches).

A document can be made up of many fields, which can be added as
a hashref:

	$plucy->add($key, \%data);

	$plucy->add(
		chap1  => { 
			title => "Moby-Dick", 
			author => "Herman Melville", 
	 		text => "Call me Ishmael ..." 
		},
		chap2  => { 
			title => "Boo-Hoo", 
			author => "Lydia Lee", 
			text => "...",
		}
	);

=head2 index_document

Alternatively, if you do not want to index lots of metadata, but rather
just simple text, you can use the index_document() method.

	$plucy->index_document($key, $data);
	$plucy->index_document(chap1 => 'Call me Ishmael ...');

=head2 delete_document

	$plucy->delete_document($id);

=head2 optimize

	$plucy->optimize;

Plucene is set-up to perform insertions quickly. After a bunch of inserts
it is good to optimize() the index for better search speed.

=head1 SEARCHING

=head2 search

	my @ids = $plucy->search('ishmael'); 
	  # ("chap1", ...)

This will return the IDs of each document matching the search term.

If you have indexed your documents with fields, you can also search with
the field name as a prefix:

	my @ids = $plucy->search("author:lee"); 
		# ("chap2" ...)

	my @results = $plucy->search($search_string);

This will search the index with the given query, and return a list of 
document ids.

Searches can be much more powerful than this - see L<Plucene> for
further details.

=head2 search_during

	my @results = $lucy->search_during($search_string, $date1, $date2);
	my @results = $lucy->search_during("to:Fred", "2001-01-01" => "2003-12-31");

If your documents were given an ISO 'date' field when indexing,
search_during() will restrict the results to all documents between the
specified dates. Any document without a 'date' field will be ignored.

=head2 indexed

	if ($plucy->indexed($id) { ... }

This returns true if there is a document with the given ID in the index.

=cut

use strict;
use warnings;

our $VERSION = '1.04';

use Plucene::Analysis::SimpleAnalyzer;
use Plucene::Analysis::WhitespaceAnalyzer;
use Plucene::Document;
use Plucene::Document::DateSerializer;
use Plucene::Document::Field;
use Plucene::Index::Reader;
use Plucene::Index::Writer;
use Plucene::QueryParser;
use Plucene::Search::DateFilter;
use Plucene::Search::HitCollector;
use Plucene::Search::IndexSearcher;

use Carp;
use File::Spec::Functions qw(catfile);
use Time::Piece;
use Time::Piece::Range;

sub open {
	my ($class, $dir) = @_;
	$dir or croak "No directory given";
	bless { _dir => $dir }, $class;
}

sub _dir { shift->{_dir} }

sub _parsed_query {
	my ($self, $query, $default) = @_;
	my $parser = Plucene::QueryParser->new({
			analyzer => Plucene::Analysis::SimpleAnalyzer->new(),
			default  => $default
		});
	$parser->parse($query);
}

sub _searcher { Plucene::Search::IndexSearcher->new(shift->_dir) }

sub _reader { Plucene::Index::Reader->open(shift->_dir) }

sub search {
	my ($self, $sstring) = @_;
	return () unless $sstring;
	my @docs;
	my $searcher = $self->_searcher;
	my $hc       = Plucene::Search::HitCollector->new(
		collect => sub {
			my ($self, $doc, $score) = @_;
			my $res = eval { $searcher->doc($doc) };
			push @docs, [ $res, $score ] if $res;
		});
	$searcher->search_hc($self->_parsed_query($sstring, 'text'), $hc);
	return map $_->[0]->get("id")->string, sort { $b->[1] <=> $a->[1] } @docs;
}

sub search_during {
	my ($self, $sstring, $date1, $date2) = @_;
	return () unless $sstring;
	my $range = Time::Piece::Range->new(
		Time::Piece->strptime($date1, "%Y-%m-%d"),
		Time::Piece->strptime($date2, "%Y-%m-%d"));
	my $filter = Plucene::Search::DateFilter->new({
			field => '_date_',
			from  => $range->start,
			to    => $range->end,
		});
	my $qp = Plucene::QueryParser->new({
			analyzer => Plucene::Analysis::WhitespaceAnalyzer->new(),
			default  => "text"
		});
	my $query = $qp->parse($sstring);
	my $hits = $self->_searcher->search($query, $filter);
	return () unless $hits->length;
	my @docs = map $hits->doc($_), 0 .. ($hits->length - 1);
	return map $_->get("id")->string, @docs;
}

sub _writer {
	my $self = shift;
	return Plucene::Index::Writer->new(
		$self->_dir,
		Plucene::Analysis::SimpleAnalyzer->new(),
		-e catfile($self->_dir, "segments") ? 0 : 1
	);
}

sub add {
	my ($self, @data) = @_;
	my $writer = $self->_writer;
	while (my ($id, $terms) = splice @data, 0, 2) {
		my $doc = Plucene::Document->new;
		$doc->add(Plucene::Document::Field->Keyword(id => $id));
		foreach my $key (keys %$terms) {
			if ($key eq 'text') {
				next;    # gets added at the end anyway
			} elsif ($key eq "date") {
				my $date = eval { Time::Piece->strptime($terms->{date}, "%Y-%m-%d") };
				do { $date = Time::Piece->new; $terms->{date} = $date->ymd; } if $@;
				$doc->add(
					Plucene::Document::Field->Keyword("_date_", freeze_date($date)));
				$doc->add(Plucene::Document::Field->Keyword("date", $date->ymd));
			} else {
				$doc->add(Plucene::Document::Field->UnStored($key => $terms->{$key}));
				$terms->{text} .= " " . $terms->{$key} unless $key =~ /^_/;
			}
		}
		$doc->add(Plucene::Document::Field->UnStored(text => $terms->{text}));
		$writer->add_document($doc);
	}
	undef $writer;
}

sub index_document {
	my ($self, $id, $data) = @_;
	my $writer = $self->_writer;
	my $doc    = Plucene::Document->new;
	$doc->add(Plucene::Document::Field->Keyword(id => $id));
	$doc->add(Plucene::Document::Field->UnStored('text' => $data));
	$writer->add_document($doc);
	undef $writer;
}

sub delete_document {
	my ($self, $id) = @_;
	my $reader = $self->_reader;
	$reader->delete_term(
		Plucene::Index::Term->new({ field => "id", text => $id }));
	$reader->close;
}

sub optimize { shift->_writer->optimize() }

sub indexed {
	my ($self, $id) = @_;
	my $term = Plucene::Index::Term->new({ field => 'id', text => $id });
	return $self->_reader->doc_freq($term);
}

=head1 COPYRIGHT

Copyright (C) 2003-2004 Kasei Limited

=cut

1;
