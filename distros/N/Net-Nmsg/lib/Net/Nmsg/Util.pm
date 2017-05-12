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

package Net::Nmsg::Util;

use strict;
use warnings;
use Carp;

use vars qw( @EXPORT_OK %EXPORT_TAGS );

require Exporter;

use base qw( Exporter );

# load xs (export stopped working)
#use Net::Nmsg qw( DEBUG );
use Net::Nmsg;

use IO::File;

###

my @Vendor = qw(

  vendors
  msgtypes
  vendor_lookup
  msgtype_lookup
  msgtype_id_lookup

  get_max_vid
  get_max_msgtype
  mname_to_msgtype
  msgtype_to_mname
  vid_to_vname
  vname_to_vid

);

my @Interface = qw(
  is_interface
  interfaces
  interface_descriptions
  interface_detection_error
);

my @Sniff = qw(
  is_nmsg_file
  is_pcap_file
  is_interface
  is_socket
  is_file
  is_callback
  is_channel
  is_chalias
  looks_like_socket
  parse_socket_spec
  expand_socket_spec
);

my @Alias = qw(
  NMSG_ALIAS_OPERATOR
  NMSG_ALIAS_GROUP
  alias_by_key
  alias_by_value
  operator_lookup
  group_lookup
);

###

my @Buffer = qw(
  NMSG_WBUFSZ_ETHER
  NMSG_WBUFSZ_JUMBO
  NMSG_WBUFSZ_MAX
  NMSG_WBUFSZ_MIN
  NMSG_RBUFSZ
  NMSG_RBUF_TIMEOUT
);

use constant NMSG_DEFAULT_SO_FREQ   => 100;
use constant NMSG_DEFAULT_SO_RATE   => 0;

use constant NMSG_PORT_MAXRANGE => 20;

my @Field_Types = qw(
  NMSG_FT_ENUM
  NMSG_FT_BYTES
  NMSG_FT_STRING
  NMSG_FT_MLSTRING
  NMSG_FT_IP
  NMSG_FT_UINT16
  NMSG_FT_UINT32
  NMSG_FT_UINT64
  NMSG_FT_INT16
  NMSG_FT_INT32
  NMSG_FT_INT64
  NMSG_FT_DOUBLE
  NMSG_FT_BOOL
);

my @Field_Flags = qw(
  NMSG_FF_REPEATED
  NMSG_FF_REQUIRED
  NMSG_FF_HIDDEN
  NMSG_FF_NOPRINT
);

my @Field = (
  @Field_Types,
  @Field_Flags,
  'field_types',
  'field_flags',
  'field_types_by_val',
  'field_flags_by_val',
);

my @IO = qw(
  NMSG_INPUT_TYPE
  NMSG_OUTPUT_TYPE

  NMSG_OUTPUT_TYPE_STREAM
  NMSG_OUTPUT_TYPE_PRES
  NMSG_OUTPUT_TYPE_CALLBACK

  NMSG_INPUT_TYPE_STREAM
  NMSG_INPUT_TYPE_PRES
  NMSG_INPUT_TYPE_PCAP

  NMSG_OUTPUT_MODE_STRIPE
  NMSG_OUTPUT_MODE_MIRROR

  NMSG_CLOSE_TYPE_EOF
  NMSG_CLOSE_TYPE_COUNT
  NMSG_CLOSE_TYPE_INTERVAL

  NMSG_PCAP_TYPE_FILE
  NMSG_PCAP_TYPE_LIVE

  NMSG_DEFAULT_SNAPLEN
  NMSG_DEFAULT_PROMISC

  NMSG_DEFAULT_SO_FREQ
  NMSG_DEFAULT_SO_RATE
  NMSG_DEFAULT_SO_SNDBUF
  NMSG_DEFAULT_SO_RCVBUF

  NMSG_PORT_MAXRANGE
);

use constant NMSG_DEFAULT_PROMISC   => 0;
use constant NMSG_DEFAULT_SO_SNDBUF => 4 * 1048576;
use constant NMSG_DEFAULT_SO_RCVBUF => 4 * 1048576;

