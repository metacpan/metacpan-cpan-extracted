package Net::CDP;

#
# $Id: CDP.pm,v 1.20 2005/08/16 11:52:30 mchapman Exp $
#

use 5.00503;
use strict;
use Carp::Clan qw(^Net::CDP);

use vars qw($VERSION $XS_VERSION @ISA $AUTOLOAD @EXPORT @EXPORT_OK %EXPORT_TAGS @EXPORT_FAIL);

$VERSION = (qw$Revision: 1.20 $)[1];
$XS_VERSION = '0.09'; # XXX Keep this in sync with libcdp

require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);

my @EXPORT_GENERAL = qw(
	CDP_PROMISCUOUS
);
my @EXPORT_RECV = qw(
	CDP_RECV_NONBLOCK CDP_RECV_DECODE_ERRORS
);
my @EXPORT_CAPS = qw(
	CDP_CAP_ROUTER CDP_CAP_TRANSPARENT_BRIDGE CDP_CAP_SOURCE_BRIDGE
	CDP_CAP_SWITCH CDP_CAP_HOST CDP_CAP_IGMP CDP_CAP_REPEATER
);
my @EXPORT_PROTOS = qw(
	CDP_ADDR_PROTO_CLNP CDP_ADDR_PROTO_IPV4 CDP_ADDR_PROTO_IPV6
	CDP_ADDR_PROTO_DECNET CDP_ADDR_PROTO_APPLETALK CDP_ADDR_PROTO_IPX
	CDP_ADDR_PROTO_VINES CDP_ADDR_PROTO_XNS CDP_ADDR_PROTO_APOLLO
);

@EXPORT = qw();
@EXPORT_OK = (@EXPORT_CAPS, @EXPORT_PROTOS, @EXPORT_GENERAL, @EXPORT_RECV, );
%EXPORT_TAGS = (
	general => [ @EXPORT_GENERAL, ],
	recv => [ @EXPORT_RECV, ],
	caps => [ @EXPORT_CAPS, ],
	protos => [ @EXPORT_PROTOS, ],
);
@EXPORT_FAIL = (@EXPORT_OK, );

sub AUTOLOAD {
	my $constname;
	($constname = $AUTOLOAD) =~ s/.*:://;
	croak '&Net::CDP::constant not defined' if $constname eq 'constant';
	my ($error, $val) = Net::CDP::Constants::constant($constname);
	croak $error if $error;
	
	no strict 'refs';
	*$AUTOLOAD = sub { $val };
	goto &$AUTOLOAD;
}

# If you REALLY need the warnings suppressed, set this to 0
use vars qw($warn_deprecated);
$warn_deprecated = 1;

{
	my $warned;
	sub _deprecated() {
		return unless $warn_deprecated;
		return if $warned;
		$warned = 1;
		warn <<EOF;
**********************************************************
*** You're using a deprecated interface! Check out the ***
*** Net::CDP documentation for more info.              ***
**********************************************************
EOF
	}
}

sub export_fail(@) {
	my $self = shift;
	_deprecated;
	();
}

bootstrap Net::CDP $XS_VERSION;

# Load in the Perl part of the Net::CDP::Address
# and Net::CDP::IPPrefix namespaces
require Net::CDP::Address;
require Net::CDP::IPPrefix;

sub _parse_args($@) {
	croak 'Invalid arguments' if @{$_[0]} % 2;
	my %args = @{+shift};
	my %check = map { $_ => 1 } keys %args;
	foreach (@_) {
		delete $check{$_} if exists $check{$_};
	}
	croak "Unknown argument '$_'" foreach keys %check;
	%args;
}

sub _v4_pack {
	my $ip = shift;
	
	if ($ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ &&
		$1 >= 0 && $1 <= 255 &&
		$2 >= 0 && $2 <= 255 &&
		$3 >= 0 && $3 <= 255 &&
		$4 >= 0 && $4 <= 255
	) {
		pack 'C4', $1, $2, $3, $4;
	} elsif ($ip =~ /^(\d+)\.(\d+)\.(\d+)$/ &&
		$1 >= 0 && $1 <= 255 &&
		$2 >= 0 && $2 <= 255 &&
		$3 >= 0 && $3 <= 255
	) {
		pack 'C4', $1, $2, 0, $3;
	} elsif ($ip =~ /^(\d+)\.(\d+)$/ &&
		$1 >= 0 && $1 <= 255 &&
		$2 >= 0 && $2 <= 255
	) {
		pack 'C4', $1, 0, 0, $4;
	} else {
		undef;
	}
}

sub _v4_unpack {
	join '.', unpack 'C4', shift;
}

use constant POWERS => "\x00\x80\xc0\xe0\xf0\xf8\xfc\xfe\xff";

