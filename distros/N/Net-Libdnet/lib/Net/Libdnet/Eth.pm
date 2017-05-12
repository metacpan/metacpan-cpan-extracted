#
# $Id: Eth.pm 57 2012-11-02 16:39:39Z gomor $
#
package Net::Libdnet::Eth;
use strict; use warnings;

use base qw(Class::Gomor::Array);

our @AS  = qw(
   device
   _handle
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Libdnet qw(:eth);

sub new {
   my $self   = shift->SUPER::new(@_);
   my $handle = dnet_eth_open($self->device) or return;
   $self->_handle($handle);
   $self;
}

sub get {
   my $self = shift;
   dnet_eth_get($self->_handle);
}

sub set {
   my $self   = shift;
   my ($addr) = @_;
   dnet_eth_set($self->_handle, $addr);
}

sub send {
   my $self  = shift;
   my ($buf) = @_;
   dnet_eth_send($self->_handle, $buf, length($buf));
}

sub DESTROY {
   my $self = shift;
   defined($self->_handle) && dnet_eth_close($self->_handle);
}

1;

__END__

=head1 NAME

Net::Libdnet::Eth - high level API to access libdnet eth_* functions

=head1 SYNOPSIS

   use Net::Libdnet::Eth;

   my $h = Net::Libdnet::Eth->new(device => 'eth0');

=head1 DESCRIPTION

This modules is a higher level abstraction for libdnet eth_* functions.

=head1 METHODS

=over 4

=item B<new> (device => scalar)

Returns an object to eth layer on success, undef otherwise. You MUST give a network interface to use for sending.

=item B<get> ()

Returns the hardware address associated with used network interface. Returns undef on error.

=item B<set> (scalar)

Sets the hardware address specified by scalar of used network interface. Returns undef on error.

=item B<send> (scalar)

Sends the raw data specified by scalar to the network interface. Returns the number of bytes sent on sucess, undef on error.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

You may distribute this module under the terms of the BSD license. See LICENSE file in the source distribution archive.

Copyright (c) 2008-2012, Patrice <GomoR> Auffret

=cut
