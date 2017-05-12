# Use of the Net-BGPdump library and related source code is subject to
# the terms of the following licenses:
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

package Net::BGPdump;

use strict;
use warnings;
use Carp;

use vars qw( $VERSION @EXPORT_OK %EXPORT_TAGS );

use base qw( Exporter DynaLoader );

BEGIN {
  $VERSION = "2.03";
  bootstrap Net::BGPdump $VERSION;
  __PACKAGE__->log_to_stderr(1);
}

###

my @Constants = qw(

  BGPDUMP_TYPE_MRTD_BGP
  BGPDUMP_TYPE_MRTD_TABLE_DUMP
  BGPDUMP_TYPE_TABLE_DUMP_V2
  BGPDUMP_TYPE_ZEBRA_BGP

  BGPDUMP_SUBTYPE_MRTD_BGP_NULL
  BGPDUMP_SUBTYPE_MRTD_BGP_UPDATE
  BGPDUMP_SUBTYPE_MRTD_BGP_PREFUPDATE
  BGPDUMP_SUBTYPE_MRTD_BGP_STATE_CHANGE
  BGPDUMP_SUBTYPE_MRTD_BGP_SYNC
  BGPDUMP_SUBTYPE_MRTD_BGP_OPEN
  BGPDUMP_SUBTYPE_MRTD_BGP_NOTIFICATION
  BGPDUMP_SUBTYPE_MRTD_BGP_KEEPALIVE
  BGPDUMP_SUBTYPE_MRTD_BGP_ROUT_REFRESH

  BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6
  BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6_32BIT_AS
  BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP
  BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP_32BIT_AS

  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_PEER_INDEX_TABLE
  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV4_UNICAST
  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV4_MULTICAST
  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV6_UNICAST
  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV6_MULTICAST
  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_GENERIC
  BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AFI_IP
  BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AFI_IP6
  BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AS2
  BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AS4

  BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE
  BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE_AS4
  BGPDUMP_SUBTYPE_ZEBRA_BGP_STATE_CHANGE
  BGPDUMP_SUBTYPE_ZEBRA_BGP_STATE_CHANGE_AS4

  BGP_STATE_IDLE
  BGP_STATE_CONNECT
  BGP_STATE_ACTIVE
  BGP_STATE_OPENSENT
  BGP_STATE_OPENCONFIRM
  BGP_STATE_ESTABLISHED

  BGP_MSG_UPDATE
  BGP_MSG_OPEN
  BGP_MSG_NOTIFY
  BGP_MSG_KEEPALIVE
  BGP_MSG_ROUTE_REFRESH_01
  BGP_MSG_ROUTE_REFRESH

);

my %All;
++$All{$_} for (@Constants);

@EXPORT_OK = keys %All;

%EXPORT_TAGS = (
  all   => \@EXPORT_OK,
  const => \@Constants,
);

###

use overload
  '<>'     => \&read_msg,
  fallback => 1;

my %Defaults = (
  ipv4            => 1,
  ipv6            => 1,
  begin_time      => 0,
  end_time        => 0,
);

my %Attr;

sub open {
  my $class = shift;
  my $file  = shift;
  -f $file || croak "file does not exist: $file\n";
  my %arg = @_;
  my %opt = %Defaults;
  for my $k (keys %arg) {
    croak "unknown option '$k'" unless defined $opt{$k};
    $opt{$k} = $arg{$k} if defined $arg{$k};
  }
  if ($opt{ipv6}) {
    if ($opt{ipv4}) {
      $opt{ipv6_flag} = 0;
    }
    else {
      $opt{ipv6_flag} = 1;
    }
  }
  else {
    $opt{ipv6_flag} = -1;
  }
  my $self = $class->_open($file);
  $Attr{$self} = \%opt;
  $self;
}

sub DESTROY {
  my $self = shift;
  delete $Attr{$self};
  $self->_destroy();
}

sub read {
  my $self = shift;
  my $attr = $Attr{$self};
  my $entry = filter_read(
    $self,
    $attr->{ipv6_flag},
    $attr->{begin_time},
    $attr->{end_time},
  );
  $entry || ();
}

sub read_msg {
  my $self = shift;
  my $attr = $Attr{$self};
  my $entry = filter_message_read(
    $self,
    $attr->{ipv6_flag},
    $attr->{begin_time},
    $attr->{end_time},
  );
  $entry || ();
}

###

1;

__END__

=pod

=head1 NAME

Net::BGPdump - Perl extension for libBGPdump

=head1 SYNOPSIS

  use Net::BGPdump qw( :all );

  my $io = Net::BGPdump->open($file);

  while (<$io>) {
    next unless $_->{type_id} == BGP_MSG_UPDATE;
    print "TIME: $_->{time}\n";
    print "TYPE: $_->{type}\n";
    printf("FROM: %s AS%d\n", $_->{peer_addr}, $_->{peer_as});
    printf("TO: %s AS%d\n", $_->{dest_addr}, $_->{dest_as});
    print "ORIGIN: $_->{origin}\n";
    print "ASPATH: $_->{as_path}\n";
    print "NEXT_HOP: $_->{next_hop}\n";
    if ($_->{announce}) {
      print "ANNOUNCE\n";
      for my $cidr (@{$_->{announce}}) {
        print "  $cidr\n";
      }
    }
    if ($_->{withdraw}) {
      print "WITHDRAW\n";
      for my $cidr (@{$_->{withdraw}}) {
        print "  $cidr\n";
      }
    }
  }

