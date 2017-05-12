package POE::Component::Supervisor::Supervised::Session;

our $VERSION = '0.09';

use Moose;
use POE::Component::Supervisor::Handle::Session;
use namespace::autoclean;

with qw(POE::Component::Supervisor::Supervised);

has '+handle_class' => ( default => "POE::Component::Supervisor::Handle::Session" );

__PACKAGE__->_inherit_attributes_from_handle_class;

sub is_abnormal_exit {
    my ( $self, %args ) = @_;
    exists $args{error};
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

POE::Component::Supervisor::Supervised::Session - Helps
L<POE::Component::Supervisor> babysit POE sessions.

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    POE::Component::Supervisor::Supervised::Session->new(
        start_callback => sub {
            return POE::Session->new(

            );
        },
    );

    POE::Component::Supervisor::Supervised::Session->new(
        implicit_tracking => 1, # any sessions from _child create events
        start_callback => sub {
            POE::Component::Foo->spawn(
                ...
            );
        },
    );

=head1 DESCRIPTION

This is a factory object that creates L<POE::Component::Supervisor::Handle::Session> objects.

=head1 ATTRIBUTES

See also L<POE::Component::Supervisor::Handle::Session/ATTRIBUTES>, all of the
documented attributes that apply to handle creation are borrowed by this class.

=over 4

=item handle_class

The class to instantiate.

Defaults to L<POE::Component::Supervisor::Handle::Session>.

Note that attributes are inherited only from
L<POE::Component::Supervisor::Handle::Session>. If your handle class requires
additional attributes, you must subclass your own C<Supervised> variant.

The C<_inherit_attributes_from_handle_class> method can then be invoked on your
subclass to re-inherit all the attributes. Read the source of
L<POE::Component::Supervisor::Supervised> for more details.

=back

=head1 METHODS

See also L<POE::Component::Supervisor::Supervised/METHODS>.

=over 4

=item spawn

Called by L<POE::Component::Supervisor> when a new instance of the child
process should be spawned.

=item is_abnormal_exit

Used by C<should_restart>. See L<POE::Component::Supervisor::Supervised> for
details.

Returns true if the C<error> argument is provided (it's added by the handle
when a C<DIE> signal is caught from one of the tracked sessions).

=back

=cut
