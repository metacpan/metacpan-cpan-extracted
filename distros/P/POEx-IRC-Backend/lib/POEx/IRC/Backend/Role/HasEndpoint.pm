package POEx::IRC::Backend::Role::HasEndpoint;
$POEx::IRC::Backend::Role::HasEndpoint::VERSION = '0.030003';
use Moo::Role;

has addr => (
  required => 1,
  is       => 'ro',
);

has port => (
  required => 1,
  is       => 'ro',
  writer   => 'set_port',
);

1;

=pod

=for Pod::Coverage has_\w+

=head1 NAME

POEx::IRC::Backend::Role::HasEndpoint

=head1 DESCRIPTION

This role is consumed by L<POEx::IRC::Backend::Connector> and 
L<POEx::IRC::Backend::Listener> objects; it defines some basic attributes
shared by listening/connecting sockets.

=head2 addr

The connecting/listening socket endpoint address.

=head2 port

The connecting/listening socket endpoint port.

=head2 set_port

Change the current port attribute.

This won't trigger any automatic Wheel changes (at this time), 
but it is useful when creating a Listener on port 0 and updating your
Listener's state accordingly.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
