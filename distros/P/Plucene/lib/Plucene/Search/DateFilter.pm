package Plucene::Search::DateFilter;
use base 'Plucene::Search::Filter';
use Carp;
use strict;
use warnings;

use Plucene::Document::DateSerializer;
use Time::Piece;
use Bit::Vector::Minimal;

=head1 NAME

Plucene::Search::DateFilter - Restrict searches to given time periods

=head1 SYNOPSIS

	my $filter = Plucene::Search::DateFilter->new({
		field => "date",
		from  => Time::Piece $from,
		to    => Time::Piece $to
	})
	my $hits = $searcher->search($query, $filter);

=head1 DESCRIPTION

This class can restrict the results of a search to a set of dates. This
requires a field to have been indexed using
L<Plucene::Document::DateSerializer>. See the documentation for that module
for how to do this.

=head1 METHODS

=head2 new

	my $filter = Plucene::Search::DateFilter->new({
		field => "date",
		from  => Time::Piece $from,
		to    => Time::Piece $to
	})

This creates a new filter. Either of C<from> or C<to> are optional.

=cut

sub new {
	my ($self, $args) = @_;
	for my $arg (qw(from to)) {
		next unless exists $args->{$arg};
		croak "$arg argument was not a Time::Piece object"
			unless UNIVERSAL::isa($args->{$arg}, "Time::Piece");
	}
	croak "Need to pass a field" unless exists $args->{field};
	no warnings 'uninitialized';
	bless {
		field => $args->{field},
		from  => freeze_date($args->{from} || Time::Piece->new(0)),
		to    => freeze_date($args->{to} || Time::Piece->new(~0)),
	}, $self;
}

=head2 bits

This is used by the searcher to iterate over the documents and return
a bitfield specifying which documents are included in the range.

=cut

sub bits {
	my ($self, $reader) = @_;
	my $bits = Bit::Vector::Minimal->new(size => $reader->max_doc);
	my $enum = $reader->terms(
		Plucene::Index::Term->new({
				field => $self->{field},
				text  => $self->{from} }));
	return $bits unless $enum->term;
	my $termdocs = $reader->term_docs;

	my $stop = Plucene::Index::Term->new({
			field => $self->{field},
			text  => $self->{to} });
	while ($enum->term->le($stop)) {
		$termdocs->seek($enum->term);
		$bits->set($termdocs->doc) while $termdocs->next;
		last unless $enum->next;
	}
	return $bits;
}

1;