sub _mask_pack {
	my $mask = shift;

	if ($mask =~ /^255\.255\.255\.(\d+)$/) {
		my $index = index POWERS, chr $1;
		$index >= 0 ? 24 + $index : undef;
	} elsif ($mask =~ /^255\.255\.(\d+)\.0$/) {
		my $index = index POWERS, chr $1;
		$index >= 0 ? 16 + $index : undef;
	} elsif ($mask =~ /^255\.(\d+)\.0\.0$/) {
		my $index = index POWERS, chr $1;
		$index >= 0 ? 8 + $index : undef;
	} elsif ($mask =~ /^(\d+)\.0\.0\.0$/) {
		my $index = index POWERS, chr $1;
		$index >= 0 ? $index : undef;
	} else {
		undef;
	}
}

sub _mask_unpack {
	_v4_unpack(pack 'B32', 1 x shift);
}

sub _v6_pack {
	my $ip = shift;

	if ($ip =~ /^([\da-f\:]+)(?::(\d+)\.(\d+)\.(\d+)\.(\d+))?$/i) {
		my $ipv6 = $1;
		if (
			defined $2 &&
			$2 >= 0 && $2 <= 255 &&
			$3 >= 0 && $3 <= 255 &&
			$4 >= 0 && $4 <= 255 &&
			$5 >= 0 && $5 <= 255
		) {
			$ipv6 .= sprintf ':%x:%x',
				($2 << 8) | $3,
				($4 << 8) | $5;
		}
		unless ($ipv6 =~ /:::/ || $ipv6 =~ /::.*::/) {
			$ipv6 =~ s/::/':0' x (9 - ($ipv6 =~ tr,:,:,))/e;
			if (($ipv6 =~ tr/:/:/) == 7) {
				$ipv6 =~ s/^:/0:/;
				$ipv6 =~ s/:$/:0/;
				return pack 'n8', map hex, split /:/, $ipv6;
			}
		}
	}
	undef;
}

sub _v6_unpack {
	my $result = sprintf '%x:%x:%x:%x:%x:%x:%x:%x', unpack 'n8', shift;
	$result =~ s/:0(:0)+:/::/;
	$result =~ s/^0:/:/;
	$result;
}

sub _rethrow(&) {
	my $sub = shift;
	if (wantarray) {
		my @result = eval { &$sub };
		if ($@) {
			$@ =~ s/ at \S+ line \d+\.\n\z//;
			croak $@;
		}
		@result;
	} else {
		my $result = eval { &$sub };
		if ($@) {
			$@ =~ s/ at \S+ line \d+\.\n\z//;
			croak $@;
		}
		$result;
	}
}

=head1 NAME

Net::CDP - Cisco Discovery Protocol (CDP) advertiser/listener

=head1 SYNOPSIS

  use Net::CDP;

  # Available network ports
  @ports = Net::CDP::ports;  

  # Creating a CDP advertiser/listener
  $cdp = new Net::CDP;

  # Receiving a CDP packet
  $packet = $cdp->recv;
  
  # Sending a CDP packet
  $cdp->send($packet);
  
  # Other Net::CDP methods
  $port = $cdp->port;
  @addresses = $cdp->addresses;

=head1 DESCRIPTION

The Net::CDP module implements an advertiser/listener for the Cisco
Discovery Protocol.

CDP is a proprietary Cisco protocol for discovering devices on a network. A
typical CDP implementation sends periodic CDP packets on every network
port. It might also listen for packets for advertisements sent by neighboring
devices.

A Net::CDP object represents an advertiser/listener for a single network
port. It can send and receive individual CDP packets, each represented by a
L<Net::CDP::Packet> object.

To manage multiple ports simultaneously, you might like to take a look at
L<Net::CDP::Manager>.

If you are upgrading code from an older version of Net::CDP, please read the
L</"UPGRADING FROM PREVIOUS VERSIONS"> section below.

=head1 CONSTRUCTORS

=over

=item B<new>

    $cdp = new Net::CDP($port)
    $cdp = new Net::CDP(
             [ port        => $port,        ]
             [ promiscuous => $promiscuous, ] # default = 0
             [ enable_recv => $enable_recv, ] # default = 1
             [ enable_send => $enable_send, ] # default = 1
           );

Returns a new Net::CDP object.

If specified, C<$port> must be the name of the network port that should be used
to send and receive packets. If no port is specified, the first port on your
system is used (typically, this is the first Ethernet device -- "eth0", for
instance).

You can use the L</"ports"> class method to retrieve a list of valid port names.

If C<$promiscuous> is non-zero, then promiscuous mode is enabled on the
specified port. Otherwise, Net::CDP attempts to use a multicast ethernet
address instead. Multicast addresses may not work with all network drivers.

By default, C<$enable_recv> and C<$enable_send> are both 1. If either of these
are set to 0 the corresponding function is disabled. This saves a small amount
of memory and a file descriptor, and might be useful when you do not intend to
both send and receive packets. You probably won't want to set I<both> to 0.

