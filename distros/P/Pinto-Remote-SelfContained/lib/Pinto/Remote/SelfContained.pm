package Pinto::Remote::SelfContained;

use v5.10;
use Moo;

use Carp qw(croak);
use Module::Runtime qw(module_notional_filename use_package_optimistically);
use Pinto::Remote::SelfContained::Action;
use Pinto::Remote::SelfContained::Chrome;
use Pinto::Remote::SelfContained::Types qw(Uri);
use Pinto::Remote::SelfContained::Util qw(current_username);
use Types::Standard qw(Bool InstanceOf Int Maybe Str);

use namespace::clean;

our $VERSION = '0.900';

with qw(
    Pinto::Remote::SelfContained::HasHttptiny
);

has root => (
    is => 'ro',
    isa => Uri,
    default => sub { $ENV{PINTO_REPOSITORY_ROOT} },
    coerce => 1,
);

has username => (
    is => 'ro',
    isa => Str,
    default => sub { current_username() },
);

has password => (is => 'ro', isa => Maybe[Str]);

has chrome => (
    is => 'lazy',
    isa => InstanceOf['Pinto::Remote::SelfContained::Chrome'],
    builder => sub { Pinto::Remote::SelfContained::Chrome->new },
);

sub run {
    my ($self, $action_name, @args) = @_;

    my $action = $self->make_action($action_name, @args);

    $action->execute;
}

sub make_action {
    my ($self, $action_name, @args) = @_;

    my $action_args = (@args == 1 && ref $args[0] eq 'HASH') ? $args[0] : { @args };

    my $action_class = $self->load_class_for_action(name => $action_name);

    local $SIG{__WARN__} = sub { $self->chrome->warning($_) for @_ };

    my $action = $action_class->new(
        name => $action_name,
        args => $action_args,
        root => $self->root,
        username => $self->username,
        password => $self->password,
        chrome => $self->chrome,
        httptiny => $self->httptiny,
    );
}

sub run_streaming {
    my ($self, $streaming_callback, $action_name, @args) = @_;

    my $action = $self->make_action($action_name, @args);

    $action->execute($streaming_callback);;
}

sub load_class_for_action {
    my ($self, %args) = @_;

    my $action_name = $args{name}
        or croak('Must specify an action name');

    my $class  = __PACKAGE__ . "::Action::\u$action_name";
    use_package_optimistically($class);
    return $INC{ module_notional_filename($class) } ? $class : __PACKAGE__.'::Action';
}

1;
__END__

=head1 NAME

Pinto::Remote::SelfContained - interact with a remote Pinto repository

=head1 DESCRIPTION

Pinto::Remote::SelfContained is a partial clone of L<Pinto::Remote>, but
without the server parts, and therefore a much smaller dependency graph.
Documentation can be found in that module.

This class exists for situations where your organisation is using Pinto, and
doesn't currently have the bandwidth to move away from it to any alternative,
but wants something smaller than the whole of L<Pinto> for interacting with the
remote repo.

=head1 METHODS

=head2 C<< run($action_name => %action_args) >>

Loads the Action subclass for the given C<$action_name> and constructs
an object using the given C<$action_args>.  If the subclass
C<Pinto::Remote::SelfContained::Action::$action_name> does not exist, then it falls
back to the L<Pinto::Remote::SelfContained::Action> base class.

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2020 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
