package POEx::IRC::Backend::Role::HasWheel;
$POEx::IRC::Backend::Role::HasWheel::VERSION = '0.030003';
use Types::Standard -all;

use Moo::Role;

has wheel_id => (
  # lazy but set by trigger in ->wheel:
  lazy    => 1,
  isa     => Defined,
  is      => 'ro',
  writer  => '_set_wheel_id',
  builder => sub { shift->wheel->ID },
);

has wheel => (
  required  => 1,
  isa       => Maybe[ InstanceOf['POE::Wheel'] ],
  is        => 'ro',
  clearer   => 'clear_wheel',
  writer    => 'set_wheel',
  predicate => 'has_wheel',
  trigger   => sub {
    my ($self, $wheel) = @_;
    $self->_set_wheel_id( $wheel->ID )
  },
);

1;

=pod

=for Pod::Coverage has_\w+

=head1 NAME

POEx::IRC::Backend::Role::HasWheel

=head1 DESCRIPTION

=head2 wheel

A L<POE::Wheel> instance; typically L<POE::Wheel::SocketFactory> for
L<POEx::IRC::Backend::Listener> and L<POEx::IRC::Backend::Connector> objects,
or L<POE::Wheel::ReadWrite> for live L<POEx::IRC::Backend::Connect> objects.

This is primarily for internal use. B<< External code should not interact
directly with the C<wheel>; >> doing so may result in misdelivered events and
other unexpected behavior.

Clearer: B<clear_wheel>

Predicate: B<has_wheel>

Writer: B<set_wheel>

=head2 wheel_id

The POE ID of the last known L</wheel>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
