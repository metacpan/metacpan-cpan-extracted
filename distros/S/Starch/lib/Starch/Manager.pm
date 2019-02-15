package Starch::Manager;

$Starch::Manager::VERSION = '0.10';

=head1 NAME

Starch::Manager - Entry point for accessing Starch state objects.

=head1 SYNOPSIS

See L<Starch>.

=head1 DESCRIPTION

This module provides a generic interface to managing the storage of
state data.

Typically you will be using the L<Starch> module to create this
object.

This class supports method proxies as described in
L<Starch/METHOD PROXIES>.

=cut

use Starch::State;
use Starch::Util qw( croak );
use Storable qw( freeze dclone );
use Scalar::Util qw( refaddr );
use Digest::SHA qw( sha1_hex );

use Types::Standard -types;
use Types::Common::String -types;
use Types::Common::Numeric -types;

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Role::Log
    MooX::MethodProxyArgs
);

# Declare BUILD so roles can apply method modifiers to it.
sub BUILD {
    my ($self) = @_;

    # Get this built as early as possible.
    $self->store();

    return;
}

=head1 REQUIRED ARGUMENTS

=head2 store

The L<Starch::Store> storage backend to use for persisting the state
data.  A hashref must be passed and it is expected to contain at least a
C<class> key and will be converted into a store object automatically.

The C<class> can be fully qualified, or relative to the C<Starch::Store>
namespace.  A leading C<::> signifies that the store's package name is relative.

More information about stores can be found at L<Starch/STORES>.

=cut

has _store_arg => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    init_arg => 'store',
);

has store => (
    is       => 'lazy',
    isa      => ConsumerOf[ 'Starch::Store' ],
    init_arg => undef,
);
sub _build_store {
    my ($self) = @_;

    my $store = $self->_store_arg();

    return $self->factory->new_store(
        %$store,
        manager => $self,
    );
}

=head1 OPTIONAL ARGUMENTS

=head2 expires

How long, in seconds, a state should live after the last time it was
modified.  Defaults to C<60 * 60 * 2> (2 hours).

See L<Starch/EXPIRATION> for more information.

=cut

has expires => (
    is       => 'ro',
    isa      => PositiveOrZeroInt,
    default => 60 * 60 * 2, # 2 hours
);

=head2 plugins

Which plugins to apply to the Starch objects, specified as an array
ref of plugin names.  The plugin names can be fully qualified, or
relative to the C<Starch::Plugin> namespace.  A leading C<::> signifies
that the plugin's package name is relative.

Plugins can modify nearly any functionality in Starch.  More information
about plugins, as well as which plugins are available, can be found at
L<Starch/PLUGINS>.

=cut

# This is a "virtual" argument of sorts handled in Starch->new.
# The plugins end up being stored in the factory object, not here.

=head2 namespace

The root array ref namespace to put starch data in.  In most cases this is
just prepended to the state ID and used as the key for storing the state
data.  Defaults to C<['starch-state']>.

If you are using the same store for independent application states you
may want to namespace them so that you can easly identify which application
a particular state belongs to when looking in the store.

=cut

has namespace => (
    is      => 'ro',
    isa     => ArrayRef[ NonEmptySimpleStr ],
    default => sub{ ['starch-state'] },
);

=head2 expires_state_key

The state key to store the L<Starch::State/expires>
value in.  Defaults to C<__STARCH_EXPIRES__>.

=cut

has expires_state_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__STARCH_EXPIRES__',
);

=head2 modified_state_key

The state key to store the L<Starch::State/modified>
value in.  Defaults to C<__STARCH_MODIFIED__>.

=cut

has modified_state_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__STARCH_MODIFIED__',
);

=head2 created_state_key

The state key to store the L<Starch::State/created>
value in.  Defaults to C<__STARCH_CREATED__>.

=cut

has created_state_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__STARCH_CREATED__',
);

=head2 no_store_state_key

This key is used by stores to mark state data as not to be
stored.  Defaults to C<__STARCH_NO_STORE__>.

This is used by the L<Starch::Plugin::LogStoreExceptions> and
L<Starch::Plugin::ThrottleStore> plugins to avoid losing state
data in the store when errors or throttling is encountered.

=cut

has no_store_state_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__STARCH_NO_STORE__',
);

=head2 dirty_state_key

This key is used to artificially mark as state as dirty by incrementing
the value of this key.  Used by L<Starch::State/mark_dirty>.

=cut

has dirty_state_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__STARCH_DIRTY__',
);

=head1 ATTRIBUTES

=head2 factory

The L<Starch::Factory> object which applies plugins and handles the
construction of the manager, state, and store objects.

=cut

# This argument is always set by Starch->new().  So, to the end-user,
# this is an attribute not a required argument.
has factory => (
    is       => 'ro',
    isa      => InstanceOf[ 'Starch::Factory' ],
    required => 1,
);

=head2 state_id_type

The L<Type::Tiny> object to validate the state ID when L</state>
is called.  Defaults to L<NonEmptySimpleStr>.

=cut

sub state_id_type { NonEmptySimpleStr }

=head1 METHODS

=head2 state

    my $new_state = $starch->state();
    my $existing_state = $starch->state( $id );

Returns a new L<Starch::State> (or whatever L<Starch::Factory/state_class>
returns) object for the specified state ID.

If no ID is specified, or is undef, then an ID will be automatically generated.

Additional arguments can be passed after the ID argument.  These extra
arguments will be passed to the state object constructor.

=cut

sub state {
    my $self = shift;
    my $id = shift;

    croak 'Invalid Starch State ID: ' . $self->state_id_type->get_message( $id )
        if defined($id) and !$self->state_id_type->check( $id );

    my $class = $self->factory->state_class();

    my $extra_args = $class->BUILDARGS( @_ );

    return $class->new(
        %$extra_args,
        manager => $self,
        defined($id) ? (id => $id) : (),
    );
}

=head2 state_id_seed

Returns a fairly unique string used for seeding L<Starch::State/id>.

=cut

my $counter = 0;
sub state_id_seed {
    my ($self) = @_;
    return join( '', ++$counter, time, rand, $$, {}, refaddr($self) )
}

=head2 generate_state_id

Generates and returns a new state ID which is a SHA-1 hex
digest of calling L</state_id_seed>.

=cut

sub generate_state_id {
    my ($self) = @_;
    return sha1_hex( $self->state_id_seed() );
}

=head2 clone_data

Clones complex perl data structures.  Used internally to build
L<Starch::State/data> from L<Starch::State/original_data>.

=cut

sub clone_data {
    my ($self, $data) = @_;
    return dclone( $data );
}

=head2 is_data_diff

Given two bits of data (scalar, array ref, or hash ref) this returns
true if the data is different.  Used internally by L<Starch::State/is_dirty>.

=cut

sub is_data_diff {
    my ($self, $old, $new) = @_;

    local $Storable::canonical = 1;

    $old = freeze( $old );
    $new = freeze( $new );

    return 0 if $new eq $old;
    return 1;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

