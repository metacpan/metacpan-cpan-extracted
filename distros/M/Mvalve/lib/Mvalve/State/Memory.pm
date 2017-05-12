# $Id$

package Mvalve::State::Memory;
use Moose;
use Digest::SHA1;
use Data::Dumper();

with 'Mvalve::State';

has 'data' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);

around qw(get set remove incr decr) => sub {
    my ($next, $self, $key, @args) = @_;

    if (ref $key) {
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Sortkeys = 1;
        $key = Digest::SHA1::sha1_hex(Data::Dumper::Dumper($key));
    }

    $next->($self, $key, @args);
};

no Moose;

sub get {
    my $self = shift;
    $self->data->{$_[0]}
}

sub set {
    my $self = shift;
    $self->data->{$_[0]} = $_[1];
}

sub remove {
    my $self = shift;
    delete $self->data->{$_[0]}
}

sub incr {
    my $self = shift;
    $self->data->{$_[0]}++
}

sub decr { 
    my $self = shift;
    $self->data->{$_[0]}--
}

1;

__END__

=head1 NAME

Mvalve::State::Memory - Keeps Mvalve State In Memory (For Debug)

=head1 METHODS

=head2 get

=head2 set 

=head2 remove

=head2 incr

=head2 decr

=cut