package POE::Component::Supervisor::Handle;

our $VERSION = '0.09';

use Moose::Role;
use POE::Component::Supervisor::Interface ();
use POE::Component::Supervisor::Supervised ();
use namespace::autoclean;

with qw(POE::Component::Supervisor::Handle::Interface);

has child => (
    does => "POE::Component::Supervisor::Supervised",
    is  => "ro",
    required => 1,
);

has supervisor => (
    does => "POE::Component::Supervisor::Interface",
    is  => "rw",
    weak_ref  => 1,
    required => 1,
    handles => [qw(notify_spawned notify_stopped)],
);

has spawned => (
    isa => "Bool",
    is  => "rw",
    writer => "_spawned",
);

has stopped => (
    isa => "Bool",
    is  => "rw",
    writer => "_stopped",
);

has [map { "${_}_callback" } qw(spawned stopped)] => (
    isa => "CodeRef",
    is  => "rw",
    required => 0,
);

sub stop_for_restart { shift->stop(@_) }

sub notify_spawn {
    my ( $self, @args ) = @_;

    $self->_spawned(1);

    $self->notify_spawned( $self->child, @args);

    if ( my $cb = $self->spawned_callback ) {
        $self->$cb(@args);
    }
}

sub notify_stop {
    my ( $self, @args ) = @_;

    $self->_stopped(1);

    $self->notify_stopped( $self->child, @args);

    if ( my $cb = $self->stopped_callback ) {
        $self->$cb(@args);
    }
}

__PACKAGE__

__END__

=pod

=head1 NAME

POE::Component::Supervisor::Handle - Base role for supervision handles

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    # see Handle::Proc and Handle::Session

=head1 DESCRIPTION

This is a base role for supervision handles.

=head1 ATTRIBUTES

=over 4

=item supervisor

The L<POE::Component::Supervisor> utilizing over this handle.

=item child

The child descriptor this handle was spawned for.

=item spawned_callback

=item stopped_callback

These callbacks are called as handle methods with the arguments sent to the
supervisor.

Note that they are not invoked with L<POE>'s calling convention, but rather
arbitrary arguments from the supervision handle.

=back

=head1 METHODS

=over 4

=item stop

Stops the running supervised thingy.

Required.

=item is_running

Checks if the supervised thingy is running.

Required.

=item stop_for_restart

By default an alias to C<stop>.

If stopping for the purpose of a restart should be handled differently this can
be overridden.

=back

=cut
