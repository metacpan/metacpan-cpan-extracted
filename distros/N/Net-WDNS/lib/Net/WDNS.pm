# Copyright (C) 2010 by Carnegie Mellon University
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, as published by
# the Free Software Foundation, under the terms pursuant to Version 2,
# June 1991.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

package Net::WDNS;

use 5.004_04;
use strict;
use warnings;
use Carp;

use vars qw( @EXPORT_OK %EXPORT_TAGS $VERSION );

require Exporter;
require DynaLoader;

use base qw( Exporter DynaLoader );

use ExtUtils::Liblist;
use File::Spec;

sub dl_load_flags { 0x01 } # global option

BEGIN {
  $VERSION = '1.01';
  bootstrap Net::WDNS $VERSION;
}

my $Debug;

sub DEBUG { @_ ? $Debug = shift : $Debug }

DEBUG(0);

use constant NMSG_LIB_NAME => 'nmsg';

sub wdns_have_library {
  my $libname = shift;
  my $libs;
  my $seen = 1;
  {
    local $SIG{__WARN__} = sub {};
    $libs = ExtUtils::Liblist->ext("-l$libname", 1, 1);
  }
  return unless ref $libs && @$libs;
  $libs->[0];
}

###

sub parse_message {
  @_ || croak("raw dns pkt required");
  bless[parse_message_raw(shift)], 'Net::WDNS::Msg';
}

###

my %Func;
++$Func{$_} foreach (qw(
  len_name
  reverse_name
  left_chop
  count_labels
  is_subdomain
  opcode_to_str
  rcode_to_str
  str_to_rcode
  rrclass_to_str
  str_to_rrclass
  rrtype_to_str
  domain_to_str
  rdata_to_str
  str_to_rdata
  str_to_rrtype
  str_to_name
  str_to_name_case
  message_to_str
  parse_message

  parse_message_raw
  clear_message

  get_id
  get_flags
  get_rcode
  get_opcode
  get_section
));

my %Const;
++$Const{$_} foreach (qw(
  WDNS_LEN_HEADER
  WDNS_MAXLEN_NAME
  
  WDNS_MSG_SEC_QUESTION
  WDNS_MSG_SEC_ANSWER
  WDNS_MSG_SEC_AUTHORITY
  WDNS_MSG_SEC_ADDITIONAL
  WDNS_MSG_SEC_MAX
  
  WDNS_PRESLEN_NAME
  WDNS_PRESLEN_TYPE_A
  WDNS_PRESLEN_TYPE_AAAA
  
  WDNS_OP_QUERY
  WDNS_OP_IQUERY
  WDNS_OP_STATUS
  WDNS_OP_NOTIFY
  WDNS_OP_UPDATE
  
  WDNS_R_NOERROR
  WDNS_R_FORMERR
  WDNS_R_SERVFAIL
  WDNS_R_NXDOMAIN
  WDNS_R_NOTIMP
  WDNS_R_REFUSED
  WDNS_R_YXDOMAIN
  WDNS_R_YXRRSET
  WDNS_R_NXRRSET
  WDNS_R_NOTAUTH
  WDNS_R_NOTZONE
  WDNS_R_BADVERS
  
  WDNS_CLASS_IN
  WDNS_CLASS_CH
  WDNS_CLASS_HS
  WDNS_CLASS_NONE
  WDNS_CLASS_ANY
  
  WDNS_TYPE_A
  WDNS_TYPE_NS
  WDNS_TYPE_MD
  WDNS_TYPE_MF
  WDNS_TYPE_CNAME
  WDNS_TYPE_SOA
  WDNS_TYPE_MB
  WDNS_TYPE_MG
  WDNS_TYPE_MR
  WDNS_TYPE_NULL
  WDNS_TYPE_WKS
  WDNS_TYPE_PTR
  WDNS_TYPE_HINFO
  WDNS_TYPE_MINFO
  WDNS_TYPE_MX
  WDNS_TYPE_TXT
  WDNS_TYPE_RP
  WDNS_TYPE_AFSDB
  WDNS_TYPE_X25
  WDNS_TYPE_ISDN
  WDNS_TYPE_RT
  WDNS_TYPE_NSAP
  WDNS_TYPE_NSAP_PTR
  WDNS_TYPE_SIG
  WDNS_TYPE_KEY
  WDNS_TYPE_PX
  WDNS_TYPE_GPOS
  WDNS_TYPE_AAAA
  WDNS_TYPE_LOC
  WDNS_TYPE_NXT
  WDNS_TYPE_EID
  WDNS_TYPE_NIMLOC
  WDNS_TYPE_SRV
  WDNS_TYPE_ATMA
  WDNS_TYPE_NAPTR
  WDNS_TYPE_KX
  WDNS_TYPE_CERT
  WDNS_TYPE_A6
  WDNS_TYPE_DNAME
  WDNS_TYPE_SINK
  WDNS_TYPE_OPT
  WDNS_TYPE_APL
  WDNS_TYPE_DS
  WDNS_TYPE_SSHFP
  WDNS_TYPE_IPSECKEY
  WDNS_TYPE_RRSIG
  WDNS_TYPE_NSEC
  WDNS_TYPE_DNSKEY
  WDNS_TYPE_DHCID
  WDNS_TYPE_NSEC3
  WDNS_TYPE_NSEC3PARAM
  WDNS_TYPE_TLSA

  WDNS_TYPE_HIP
  WDNS_TYPE_NINFO
  WDNS_TYPE_RKEY
  WDNS_TYPE_TALINK
  WDNS_TYPE_CDS
  WDNS_TYPE_CDNSKEY
  WDNS_TYPE_OPENPGPKEY
  WDNS_TYPE_CSYNC

  WDNS_TYPE_SPF
  WDNS_TYPE_UINFO
  WDNS_TYPE_UID
  WDNS_TYPE_GID
  WDNS_TYPE_UNSPEC
  WDNS_TYPE_NID
  WDNS_TYPE_L32
  WDNS_TYPE_L64
  WDNS_TYPE_LP
  WDNS_TYPE_EUI48
  WDNS_TYPE_EUI64

  WDNS_TYPE_TKEY
  WDNS_TYPE_TSIG
  WDNS_TYPE_IXFR
  WDNS_TYPE_AXFR
  WDNS_TYPE_MAILB
  WDNS_TYPE_MAILA
  WDNS_TYPE_ANY
  WDNS_TYPE_URI
  WDNS_TYPE_CAA
  WDNS_TYPE_TA
  WDNS_TYPE_DLV


));

