package POE::Component::Supervisor::Supervised::Proc;

our $VERSION = '0.09';

use Moose;
use POE::Component::Supervisor::Handle::Proc;
use namespace::autoclean;

with qw(POE::Component::Supervisor::Supervised);

has '+handle_class' => ( default => "POE::Component::Supervisor::Handle::Proc" );

__PACKAGE__->_inherit_attributes_from_handle_class;

sub is_abnormal_exit {
    my ( $self, %args ) = @_;

    my $exit_code = $args{exit_code};

    return ( defined($exit_code) and $exit_code != 0 );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

POE::Component::Supervisor::Supervised::Proc - A supervision descriptor for UNIX processes.

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use POE;

    use POE::Component::Supervisor;
    use POE::Component::Supervisor::Supervised::Proc;

    POE::Component::Supervisor->new(
        children => [
            POE::Component::Supervisor::Supervised::Proc->new(
                program => [qw(memcached -m 64)],
                restart_policy => "permanent",
            ),
        ],
    );

    $poe_kernel->run;

=head1 DESCRIPTION

This is a factory object that creates L<POE::Component::Supervisor::Handle::Proc> objects.

=head1 ATTRIBUTES

See also L<POE::Component::Supervisor::Handle::Proc/ATTRIBUTES>, all of the
documented attributes that apply to handle creation are borrowed by this class.

=over 4

=item handle_class

The class to instantiate.

Defaults to L<POE::Component::Supervisor::Handle::Proc>.

Note that attributes are inherited only from
L<POE::Component::Supervisor::Handle::Proc>. If your handle class requires
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

Returns true if the C<exit_code> argument is not equal to 0.

=back

=cut
