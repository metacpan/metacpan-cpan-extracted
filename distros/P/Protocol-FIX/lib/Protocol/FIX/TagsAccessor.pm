package Protocol::FIX::TagsAccessor;

use strict;
use warnings;

our $VERSION = '0.05';    ## VERSION

=head1 NAME

Protocol::FIX::TagsAccessor - access to tags of deserialized FIX messages

=cut

=head1 METHODS

=head3 new

    new($class, $tag_pairs)

Creates new TagsAccessor (performed by Parser). Not for direct usage
by end-users.

=cut

sub new {
    my ($class, $tag_pairs) = @_;
    my %by_name;
    my $count = 0;
    for (my $idx = 0; $idx < @$tag_pairs; $idx += 2) {
        my $composite = $tag_pairs->[$idx];
        # value is either value (i.e. string) or another TagAccessor
        my $value = $tag_pairs->[$idx + 1];
        $by_name{$composite->{name}} = $value;
        ++$count;
    }
    $by_name{_count} = $count;
    return bless \%by_name, $class;
}

=head3 value

    value($self, $name)

Returns value. Please, refer to L<MessageInstance/value>

=cut

sub value {
    my ($self, $name) = @_;
    return $self->{$name};
}

=head3 count

    count($self)

Returns the count for the repetitive tag pairs

=cut

sub count {
    my $self = shift;
    return $self->{_count};
}

1;
