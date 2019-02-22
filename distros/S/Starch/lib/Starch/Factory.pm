package Starch::Factory;
use 5.008001;
use strictures 2;
our $VERSION = '0.11';

=head1 NAME

Starch::Factory - Role applicator and class creator.

=head1 DESCRIPTION

This class consumes the L<Starch::Plugin::Bundle> role and
is used by L<Starch> to apply specified plugins to manager,
state, and store classes.

Normally there is no need to interact with this class directly.

=cut

use Moo::Role qw();
use Types::Standard -types;
use Types::Common::String -types;
use Moo::Object qw();
use Starch::Util qw( load_prefixed_module croak );
use Module::Runtime qw( require_module );

use Starch::Manager;
use Starch::State;

use Moo;
use namespace::clean;

with qw(
    Starch::Plugin::Bundle
);

=head1 OPTIONAL ARGUMENTS

=head2 plugins

This is the L<Starch::Plugin::Bundle/plugins> attribute, but altered
to be an argument.

=cut

has '+plugins' => (
    init_arg => 'plugins',
);
sub bundled_plugins {
    return [];
}

=head2 base_manager_class

The base class of the Starch manager object.  Default to C<Starch::Manager>.

=cut

has base_manager_class => (
    is      => 'lazy',
    isa     => NonEmptySimpleStr,
    default => 'Starch::Manager',
);

=head2 base_state_class

The base class of Starch state objects.  Default to C<Starch::State>.

=cut

has base_state_class => (
    is      => 'lazy',
    isa     => NonEmptySimpleStr,
    default => 'Starch::State',
);

=head1 ATTRIBUTES

=head2 manager_class

The anonymous class which extends L</base_manager_class> and has
L</manager_roles> applied to it.

=cut

has manager_class => (
    is       => 'lazy',
    isa      => ClassName,
    init_arg => undef,
);
sub _build_manager_class {
    my ($self) = @_;

    my $roles = $self->manager_roles();
    my $class = $self->base_manager_class();
    require_module( $class );

    return $class if !@$roles;

    return Moo::Role->create_class_with_roles( $class, @$roles );
}

=head2 state_class

The anonymous class which extends L</base_state_class> and has
L</state_roles> applied to it.

=cut

has state_class => (
    is       => 'lazy',
    isa      => ClassName,
    init_arg => undef,
);
sub _build_state_class {
    my ($self) = @_;

    my $roles = $self->state_roles();
    my $class = $self->base_state_class();
    require_module( $class );

    return $class if !@$roles;

    return Moo::Role->create_class_with_roles( $class, @$roles );
}

=head1 METHODS

=head2 base_store_class

    my $class = $factory->base_store_class( '::Memory' );
    # Starch::Store::Memory
    
    my $class = $factory->base_store_class( 'Starch::Store::Memory' );
    # Starch::Store::Memory

Given an absolute or relative store class name this will
return the resolved class name.

=cut

sub base_store_class {
    my ($self, $suffix) = @_;

    return load_prefixed_module(
        'Starch::Store',
        $suffix,
    );
}

=head2 store_class

    my $class = $factory->store_class( '::Memory' );

Given an absolute or relative store class name this will
return an anonymous class which extends the store class
and has L</store_roles> applied to it.

=cut

sub store_class {
    my ($self, $suffix) = @_;

    my $roles = $self->store_roles();
    my $class = $self->base_store_class( $suffix );

    return $class if !@$roles;

    return Moo::Role->create_class_with_roles( $class, @$roles );
}

=head2 new_store

    my $store = $factory->new_store( class=>'::Memory', %args );

Creates and returns a new L</store_class> object with the
factory argument set.

Note that since the L<Starch::Store/expires> argument is
required you must specify it.

=cut

sub new_store {
    my $self = shift;

    my $args = Moo::Object->BUILDARGS( @_ );
    $args = { %$args };
    my $suffix = delete $args->{class};
    croak "No class key was declared in the Starch store hash ref"
        if !defined $suffix;

    my $class = $self->store_class( $suffix );
    return $class->new(
        %$args,
    );
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

