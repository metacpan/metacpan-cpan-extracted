package Plucene::Index::SegmentTermPositions;

# final class SegmentTermPositions
#   extends SegmentTermDocs implements TermPositions

=head1 NAME 

Plucene::Index::SegmentTermPositions - Segment term positions

=head1 SYNOPSIS

	# isa Plucene::Index::SegmentTermDocs

	$seg_term_pos->skipping_doc;

	my $next = $seg_term_pos->next_position;

=head1 DESCRIPTION

This is the segment term positions class.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp;

use base 'Plucene::Index::SegmentTermDocs';

__PACKAGE__->mk_accessors(qw(_prox_stream _prox_count));

# private InputStream proxStream;
# private int proxCount;
# private int position;

=head2 new

	my $seg_term_pos = Plucene::Index::SegmentTermPositions
		->new(Plucene::Index::SegmentReader $seg_reader);
=cut

# SegmentTermPositions(SegmentReader p) throws IOException {
#   super(p);
#   this.proxStream = (InputStream)parent.proxStream.clone();
# }

sub new {
	my $self = shift->SUPER::new(@_);
	$self->{_prox_stream} = $self->parent->prox_stream;
	$self->{_prox_ptr}    = 0;
	$self->{_prox_count}  = 0;
	return $self;
}

# final void seek(TermInfo ti) throws IOException {
#   super.seek(ti);
#   if (ti != null)
#     proxStream.seek(ti.proxPointer);
#   else
#     proxCount = 0;
# }

sub _seek {
	my ($self, $ti) = @_;
	$self->SUPER::_seek($ti);
	if ($ti) {
		$self->{_prox_ptr} = $ti->prox_pointer;
	} else {
		$self->{_prox_count} = 0;
	}
}

=head2 close 

	$seg_term_pos->close;

=cut

# public final void close() throws IOException {
#	  super.close();
#   proxStream.close();
# }

=head2 next_position

	my $next = $seg_term_pos->next_position;

=cut

# public final int nextPosition() throws IOException {
#   proxCount--;
#   return position += proxStream.readVInt();
# }

sub next_position {
	my $self = shift;
	$self->{_prox_count}--;
	return $self->{position} += $self->{_prox_stream}->[ $self->{_prox_ptr}++ ];
}

=head2 skipping_doc

	$seg_term_pos->skipping_doc;

=cut

# protected final void skippingDoc() throws IOException {
#   for (int f = freq; f > 0; f--)      // skip all positions
#     proxStream.readVInt();
# }

sub skipping_doc {
	my $self = shift;
	$self->{_prox_ptr} += $self->freq;
}

# public final boolean next() throws IOException {
#   for (int f = proxCount; f > 0; f--)     // skip unread positions
#     proxStream.readVInt();
#
#   if (super.next()) {         // run super
#     proxCount = freq;         // note frequency
#     position = 0;         // reset position
#     return true;
#   }
#   return false;
# }

sub next {
	my $self = shift;
	$self->{_prox_ptr} += $self->{_prox_count};
	if ($self->SUPER::next()) {
		$self->{_prox_count} = $self->freq;
		$self->{position}    = 0;
		return 1;
	}
	return;
}

=head2 read 

This should not be called

=cut

# public final int read(final int[] docs, final int[] freqs)
#   throws IOException {
#  throw new RuntimeException();
# }

sub read { croak "'read' should not be called" }

1;