###

our @EXPORT_OK = (
  'DEBUG',
  keys %Func,
  keys %Const,
);

our %EXPORT_TAGS = (
  all   => \@EXPORT_OK,
  func  => [keys %Func],
  const => [keys %Const],
);

require Net::WDNS::Msg;
require Net::WDNS::Question;
require Net::WDNS::RD;
require Net::WDNS::RR;

###############################################################################

1;

__END__

=pod

=head1 NAME

Net::WDNS - Perl extension for the wdns low-level DNS library

=head1 SYNOPSIS

  # The primary interface to libwdns is through Net::WDNS::Msg objects:

  use Net::WDNS qw(:func);

  for my $pkt (@pkt_source) {
    my $msg = parse_message($pkt); # same as Net::WDNS::Msg->new($pkt)
    print $msg->as_str, "\n" if $msg->flags->{aa}; # or print "$msg\n"
  }

=head1 DESCRIPTION

Net::WDNS is a perl binding to libwdns, the low-level DNS library.
The library is designed to parse, examine, and render raw DNS packets.  

Net::WDNS exports functions and constants from libwdns. Typically
interactions with the library will be through the parse_message()
function and, subsequently, L<Net::Nmsg::Msg> objects. The rest of the
functions exported here are provided for development purposes.

=head1 EXPORTED CONSTANTS AND FUNCTIONS

Functions and constants are individually exportable. To export
everything, use ':all'. When functions describe dealing with "raw"
formats, it means formatted for over the wire. The following tag groups
are also available:

=head2 Tag group :func

=over 4

=item parse_message($pkt)

=item message_to_str($raw_msg)

Convert a raw message type to a human-readable string.

=item domain_to_str($raw_domain)

Convert a raw domain name to a human-readable string.

=item opcode_to_str($int)

Convert a numeric opcode to a descriptive string.

=item rcode_to_str($int)

Convert a numeric rcode to a descriptive string.

=item str_to_rcode($str)

Convert a string description of an rcode to its numeric equivalent.

=item rrclass_to_str($int)

Convert a numeric rrclass to a descriptive string.

=item str_to_rrclass($str)

Convert a string description of rrclass to its numeric equivalent.

=item rrtype_to_str($int)

Convert a numeric rrtype to a descriptive string. See also
C<str_to_rrtype()>.

=item rdata_to_str($raw_rdata, $rrtype, $rrclass)

Convert a raw rdata type to a human-readable string.

=item str_to_rdata($str, $rrtype, $rrclass)

Convert a string representation of an rdata type to raw format.

=item str_to_rrtype($str)

Convert a string to a raw rrtype. See also C<rrtype_to_str()>.

=item str_to_name($str)

Convert a string to a raw domain. See also C<domain_to_str()>.

=item str_to_name_case($str)

Convert a string to a raw domain, preserving case.

=item len_name($raw_domain)

Return the length of a raw (uncompressed wire format) domain name.

=item reverse_name($raw_domain)

Return a reversed raw domain.

=item left_chop($raw_domain)

Return a raw domain with the leftmost domain component (label) removed.

=item count_labels($raw_domain)

Return the number of components in a raw domain.

=item is_subdomain($raw_domain1, $raw_domain2)

Return whether or not the first raw domain is a sub-domain of the second.

=item clear_message($raw_msg)

Free the memory assosciated with the raw msg. This normally happens
during the C<DESTROY()> call to a L<Net::WDNS::Msg> object.

