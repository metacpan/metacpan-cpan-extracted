package Plucene::Index::SegmentReader;

=head1 NAME 

Plucene::Index::SegmentReader - the Segment reader

=head1 SYNOPSIS

	my $seg_reader = 
	  Plucene::Index::SegmentReader->new( Plucene::Index::SegmentInfo $si);

	my @files = $seg_reader->files;
	my @terms = $seg_reader->terms;
	my $doc = $seg_reader->document($id);
	my $doc_freq = $seg_reader->doc_freq($term);
	my $max_doc = $seg_reader->max_doc;
	my $norms = $seg_reader->norms($field, $offset);
	
	my Plucene::Index::SegmentTermDocs $docs 
		= $seg_reader->term_docs($term);
	
	my Plucene::Index::SegmentTermPositions $pos 
		= $seg_reader->term_positions($term);
		
	my Plucene::Store::InputStream $stream 
		= $seg_reader->norm_stream($field);
		
	if ($seg_reader->is_deleted($id)) {  .. }
	if ($seg_reader->has_deletions(Plucene::Index::SegmentInfo $si)) 
		{  ... }
	
=head1 DESCRIPTION

The segment reader class.

=head1 METHODS

=cut

use strict;
use warnings;

use File::Slurp;
use Plucene::Bitvector;
use Plucene::Index::FieldInfos;
use Plucene::Index::FieldsReader;
use Plucene::Index::SegmentTermDocs;
use Plucene::Index::SegmentTermPositions;
use Plucene::Index::TermInfosReader;
use Plucene::Utils;
use Plucene::Store::InputStream;
use Plucene::Store::OutputStream;

use base qw(Plucene::Index::Reader Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
	qw(field_infos fields_reader deleted_docs freq_stream prox_stream directory)
);

=head2 new

	my $seg_reader = 
	  Plucene::Index::SegmentReader->new( Plucene::Index::SegmentInfo $si);

This will create a new Plucene::Index::SegmentReader object.

=cut

sub new {
	my ($class, $si) = @_;
	my $self = $class->SUPER::new($si->dir);
	my $segment = $self->{segment} = $si->name;
	$self->field_infos(
		Plucene::Index::FieldInfos->new($self->{directory}, "$segment.fnm"));
	$self->fields_reader(
		Plucene::Index::FieldsReader->new(
			$self->{directory}, $segment, $self->{field_infos}));

	$self->{tis} =
		Plucene::Index::TermInfosReader->new($self->{directory}, $segment,
		$self->{field_infos});

	if ($self->has_deletions($si)) {
		my $stream =
			Plucene::Store::InputStream->new("$self->{directory}/$segment.del");
		$self->deleted_docs(Plucene::Bitvector->read($stream));
	}

	$self->freq_stream(
		[ unpack "(w)*", read_file("$self->{directory}/$segment.frq") ]);
	$self->prox_stream(
		[ unpack "(w)*", read_file("$self->{directory}/$segment.prx") ]);
	$self->_open_norms;
	return $self;
}

sub _do_close {
	my $self = shift;
	if ($self->{deleted_docs_dirty}) {
		my $file = "$self->{directory}/$self->{segment}";
		do_locked {
			my $stream = Plucene::Store::OutputStream->new($file . ".tmp");
			$self->deleted_docs->write($stream);
			$stream->close;
			rename $file . ".tmp", $file . ".del";
			}
			"$self->{directory}/commit.lock";
		$self->{deleted_docs_dirty} = 0;
	}
}

=head2 has_deletions

	if ($seg_reader->has_deletions(Plucene::Index::SegmentInfo $si)) 
		{  ... }

=cut

sub has_deletions {
	-e ($_[1]->dir . "/" . $_[1]->name . ".del");
}

sub _do_delete {
	my ($self, $doc_num) = @_;
	$self->{deleted_docs} = Plucene::Bitvector->new(size => $self->max_doc)
		unless $self->deleted_docs;
	$self->deleted_docs->set($doc_num);
	$self->{deleted_docs_dirty} = 1;
}

=head2 files

	my @files = $seg_reader->files;

=cut

