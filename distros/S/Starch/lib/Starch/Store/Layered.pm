package Starch::Store::Layered;

$Starch::Store::Layered::VERSION = '0.10';

=head1 NAME

Starch::Store::Layered - Layer multiple Starch stores.

=head1 SYNOPSIS

    my $starch = Starch->new(
        expires => 2 * 60 * 60, # 2 hours
        store => {
            class => '::Layered',
            outer => {
                class=>'::CHI',
                max_expires => 10 * 60, # 10 minutes
                ...,
            },
            inner => {
                class=>'::MongoDB',
                ...,
            },
        },
    );

=head1 DESCRIPTION

This store provides the ability to declare two stores that act
in a layered fashion where all writes (C<set> and C<remove>) are
applied to both stores but all reads (C<get>) are attempted, first,
on the L</outer> store, and if that fails the read is attempted in
the L</inner> store.

When C<get> is called, if the outer store did not have the data,
but the inner store did, then the data will be automatically
written to the outer store.

The most common use-case for this store is for placing a cache in
front of a persistent store.  Typically caches are much faster than
persistent storage engines.

Another use case is for migrating from one store to another.  Your
new store would be set as the inner store, and your old store
would be set as the outer store.  Once sufficient time has passed,
and the new store has been populated, you could switch to using
just the new store.

If you'd like to layer more than two stores you can use layered
stores within layered stores.

=cut

use Types::Standard -types;
use Scalar::Util qw( blessed );

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Store
);

after BUILD => sub{
    my ($self) = @_;

    # Load these up as early as possible.
    $self->outer();
    $self->inner();

    return;
};

=head1 REQUIRED ARGUMENTS

=head2 outer

This is the outer store, the one that tries to handle read requests
first before falling back to the L</inner> store.

Accepts the same value as L<Starch::Manager/store>.

=cut

has _outer_arg => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    init_arg => 'outer',
);

has outer => (
    is       => 'lazy',
    isa      => ConsumerOf[ 'Starch::Store' ],
    init_arg => undef,
);
sub _build_outer {
    my ($self) = @_;
    my $store = $self->_outer_arg();
    return $self->new_sub_store( %$store );
}

=head2 inner

This is the inner store, the one that only handles read requests
if the L</outer> store was unable to.

Accepts the same value as L<Starch::Manager/store>.

=cut

has _inner_arg => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    init_arg => 'inner',
);

has inner => (
    is       => 'lazy',
    isa      => ConsumerOf[ 'Starch::Store' ],
    init_arg => undef,
);
sub _build_inner {
    my ($self) = @_;
    my $store = $self->_inner_arg();
    return $self->new_sub_store( %$store );
}

=head1 ATTRIBUTES

=head2 can_reap_expired

Return true if either the L</inner> or L</outer> stores support the
L<Starch::Store/reap_expired> method.

=cut

sub can_reap_expired {
    my ($self) = @_;
    return 1 if $self->outer->can_reap_expired();
    return 1 if $self->inner->can_reap_expired();
    return 0;
}

=head1 METHODS

=head2 reap_expired

Calls L<Starch::Store/reap_expired> on the L</outer> and L</inner>
stores, if they support expired state reaping.

=cut

around reap_expired => sub{
    my ($orig, $self) = @_;

    # Go ahead and throw the exception provided by Starch::Store::reap_expired.
    return $self->$orig() if !$self->can_reap_expired();

    $self->outer->reap_expired() if $self->outer->can_reap_expired();
    $self->inner->reap_expired() if $self->inner->can_reap_expired();

    return;
};

=head2 set

Set L<Starch::Store/set>.

=head2 get

Set L<Starch::Store/get>.

=head2 remove

Set L<Starch::Store/remove>.

=cut

sub set {
    my $self = shift;
    $self->outer->set( @_ );
    $self->inner->set( @_ );
    return;
}

sub get {
    my ($self, $key, $namespace) = @_;

    my $data = $self->outer->get( $key, $namespace );
    return $data if $data;

    $data = $self->inner->get( $key, $namespace );
    return undef if !$data;

    # Now we got the data from the inner store but not the outer store.
    # Let's set it on the outer store so that we can retrieve it from
    # there next time.

    my $expires = $data->{ $self->manager->expires_state_key() };
    $expires = $self->manager->expires() if !defined $expires;

    # Make sure we take into account max_expires.
    $expires = $self->calculate_expires( $expires );

    $self->outer->set( $key, $namespace, $data, $expires );

    return $data;
}

sub remove {
    my $self = shift;
    $self->outer->remove( @_ );
    $self->inner->remove( @_ );
    return;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

