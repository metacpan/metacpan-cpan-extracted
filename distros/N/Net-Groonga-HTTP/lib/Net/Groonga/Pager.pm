package Net::Groonga::Pager;
use strict;
use warnings;
use utf8;

use Mouse;

has offset => (is => 'ro', isa => 'Int', required => 1);
has limit  => (is => 'ro', isa => 'Int', required => 1);
has total_entries => (is => 'ro', isa => 'Int', required => 1);

no Mouse;

sub has_next {
    my ($self) = @_;
    return $self->limit + $self->offset < $self->total_entries;
}

1;
__END__

=head1 NAME

Net::Groonga::Pager - Pager object for Net::Groonga::HTTP

=head1 METHODS

=over 4

=item $pager->offset() :Int

Offset clause for searching.

=item $pager->limit() :Int

Limit clause for searching.

=item $pager->total_entries() :Int

The number of total entries for searching result.

=item $pager->has_next() :Int

Return true if next page is available.

=back

=head1 AUTHOR

Tokuhiro Matsuno

