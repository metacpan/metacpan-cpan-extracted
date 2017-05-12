package Queue::Leaky::State::Memory;

use Moose;

with 'Queue::Leaky::State';

has 'data' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);

no Moose;

sub get { shift->data->{$_[0]} || 0 }
sub set { shift->data->{$_[0]} = $_[1] }
sub remove { delete shift->data->{$_[0]} }

sub incr { ++shift->data->{$_[0]} }
sub decr { --shift->data->{$_[0]} }

1;

__END__

=head1 NAME

Queue::Leaky::State::Memory - Keeps State In Memory

=head1 METHODS

=head2 get

=head2 set 

=head2 remove

=head2 incr

=head2 decr

=cut
