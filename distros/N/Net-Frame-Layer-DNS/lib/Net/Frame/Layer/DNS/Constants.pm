#
# $Id: Constants.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::DNS::Constants;
use strict; use warnings;

our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_DNS_TYPE_A
      NF_DNS_TYPE_NS
      NF_DNS_TYPE_MD
      NF_DNS_TYPE_MF
      NF_DNS_TYPE_CNAME
      NF_DNS_TYPE_SOA
      NF_DNS_TYPE_MB
      NF_DNS_TYPE_MG
      NF_DNS_TYPE_MR
      NF_DNS_TYPE_NULL
      NF_DNS_TYPE_WKS
      NF_DNS_TYPE_PTR
      NF_DNS_TYPE_HINFO
      NF_DNS_TYPE_MINFO
      NF_DNS_TYPE_MX
      NF_DNS_TYPE_TXT
      NF_DNS_TYPE_RP
      NF_DNS_TYPE_AFSDB
      NF_DNS_TYPE_X25
      NF_DNS_TYPE_ISDN
      NF_DNS_TYPE_RT
      NF_DNS_TYPE_NSAP
      NF_DNS_TYPE_NSAP_PTR
      NF_DNS_TYPE_SIG
      NF_DNS_TYPE_KEY
      NF_DNS_TYPE_PX
      NF_DNS_TYPE_GPOS
      NF_DNS_TYPE_AAAA
      NF_DNS_TYPE_LOC
      NF_DNS_TYPE_NXT
      NF_DNS_TYPE_EID
      NF_DNS_TYPE_NIMLOC
      NF_DNS_TYPE_NB
      NF_DNS_TYPE_SRV
      NF_DNS_TYPE_NBSTAT
      NF_DNS_TYPE_ATMA
      NF_DNS_TYPE_NAPTR
      NF_DNS_TYPE_KX
      NF_DNS_TYPE_CERT
      NF_DNS_TYPE_A6
      NF_DNS_TYPE_DNAME
      NF_DNS_TYPE_SINK
      NF_DNS_TYPE_OPT
      NF_DNS_TYPE_APL
      NF_DNS_TYPE_DS
      NF_DNS_TYPE_SSHFP
      NF_DNS_TYPE_IPSECKEY
      NF_DNS_TYPE_RRSIG
      NF_DNS_TYPE_NSEC
      NF_DNS_TYPE_DNSKEY
      NF_DNS_TYPE_DHCID
      NF_DNS_TYPE_NSEC3
      NF_DNS_TYPE_NSEC3PARAM
      NF_DNS_TYPE_HIP
      NF_DNS_TYPE_NINFO
      NF_DNS_TYPE_RKEY
      NF_DNS_TYPE_TALINK
      NF_DNS_TYPE_SPF
      NF_DNS_TYPE_UINFO
      NF_DNS_TYPE_UID
      NF_DNS_TYPE_GID
      NF_DNS_TYPE_UNSPEC
      NF_DNS_TYPE_TKEY
      NF_DNS_TYPE_TSIG
      NF_DNS_TYPE_IXFR
      NF_DNS_TYPE_AXFR
      NF_DNS_TYPE_MAILB
      NF_DNS_TYPE_MAILA
      NF_DNS_TYPE_ALL
      NF_DNS_QTYPE_AXFR
      NF_DNS_QTYPE_MAILB
      NF_DNS_QTYPE_MAILA
      NF_DNS_QTYPE_ALL
      NF_DNS_CLASS_RESERVED
      NF_DNS_CLASS_IN
      NF_DNS_CLASS_CH
      NF_DNS_CLASS_HS
      NF_DNS_CLASS_NONE
      NF_DNS_CLASS_ANY
      NF_DNS_QCLASS_ANY
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_DNS_TYPE_A          => 1;
use constant NF_DNS_TYPE_NS         => 2;
use constant NF_DNS_TYPE_MD         => 3;
use constant NF_DNS_TYPE_MF         => 4;
use constant NF_DNS_TYPE_CNAME      => 5;
use constant NF_DNS_TYPE_SOA        => 6;
use constant NF_DNS_TYPE_MB         => 7;
use constant NF_DNS_TYPE_MG         => 8;
use constant NF_DNS_TYPE_MR         => 9;
use constant NF_DNS_TYPE_NULL       => 10;
use constant NF_DNS_TYPE_WKS        => 11;
use constant NF_DNS_TYPE_PTR        => 12;
use constant NF_DNS_TYPE_HINFO      => 13;
use constant NF_DNS_TYPE_MINFO      => 14;
use constant NF_DNS_TYPE_MX         => 15;
use constant NF_DNS_TYPE_TXT        => 16;
use constant NF_DNS_TYPE_RP         => 17;
use constant NF_DNS_TYPE_AFSDB      => 18;
use constant NF_DNS_TYPE_X25        => 19;
use constant NF_DNS_TYPE_ISDN       => 20;
use constant NF_DNS_TYPE_RT         => 21;
use constant NF_DNS_TYPE_NSAP       => 22;
use constant NF_DNS_TYPE_NSAP_PTR   => 23;
use constant NF_DNS_TYPE_SIG        => 24;
use constant NF_DNS_TYPE_KEY        => 25;
use constant NF_DNS_TYPE_PX         => 26;
use constant NF_DNS_TYPE_GPOS       => 27;
use constant NF_DNS_TYPE_AAAA       => 28;
use constant NF_DNS_TYPE_LOC        => 29;
use constant NF_DNS_TYPE_NXT        => 30;
use constant NF_DNS_TYPE_EID        => 31;
use constant NF_DNS_TYPE_NIMLOC     => 32;
use constant NF_DNS_TYPE_NB         => 32;
use constant NF_DNS_TYPE_SRV        => 33;
use constant NF_DNS_TYPE_NBSTAT     => 33;
use constant NF_DNS_TYPE_ATMA       => 34;
use constant NF_DNS_TYPE_NAPTR      => 35;
use constant NF_DNS_TYPE_KX         => 36;
use constant NF_DNS_TYPE_CERT       => 37;
use constant NF_DNS_TYPE_A6         => 38;
use constant NF_DNS_TYPE_DNAME      => 39;
use constant NF_DNS_TYPE_SINK       => 40;
use constant NF_DNS_TYPE_OPT        => 41;
use constant NF_DNS_TYPE_APL        => 42;
use constant NF_DNS_TYPE_DS         => 43;
use constant NF_DNS_TYPE_SSHFP      => 44;
use constant NF_DNS_TYPE_IPSECKEY   => 45;
use constant NF_DNS_TYPE_RRSIG      => 46;
use constant NF_DNS_TYPE_NSEC       => 47;
use constant NF_DNS_TYPE_DNSKEY     => 48;
use constant NF_DNS_TYPE_DHCID      => 49;
use constant NF_DNS_TYPE_NSEC3      => 50;
use constant NF_DNS_TYPE_NSEC3PARAM => 51;
use constant NF_DNS_TYPE_HIP        => 55;
use constant NF_DNS_TYPE_NINFO      => 56;
use constant NF_DNS_TYPE_RKEY       => 57;
use constant NF_DNS_TYPE_TALINK     => 58;
use constant NF_DNS_TYPE_SPF        => 99;
use constant NF_DNS_TYPE_UINFO      => 100;
use constant NF_DNS_TYPE_UID        => 101;
use constant NF_DNS_TYPE_GID        => 102;
use constant NF_DNS_TYPE_UNSPEC     => 103;
use constant NF_DNS_TYPE_TKEY       => 249;
use constant NF_DNS_TYPE_TSIG       => 250;
use constant NF_DNS_TYPE_IXFR       => 251;
use constant NF_DNS_TYPE_AXFR       => 252;
use constant NF_DNS_TYPE_MAILB      => 253;
use constant NF_DNS_TYPE_MAILA      => 254;
use constant NF_DNS_TYPE_ALL        => 255;
use constant NF_DNS_QTYPE_AXFR      => 252;
use constant NF_DNS_QTYPE_MAILB     => 253;
use constant NF_DNS_QTYPE_MAILA     => 254;
use constant NF_DNS_QTYPE_ALL       => 255;