my @Result = qw(
  NMSG_RES_SUCCESS
  NMSG_RES_FAILURE
  NMSG_RES_EOF
  NMSG_RES_MEMFAIL
  NMSG_RES_MAGIC_MISMATCH
  NMSG_RES_VERSION_MISMATCH
  NMSG_RES_PBUF_READY
  NMSG_RES_NOTIMPL
  NMSG_RES_STOP
  NMSG_RES_AGAIN
  NMSG_RES_PARSE_ERROR
  NMSG_RES_PCAP_ERROR
  NMSG_RES_READ_FAILURE

  nmsg_lookup_result
);

###

my @Channel = qw(
  is_channel
  channel_lookup
  is_chalias
  chalias_lookup
);

###

my %All;
++$All{$_} for (
  @Buffer,
  @Field,
  @Interface,
  @IO,
  @Sniff,
  @Result,
  @Vendor,
  @Channel,
  @Alias,
  'DEBUG',
);

@EXPORT_OK = keys %All;

%EXPORT_TAGS = (
  all     => \@EXPORT_OK,
  buffer  => \@Buffer,
  field   => \@Field,
  iface   => \@Interface,
  io      => \@IO,
  result  => \@Result,
  sniff   => \@Sniff,
  vendor  => \@Vendor,
  channel => \@Channel,
  chalias => \@Channel,
  alias   => \@Alias,
);

### field descriptors

sub field_types {
  my %types;
  for my $f (@Field_Types) {
    $types{$f} = eval "$f()";
  }
  wantarray ? %types : \%types;
}

sub field_flags {
  my %flags;
  for my $f (@Field_Flags) {
    $flags{$f} = eval "$f()";
  }
  wantarray ? %flags : \%flags;
}

sub field_types_by_val {
  my %types;
  for my $f (@Field_Types) {
    my $v = eval "$f()";
    $types{$v} = $f;
  }
  wantarray ? %types : \%types;
}

sub field_flags_by_val {
  my %flags;
  for my $f (@Field_Flags) {
    my $v = eval "$f()";
    $flags{$v} = $f;
  }
  wantarray ? %flags : \%flags;
}

### iface

my(%Devs, $Dev_Error, $Devs_Loaded);

sub _init_devs {
  eval { %Devs = find_all_devs() };
  $Dev_Error = $@ || '';
  if (! %Devs && ! $Dev_Error) {
    $Dev_Error = "no interfaces found (need root privs?)";
  }
  delete $Devs{any};
  ++$Devs_Loaded;
}

sub interface_detection_error {
  _init_devs unless $Devs_Loaded;
  $Dev_Error;
}

sub is_interface {
  _init_devs unless $Devs_Loaded;
  @_ && exists $Devs{shift()};
}

sub interfaces {
  _init_devs unless $Devs_Loaded;
  sort keys %Devs;
}

sub interface_descriptions {
  _init_devs unless $Devs_Loaded;
  wantarray ? %Devs : { %Devs };
}

### channel aliases

*channel_lookup = *is_channel = *is_chalias = \&chalias_lookup;

### alias

sub _alias_lookup {
  @_ || croak "alias type required";
  my $type = shift;
  my($id, $alias);
  if (my $v = shift) {
    if ($v =~ /^\d+$/) {
      if ($alias = alias_by_key($type, $v) || '') {
        $id = $v;
      }
      else {
        $id = 0;
      }
    }
    else {
      if ($id = alias_by_value($type, $v) || 0) {
        $alias = $v;
      }
      else {
        $alias = '';
      }
    }
  }
  else {
    ($id, $alias) = (0, '');
  }
  ($id, $alias);
}

sub operator_lookup { _alias_lookup(NMSG_ALIAS_OPERATOR, @_) }
sub group_lookup    { _alias_lookup(NMSG_ALIAS_GROUP,    @_) }

### vendor modules

sub vendors {
  my @names;
  for my $vid (1 .. get_max_vid()) {
    my $name = vid_to_vname($vid);
    push(@names, $name) if defined $name;
  }
  wantarray ? @names : \@names;
}

sub msgtypes {
  my %vendors;
  for my $vid (1 .. get_max_vid()) {
    my $vname = vid_to_vname($vid);
    next unless defined $vname;
    my $msgs = $vendors{$vname} = [];
    for my $mid (1 .. get_max_msgtype($vid)) {
      my $mname = msgtype_to_mname($vid, $mid);
      push(@$msgs, $mname) if defined $mname;
    }
  }
  wantarray ? %vendors : \%vendors;
}

