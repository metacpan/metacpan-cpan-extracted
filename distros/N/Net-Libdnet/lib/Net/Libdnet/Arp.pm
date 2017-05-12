#
# $Id: Arp.pm 57 2012-11-02 16:39:39Z gomor $
#
package Net::Libdnet::Arp;
use strict; use warnings;

use base qw(Class::Gomor::Array);

our @AS  = qw(
   _handle
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Libdnet qw(:arp);

sub new {
   my $self   = shift->SUPER::new(@_);
   my $handle = dnet_arp_open() or return;
   $self->_handle($handle);
   $self;
}

sub add {
   my $self       = shift;
   my ($ip, $mac) = @_;
   dnet_arp_add($self->_handle, {arp_pa => $ip, arp_ha => $mac});
}

sub delete {
   my $self  = shift;
   my ($dst) = @_;
   dnet_arp_delete($self->_handle, {arp_pa => $dst});
}

sub get {
   my $self  = shift,
   my ($dst) = @_;
   my $h = dnet_arp_get($self->_handle, {arp_pa => $dst});
   return $h->{arp_ha} if $h;
   undef;
}

sub loop {
   my $self         = shift;
   my ($sub, $data) = @_;
   dnet_arp_loop($self->_handle, $sub, $data || \'');
}

sub DESTROY {
   my $self = shift;
   defined($self->_handle) && dnet_arp_close($self->_handle);
}

1;

__END__

=head1 NAME

Net::Libdnet::Arp - high level API to access libdnet arp_* functions

=head1 SYNOPSIS

   use Net::Libdnet::Arp;

   my $h      = Net::Libdnet::Arp->new;
   my $mac    = $h->get('10.0.0.1');
   my $sucess = $h->add('10.0.0.1', '00:11:22:33:44:55');
   my $sucess = $h->delete('10.0.0.1', '00:11:22:33:44:55');

   my $data;
   $h->loop(\&arp_print, \$data);

   sub arp_print {
      my ($e, $data) = @_;
      printf("%s at %s\n", $e->{arp_pa}, $e->{arp_ha});
   }

=head1 DESCRIPTION

This modules is a higher level abstraction for libdnet arp_* functions.

=head1 METHODS

=over 4

=item B<new> ()

Returns an object to access arp cache table on success, undef otherwise.

=item B<get> (scalar)

Returns the mac address of specified IP address, undef otherwise.

=item B<add> (scalar, scalar)

Adds an entry to arp cache table. Returns 1 on success, undef otherwise. First parameter is the IP address, second is the mac address.

=item B<delete> (scalar, scalar)

Deletes an entry from arp cache table. Returns 1 on success, undef otherwise. First parameter is the IP address, second is the mac address.

=item B<loop> (subref, [ scalarref ])

Calls the specified sub ref for each entry in the arp cache table. The second optional parameter is a scalar ref, to store state information (if any).

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

You may distribute this module under the terms of the BSD license. See LICENSE file in the source distribution archive.

Copyright (c) 2008-2012, Patrice <GomoR> Auffret

=cut