=head1 DESCRIPTION

Net::PGPDump is a perl extension for libBGPdump, a C library designed to
help with analyzing dump files produced by Zebra/Quagga or MRT. These
include update files as well as table dump (or RIB) files.

The bgpdump library can be L<found here:|https://bitbucket.org/ripencc/bgpdump/>

=head1 METHODS

The following methods are available to IO objects:

=over

=item open($filename, %opts)

Opens a bgpdump file produced by Zebra/Quagga or MRT and returns a
C<Net::BGPdump> IO object. Files can be uncompressed, gzip or bzip2. Use
a filename of '-' for reading STDIN.

The following keyword filtering options are accepted. The constants used
for these options are exported via the C<:const> or C<:all> export tags,
or individually.

=over

=item ipv6

Include or exclude records involving IPv6 (default: 1)

=item ipv4

Include or exclude records involving IPv4 (default: 1)

=item begin_time

=item end_time

Exclude records with timestamps < begin_time or >= end_time.

=back

B<Note:> opening and handling more than one table dump file (as opposed
to update files) will likely cause problems. See the BUGS section below
for more information.

=item close()

Close the C<Net::BGPdump> IO object.

=item read()

Return the next record as a hash reference. Records are possibly subject
to filtering on ipv6 or time as specified in the C<open()> constructor.

=item read_msg()

Return the next update record as a hash reference. This limits records
to either MRTD or ZEBRA messages and discards things such as keepalive
records.  Records are possibly subject to filtering on ipv6 or time as
specified in the C<open()> constructor.

=item closed()

Return whether or not the file has been closed.

=item eof()

Return whether or not the end of the file has been reached.

=item filename()

Return the filename this IO object is reading.

=item file_type()

Return the type of file this IO object has opened: 'uncompressed',
'bzip2', or 'gzip'.

=item records()

Return the total number of records read so far from the file.

=item parsed_fail()

Return the number of records that have failed to parse so far.

=item parsed_ok()

Return the number of records successfully poarsed so far.

=back

=head1 OPERATORS

IO objects can be used as filehandles, so C<E<lt>$ioE<gt>> works as
though C<read_msg()> was called.

=head1 ADDITIONAL CONSTANTS

Record types:

  BGPDUMP_TYPE_MRTD_BGP
  BGPDUMP_TYPE_MRTD_TABLE_DUMP
  BGPDUMP_TYPE_TABLE_DUMP_V2
  BGPDUMP_TYPE_ZEBRA_BGP

Record subtypes:

  BGPDUMP_SUBTYPE_MRTD_BGP_NULL
  BGPDUMP_SUBTYPE_MRTD_BGP_UPDATE
  BGPDUMP_SUBTYPE_MRTD_BGP_PREFUPDATE
  BGPDUMP_SUBTYPE_MRTD_BGP_STATE_CHANGE
  BGPDUMP_SUBTYPE_MRTD_BGP_SYNC
  BGPDUMP_SUBTYPE_MRTD_BGP_OPEN
  BGPDUMP_SUBTYPE_MRTD_BGP_NOTIFICATION
  BGPDUMP_SUBTYPE_MRTD_BGP_KEEPALIVE
  BGPDUMP_SUBTYPE_MRTD_BGP_ROUT_REFRESH

  BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6
  BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP6_32BIT_AS
  BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP
  BGPDUMP_SUBTYPE_MRTD_TABLE_DUMP_AFI_IP_32BIT_AS

  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_PEER_INDEX_TABLE
  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV4_UNICAST
  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV4_MULTICAST
  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV6_UNICAST
  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_IPV6_MULTICAST
  BGPDUMP_SUBTYPE_TABLE_DUMP_V2_RIB_GENERIC
  BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AFI_IP
  BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AFI_IP6
  BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AS2
  BGPDUMP_PEERTYPE_TABLE_DUMP_V2_AS4

  BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE
  BGPDUMP_SUBTYPE_ZEBRA_BGP_MESSAGE_AS4
  BGPDUMP_SUBTYPE_ZEBRA_BGP_STATE_CHANGE
  BGPDUMP_SUBTYPE_ZEBRA_BGP_STATE_CHANGE_AS4

Message types:

  BGP_MSG_UPDATE
  BGP_MSG_OPEN
  BGP_MSG_NOTIFY
  BGP_MSG_KEEPALIVE
  BGP_MSG_ROUTE_REFRESH_01
  BGP_MSG_ROUTE_REFRESH

The following constants can also be exported:

  BGP_STATE_IDLE
  BGP_STATE_CONNECT
  BGP_STATE_ACTIVE
  BGP_STATE_OPENSENT
  BGP_STATE_OPENCONFIRM
  BGP_STATE_ESTABLISHED

=head1 BUGS

* Opening and reading more than one table dump file (as opposed to mere
  update files) will likely cause a segfault since libbgpdump uses a
  single global index table each time a file of that type is opened and
  frees the structure whenever one of the files is closed, even if the
  other one is still using the index table.

* Corrupt files will cause perl to silently abort when a bad record
  is encountered and cannot be caught using eval(). This happens when
  libbgpdump attempts to call the err() function -- there is some sort
  of name collision with the perl library. Until this is fixed, files
  must unfortunately be checked ahead of time with gunzip or bunzip2.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2015-2016 by Carnegie Mellon University

Use of the Net-BGPdump library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