sub _dump_msgtypes {
  my @dump;
  for my $vid (1 .. get_max_vid()) {
    my $vname = vid_to_vname($vid);
    next unless defined $vname;
    for my $mid (1 .. get_max_msgtype($vid)) {
      my $mname = msgtype_to_mname($vid, $mid);
      next unless defined $mname;
      push(@dump, [$vid, $mid, $vname, $mname]);
    }
  }
  wantarray ? @dump : \@dump;
}

# _msgtype_lookup() defined in Nmsg.pm for XS bootstrapping purposes

sub msgtype_lookup {
  my($vid, $mid, $vname, $mname) = _msgtype_lookup(@_);
  wantarray ? ($vname, $mname) : [$vname, $mname];
}

sub msgtype_id_lookup {
  my($vid, $mid, $vname, $mname) = _msgtype_lookup(@_);
  wantarray ? ($vid, $mid) : [$vid, $mid];
}

sub msgmod_lookup {
  my($vid, $mid, $vname, $mname) = _msgtype_lookup(@_);
  _msgmod_lookup($vid, $mid);
}

### sniff

sub is_nmsg_file {
  my $file = shift;
  return unless defined $file && -f $file && -s _;
  my $fh = IO::File->new($file, 'r') || return;
  eval { Net::Nmsg::XS::input->open_file($fh)->read };
  return 1 unless $@;
  die $@ unless $@ =~ /nmsg_input_read.*failed/i;
  0;
}

sub is_pcap_file {
  my $file = shift;
  return unless defined $file && -f $file && -s _;
  eval { Net::Nmsg::XS::pcap->open_offline($file) };
  return 1 unless $@;
  die $@ unless $@ =~ /pcap.*failed/i;
  0;
}

sub is_socket { @_ && -S shift }

sub is_file   { @_ && -f shift }

sub is_callback { @_ && ref $_[0] && ref $_[0] eq 'CODE' }

sub is_filehandle { @_ && ref $_[0] && defined(fileno($_[0])) }

sub looks_like_socket {
  return 0 unless @_;
  return 0 if is_callback(@_);
  return 1 if is_socket(@_);
  return 1 if expand_socket_spec(@_);
  return 0;
}

sub parse_socket_spec {
  # return ($host, $port) on success
  my $spec = shift || return;
  my $sep;
  if ($spec =~ tr/:/:/ == 1) {
    # ipv4 style
    return $spec =~ m{^([^:]+)[:/](\d+)$};
  }
  else {
    # possibly ipv6 or '/' delimited
    return $spec =~ m{^([^/]+)[/](\d+)$};
  }
}

sub expand_socket_spec {
  my $spec = shift || return;
  my $hi;
  $hi = $1 if $spec =~ s/\.\.(\d+)$//;
  my($host, $lo) = parse_socket_spec($spec);
  return unless defined $host;
  $hi = $lo unless defined $hi;
  ($lo, $hi) = sort { $a <=> $b } ($lo, $hi);
  if ($hi - $lo > NMSG_PORT_MAXRANGE) {
    croak sprintf("port range (%d) exceeded (%d..%d)",
                  NMSG_PORT_MAXRANGE, $lo, $hi);
  }
  my @specs;
  for my $port ($lo .. $hi) {
    push(@specs, "$host/$port");
  }
  @specs;
}

1;

__END__

=pod

=head1 NAME

Net::Nmsg::Util - Perl extension for the NMSG message interchange library

=head1 SYNOPSIS

  # Provide access to constants, data types, and various utility
  # functions in, or relating to, the nmsg library

  use Net::Nmsg::Util qw(
    :all
    :buffer
    :field
    :iface
    :io
    :result
    :sniff
    :vendor
    :channel
    :alias
    DEBUG
  );


=head1 DESCRIPTION

Net::Nmsg::Util exposes constants, data types, and functions of libnmsg.
These are primarily intended for development purposes rather than
typical usage.

=head1 EXPORTED CONSTANTS AND FUNCTIONS

Functions and constants being individually exportable. To export
everything, use ':all'. The following tag groups are also available:

