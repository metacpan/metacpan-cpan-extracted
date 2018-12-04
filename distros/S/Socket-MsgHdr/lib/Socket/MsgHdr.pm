package Socket::MsgHdr;

use 5.006;
use strict;
#use bytes;

our @EXPORT    = qw( sendmsg recvmsg );
our @EXPORT_OK = qw( pack_cmsghdr unpack_cmsghdr ); # Undocumented!
our $VERSION = '0.05';

# Forcibly export our sendmsg, recvmsg methods
BEGIN {
  *IO::Socket::sendmsg = \&sendmsg;
  *IO::Socket::recvmsg = \&recvmsg;
}

# Define our simple accessor/mutator methods

sub flags {
  my $self = shift;
  $self->{flags} = shift if @_;
  $self->{flags} = 0 unless defined $self->{flags};
  $self->{flags};
}

BEGIN {
  for my $attr (qw|name buf control|) {
    no strict 'refs';

    *{$attr} = sub {
      my $self = shift;
      $self->{$attr} = shift if @_;
      $self->{$attr} = '' unless defined $self->{$attr};
	  $self->{$attr};
    };
  }

  foreach my $attr (qw|name buf control|) {
    no strict 'refs';
    *{$attr . "len"} = sub {
      my $self = shift;
      my $olen = length($self->$attr);
      return $olen unless @_;
      my $nlen = shift;

      if ($nlen != $olen) {
        $self->{$attr} = $olen > $nlen ?
                         substr($self->{$attr}, 0, $nlen) :
                         "\x00" x $nlen;
      }
      $nlen;
    };
  }

}

# XS functions
# ============
#
# -- sendmsg, recvmsg, pack_cmsghdr, unpack_cmsghdr
#
require XSLoader;
XSLoader::load('Socket::MsgHdr', $VERSION);

# Module import
# =============
#
sub import {
  require Exporter;
  goto &Exporter::import;
}

# Constructor
# ===========
#
sub new {
  my $class = shift;
  my $self = { name    => '',
               control => '',
               buf     => '',
               flags   => 0 };

  bless $self, $class;

  my %args = @_;
  foreach my $m (keys %args) {
    $self->$m($args{$m});
  }

  return $self;
}

# Methods
# =======
#
# -- cmsghdr
#
sub cmsghdr {
  my $self = shift;
  unless (@_) { return &unpack_cmsghdr($self->{control}); }
  $self->{control} = &pack_cmsghdr(@_);
}

# -- name, buf, control, flags
# -- namelen, buflen, controllen
#    (loaded in INIT)

1;
__END__
# begin POD

=head1 NAME

Socket::MsgHdr - sendmsg, recvmsg and ancillary data operations

=head1 SYNOPSIS

  use Socket::MsgHdr;
  use Socket;

  # sendto() behavior
  my $echo = sockaddr_in(7, inet_aton("10.20.30.40"));
  my $outMsg = new Socket::MsgHdr(buf  => "Testing echo service",
                                  name => $echo);
  sendmsg(OUT, $outMsg, 0) or die "sendmsg: $!\n";

  # recvfrom() behavior, OO-style
  my $msgHdr = new Socket::MsgHdr(buflen => 512)

  $msgHdr->buflen(8192);    # maybe 512 wasn't enough!
  $msgHdr->namelen(256);    # only 16 bytes needed for IPv4

  die "recvmsg: $!\n" unless defined recvmsg(IN, $msgHdr, 0);

  my ($port, $iaddr) = sockaddr_in($msgHdr->name());
  my $dotted = inet_ntoa($iaddr);
  print "$dotted:$port said: " . $msgHdr->buf() . "\n";

  # Pack ancillary data for sending
  $outHdr->cmsghdr(SOL_SOCKET,                # cmsg_level
                   SCM_RIGHTS,                # cmsg_type
                   pack("i", fileno(STDIN))); # cmsg_data
  sendmsg(OUT, $outHdr);

  # Unpack the same
  my $inHdr = Socket::MsgHdr->new(buflen => 8192, controllen => 256);
  recvmsg(IN, $inHdr, $flags);
  my ($level, $type, $data) = $inHdr->cmsghdr();
  my $new_fileno = unpack('i', $data);
  open(NewFH, '<&=' . $new_fileno);     # voila!

=head1 DESCRIPTION

Socket::MsgHdr provides advanced socket messaging operations via L<sendmsg>
and L<recvmsg>.  Like their C counterparts, these functions accept few
parameters, instead stuffing a lot of information into a complex structure.

This structure describes the message sent or received (L<buf>), the peer on
the other end of the socket (L<name>), and ancillary or so-called control
information (L<cmsghdr>).  This ancillary data may be used for file descriptor
passing, IPv6 operations, and a host of implemenation-specific extensions.

