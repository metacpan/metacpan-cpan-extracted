package Plucene::Index::SegmentsReader;

=head1 NAME 

Plucene::Index::SegmentsReader - reads the segments

=head1 SYNOPSIS

	my $segs_reader = Plucene::Index::SegmentsReader
		->new($dir, Plucene::Index::SegmentReader @readers);

	my $num_docs = $segs_reader->num_docs;
	my $doc = $segs_reader->document($id);
	my $norms = $seg_reader->norms($field);
	my $doc_freq = $segs_reader->doc_freq($term);

	my Plucene::Index::SegmentsTermEnum $term_enum 
		= $segs_reader->terms($term);
	my Plucene::Index::SegmentsTermDocs $term_docs 
		= $segs_reader->term_docs;
	my Plucene::Index::SegmentsTermPositions $term_positions 
		= $segs_reader->term_positions;
	
	if ($segs_reader->is_deleted($id)) { ... }

=head1 DESCRIPTION

This is the segments reader class.

=head1 METHODS

=cut

use strict;
use warnings;

use List::Util qw(sum);
use Plucene::Index::SegmentsTermEnum;

use base qw(Plucene::Index::Reader Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(max_doc));

use Memoize;
memoize("norms");    # Saves messing with normsCache

=head2 new

	my $segs_reader = Plucene::Index::SegmentsReader
		->new($dir, Plucene::Index::SegmentReader @readers);

This will create a new Plucene::Index::SegmentsReader object with the passed
directory and Plucene::Index::SegmentReader objects.

=cut

sub new {
	my ($class, $dir, @readers) = @_;
	my $self = $class->SUPER::new($dir);
	$self->{readers} = \@readers;
	$self->{max_doc} = 0;
	for my $reader (@readers) {
		push @{ $self->{starts} }, $self->{max_doc};
		$self->{max_doc} += $reader->max_doc;
	}

	return $self;
}

=head2 num_docs

	my $num_docs = $segs_reader->num_docs;

This will return the number of documents in all the segments in the Reader.

=cut

sub num_docs {
	my $self = shift;
	return $self->{num_docs} if exists $self->{num_docs};
	return $self->{num_docs} = sum(map $_->num_docs, @{ $self->{readers} });
}

=head2 document

	my $doc = $segs_reader->document($id);

This will return the document at the passed document id.

=cut

sub document {
	my ($self, $n) = @_;
	my $i = $self->_reader_index($n);
	return $self->{readers}[$i]->document($n - $self->{starts}[$i]);
}

=head2 is_deleted

	if ($segs_reader->is_deleted($id)) { ... }

=cut

sub is_deleted {
	my ($self, $n) = @_;
	my $i = $self->_reader_index($n);
	return $self->{readers}[$i]->is_deleted($n - $self->{starts}[$i]);
}

sub _do_delete {
	my ($self, $n) = @_;
	delete $self->{num_docs};    # Invalidate cache
	my $i = $self->_reader_index($n);
	return $self->{readers}[$i]->_do_delete($n - $self->{starts}[$i]);
}

sub _do_close {
	my $self = shift;
	$_->close for @{ $self->{readers} };
}