=head2 Tag group :channel

=over 4

=item is_channel($channel)

=item channel_lookup($channel)

=back


=head2 Tag group :alias

  NMSG_ALIAS_OPERATOR
  NMSG_ALIAS_GROUP

  alias_by_key($key)
  alias_by_value($val)
  operator_lookup($name_or_val)
  group_lookup($name_or_val)


=head2 Tag group :sniff

  is_nmsg_file($name)
  is_pcap_file($name)
  is_interface($name)
  is_socket($handle)
  is_file($handle_or_name)
  is_filehandle($handle)
  is_channel($channel)
  expand_socket_spec($spec)


=head2 Tag group :vendor

  vendor_lookup($vendor_name_or_id)
  message_lookup($msg_type_or_id)
  mv_lookup($vendor_name_or_id, $msg_type_or_id)
  vendors()

  get_max_vid()
  get_max_msgtype($vid)
  mname_to_msgtype($vid, $name)
  msgtype_to_mname($vid, $msgtype)
  vname_to_vid($name)
  vid_to_vname($vid)


=head2 Tag group :iface

Note that some of these, such as interfaces(), rely upon libpcap(3).
As such, root privileges are likely necessary for them to be useful.

  is_interface($name)
  interfaces()
  interface_descriptions()
  interface_detection_error()


=head2 Tag group :buffer

  NMSG_WBUFSZ_ETHER
  NMSG_WBUFSZ_JUMBO
  NMSG_WBUFSZ_MAX
  NMSG_WBUFSZ_MIN

=head2 Tag group :field

  NMSG_FT_ENUM
  NMSG_FT_BYTES
  NMSG_FT_STRING
  NMSG_FT_MLSTRING
  NMSG_FT_IP
  NMSG_FT_UINT16
  NMSG_FT_UINT32
  NMSG_FT_UINT64
  NMSG_FT_INT16
  NMSG_FT_INT32
  NMSG_FT_INT64
  NMSG_FT_DOUBLE
  NMSG_FT_BOOL

  NMSG_FF_REPEATED
  NMSG_FF_REQUIRED
  NMSG_FF_NOPRINT
  NMSG_FF_HIDDEN

  field_types()
  field_flags()


=head2 Tag group :io

  NMSG_INPUT_TYPE
  NMSG_OUTPUT_TYPE

  NMSG_OUTPUT_TYPE_STREAM
  NMSG_OUTPUT_TYPE_PRES
  NMSG_OUTPUT_TYPE_CALLBACK

  NMSG_INPUT_TYPE_STREAM
  NMSG_INPUT_TYPE_PRES
  NMSG_INPUT_TYPE_PCAP

  NMSG_OUTPUT_MODE_STRIPE
  NMSG_OUTPUT_MODE_MIRROR

  NMSG_CLOSE_TYPE_EOF
  NMSG_CLOSE_TYPE_COUNT
  NMSG_CLOSE_TYPE_INTERVAL

  NMSG_DEFAULT_SNAPLEN
  NMSG_DEFAULT_PROMISC

  NMSG_DEFAULT_SO_FREQ
  NMSG_DEFAULT_SO_RATE
  NMSG_DEFAULT_SO_SNDBUF
  NMSG_DEFAULT_SO_RCVBUF

  NMSG_PORT_MAXRANGE


=head2 Tag group :result

  NMSG_RES_SUCCESS
  NMSG_RES_FAILURE
  NMSG_RES_EOF
  NMSG_RES_MEMFAIL
  NMSG_RES_MAGIC_MISMATCH
  NMSG_RES_VERSION_MISMATCH
  NMSG_RES_PBUF_READY
  NMSG_RES_NOTIMPL
  NMSG_RES_STOP
  NMSG_RES_AGAIN
  NMSG_RES_PARSE_ERROR
  NMSG_RES_PCAP_ERROR
  NMSG_RES_READ_FAILURE

  lookup_result($result_id)


=head1 SEE ALSO

L<Net::Nmsg>, L<Net::Nmsg::IO>, L<Net::Nmsg::Input>, L<Net::Nmsg::Output>, L<nmsgtool(3)>


=head1 AUTHOR

Matthew Sisk, E<lt>sisk@cert.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010-2015 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
