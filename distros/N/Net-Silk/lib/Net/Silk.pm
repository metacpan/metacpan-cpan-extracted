# Use of the Net-Silk library and related source code is subject to the
# terms of the following licenses:
# 
# GNU Public License (GPL) Rights pursuant to Version 2, June 1991
# Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013
# 
# NO WARRANTY
# 
# ANY INFORMATION, MATERIALS, SERVICES, INTELLECTUAL PROPERTY OR OTHER 
# PROPERTY OR RIGHTS GRANTED OR PROVIDED BY CARNEGIE MELLON UNIVERSITY 
# PURSUANT TO THIS LICENSE (HEREINAFTER THE "DELIVERABLES") ARE ON AN 
# "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY 
# KIND, EITHER EXPRESS OR IMPLIED AS TO ANY MATTER INCLUDING, BUT NOT 
# LIMITED TO, WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE, 
# MERCHANTABILITY, INFORMATIONAL CONTENT, NONINFRINGEMENT, OR ERROR-FREE 
# OPERATION. CARNEGIE MELLON UNIVERSITY SHALL NOT BE LIABLE FOR INDIRECT, 
# SPECIAL OR CONSEQUENTIAL DAMAGES, SUCH AS LOSS OF PROFITS OR INABILITY 
# TO USE SAID INTELLECTUAL PROPERTY, UNDER THIS LICENSE, REGARDLESS OF 
# WHETHER SUCH PARTY WAS AWARE OF THE POSSIBILITY OF SUCH DAMAGES. 
# LICENSEE AGREES THAT IT WILL NOT MAKE ANY WARRANTY ON BEHALF OF 
# CARNEGIE MELLON UNIVERSITY, EXPRESS OR IMPLIED, TO ANY PERSON 
# CONCERNING THE APPLICATION OF OR THE RESULTS TO BE OBTAINED WITH THE 
# DELIVERABLES UNDER THIS LICENSE.
# 
# Licensee hereby agrees to defend, indemnify, and hold harmless Carnegie 
# Mellon University, its trustees, officers, employees, and agents from 
# all claims or demands made against them (and any related losses, 
# expenses, or attorney's fees) arising out of, or relating to Licensee's 
# and/or its sub licensees' negligent use or willful misuse of or 
# negligent conduct or willful misconduct regarding the Software, 
# facilities, or other rights or assistance granted by Carnegie Mellon 
# University under this License, including, but not limited to, any 
# claims of product liability, personal injury, death, damage to 
# property, or violation of any laws or regulations.
# 
# Carnegie Mellon University Software Engineering Institute authored 
# documents are sponsored by the U.S. Department of Defense under 
# Contract FA8721-05-C-0003. Carnegie Mellon University retains 
# copyrights in all material produced under this contract. The U.S. 
# Government retains a non-exclusive, royalty-free license to publish or 
# reproduce these documents, or allow others to do so, for U.S. 
# Government purposes only pursuant to the copyright license under the 
# contract clause at 252.227.7013.

package Net::Silk;

use 5.004_04;
use strict;
use warnings;
use FindBin;

use vars qw( @EXPORT_OK %EXPORT_TAGS $VERSION );

require Exporter;
require DynaLoader;

use base qw( Exporter DynaLoader );

sub dl_load_flags { 0x01 } # global option

BEGIN {
  $VERSION = '2.05';
  bootstrap Net::Silk $VERSION;
}

use constant DEBUG => 0;

module_init($FindBin::Script);

use constant SILK_IPWILDCARD_CLASS      => 'Net::Silk::IPWildcard';
use constant SILK_IPADDR_CLASS          => 'Net::Silk::IPAddr';
use constant SILK_IPV4ADDR_CLASS        => 'Net::Silk::IPv4Addr';
use constant SILK_IPV6ADDR_CLASS        => 'Net::Silk::IPv6Addr';
use constant SILK_RANGE_CLASS           => 'Net::Silk::Range';
use constant SILK_CIDR_CLASS            => 'Net::Silk::CIDR';
use constant SILK_PROTOPORT_CLASS       => 'Net::Silk::ProtoPort';
use constant SILK_TCPFLAGS_CLASS        => 'Net::Silk::TCPFlags';
use constant SILK_RWREC_CLASS           => 'Net::Silk::RWRec';
use constant SILK_IPSET_CLASS           => 'Net::Silk::IPSet';
use constant SILK_BAG_CLASS             => 'Net::Silk::Bag';
use constant SILK_PMAP_CLASS            => 'Net::Silk::Pmap';
use constant SILK_PMAP_IPV4_CLASS       => 'Net::Silk::Pmap::IPv4';
use constant SILK_PMAP_IPV6_CLASS       => 'Net::Silk::Pmap::IPv6';
use constant SILK_PMAP_PP_CLASS         => 'Net::Silk::Pmap::ProtoPort';
use constant SILK_IPWILDCARD_ITER_CLASS => 'Net::Silk::IPWildcard::iter_xs';
use constant SILK_IPSET_ITER_CLASS      => 'Net::Silk::IPSet::iter_xs';
use constant SILK_BAG_ITER_CLASS        => 'Net::Silk::Bag::iter_xs';
use constant SILK_PMAP_ITER_CLASS       => 'Net::Silk::Pmap::iter_xs';
use constant SILK_SITE_REPO_ITER_CLASS  => 'Net::Silk::Site::iter_xs';
use constant SILK_SITE_CLASS            => 'Net::Silk::Site';
use constant SILK_FILE_CLASS            => 'Net::Silk::File';
use constant SILK_FILE_IO_CLASS         => 'Net::Silk::File::io_xs';