This constructor used to take a single argument, C<$flags>. This is now
deprecated. See L</"UPGRADING FROM PREVIOUS VERSIONS"> below.

=back

=cut

sub new($;@) {
	my $class = shift;
	my $port;
	my $flags = 0;
	
	if (@_ == 2 && $_[1] =~ /^\d+$/) {
		_deprecated;
		$flags = pop;
	}
	
	$port = shift if @_ == 1;
	my %args = _parse_args \@_, qw(port promiscuous enable_recv enable_send);
	
	$port = $args{port} if exists $args{port};
	$flags |= CDP_PROMISCUOUS() if $args{promiscuous};
	$flags |= CDP_DISABLE_RECV()
		if exists $args{enable_recv} && !$args{enable_recv};
	$flags |= CDP_DISABLE_SEND()
		if exists $args{enable_send} && !$args{enable_send};
	carp "enable_recv => 0 and enable_send => 0 both specified"
		if $flags & CDP_DISABLE_RECV() and $flags & CDP_DISABLE_SEND();
	
	_rethrow { $class->_new($port, $flags) };
}

=head1 CLASS METHODS

=over 

=item B<ports>

    @ports = Net::CDP::ports()

Returns a list of network ports that can be used by this module.

=back

=cut

sub ports() { _rethrow { _ports(); } }

=head1 OBJECT METHODS

=over

=item B<port>

    $port = $cdp->port()

Returns the network port associated with this Net::CDP object.

=item B<addresses>

    @addresses = $cdp->addresses()

Returns the addresses of the network port associated with this
Net::CDP object. In scalar context the number of addresses is returned.

I<NOTE:> Currently only a single IPv4 address is returned, even if the port
has more than one bound address.

=item B<recv>

    $packet = $cdp->recv(
                 [ nonblock      => $nonblock,      ] # default = 0
                 [ decode_errors => $decode_errors, ] # default = 0
              )

Returns the next available CDP packet as a L<Net::CDP::Packet> object. If the
C<$nonblock> flag is set, an undefined value returned if no packets are
immediately available. Otherwise, this method blocks until a packet is received
or an error occurs. If an error occurs, this method croaks.

By default, decoding errors will be silently ignored. If C<$decode_errors> is
set, this method will croak on a decoding error.

This method used to take a single argument, C<$flags>. This is now
deprecated. See L</"UPGRADING FROM PREVIOUS VERSIONS"> below.

=cut

sub recv($;@) {
	my $self = shift;
	my $flags = 0;
	
	if (@_ == 1 && $_[0] =~ /^\d+$/) {
		_deprecated;
		$flags = pop;
	}
	
	my %args = _parse_args \@_, qw(nonblock decode_errors);
	
	$flags |= CDP_RECV_NONBLOCK() if $args{nonblock};
	$flags |= CDP_RECV_DECODE_ERRORS() if  $args{decode_errors};
	
	_rethrow { $self->_recv($flags) };
}

=item B<send>

    $bytes = $cdp->send($packet)

Transmits the specified packet, which must be a L<Net::CDP::Packet> object,
and returns the number of bytes sent. If an error occurs, this method croaks.

=back

=cut

sub send($;@) {
	my $self = shift;
	my $packet;
	
	$packet = shift if @_ == 1;
	my %args = _parse_args \@_, qw(packet);
	
	$packet = $args{packet} if exists $args{packet};
	
	croak 'No packet supplied' unless defined $packet;
	
	_rethrow { $self->_send($packet) };
}

=head1 UPGRADING FROM PREVIOUS VERSIONS

Net::CDP version 0.07 introduces the use of named arguments instead of flag
bitmaps for the L</"new"> constructor and L</"recv"> method. Furthermore, the
C<:caps> and C<:protos> import tags now live in L<Net::CDP::Packet> and
L<Net::CDP::Address> respectively.

A warning is generated the first time you attempt to use a deprecated feature.
Actual support for the old-style flag bitmaps will be removed soon. To upgrade
your code you will need to:

=over

=item *

Do not import the C<:general> or C<:recv> tags; use named arguments
in calls to L</"new"> and L</"recv"> instead.

=item *

Replace C<use Net::CDP qw(:caps)> with C<use Net::CDP::Packet qw(:caps)>, and
C<use Net::CDP qw(:protos)> with C<use Net::CDP::Address qw(:protos)>.

=back

=head1 SEE ALSO

L<Net::CDP::Packet>

=head1 AUTHOR

Michael Chapman, E<lt>cpan@very.puzzling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Michael Chapman

libcdp is released under the terms and conditions of the GNU Library General
Public License version 2. Net::CDP may be redistributed and/or modified under
the same terms as Perl itself.

=cut

1;