sub _reader_index {
	my ($self, $n)  = @_;
	my ($lo,   $hi) = (0, $#{ $self->{readers} });

	# Binary search
	while ($hi >= $lo) {
		my $mid     = int(($lo + $hi) / 2);
		my $mid_val = $self->{starts}[$mid];
		if    ($n < $mid_val) { $hi = $mid - 1; }
		elsif ($n > $mid_val) { $lo = $mid + 1; }
		else { return $mid; }
	}
	return $hi;
}

=head2 norms

	my $norms = $seg_reader->norms($field);

This returns the norms for the passed field.

=cut

sub norms {
	my ($self, $field) = @_;
	my $bytes = "\0" x $self->max_doc;
	for my $i (0 .. $#{ $self->{readers} }) {
		my $norm = $self->{readers}[$i]->norms($field);
		substr($bytes, $self->{starts}[$i], length $norm) = $norm;
	}
	return $bytes;
}

=head2 terms

	my Plucene::Index::SegmentsTermEnum $term_enum 
		= $segs_reader->terms($term);

This will return the Plucene::Index::SegmentsTermEnum onject for the
passed in term.
		
=cut

sub terms {
	my ($self, $term) = @_;
	return Plucene::Index::SegmentsTermEnum->new($self->{readers},
		$self->{starts}, $term);
}

=head2 doc_freq

	my $doc_freq = $segs_reader->doc_freq($term);

This returns the number of documents containing the passed term.

=cut

sub doc_freq {
	my ($self, $term) = @_;
	return sum map $_->doc_freq($term), @{ $self->{readers} };
}

=head2 term_docs

	my Plucene::Index::SegmentsTermDocs $term_docs 
		= $segs_reader->term_docs;

This will return the Plucene::Index::SegmentsTermDocs object.
		
=cut

sub term_docs {
	my $self = shift;
	my $term = shift;
	my $docs =
		Plucene::Index::SegmentsTermDocs->new($self->{readers}, $self->{starts});
	if ($term) { $docs->seek($term) }
	return $docs;

}

=head2 term_positions

	my Plucene::Index::SegmentsTermPositions $term_positions 
		= $segs_reader->term_positions;

This will return the Plucene::Index::SegmentsTermPositions object.

=cut

sub term_positions {
	my $self = shift;
	my $term = shift;
	my $pos  =
		Plucene::Index::SegmentsTermPositions->new($self->{readers},
		$self->{starts});
	if ($term) { $pos->seek($term) }
	return $pos;
}

package Plucene::Index::SegmentsTermDocs;

sub new {
	my ($class, $readers, $starts) = @_;
	bless {
		readers       => $readers,
		starts        => $starts,
		seg_term_docs => [],
		base          => 0,
		pointer       => 0,
		current       => undef,
	}, $class;
}

sub doc {
	my $self = shift;
	return $self->{base} + $self->{current}->doc;
}

sub freq { return shift->{current}->freq; }

sub seek {
	my ($self, $term) = @_;
	$self->{term}    = $term;
	$self->{base}    = 0;
	$self->{pointer} = 0;
	$self->{current} = undef;
}

sub _at_end { $_[0]->{pointer} >= @{ $_[0]->{readers} } }

sub _set_base_and_advance {
	my $self = shift;
	$self->{base}    = $self->{starts}[ $self->{pointer} ];
	$self->{current} = $self->term_docs($self->{pointer}++);
}

sub next {
	my $self = shift;
	return 1 if $self->{current} && $self->{current}->next;
	unless ($self->_at_end) {
		$self->_set_base_and_advance;
		return $self->next;
	}
	return 0;
}

sub read {
	my ($self) = @_;
	my ($docs, $freqs) = ([], []);
	while (1) {

		# Get a .current, somehow
		while (!$self->{current}) {
			goto done if $self->_at_end;    # Don't fall off
			$self->_set_base_and_advance;
		}

		my ($new_docs, $new_freqs) = $self->{current}->read($docs, $freqs);
		if (!scalar @$new_docs) {

			# It's empty
			undef $self->{current};
		} else {

			# Correct the doc positions to the appropriate base
			$_ += $self->{base} for @$new_docs;
			push @$docs,  @$new_docs;
			push @$freqs, @$new_freqs;
			goto done;
		}
	}

	done: return ($docs, $freqs);
}

sub skip_to {
	my ($self, $target) = @_;
	$self->next || return while $target > $self->doc;
	return 1;
}

sub term_docs {
	my ($self, $i) = @_;
	return unless $self->{term};
	$self->{seg_term_docs}[$i] = $self->term_docs_r($self->{readers}[$i])
		unless exists $self->{seg_term_docs}[$i];
	my $result = $self->{seg_term_docs}[$i];
	$result->seek($self->{term});
	return $result;
}

sub term_docs_r {
	my ($self, $reader) = @_;
	return $reader->term_docs;
}

package Plucene::Index::SegmentsTermPositions;
use base 'Plucene::Index::SegmentsTermDocs';

sub term_docs_r {
	my ($self, $reader) = @_;
	return $reader->term_positions;
}

sub next_position {
	return shift->{current}->next_position;
}

1;