use Math::Int64;
use Math::Int64::die_on_overflow;
use Math::Int128 qw(string_to_uint128);
use Math::Int128::die_on_overflow;

my $IPv6Max;
BEGIN {
  $IPv6Max = string_to_uint128("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
  $IPv6Max = SILK_IPV6ADDR_CLASS->new($IPv6Max) if SILK_IPV6_ENABLED;
}
use constant SILK_IPV6ADDR_MAX  => $IPv6Max;
use constant SILK_IPV6ADDR_BITS => 128;
use constant SILK_IPV4ADDR_MAX  => SILK_IPV4ADDR_CLASS->new(0xFFFFFFFF);
use constant SILK_IPV4ADDR_BITS => 32;

# note: SILK_IPV6_ENABLED defined in Silk.xs/BOOT

BEGIN {

  my @Basic = qw(

    SILK_IPV6_ENABLED
    SILK_ZLIB_ENABLED
    SILK_LZO_ENABLED
    SILK_LOCALTIME_ENABLED
    SILK_INITIAL_TCPFLAGS_ENABLED

    SILK_IPV4ADDR_MAX
    SILK_IPV4ADDR_BITS
    SILK_IPV6ADDR_MAX
    SILK_IPV6ADDR_BITS

    SILK_IPWILDCARD_CLASS
    SILK_IPWILDCARD_ITER_CLASS

    SILK_IPADDR_CLASS
    SILK_IPV4ADDR_CLASS
    SILK_IPV6ADDR_CLASS

    SILK_TCPFLAGS_CLASS

    SILK_RWREC_CLASS

    SILK_IPSET_CLASS
    SILK_IPSET_ITER_CLASS

    SILK_BAG_CLASS
    SILK_BAG_ITER_CLASS

    SILK_PMAP_CLASS
    SILK_PMAP_IPV4_CLASS
    SILK_PMAP_IPV6_CLASS
    SILK_PMAP_PP_CLASS
    SILK_PMAP_ITER_CLASS

    SILK_RANGE_CLASS
    SILK_CIDR_CLASS

    SILK_SITE_REPO_ITER_CLASS

    SILK_PROTOPORT_CLASS

    SILK_SITE_CLASS
    SILK_FILE_CLASS
    SILK_FILE_IO_CLASS

    compression_methods
    timezone_support

  );


  @EXPORT_OK = (
    @Basic,
    'DEBUG',
  );

  %EXPORT_TAGS = (
    all   => \@EXPORT_OK, 
    basic => \@Basic,
  );

}

###

sub compression_methods {
  my @cmethods = ["none"];
  push(@cmethods, "zlib")  if SILK_ZLIB_ENABLED;
  push(@cmethods, "lzo1x") if SILK_LZO_ENABLED;
  return @cmethods;
}

use constant INITIAL_TCPFLAGS_ENABLED => 1;

sub timezone_support {
  SILK_LOCALTIME_ENABLED ? "local" : "UTC";
}

END { module_destroy() }

###

require Net::Silk::IPSet;
require Net::Silk::Bag;
require Net::Silk::Pmap;
require Net::Silk::IPWildcard;
require Net::Silk::Range;
require Net::Silk::CIDR;
require Net::Silk::IPAddr;
require Net::Silk::TCPFlags;
require Net::Silk::ProtoPort;
require Net::Silk::File;
require Net::Silk::Site;
require Net::Silk::RWRec;

###

1;

__END__

=head1 NAME

Net::Silk - Interface to the SiLK network flow library

=head1 DESCRIPTION

C<Net::Silk> is a perl binding to the SiLK network flow library. SiLK
is self-described as:

  SiLK, the System for Internet-Level Knowledge, is a collection of
  traffic analysis tools developed by the CERT Network Situational
  Awareness Team (CERT NetSA) to facilitate security analysis of large
  networks. The SiLK tool suite supports the efficient collection,
  storage, and analysis of network flow data, enabling network security
  analysts to rapidly query large historical traffic data sets. SiLK is
  ideally suited for analyzing traffic on the backbone or border of a
  large, distributed enterprise or mid-sized ISP.

The SiLK suite can be L<found here.|https://tools.netsa.cert.org/silk/index.html>

=head1 EXPORTS

The following are available via the C<:basic> export tag. They
pertain to how the SiLK library was compiled:

=head2 CONSTANTS

=over

    SILK_IPV6_ENABLED
    SILK_ZLIB_ENABLED
    SILK_LZO_ENABLED
    SILK_LOCALTIME_ENABLED
    SILK_INITIAL_TCPFLAGS_ENABLED

=back

=head2 FUNCTIONS

=over

=item compression_methods()

Returns a list of available compression methods.

=item timezone_support()

Returns either "UTC" or "local" depending on how SiLK was compiled.

=back

=head1 SEE ALSO

L<Net::Silk::RWRec>, L<Net::Silk::IPSet>, L<Net::Silk::Bag>, L<Net::Silk::Pmap>, L<Net::Silk::IPWildcard>, L<Net::Silk::Range>, L<Net::Silk::CIDR>, L<Net::Silk::IPAddr>, L<Net::Silk::TCPFlags>, L<Net::Silk::ProtoPort>, L<Net::Silk::File>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
