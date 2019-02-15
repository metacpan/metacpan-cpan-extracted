package Starch::State;

$Starch::State::VERSION = '0.10';

=head1 NAME

Starch::State - The Starch state object.

=head1 SYNOPSIS

    my $state = $starch->state();
    $state->data->{foo} = 'bar';
    $state->save();
    $state = $starch->state( $state->id() );
    print $state->data->{foo}; # bar

=head1 DESCRIPTION

This is the state class used by L<Starch::Manager/state>.

=cut

use Types::Standard -types;
use Types::Common::String -types;
use Starch::Util qw( croak );

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Role::Log
);

# Declare BUILD so roles can apply method modifiers to it.
sub BUILD { }

=head1 REQUIRED ARGUMENTS

=head2 manager

The L<Starch::Manager> object that glues everything together.  The state
object needs this to get at configuration information and the stores.
This argument is automatically set by L<Starch::Manager/state>.

=cut

has manager => (
    is       => 'ro',
    isa      => InstanceOf[ 'Starch::Manager' ],
    required => 1,
);

=head1 OPTIONAL ARGUMENTS

=head2 id

The state ID.  If one is not specified then one will be built and
the state will be considered new.

=cut

has _existing_id => (
    is        => 'ro',
    init_arg  => 'id',
    predicate => 1,
    clearer   => '_clear_existing_id',
);

has id => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => '_clear_id',
);
sub _build_id {
    my ($self) = @_;
    return $self->_existing_id() if $self->_has_existing_id();
    return $self->manager->generate_state_id();
}

=head1 ATTRIBUTES

=head2 original_data

The state data at the point it was when the state object was first instantiated.

=cut

has original_data => (
    is        => 'lazy',
    isa       => HashRef,
    init_arg  => undef,
    writer    => '_set_original_data',
    clearer   => '_clear_original_data',
    predicate => 'is_loaded',
);
sub _build_original_data {
    my ($self) = @_;

    return {} if !$self->in_store();

    my $manager = $self->manager();
    my $data = $manager->store->get( $self->id(), $manager->namespace() );

    return $data if $data;

    $self->_set_in_store( 0 );
    return {};
}

=head2 data

The state data which is meant to be modified.

=cut

has data => (
    is       => 'lazy',
    init_arg => undef,
    writer   => '_set_data',
    clearer  => '_clear_data',
);
sub _build_data {
    my ($self) = @_;
    return $self->manager->clone_data( $self->original_data() );
}

=head2 expires

This defaults to L<Starch::Manager/expires> and is stored in the L</data>
under the L<Starch::Manager/expires_state_key> key.

=cut

has expires => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => '_clear_expires',
    writer   => '_set_expires',
);
sub _build_expires {
    my ($self) = @_;

    my $manager = $self->manager();
    my $expires = $self->original_data->{ $manager->expires_state_key() };

    $expires = $manager->expires() if !defined $expires;

    return $expires;
}

=head2 modified

Whenever the state is L</save>d this will be updated and stored in
L</data> under the L<Starch::Manager/modified_state_key>.

=cut

has modified => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => '_clear_modified',
);
sub _build_modified {
    my ($self) = @_;

    my $modified = $self->original_data->{
        $self->manager->modified_state_key()
    };

    $modified = $self->created() if !defined $modified;

    return $modified;
}

=head2 created

When the state is created this is set and stored in L</data>
under the L<Starch::Manager/created_state_key>.

=cut

has created => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => '_clear_created',
);
sub _build_created {
    my ($self) = @_;

    my $created = $self->original_data->{
        $self->manager->created_state_key()
    };

    $created = time() if !defined $created;

    return $created;
}

=head2 in_store

Returns true if the state is expected to exist in the store
(AKA, if the L</id> argument was specified or L</save> was called).

Note that the value of this attribute may change after L</data>
is called which will set this to false if the store did not have
the data for the state.

=cut

has in_store => (
    is       => 'lazy',
    writer   => '_set_in_store',
    init_arg => undef,
);
sub _build_in_store {
    my ($self) = @_;
    return( $self->_has_existing_id() ? 1 : 0 );
}

=head2 is_loaded

This returns true if the L</original_data> has been loaded up from
the store.  Note that L</original_data> will be automatically
loaded if L</original_data>, L</data>, or any methods that call them,
are called.

=cut

# This is provided by the original_data attribute via its predicate.

=head2 is_saved

Returns true if the state is L</in_store> and is not L</is_dirty>.

=cut

sub is_saved {
    my ($self) = @_;
    return 0 if !$self->in_store();
    return 0 if $self->is_dirty();
    return 1;
}

=head2 is_deleted

Returns true if L</delete> has been called on this state.

=cut

has is_deleted => (
    is       => 'ro',
    writer   => '_set_is_deleted',
    init_arg => undef,
    default  => 0,
);