=head2 FUNCTIONS

=over 4

=item sendmsg SOCKET, MSGHDR

=item sendmsg SOCKET, MSGHDR, FLAGS

Send a message as described by C<Socket::MsgHdr> MSGHDR over SOCKET,
optionally as specified by FLAGS (default 0).  MSGHDR should supply
at least a I<buf> member, and connectionless socket senders might
also supply a I<name> member.  Ancillary data may be sent via
I<control>.

Returns number of bytes sent, or undef on failure.

=item recvmsg SOCKET, MSGHDR

=item recvmsg SOCKET, MSGHDR, FLAGS

Receive a message as requested by C<Socket::MsgHdr> MSGHDR from
SOCKET, optionally as specified by FLAGS (default 0).  The caller
requests I<buflen> bytes in MSGHDR, possibly also recording up to
I<namelen> bytes of the sender's (packed) address and perhaps
I<controllen> bytes of ancillary data.

Returns number of bytes received, or undef on failure.  I<buflen>
et. al. are updated to reflect the actual lengths of received data.

=back

=head2 Socket::MsgHdr

=over 4

=item new [PARAMETERS]

Return a new Socket::MsgHdr object.  Optional PARAMETERS may specify method
names (C<buf>, C<name>, C<control>, C<flags> or their corresponding I<...len>
methods where applicable) and values, sparing an explicit call to those
methods.

=item buf [SCALAR]

=item buflen LENGTH

C<buf> gets the current message buffer or sets it to SCALAR.  C<buflen>
allocates LENGTH bytes for use in L<recvmsg>.

=item name [SCALAR]

=item namelen LENGTH

Get or set the socket name (address) buffer, an attribute analogous to the
optional TO and FROM parameters of L<perlfunc/send> and L<perlfunc/recv>.
Note that socket names are packed structures.

=item controllen LENGTH

Prepare the ancillary data buffer to receive LENGTH bytes.  There is a
corresponding C<control> method, but its use is discouraged -- you have to
L<perlfunc/pack> the C<struct cmsghdr> yourself.  Instead see L<cmsghdr> below
for convenient access to the control member.

=item flags [FLAGS]

Get or set the Socket::MsgHdr flags, distinct from the L<sendmsg> or
L<recvmsg> flags.  Example:

  $hdr = new Socket::MsgHdr (buflen => 512, controllen => 3);
  recvmsg(IN, $hdr);
  if ($hdr->flags & MSG_CTRUNC) {   # &Socket::MSG_CTRUNC
    warn "Yikes!  Ancillary data was truncated\n";
  }

=item cmsghdr

=item cmsghdr LEVEL, TYPE, DATA [ LEVEL, TYPE, DATA ... ]

Without arguments, this method returns a list of "LEVEL, TYPE, DATA, ...", or
an empty list if there is no ancillary data.  With arguments, this method
copies and flattens its parameters into the internal control buffer.

In any case, DATA is in a message-specific format which likely requires
special treatment (packing or unpacking).

Examples:

   my @cmsg = $hdr->cmsghdr();
   while (my ($level, $type, $data) = splice(@cmsg, 0, 3)) {
     warn "unknown cmsg LEVEL\n", next unless $level == IPPROTO_IPV6;
     warn "unknown cmsg TYPE\n", next unless $type == IPV6_PKTINFO;
     ...
   }

   my $data = pack("i" x @filehandles, map {fileno $_} @filehandles);
   my $hdr->cmsghdr(SOL_SOCKET, SCM_RIGHTS, $data);
   sendmsg(S, $hdr);

=back

=head2 EXPORT

C<Socket::MsgHdr> exports L<sendmsg> and L<recvmsg> by default into the
caller's namespace, and in any case these methods into the IO::Socket
namespace.

=head1 BUGS

The underlying XS presently makes use of RFC 2292 CMSG_* manipulation macros,
which may not be available on all systems supporting sendmsg/recvmsg as known
to 4.3BSD Reno/POSIX.1g.  Older C<struct msghdr> definitions with
C<msg_accrights> members (instead of C<msg_control>) are not supported at all.

There is no Socket::CMsgHdr, which may be a good thing.  Examples are meager,
see the t/ directory for send(to) and recv(from) emulations in terms of this
module.

=head1 SEE ALSO

L<sendmsg(2)>, L<recvmsg(2)>, L<File::FDpasser>, L<RFC 2292|https://tools.ietf.org/html/rfc2292>

=head1 AUTHOR

Michael J. Pomraning, co-maintained by Felipe Gasper

=head1 COPYRIGHT AND LICENSE

Copyright 2003, 2010 by Michael J. Pomraning

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
