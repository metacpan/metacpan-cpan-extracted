package Starch::Store::Memory;
our $VERSION = '0.14';

=encoding utf8

=head1 NAME

Starch::Store::Memory - In-memory Starch store.

=head1 DESCRIPTION

This store provides an in-memory store using a hash ref to store the
data.  This store is mostly here as a proof of concept and for writing
tests against.

=cut

use Types::Common::Numeric -types;
use Types::Standard -types;

use Moo;
use strictures 2;
use namespace::clean;

with 'Starch::Store';

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

=head1 SUPPORT

See L<Starch/SUPPORT>.

=head1 AUTHORS

See L<Starch/AUTHORS>.

=head1 COPYRIGHT AND LICENSE

See L<Starch/COPYRIGHT AND LICENSE>.

=cut

