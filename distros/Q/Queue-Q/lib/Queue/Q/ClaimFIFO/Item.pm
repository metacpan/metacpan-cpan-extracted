package Queue::Q::ClaimFIFO::Item;
use strict;
use warnings;
use Sereal::Decoder;
use Sereal::Encoder;
use Digest::MD5 (); # much faster than sha1 and good enough

use Class::XSAccessor {
    constructor => 'new',
    getters => [qw(item_data)],
};

BEGIN { *data = \&item_data; }

our $SerealEncoder = Sereal::Encoder->new;
our $SerealDecoder = Sereal::Decoder->new;
our $MD5 = Digest::MD5->new;

# for "friends" only
sub _key {
    my $self = shift;
    return $self->{_key}
        if defined $self->{_key};
    $MD5->add($self->_serialized_data);
    $MD5->add(rand(), time());
    return( $self->{_key} = $MD5->digest );
}

# for "friends" only
sub _serialized_data {
    my $self = shift;
    return $self->{_serialized_data}
        if defined $self->{_serialized_data};
    return( $self->{_serialized_data} = $self->_serialize_data($self->data) );
}

# for "friends" only
sub _serialize_data {
    my $self = shift;
    return $SerealEncoder->encode($_[0]);
}

# for "friends" only
sub _deserialize_data {
    my $self = shift;
    return undef if not defined $_[0];
    return $SerealDecoder->decode($_[0]);
}

1;
__END__

=head1 NAME

Queue::Q::ClaimFIFO::Item - An item in a 'ClaimFIFO' queue

=head1 SYNOPSIS

  use Queue::Q::ClaimFIFO::Redis; # or ::Perl or ...
  my $q = ... create object of chosen ClaimFIFO implementation...
  
  # consumer:
  my $item = $q->claim_item; # this is a Queue::Q::ClaimFIFO::Item!
  my $data = $item->data;
  # work with data...
  $q->mark_item_as_done($item);

=head1 DESCRIPTION

Instances of this class represent a single item in a C<ClaimFIFO>
type queue (or C<DistFIFO> if that is based on C<ClaimFIFO> shards).

Typically, you do not have to create C<Queue::Q::ClaimFIFO::Item> objects
manually. They are implicitly created by the queue when you enqueue
a new data structure.

=head1 METHODS

=head2 new

Takes named parameters. Requires an C<data> parameter that
is the item's content.

If the queue backend implementation requires serialization (which
is bound to be the general case), the data must be a data structure that
can be serialized in the C<Sereal> format using L<Sereal::Encoder>.

=head2 data

Returns the item's content.

=head2 item_data

Alias for C<data>. DEPRECATED.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