=item get_id($raw_msg)

Return the numeric id of a raw msg.

=item get_flags($raw_msg)

Return the bit-encoded flags of a raw msg.

=item get_rcode($raw_msg)

Return the numeric rcode of a raw msg.

=item get_opcode($raw_msg)

Return the numeric opcode of a raw msg.

=item get_section($raw_msg)

Return the section (0-3) of a raw msg as an array of blessed objects
(L<Net::Nmsg::Question> or L<Net::Nmsg::RR>)

=back

=head2 Tag group :const

  WDNS_LEN_HEADER
  WDNS_MAXLEN_NAME
  
  WDNS_MSG_SEC_QUESTION
  WDNS_MSG_SEC_ANSWER
  WDNS_MSG_SEC_AUTHORITY
  WDNS_MSG_SEC_ADDITIONAL
  WDNS_MSG_SEC_MAX
  
  WDNS_PRESLEN_NAME
  WDNS_PRESLEN_TYPE_A
  WDNS_PRESLEN_TYPE_AAAA
  
  WDNS_OP_QUERY
  WDNS_OP_IQUERY
  WDNS_OP_STATUS
  WDNS_OP_NOTIFY
  WDNS_OP_UPDATE
  
  WDNS_R_NOERROR
  WDNS_R_FORMERR
  WDNS_R_SERVFAIL
  WDNS_R_NXDOMAIN
  WDNS_R_NOTIMP
  WDNS_R_REFUSED
  WDNS_R_YXDOMAIN
  WDNS_R_YXRRSET
  WDNS_R_NXRRSET
  WDNS_R_NOTAUTH
  WDNS_R_NOTZONE
  WDNS_R_BADVERS
  
  WDNS_CLASS_IN
  WDNS_CLASS_CH
  WDNS_CLASS_HS
  WDNS_CLASS_NONE
  WDNS_CLASS_ANY
  
  WDNS_TYPE_A
  WDNS_TYPE_NS
  WDNS_TYPE_MD
  WDNS_TYPE_MF
  WDNS_TYPE_CNAME
  WDNS_TYPE_SOA
  WDNS_TYPE_MB
  WDNS_TYPE_MG
  WDNS_TYPE_MR
  WDNS_TYPE_NULL
  WDNS_TYPE_WKS
  WDNS_TYPE_PTR
  WDNS_TYPE_HINFO
  WDNS_TYPE_MINFO
  WDNS_TYPE_MX
  WDNS_TYPE_TXT
  WDNS_TYPE_RP
  WDNS_TYPE_AFSDB
  WDNS_TYPE_X25
  WDNS_TYPE_ISDN
  WDNS_TYPE_RT
  WDNS_TYPE_NSAP
  WDNS_TYPE_NSAP_PTR
  WDNS_TYPE_SIG
  WDNS_TYPE_KEY
  WDNS_TYPE_PX
  WDNS_TYPE_GPOS
  WDNS_TYPE_AAAA
  WDNS_TYPE_LOC
  WDNS_TYPE_NXT
  WDNS_TYPE_EID
  WDNS_TYPE_NIMLOC
  WDNS_TYPE_SRV
  WDNS_TYPE_ATMA
  WDNS_TYPE_NAPTR
  WDNS_TYPE_KX
  WDNS_TYPE_CERT
  WDNS_TYPE_A6
  WDNS_TYPE_DNAME
  WDNS_TYPE_SINK
  WDNS_TYPE_OPT
  WDNS_TYPE_APL
  WDNS_TYPE_DS
  WDNS_TYPE_SSHFP
  WDNS_TYPE_IPSECKEY
  WDNS_TYPE_RRSIG
  WDNS_TYPE_NSEC
  WDNS_TYPE_DNSKEY
  WDNS_TYPE_DHCID
  WDNS_TYPE_NSEC3
  WDNS_TYPE_NSEC3PARAM
  WDNS_TYPE_HIP
  WDNS_TYPE_NINFO
  WDNS_TYPE_RKEY
  WDNS_TYPE_TALINK
  WDNS_TYPE_CDS
  WDNS_TYPE_SPF
  WDNS_TYPE_TKEY
  WDNS_TYPE_TSIG
  WDNS_TYPE_IXFR
  WDNS_TYPE_AXFR
  WDNS_TYPE_MAILB
  WDNS_TYPE_MAILA
  WDNS_TYPE_ANY
  WDNS_TYPE_URI
  WDNS_TYPE_CAA
  WDNS_TYPE_TA
  WDNS_TYPE_DLV

=head1 SEE ALSO

L<Net::WDNS::Msg>, L<Net::WDNS::Question>, L<Net::WDNS::RD>, L<Net::WDNS::RR>, L<Net::Nmsg>

The wdns library can be downloaded from: https://github.com/farsightsec/wdns

=head1 AUTHOR

Matthew Sisk, E<lt>sisk@cert.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2016 by Carnegie Mellon University

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License, as published by
the Free Software Foundation, under the terms pursuant to Version 2,
June 1991.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

=cut
