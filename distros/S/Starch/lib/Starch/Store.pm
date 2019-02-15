package Starch::Store;

$Starch::Store::VERSION = '0.10';

=head1 NAME

Starch::Store - Base role for Starch stores.

=head1 DESCRIPTION

This role defines an interfaces for Starch store classes.  Starch store
classes are meant to be thin wrappers around the store implementations
(such as DBI, CHI, etc).

See L<Starch/STORES> for instructions on using stores and a list of
available Starch stores.

See L<Starch::Extending/STORES> for instructions on writing your own stores.

This role adds support for method proxies to consuming classes as
described in L<Starch/METHOD PROXIES>.

=cut

use Types::Standard -types;
use Types::Common::Numeric -types;
use Types::Common::String -types;
use Starch::Util qw( croak );

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Role::Log
    MooX::MethodProxyArgs
);

requires qw(
    set
    get
    remove
);

# Declare BUILD so roles can apply method modifiers to it.
sub BUILD { }

around set => sub{
    my ($orig, $self, $id, $keys, $data, $expires) = @_;

    # Short-circuit set operations if the data should not be stoed.
    return if $data->{ $self->manager->no_store_state_key() };

    $expires = $self->calculate_expires( $expires );

    return $self->$orig( $id, $keys, $data, $expires );
};

=head1 REQUIRED ARGUMENTS

=head2 manager

The L<Starch::Manager> object which is used by stores to
access configuration and create sub-stores (such as the Layered
store's outer and inner stores).  This is automatically set when
the stores are built by L<Starch::Factory>.

=cut

has manager => (
    is       => 'ro',
    isa      => InstanceOf[ 'Starch::Manager' ],
    required => 1,
    weak_ref => 1,
    handles  => ['factory'],
);

=head1 OPTIONAL ARGUMENTS

=head2 max_expires

Set the per-store maximum expires which will override the state's expires
if the state's expires is larger.

=cut

has max_expires => (
    is  => 'ro',
    isa => (PositiveOrZeroInt) | Undef,
);

=head2 key_separator

Used by L</stringify_key> to combine the state namespace
and ID.  Defaults to C<:>.

=cut

has key_separator => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => ':',
);

=head1 ATTRIBUTES

=head2 can_reap_expired

Return true if the stores supports the L</reap_expired> method.

=cut

sub can_reap_expired { 0 }

=head2 short_store_class_name

Returns L<Starch::Role::Log/short_class_name> with the
C<Store::> prefix remove.

=cut

sub short_store_class_name {
    my ($self) = @_;
    my $class = $self->short_class_name();
    $class =~ s{^Store::}{};
    return $class;
}

=head1 METHODS

=head2 new_sub_store

Builds a new store object.  Any arguments passed will be
combined with the L</sub_store_args>.

=cut

sub new_sub_store {
    my $self = shift;

    my $args = $self->sub_store_args( @_ );

    return $self->factory->new_store( $args );
}

=head2 sub_store_args

Returns the arguments needed to create a sub-store.  Any arguments
passed will be combined with the default arguments.  The default
arguments will be L</manager> and L</max_expires> (if set).  More
arguments may be present if any plugins extend this method.

=cut

sub sub_store_args {
    my $self = shift;

    my $args = $self->BUILDARGS( @_ );

    return {
        manager       => $self->manager(),
        max_expires   => $self->max_expires(),
        key_separator => $self->key_separator(),
        %$args,
    };
}

=head2 calculate_expires

Given an expires value this will calculate the expires that this store
should use considering what L</max_expires> is set to.

=cut

sub calculate_expires {
    my ($self, $expires) = @_;

    my $max_expires = $self->max_expires();
    return $expires if !defined $max_expires;

    return $max_expires if $expires > $max_expires;

    return $expires;
}

=head2 stringify_key

    my $store_key = $starch->stringify_key(
        $state_id,
        \@namespace,
    );

This method is used by stores that store and lookup data by
a string (all of them at this time).  It combines the state
ID with the L</namespace> of the key data for the store
request.

=cut

sub stringify_key {
    my ($self, $id, $namespace) = @_;
    return join(
        $self->key_separator(),
        @$namespace,
        $id,
    );
}

=head2 reap_expired

This triggers the store to find and delete all expired states.
This is meant to be used in an offline process, such as a cronjob,
as finding and deleting the states could take hours depending
on the amount of data and the storage engine's speed.

By default this method will throw an exception if the store does
not define its own reap method.  You can check if a store supports
this method by calling L</can_reap_expired>.

=cut

sub reap_expired {
    my ($self) = @_;

    croak sprintf(
        '%s does not support expired state reaping',
        $self->short_class_name(),
    );
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

