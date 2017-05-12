package POEx::ZMQ::Buffered;
$POEx::ZMQ::Buffered::VERSION = '0.005007';
use Carp;
use strictures 2;

use List::Objects::Types  -types;
use Types::Standard       -types;

use Moo; use MooX::late;


has item => (
  required  => 1,
  is        => 'ro',
  isa       => Defined,
);

has item_type => (
  required  => 1,
  is        => 'ro',
  isa       => Enum[qw/single multipart/],
);

has flags => (
  lazy      => 1,
  is        => 'ro',
  predicate => 1,
  builder   => sub { 0 },
);

1;


=pod

=for Pod::Coverage has_flags

=head1 NAME

POEx::ZMQ::Buffered - A message internally queued on a POEx::ZMQ::Socket

=head1 SYNOPSIS

  use POEx::ZMQ;
  my $zsock = POEx::ZMQ->socket(type => ZMQ_ROUTER);
  # ...
  my @waiting = $zsock->get_buffered_items->all;
  for my $msg (@waiting) {
    my $contents = $msg->item;
    ...
  }

=head1 DESCRIPTION

A buffered outgoing single or multipart message.

See L<POEx::ZMQ> & L<POEx::ZMQ::Socket>.

=head2 ATTRIBUTES

=head3 item

The message body.

=head3 item_type

The message type -- C<single> or C<multipart>.

=head3 flags

The ZeroMQ message flags.

Predicate: B<has_flags>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
