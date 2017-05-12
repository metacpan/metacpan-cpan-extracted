#
# $Id: Tun.pm 57 2012-11-02 16:39:39Z gomor $
#
package Net::Libdnet::Tun;
use strict; use warnings;

use base qw(Class::Gomor::Array);

our @AS  = qw(
   src
   dst
   _mtu
   _handle
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Libdnet qw(:tun);

sub _getMtu {
   my ($src) = @_;
   my $h    = dnet_intf_open()            or return;
   my $intf = dnet_intf_get_src($h, $src) or return;
   $intf->{intf_mtu} || undef;
}

sub new {
   my $self   = shift->SUPER::new(@_);
   my $mtu    = _getMtu($self->src)
      or die("Tun::new: unable to get mtu");
   $self->_mtu($mtu);
   my $handle = dnet_tun_open($self->src, $self->dst, $mtu)
      or die("Tun::new: unable to open");
   $self->_handle($handle);
   $self;
}

sub fileno {
   my $self = shift;
   dnet_tun_fileno($self->_handle);
}

sub name {
   my $self = shift;
   dnet_tun_name($self->_handle);
}

sub send {
   my $self = shift;
   my ($buf) = @_;
   dnet_tun_send($self->_handle, $buf, length($buf));
}

sub recv {
   my $self = shift;
   dnet_tun_recv($self->_handle, $self->_mtu);
}

sub DESTROY {
   my $self = shift;
   defined($self->_handle) && dnet_tun_close($self->_handle);
}

1;

__END__

=head1 NAME

Net::Libdnet::Tun - high level API to access libdnet tun_* functions

=head1 SYNOPSIS

XXX

=head1 DESCRIPTION

XXX

=head1 METHODS

=over 4

=item B<new>

=item B<fileno>

=item B<name>

=item B<recv>

=item B<send>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

You may distribute this module under the terms of the BSD license. See LICENSE file in the source distribution archive.

Copyright (c) 2008-2012, Patrice <GomoR> Auffret

=cut
