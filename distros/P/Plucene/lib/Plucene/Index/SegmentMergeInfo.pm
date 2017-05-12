package Plucene::Index::SegmentMergeInfo;

# final class SegmentMergeInfo

=head1 NAME 

Plucene::Index::SegmentMergeInfo - Segment Merge information

=head1 SYNOPSIS

	my $seg_merge_info 
		= Plucene::Index::SegmentMergeInfo->new($b, $te, $r); 

	$seg_merge_info->next;

=head1 DESCRIPTION

This is the Plucene::Index::SegmentMergeInfo class.

=head1 METHODS

=cut

use strict;
use warnings;

use Plucene::Index::SegmentTermPositions;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw( base reader term_enum term postings doc_map));

use overload cmp => sub {
	$_[0]->{term} cmp $_[1]->{term}
		|| $_[0]->{base} <=> $_[1]->{base};
	},
	fallback => 1;

=head2 new

	my $seg_merge_info = Plucene::Index::SegmentMergeInfo
		->new($base, Plucene::Index::TermEnum $te, $reader); 

This will create a new Plucene::Index::SegmentMergerInfo object.
		
=head2 base / reader / term_enum / term / postings / doc_map

Get / set these attributes.
		
=cut

# SegmentMergeInfo(int b, SegmentTermEnum te, SegmentReader r)
#   throws IOException {
#   base = b;
#   reader = r;
#   termEnum = te;
#   term = te.term();
#   postings = new SegmentTermPositions(r);
#
#   if (reader.deletedDocs != null) {
#     // build array which maps document numbers around deletions
#     BitVector deletedDocs = reader.deletedDocs;
#     int maxDoc = reader.maxDoc();
#     docMap = new int[maxDoc];
#     int j = 0;
#     for (int i = 0; i < maxDoc; i++) {
#       if (deletedDocs.get(i))
#         docMap[i] = -1;
#       else
#         docMap[i] = j++;
#     }
#   }
# }

sub new {
	my ($class, $b, $te, $r) = @_;
	my $self = $class->SUPER::new({
			base      => $b,
			reader    => $r,
			term_enum => $te,
			term      => $te->term,
			postings  => Plucene::Index::SegmentTermPositions->new($r),
		});

	if (my $del = $r->deleted_docs) {
		my $j;
		$self->{doc_map} = [ map $del->get($_) ? -1 : $j++, 0 .. $r->max_doc ];
	}
	return $self;
}

=head2 next

	$seg_merge_info->next;

=cut

# final boolean next() throws IOException {
#   if (termEnum.next()) {
#     term = termEnum.term();
#     return true;
#   } else {
#     term = null;
#     return false;
#   }
# }

sub next {
	my $self = shift;
	if ($self->{term_enum}->next) {
		$self->{term} = $self->{term_enum}->term;
		return 1;
	} else {
		undef $self->{term};
		return;
	}
}

=head2 close

	$seg_merge_info->close;

=cut

# final void close() throws IOException {
#   termEnum.close();
#   postings.close();
# }

sub close {
	my $self = shift;
	$self->term_enum->close;
	$self->postings->close;
}

1;
