package POE::Component::Supervisor::Supervised;

our $VERSION = '0.09';

use Moose::Role;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

with qw(POE::Component::Supervisor::Supervised::Interface);

has handle_class => (
    isa => "ClassName",
    is  => "rw",
    required => 1,
    # handles => {
    #     create_handle => "new",
    # },
);

sub spawn {
    my ( $self, @args ) = @_;
    $self->create_handle( @args );
}

sub _get_handle_attributes {
    my ( $class, $handle_class ) = @_;

    my $meta = $class->meta;

    $handle_class ||= $meta->get_attribute("handle_class")->default || die "no default handle_class for $class";

    my $handle_meta = $handle_class->meta;

    my @handle_attrs =
        map { $_->clone }
        grep { not $meta->has_attribute($_->name) }
        grep { defined $_->init_arg } grep { $_->name !~ /^(?: child | supervisor | logger )$/x }
        $handle_meta->get_all_attributes;
}

sub _inherit_attributes_from_handle_class {
    my ( $class, @args ) = @_;

    my $meta = $class->meta;

    my @handle_attrs = do {
        no strict 'refs';
        @{ "${class}::_handle_attrs" } = $class->_get_handle_attributes(@args)
    };

    $meta->add_attribute($_) for @handle_attrs;
}

sub create_handle {
    my ( $self, @args ) = @_;

    my $class = ref $self;

    my @handle_attrs = do {
        no strict 'refs';
        @{ "${class}::_handle_attrs" };
    };

    $self->construct_handle(
        child => $self,
        ( map { $_->init_arg => scalar($_->get_value($self)) } grep { $_->has_value($self) } @handle_attrs ),
        @args,
    );
}

sub construct_handle {
    my ( $self, @args ) = @_;
    $self->handle_class->new(@args);
}

requires 'is_abnormal_exit';

has restart_policy => (
    isa => enum(__PACKAGE__ . "::RestartPolicy" => [qw(permanent transient temporary)]),
    is  => "rw",
    default => "transient",
);

sub is_transient {
    my $self = shift;
    $self->restart_policy eq 'transient';
}

sub is_permanent {
    my $self = shift;
    $self->restart_policy eq 'permanent';
}

sub is_temporary {
    my $self = shift;
    $self->restart_policy eq 'temporary';
}

sub should_restart {
    my ( $self, @args ) = @_;

    if ( $self->is_permanent ) {
        return 1;
    } elsif ( $self->is_transient ) {
        return $self->is_abnormal_exit(@args);
    } elsif ( $self->is_temporary ) {
        return;
    }

    # never reached
    return 1;
}

sub respawn { shift->spawn(@_) }

__PACKAGE__

__END__

=pod

=head1 NAME

POE::Component::Supervisor::Supervised - A role for supervision descriptors.

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    # See e.g. POE::Component::Supervisor::Supervised::Proc;

=head1 DESCRIPTION

All children supervised by the L<POE::Component::Supervisor> must compose this role.

This role provides an API for instantiating
L<POE::Component::Supervisor::Handle> as required by the supervisor,
corresponding to living instances of the child. The
L<POE::Component::Supervisor::Supervised> objects serve as descriptors for
these handles, and know how to spawn the actual child.

=head1 ATTRIBUTES

=over 4

=item restart_policy

One of C<permanent>, C<transient> or C<temporary>.

Defaults to C<transient>.

See C<should_restart>.

=item handle_class

This attribute should be extended by your class to provide a default for
C<_inherit_attributes_from_handle_class> (and subsequently C<create_handle>) to
work.

=back

=head1 METHODS

=over 4

=item construct_handle

Calls C<new> on C<handle_class> with the arguments.

=item create_handle

Iterates the inherited attributes and copies them from the C<$self>, and also
passes C<$self> as the C<child> parameter, along with all provided arguments to
C<construct_handle>.

=item should_restart

Returns a boolean value, which instructs the supervisor as to whether or not
the child should be restarted after exit.

If the child is C<permanent> this always returns true.

If the child is C<transient> this returns true if C<is_abnormal_exit> returns
true.

If the child is C<temporary> this returns false.

=item is_abnormal_exit %args

Required.

Given exit arguments from the handle, check whether or not the exit was normal
or not.

For example L<POE::Component::Supervisor::Supervised::Proc> will by default
check if the exit status is 0.

Only applies to C<transient> children.

=item spawn

Required.

Creates a new L<POE::Component::Supervisor::Handle> object for the supervisor.

=for stopwords respawn respawning

=item respawn

An alias for C<spawn> by default.

May be overridden if respawning requires cleanup first, or something like that.

=item is_transient

=item is_temporary

=item is_permanent

Boolean query methods that operate on C<restart_policy>.

=back

=cut