use constant NF_DNS_CLASS_RESERVED  => 0;
use constant NF_DNS_CLASS_IN        => 1;
use constant NF_DNS_CLASS_CH        => 3;
use constant NF_DNS_CLASS_HS        => 4;
use constant NF_DNS_CLASS_NONE      => 254;
use constant NF_DNS_CLASS_ANY       => 255;
use constant NF_DNS_QCLASS_ANY      => 255;

1;

__END__

=head1 NAME

Net::Frame::Layer::DNS::Constants - DNS Type / Class constants

=head1 SYNOPSIS

   use Net::Frame::Layer::DNS::Constants qw(:consts);

=head1 DESCRIPTION

This modules implements the DNS Type and Class constants used in both
Query and Response.

=head1 CONSTANTS

Load them: use Net::Frame::Layer::DNS::Constants qw(:consts);

=over 4

=item B<NF_DNS_TYPE_A>

=item B<NF_DNS_TYPE_NS>

=item B<NF_DNS_TYPE_MD>

=item B<NF_DNS_TYPE_MF>

=item B<NF_DNS_TYPE_CNAME>

=item B<NF_DNS_TYPE_SOA>

=item B<NF_DNS_TYPE_MB>

=item B<NF_DNS_TYPE_MG>

=item B<NF_DNS_TYPE_MR>