sub files {
	my $self    = shift;
	my $segment = $self->{segment};
	my @files   = map "$segment.$_", qw( fnm fdx fdt tii tis frq prx);
	push @files, "$segment.del" if -e "$self->{directory}/$segment.del";
	my @fi = $self->field_infos->fields;
	($fi[$_]->is_indexed && push @files, "$segment.f$_") for 0 .. $#fi;
	return @files;
}

=head2 terms

	my @terms = $seg_reader->terms;

=cut

sub terms { shift->{tis}->terms(@_) }

=head2 document

	my $doc = $seg_reader->document($id);

=cut

sub document {
	my ($self, $id) = @_;
	die "Attempt to access deleted document $id" if $self->is_deleted($id);
	return $self->{fields_reader}->doc($id);
}

=head2 is_deleted

	if ($seg_reader->is_deleted($id)) {  .. }

=cut

sub is_deleted {
	$_[0]->{deleted_docs} ? $_[0]->{deleted_docs}->get($_[1]) : 0;
}

=head2 term_docs

	my Plucene::Index::SegmentTermDocs $docs 
		= $seg_reader->term_docs($term);

This will return the Plucene::Index::SegmentTermDocs object for the
given term.

=cut

sub term_docs {
	my ($self, $term) = @_;
	my $docs = Plucene::Index::SegmentTermDocs->new($self);
	if ($term) { $docs->seek($term) }
	return $docs;
}

=head2 term_positions

	my Plucene::Index::SegmentTermPositions $pos 
		= $seg_reader->term_positions($term);

This will return the Plucene::Index::SegmentTermPositions object for the
given term.

=cut

sub term_positions {
	my ($self, $term) = @_;
	my $pos = Plucene::Index::SegmentTermPositions->new($self);
	$pos->seek($term) if $term;
	return $pos;

}

=head2 doc_freq

	my $doc_freq = $seg_reader->doc_freq($term);

This returns the number of documents containing the passed term.
	
=cut

sub doc_freq {
	my ($self, $term) = @_;
	my $ti = $self->{tis}->get($term) or return 0;
	return $ti->doc_freq;
}

=head2 num_docs

	my $num_docs = $seg_reader->num_docs;

This is the number of documents, excluding deleted ones.

=cut

sub num_docs {
	my $self = shift;
	my $num  = $self->max_doc;
	$num -= $self->deleted_docs->count if $self->deleted_docs;
	$num;
}

=head2 max_doc

	my $max_doc = $seg_reader->max_doc;

=cut

sub max_doc { $_[0]->fields_reader->size; }

=head2 norms

	my $norms = $seg_reader->norms($field, $offset);

This returns the byte-encoded normalisation factor for the passed
field. This is used by the search code to score documents.

Note we are not using the 'offset' and 'bytes' arguments per the Java.
Instead, callers should use substr to put the result of "norms" into 
the appropriate place in a string.

=cut

sub norms {
	my ($self, $field, $offset) = @_;
	my $norm = $self->{norms}->{$field} or return;
	return $norm->{bytes} ||= $self->_norm_read_from_stream($field);
}

sub _norm_read_from_stream {
	my ($self, $field) = @_;
	my $ns = $self->norm_stream($field) or return;
	$ns->read(my $output, $self->max_doc);
	return $output;
}

=head2 norm_stream

	my Plucene::Store::InputStream $stream 
		= $seg_reader->norm_stream($field);

This will return the Plucene::Store::InputStream for the passed field.
		
=cut

sub norm_stream {
	my ($self, $field) = @_;
	my $norm = $self->{norms}->{$field} or return;

	# Clone the norm's filehandle
	my $clon = $norm->{in}->clone;
	$clon->seek(0, 0);
	return $clon;
}

sub _open_norms {
	my $self = shift;
	for my $fi (grep $_->is_indexed, $self->field_infos->fields) {
		my $file = "$self->{directory}/$self->{segment}.f" . $fi->number;
		my $fh = Plucene::Store::InputStream->new($file) or die $file . " :" . $!;
		$self->{norms}{ $fi->name } = Plucene::Index::Norm->new($fh);
	}
}

package Plucene::Index::Norm;

sub new { bless { in => $_[1] }, $_[0] }

# They have bytes, too, but we're not worrying about that.

1;
