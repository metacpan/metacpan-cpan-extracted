package Plucene::Index::SegmentTermDocs;

=head1 NAME 

Plucene::Index::SegmentTermDocs - Segment term docs

=head1 SYNOPSIS

	my $seg_term_docs = Plucene::Index::SegmentTermDocs
		->new(Plucene::Index::SegmentReader $seg_reader);
	
	$seg_term_docs->seek($term);
	$seg_term_docs->next;
	$seg_term_docs->read;
	$seg_term_docs->skip_to($target);
	
=head1 DESCRIPTION

This is the segment term docs class.

=head1 METHODS

=cut

use strict;
use warnings;

use IO::Handle;
use Carp qw/confess/;

use Plucene::Bitvector;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(
	qw(parent freq_stream freq_count deleted_docs doc freq));

=head2 new

	my $seg_term_docs = Plucene::Index::SegmentTermDocs
		->new(Plucene::Index::SegmentReader $seg_reader);

This will create a new Plucene::Index::SegmentTermDocs object with the passed
segment reader.
	
=head2 parent / freq_stream / freq_count / deleted_docs / doc / freq

Get / set these attributes.
	
=cut

sub new {
	my $self       = shift;
	my $seg_reader = shift;
	return bless {
		parent       => $seg_reader,
		freq_stream  => $seg_reader->freq_stream,    # listref
		deleted_docs => $seg_reader->deleted_docs,
		doc          => 0,
	} => $self;
}

=head2 seek

	$seg_term_docs->seek($term);

=cut

sub seek {
	my ($self, $ti) = @_;

	# I object to this, but hey.
	if ($ti->isa("Plucene::Index::Term")) {
		$self->_seek($self->parent->{tis}->get($ti));
	} else {
		$self->_seek($ti);
	}
}

sub _seek {
	my ($self, $ti) = @_;
	if (!$ti) {
		$self->freq_count(0);
		return;
	}
	$self->freq_count($ti->doc_freq);
	$self->doc(0);
	$self->{ptr} = $ti->freq_pointer;    # offset in our array
}

=head2 skipping_doc

By default this does nothing. You may wish to override it to do something.

=cut

sub skipping_doc { }

sub _read_one {
	my $self     = shift;
	my $doc_code = $self->freq_stream->[ $self->{ptr}++ ];

	# A sequence that smacks of overoptimization
	$self->{doc} += $doc_code >> 1;
	if ($doc_code & 1) {
		$self->freq(1);
	} else {
		$self->freq($self->freq_stream->[ $self->{ptr}++ ]);
	}
	$self->{freq_count}--;
}

=head2 next

	$seg_term_docs->next;

=cut

sub next {
	my $self = shift;
	while (1) {
		return if $self->freq_count == 0;
		$self->_read_one();
		last
			unless $self->{deleted_docs}
			&& $self->{deleted_docs}->get($self->{doc});
		$self->skipping_doc;
	}
	return 1;
}

=head2 read

	$seg_term_docs->read;

=cut

# Called by TermScorer and SegmentsTermDocs
sub read {
	my $self = shift;
	my (@docs, @freqs);
	while ($self->{freq_count} > 0) {
		$self->_read_one;
		next
			if $self->{deleted_docs}
			&& $self->{deleted_docs}->get($self->{doc});
		push @docs,  $self->doc;
		push @freqs, $self->freq;
	}
	return (\@docs, \@freqs);
}

=head2 skip_to

	$seg_term_docs->skip_to($target);

=cut

sub skip_to {
	my ($self, $target) = @_;
	$self->next || return 0 while $target > $self->doc;
	return 1;
}

1;