=head2 is_dirty

Returns true if the state data has changed (if L</original_data>
and L</data> are different).

=cut

sub is_dirty {
    my ($self) = @_;

    # If we haven't even loaded the data from the store then
    # there is no way we're dirty.
    return 0 if !$self->is_loaded();

    return $self->manager->is_data_diff( $self->original_data(), $self->data() );
}

=head1 METHODS

=head2 save

Saves this state in the L<Starch::Manager/store> if it L</is_dirty> and
not L</is_deleted>.

=cut

sub save {
    my ($self) = @_;

    return if !$self->is_dirty();
    return if $self->is_deleted();

    my $manager = $self->manager();
    my $data = $self->data();

    $data->{ $manager->created_state_key() }  = $self->created();
    $data->{ $manager->modified_state_key() } = time();
    $data->{ $manager->expires_state_key() }  = $self->expires();

    $self->_clear_modified();

    $manager->store->set(
        $self->id(),
        $manager->namespace(),
        $data,
        $self->expires(),
    );

    # This will cause is_saved to return true.
    $self->_set_in_store( 1 );
    $self->mark_clean();

    return;
}

=head2 delete

Deletes the state from the L<Starch::Manager/store> and sets
L</is_deleted>.

=cut

sub delete {
    my ($self) = @_;

    if ($self->in_store()) {
        my $manager = $self->manager();
        $manager->store->remove( $self->id(), $manager->namespace() );
    }

    $self->_set_is_deleted( 1 );
    $self->_set_in_store( 0 );

    return;
}

=head2 reload

Clears L</original_data> and L</data> so that the next call to these
will reload the state data from the store.  This method is potentially
destructive as you will loose any changes to the data that have not
been saved.

=cut

sub reload {
    my ($self) = @_;

    $self->_clear_original_data();
    $self->_clear_data();

    return;
}

=head2 rollback

Sets L</data> to L</original_data>.

=cut

sub rollback {
    my ($self) = @_;

    $self->_set_data(
        $self->manager->clone_data( $self->original_data() ),
    );

    return;
}

=head2 clear

Empties L</data> and L</original_data>, and calls L</mark_dirty>.

=cut

sub clear {
    my ($self) = @_;

    # Make sure we retain these values.
    $self->expires();
    $self->modified();
    $self->created();

    $self->_set_original_data( {} );
    $self->_set_data( {} );
    $self->mark_dirty();

    return;
}

=head2 mark_clean

Marks the state as not L</is_dirty> by setting L</original_data> to
L</data>.  This is a potentially destructive method as L</save> will
silentfly not save if the state is not L</is_dirty>.

=cut

sub mark_clean {
    my ($self) = @_;

    $self->_set_original_data(
        $self->manager->clone_data( $self->data() ),
    );

    return;
}

=head2 mark_dirty

Increments the L<Starch::Manager/dirty_state_key> value in L</data>,
which causes the state to be considered dirty.

=cut

sub mark_dirty {
    my ($self) = @_;

    my $key = $self->manager->dirty_state_key();

    my $counter = $self->data->{ $key };
    $counter = ($counter || 0) + 1;
    $self->data->{ $key } = $counter;

    return;
}

=head2 set_expires

    # Extend this state's expires duration by two hours.
    $state->set_expires( $state->expires() + (2 * 60 * 60) );

Use this to set the state's expires to a duration different than the
global expires set by L<Starch::Manager/expires>.  This is useful for,
for example, to support a "Remember Me" checkbox that many login
forms provide where the difference between the user checking it or not
is just a matter of what the state's expires duration is set to.

Remember that the "expires" duration is a measurement, in seconds, of
how long the state will live in the store since the last modification,
and how long the cookie (if you are using cookies) will live since the
last request.

The expires duration can be more than or less than the global expires,
there is no artificial constraint.

=cut

sub set_expires {
    my ($self, $expires) = @_;

    $self->_set_expires( $expires );
    $self->data->{ $self->manager->expires_state_key() } = $expires;

    return;
}

=head2 reset_expires

Sets this state's expires to L<Starch::Manager/expires>, overriding
and custom expires set on this state.

=cut

sub reset_expires {
    my ($self) = @_;

    $self->set_expires( $self->manager->expires() );

    return;
}

=head2 reset_id

This re-generates a new L</id> and marks the L</data> as dirty.
Often this is used to avoid
L<session fixation|https://en.wikipedia.org/wiki/Session_fixation>
as part of authentication and de-authentication (login/logout).

=cut

sub reset_id {
    my ($self) = @_;

    # Remove the data for the current state ID.
    $self->manager->state( $self->id() )->delete()
        if $self->in_store();

    # Ensure that future calls to id generate a new one.
    $self->_clear_existing_id();
    $self->_clear_id();

    $self->_set_original_data( {} );
    $self->_set_in_store( 0 );

    return;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

