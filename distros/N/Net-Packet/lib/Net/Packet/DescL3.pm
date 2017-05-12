#
# $Id: DescL3.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::DescL3;
use strict;
use warnings;
use Carp;

require Net::Packet::Desc;
our @ISA = qw(Net::Packet::Desc);

our @AS = qw(
   _ethHeader
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

use Net::Packet::Utils qw(getIpMac);

BEGIN {
   my $osname = {
      cygwin  => [ \&_newWin32, \&_sendWin32 ],
      MSWin32 => [ \&_newWin32, \&_sendWin32 ],
   };

   *new  = $osname->{$^O}->[0] || \&_newOther;
   *send = $osname->{$^O}->[1] || \&_sendOther;
}

sub _newWin32 {
   my $self = shift->SUPER::new(@_);

   confess("@{[(caller(0))[3]]}: you must pass `target' parameter\n")
      unless $self->[$__target];

   require Net::Write::Layer2;
   my $nwrite = Net::Write::Layer2->new(
      dev => $self->[$__dev],
   );
   $nwrite->open;

   $self->[$___io] = $nwrite;

   $self->[$__targetMac] = getIpMac($self->[$__target]);
   $self->_buildEthHeaderWin32;

   $self->cgDebugPrint(1, "target:     [@{[$self->target]}]")
      if $self->target;
   $self->cgDebugPrint(1, "targetMac:  [@{[$self->targetMac]}]")
      if $self->targetMac;

   $self;
}

# XXX: only support for IPv4 as now
# XXX: should add an attribute to tell one wants autocreation of L2, even 
#      under Unix systems (useful with IPv6)
sub _buildEthHeaderWin32 {
   my $self = shift;
   use Net::Packet::Env qw($Env);
   $Env->doIPv4Checksum(1);
   require Net::Packet::ETH;
   use Net::Packet::Consts qw(:eth);
   my $eth = Net::Packet::ETH->new(
      src  => $Env->mac,
      dst  => $self->[$__targetMac],
      type => NP_ETH_TYPE_IPv4,
   );
   $eth->pack;
   $self->[$___ethHeader] = $eth;
}

sub _newOther {
   my $self = shift->SUPER::new(@_);

   confess("@{[(caller(0))[3]]}: you must pass `target' parameter\n")
      unless $self->[$__target];

   require Net::Write::Layer3;
   my $nwrite = Net::Write::Layer3->new(
      dev => $self->[$__dev],
      dst => $self->[$__target],
   );
   $nwrite->open;

   $self->[$___io] = $nwrite;

   $self;
}

sub _sendWin32 {
   my $self = shift;
   my ($raw) = @_;
   $self->_io->send($self->[$___ethHeader]->raw.$raw);
}

sub _sendOther { shift->SUPER::send(@_) }

1;

__END__

=head1 NAME

Net::Packet::DescL3 - object for a network layer (layer 3) descriptor

=head1 SYNOPSIS

   require Net::Packet::DescL3;

   # Usually, you use it to send IPv4 frames
   my $d3 = Net::Packet::DescL3->new(
      dev    => 'eth0',
      target => '192.168.0.1',
   );

   $d3->send($rawStringToNetwork);

=head1 DESCRIPTION

See also B<Net::Packet::Desc> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<target>

IPv4 address of the target host. You must set it to be able to send frames.

=back

=head1 METHODS

=over 4

=item B<new>

Create the object, using default B<$Env> object values for B<dev>, B<ip>, B<ip6> and B<mac> (see B<Net::Packet::Env>). When the object is created, the B<$Env> global object has its B<desc> attributes set to it. You can avoid this behaviour by setting B<noDescAutoSet> in B<$Env> object (see B<Net::Packet::Env>).

Default values for attributes:

dev: $Env->dev

ip:  $Env->ip

ip6: $Env->ip6

mac: $Env->mac

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 RELATED MODULES

L<NetPacket>, L<Net::RawIP>, L<Net::RawSock>

=cut