=item B<NF_DNS_TYPE_NULL>

=item B<NF_DNS_TYPE_WKS>

=item B<NF_DNS_TYPE_PTR>

=item B<NF_DNS_TYPE_HINFO>

=item B<NF_DNS_TYPE_MINFO>

=item B<NF_DNS_TYPE_MX>

=item B<NF_DNS_TYPE_TXT>

=item B<NF_DNS_TYPE_RP>

=item B<NF_DNS_TYPE_AFSDB>

=item B<NF_DNS_TYPE_X25>

=item B<NF_DNS_TYPE_ISDN>

=item B<NF_DNS_TYPE_RT>

=item B<NF_DNS_TYPE_NSAP>

=item B<NF_DNS_TYPE_NSAP_PTR>

=item B<NF_DNS_TYPE_SIG>

=item B<NF_DNS_TYPE_KEY>

=item B<NF_DNS_TYPE_PX>

=item B<NF_DNS_TYPE_GPOS>

=item B<NF_DNS_TYPE_AAAA>

=item B<NF_DNS_TYPE_LOC>

=item B<NF_DNS_TYPE_NXT>

=item B<NF_DNS_TYPE_EID>

=item B<NF_DNS_TYPE_NIMLOC>

=item B<NF_DNS_TYPE_NB>

=item B<NF_DNS_TYPE_SRV>

=item B<NF_DNS_TYPE_NBSTAT>

=item B<NF_DNS_TYPE_ATMA>

=item B<NF_DNS_TYPE_NAPTR>

=item B<NF_DNS_TYPE_KX>

=item B<NF_DNS_TYPE_CERT>

=item B<NF_DNS_TYPE_A6>

=item B<NF_DNS_TYPE_DNAME>

=item B<NF_DNS_TYPE_SINK>

=item B<NF_DNS_TYPE_OPT>

=item B<NF_DNS_TYPE_APL>

=item B<NF_DNS_TYPE_DS>

=item B<NF_DNS_TYPE_SSHFP>

=item B<NF_DNS_TYPE_IPSECKEY>

=item B<NF_DNS_TYPE_RRSIG>

=item B<NF_DNS_TYPE_NSEC>

=item B<NF_DNS_TYPE_DNSKEY>

=item B<NF_DNS_TYPE_DHCID>

=item B<NF_DNS_TYPE_NSEC3>

=item B<NF_DNS_TYPE_NSEC3PARAM>

=item B<NF_DNS_TYPE_HIP>

=item B<NF_DNS_TYPE_NINFO>

=item B<NF_DNS_TYPE_RKEY>

=item B<NF_DNS_TYPE_TALINK>

=item B<NF_DNS_TYPE_SPF>

=item B<NF_DNS_TYPE_UINFO>

=item B<NF_DNS_TYPE_UID>

=item B<NF_DNS_TYPE_GID>

=item B<NF_DNS_TYPE_UNSPEC>

=item B<NF_DNS_TYPE_TKEY>

=item B<NF_DNS_TYPE_TSIG>

=item B<NF_DNS_TYPE_IXFR>

=item B<NF_DNS_TYPE_AXFR>

=item B<NF_DNS_TYPE_MAILB>

=item B<NF_DNS_TYPE_MAILA>

=item B<NF_DNS_TYPE_ALL>

=item B<NF_DNS_QTYPE_AXFR>

=item B<NF_DNS_QTYPE_MAILB>

=item B<NF_DNS_QTYPE_MAILA>

=item B<NF_DNS_QTYPE_ALL>

Type values.

=item B<NF_DNS_CLASS_RESERVED>

=item B<NF_DNS_CLASS_IN>

=item B<NF_DNS_CLASS_CH>

=item B<NF_DNS_CLASS_HS>

=item B<NF_DNS_CLASS_NONE>

=item B<NF_DNS_CLASS_ANY>

=item B<NF_DNS_QCLASS_ANY>

Class values.

=back

=head1 SEE ALSO

L<Net::Frame::Layer::DNS>, L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
