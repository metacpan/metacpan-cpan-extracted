package Starch::Store::Memory;

$Starch::Store::Memory::VERSION = '0.10';

=head1 NAME

Starch::Store::Memory - In-memory Starch store.

=head1 DESCRIPTION

This store provides an in-memory store using a hash ref to store the
data.  This store is mostly here as a proof of concept and for writing
tests against.

=cut

use Types::Standard -types;
use Types::Common::Numeric -types;

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Store
);

=head1 OPTIONAL ARGUMENTS

=head2 global

Set this to a true value to use a shared memory store for all instances
of this class that enable this argument.

=cut

my $global_memory = {};

has global => (
    is  => 'ro',
    isa => Bool,
);

=head2 memory

This is the hash ref which is used for storing states.
Defaults to a global hash ref if L</global> is set, or
a new hash ref if not.

=cut

has memory => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_memory {
    my ($self) = @_;
    return $global_memory if $self->global();
    return {};
}

=head1 METHODS

=head2 set

Set L<Starch::Store/set>.

=head2 get

Set L<Starch::Store/get>.

=head2 remove

Set L<Starch::Store/remove>.

=cut

sub set {
    my ($self, $id, $namespace, $data) = @_;

    $self->memory->{
        $self->stringify_key( $id, $namespace )
    } = $data;

    return;
}

sub get {
    my ($self, $id, $namespace) = @_;
    return $self->memory->{
        $self->stringify_key( $id, $namespace )
    };
}

sub remove {
    my ($self, $id, $namespace) = @_;
    delete( $self->memory->{
        $self->stringify_key( $id, $namespace )
    } );
    return;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

