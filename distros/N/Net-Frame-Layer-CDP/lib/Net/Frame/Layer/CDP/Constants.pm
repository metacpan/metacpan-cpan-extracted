#
# $Id: Constants.pm 1640 2013-03-28 17:58:27Z VinsWorldcom $
#
package Net::Frame::Layer::CDP::Constants;
use strict; use warnings;

use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_CDP_TYPE_DEVICE_ID
      NF_CDP_TYPE_ADDRESSES
      NF_CDP_TYPE_PORT_ID
      NF_CDP_TYPE_CAPABILITIES
      NF_CDP_TYPE_SOFTWARE_VERSION
      NF_CDP_TYPE_PLATFORM
      NF_CDP_TYPE_IPNET_PREFIX
      NF_CDP_TYPE_PROTOCOL_HELLO
      NF_CDP_TYPE_VTP_DOMAIN
      NF_CDP_TYPE_NATIVE_VLAN
      NF_CDP_TYPE_DUPLEX
      NF_CDP_TYPE_UNKNOWN_000c
      NF_CDP_TYPE_UNKNOWN_000d
      NF_CDP_TYPE_VOIP_VLAN_REPLY
      NF_CDP_TYPE_VOIP_VLAN_QUERY
      NF_CDP_TYPE_POWER
      NF_CDP_TYPE_MTU
      NF_CDP_TYPE_TRUST_BITMAP
      NF_CDP_TYPE_UNTRUSTED_COS
      NF_CDP_TYPE_SYSTEM_NAME
      NF_CDP_TYPE_SYSTEM_OID
      NF_CDP_TYPE_MANAGEMENT_ADDR
      NF_CDP_TYPE_LOCATION
      NF_CDP_TYPE_EXT_PORT_ID
      NF_CDP_TYPE_POWER_REQUESTED
      NF_CDP_TYPE_POWER_AVAILABLE
      NF_CDP_TYPE_PORT_UNIDIR
      NF_CDP_TYPE_NRGYZ
      NF_CDP_TYPE_SPARE_POE
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_CDP_TYPE_DEVICE_ID          => 0x0001;
use constant NF_CDP_TYPE_ADDRESSES          => 0x0002;
use constant NF_CDP_TYPE_PORT_ID            => 0x0003;
use constant NF_CDP_TYPE_CAPABILITIES       => 0x0004;
use constant NF_CDP_TYPE_SOFTWARE_VERSION   => 0x0005;
use constant NF_CDP_TYPE_PLATFORM           => 0x0006;
use constant NF_CDP_TYPE_IPNET_PREFIX       => 0x0007;
use constant NF_CDP_TYPE_PROTOCOL_HELLO     => 0x0008;
use constant NF_CDP_TYPE_VTP_DOMAIN         => 0x0009;
use constant NF_CDP_TYPE_NATIVE_VLAN        => 0x000a;
use constant NF_CDP_TYPE_DUPLEX             => 0x000b;
use constant NF_CDP_TYPE_UNKNOWN_000c       => 0x000c;
use constant NF_CDP_TYPE_UNKNOWN_000d       => 0x000d;
use constant NF_CDP_TYPE_VOIP_VLAN_REPLY    => 0x000e;
use constant NF_CDP_TYPE_VOIP_VLAN_QUERY    => 0x000f;
use constant NF_CDP_TYPE_POWER              => 0x0010;
use constant NF_CDP_TYPE_MTU                => 0x0011;
use constant NF_CDP_TYPE_TRUST_BITMAP       => 0x0012;
use constant NF_CDP_TYPE_UNTRUSTED_COS      => 0x0013;
use constant NF_CDP_TYPE_SYSTEM_NAME        => 0x0014;
use constant NF_CDP_TYPE_SYSTEM_OID         => 0x0015;
use constant NF_CDP_TYPE_MANAGEMENT_ADDR    => 0x0016;
use constant NF_CDP_TYPE_LOCATION           => 0x0017;
use constant NF_CDP_TYPE_EXT_PORT_ID        => 0x0018;
use constant NF_CDP_TYPE_POWER_REQUESTED    => 0x0019;
use constant NF_CDP_TYPE_POWER_AVAILABLE    => 0x001a;
use constant NF_CDP_TYPE_PORT_UNIDIR        => 0x001b;
use constant NF_CDP_TYPE_NRGYZ              => 0x001d;
use constant NF_CDP_TYPE_SPARE_POE          => 0x001f;

1;

__END__

=head1 NAME

Net::Frame::Layer::CDP::Constants - CDP message type constants

=head1 SYNOPSIS

   use Net::Frame::Layer::CDP::Constants qw(:consts);

=head1 DESCRIPTION

This modules implements the CDP message type constants.

=head1 CONSTANTS

Load them: use Net::Frame::Layer::CDP::Constants qw(:consts);

=over 4

=item B<NF_CDP_TYPE_DEVICE_ID>

=item B<NF_CDP_TYPE_ADDRESSES>

=item B<NF_CDP_TYPE_PORT_ID>

=item B<NF_CDP_TYPE_CAPABILITIES>

=item B<NF_CDP_TYPE_SOFTWARE_VERSION>

=item B<NF_CDP_TYPE_PLATFORM>

=item B<NF_CDP_TYPE_IPNET_PREFIX>

=item B<NF_CDP_TYPE_PROTOCOL_HELLO>

=item B<NF_CDP_TYPE_VTP_DOMAIN>

=item B<NF_CDP_TYPE_NATIVE_VLAN>

=item B<NF_CDP_TYPE_DUPLEX>

=item B<NF_CDP_TYPE_UNKNOWN_000c>

=item B<NF_CDP_TYPE_UNKNOWN_000d>

=item B<NF_CDP_TYPE_VOIP_VLAN_REPLY>

=item B<NF_CDP_TYPE_VOIP_VLAN_QUERY>

=item B<NF_CDP_TYPE_POWER>

=item B<NF_CDP_TYPE_MTU>

=item B<NF_CDP_TYPE_TRUST_BITMAP>

=item B<NF_CDP_TYPE_UNTRUSTED_COS>

=item B<NF_CDP_TYPE_SYSTEM_NAME>

=item B<NF_CDP_TYPE_SYSTEM_OID>

=item B<NF_CDP_TYPE_MANAGEMENT_ADDR>

=item B<NF_CDP_TYPE_LOCATION>

=item B<NF_CDP_TYPE_EXT_PORT_ID>

=item B<NF_CDP_TYPE_POWER_REQUESTED>

=item B<NF_CDP_TYPE_POWER_AVAILABLE>

=item B<NF_CDP_TYPE_PORT_UNIDIR>

=item B<NF_CDP_TYPE_NRGYZ>

=item B<NF_CDP_TYPE_SPARE_POE>

CDP message types.

=back

=head1 SEE ALSO

L<Net::Frame::Layer::CDP::Address>, L<Net::Frame::Layer::CDP::Capabilities>, L<Net::Frame::Layer::CDP::Duplex>, L<Net::Frame::Layer::CDP::TrustBitmap>, L<Net::Frame::Layer::CDP>, L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
