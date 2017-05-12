package Net::Pcap::Reassemble;

require 5.002;
use strict;
use warnings;
use vars qw($VERSION %pending $callback $linktype $debug $stripl2);

use Net::Pcap;
use Carp;

#
# Copyright (c) 2006-2010 James Raftery <james@now.ie>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# Please submit bug reports, patches and comments to the author.
#
# $Id: Reassemble.pm,v 1.22 2010/05/13 18:29:13 james Exp $
#
# This module is a wrapper for the loop() function of the Net::Pcap
# module. It performs IP fragment reassembly for fragmented datagrams
# in the libpcap dump data. You require the Net::Pcap module to use
# Net::Pcap::Reassemble. See the Net::Pcap::Reassemble(3) man page for
# more information.
#

$VERSION = '0.05';
$debug   =  0;
$stripl2 =  0;

####

#
# Wrapper around Net::Pcap's loop() function. This takes the same
# arguments as Net::Pcap's loop().
#
sub loop ($$&$) {

	my ($pcap_t, $num, $user_data);

	($pcap_t, $num, $callback, $user_data) = @_ or
		croak('Missing arguments to loop()');

	defined($linktype = Net::Pcap::datalink($pcap_t)) or die;

	#
	# A reference to the user's callback is in $callback, which is
	# declared as a package global. We call Net::Pcap::loop,
	# specifying instead our own _reassemble() sub as its callback.
	# _reassemble() will give a packet to the sub referenced in
	# $callback when it has a complete datagram.
	#
	return Net::Pcap::loop($pcap_t, $num, \&_reassemble, $user_data);
}

sub flush () {
	undef %pending;
}

#
# Callback function. Read the IP version from the packet header and call
# the appropriate function to read it. If that function returns data
# (i.e. a complete datagram) then summon up the user's callback,
# supplying the packet.
#
sub _reassemble ($$$) {

	my ($user_data, $header, $packet, $ver, $l2);

	($user_data, $header, $packet) = @_ or
		croak('Missing arguments to _reassemble()');

	($l2, $packet) = _splitpkt($packet);
	$ver = unpack('C', $packet) >> 4;

	if ($ver == 4) {
		$packet = _readIPv4pkt($packet);
	} elsif ($ver == 6) {
		$packet = _readIPv6pkt($packet);
	} else {
		$packet = undef;
	}

	if ($packet) {
		# Put back the layer 2 header data from the most recent packet
		$packet = $l2.$packet unless $stripl2;
		&$callback($user_data, $header, $packet);
	}
}

#
# Split the packet into layer 2 header and IP datagram (+ optional padding).
#
sub _splitpkt ($) {

	my ($packet, $bytes);

	$packet = shift or croak('Missing argument to _splitpkt()');

	if ($linktype == DLT_EN10MB) {
		# ethernet header
		$bytes = 14;
	} elsif ($linktype == DLT_LOOP or $linktype == DLT_NULL) {
		# loopback header
		$bytes = 4;
	} elsif ($linktype == DLT_RAW) {
		# no header
		$bytes = 0;
	} elsif ($linktype == DLT_LINUX_SLL) {
		# linux 'cooked'
		$bytes = 16;
	} else {
		# barf
		croak("unsupported linktype: $linktype");
	}

	return unpack("a$bytes a*", $packet);
}

#
# Read an IPv4 packet.
#
sub _readIPv4pkt ($) {

	my ($packet, $i, $ver, $ihl, $pktlen, $id, $mf, $offset, $proto,
	    $src, $dst, $payload, $datalen);

	$packet = shift or croak('Missing argument to _readIPv4pkt()');

	# The x's are: tos, ttl, chksum, options+data
	($i, $pktlen, $id, $offset, $proto, $src, $dst) = 
				unpack('C x n3 x C x2 a4 a4', $packet);

	$ver     = $i >> 4;
	$ihl     = ($i & 0x0f) * 4;
	$mf      = ($offset >> 13) & 0x01;	# More fragments flag
	$offset  = ($offset & 0x1fff) << 3;
	$src     = join('.', unpack('C*', $src));
	$dst     = join('.', unpack('C*', $dst));
	$datalen = $pktlen - $ihl;

	print "ver:$ver ihl:$ihl packetlen:$pktlen id:$id mf:$mf " .
		"offset:$offset datalen:$datalen proto:$proto\n".
		"src:$src dst:$dst\n" if $debug;

	print "Dropping padding\n"  if ($debug and length($packet) > $pktlen);
	print "Incomplete packet\n" if (length($packet) < $pktlen);
	$packet = substr($packet, 0, $pktlen);

	#
	# Fragment 1:		MF == 1, offset == 0
	# Fragment 2..(n-1):	MF == 1, offset >  0
	# Fragment n:		MF == 0, offset >  0
	#

	#
	# Can you encounter a negative offset? Maybe if we unpack the
	# data incorrectly.
	#
	# If this isn't a fragment we drop down to the return statement
	# which passes back the unmodified $packet data.
	#
	if (($mf and $offset >= 0) or ($offset > 0)) {
		print "Fragment! ver:$ver ihl:$ihl packetlen:$pktlen id:$id ".
			"mf:$mf offset:$offset datalen:$datalen proto:$proto\n".
			"src:$src dst:$dst\n" if $debug;

		$i = "$src $dst $id $proto";

		#
		# If initial fragment - use the whole packet as the data.
		# XXX The user callback gets a packet with the header
		#     from the first fragment. 'total length' and MF
		#     are going to be wrong w.r.t. the reassembled
		#     packet.
		#
		if ($offset == 0) {
			$payload = $packet;
		} else {
			$payload = substr($packet, $ihl, $datalen);
		}

		#
		# XXX We don't expunge old entries
		#
		if (exists $pending{$i}) {
			$pending{$i}->addfragment($offset, $datalen, $mf,
					$payload) or
				print STDERR "addfragment: $offset $datalen $mf failed\n";
		} else {
			$pending{$i} = Net::Pcap::Reassemble::Packet->new($i,
					$offset, $datalen, $mf, $payload) or
				print STDERR "new Packet: $i $offset $datalen, $mf failed\n";
		}

		print $pending{$i}->listfragments if $debug;

		# We get a packet if all the fragments have arrived, or
		# an empty string if not.
		$packet = $pending{$i}->iscomplete;
		if ($packet) {
			delete $pending{$i};
			print "Fragment '$i' is complete.\n" if $debug;
		}
	}

	return $packet;
}

#
# Read an IPv6 header/packet.
#
sub _readIPv6pkt ($) {

	my ($packet, $ver, $payloadlen, $nexthdr, $src, $dst, $payload, $i,
	    $offset, $id, $m, $hdrlen, $exthdrlentotal, $unfrag,
	    $unfragoffset, $prevhdr, $prevhdrlen);

	$packet  = shift or croak('Missing argument to _readIPv6pkt()');
	$prevhdr = 0;	# Hackity, hack, hack

	# The x's are: class, label, hlim
	($ver, $payloadlen, $nexthdr, $src, $dst) = 
			unpack('C x3 n C x a16 a16', $packet);

	$ver >>= 4;
	$src   = join(':', unpack('H4'x8, $src));
	$dst   = join(':', unpack('H4'x8, $dst));
	$exthdrlentotal = 0;	# extension header bytes read so far

	print "ver:$ver payloadlen:$payloadlen nexthdr:$nexthdr\n" .
			"src:$src\ndst:$dst\n" if $debug;

	# XXX not tested
	print "Dropping padding\n"  if ($debug and length($packet) > 40+$payloadlen);
	print "Incomplete packet\n" if (length($packet) < 40+$payloadlen);
	$packet  = substr($packet, 0, 40+$payloadlen);
	$payload = substr($packet, 40);

	#
	# Since this module isn't a v6 capable end-host it doesn't
	# implement TCP or UDP or any other `upper-layer' protocol. How
	# do we decide when to stop looking ahead to the next header
	# (and return some data to the caller)? We stop when we find
	# a `next header' which isn't a known Extension Header:
	#
	#  0 Hop-by-Hop Options
	# 43 Routing
	# 44 Fragment
	# 50 Encapsulating Security Payload
	# 51 Authentication
	# 60 Destination Options
	#
	# This means this will fail to deal with any subsequently added
	# Extension Headers, which is sucky, but the alternative is to
	# list all the other `next header' values and then break when a
	# new one of them is defined :)
	#
	EXTHEADER: for (;;) {

		if ($nexthdr ==  0 or $nexthdr == 43 or $nexthdr == 50 or
		    $nexthdr == 51 or $nexthdr == 60) {

			$prevhdr         = $nexthdr;
			$prevhdrlen      = $hdrlen;
			$exthdrlentotal += $hdrlen;
			($nexthdr, $hdrlen, $payload) = _readIPv6Extheader($payload);

			next EXTHEADER;
		}

		last EXTHEADER if ($nexthdr != 44);

		#
		# Fragment Header
		#
		($nexthdr, $offset, $id, $m, $payload) = _readIPv6Fragheader($payload);

		$i = "$src $dst $id";

		#
		# Initial fragment - use the whole packet minus the Fragment
		# header as the data.
		# Munge the Next Header value from 44 (Fragment Header) to that
		# of the subsequent header.
		#
		# XXX The user callback gets a packet with the header from the
		#     first fragment. `length' is going to be wrong w.r.t. the
		#     reassembled packet.
		#
		if ($offset == 0) {

			# Offset to the start of the unfragmentable part
			$unfragoffset = 40+$exthdrlentotal;
			$unfrag = substr($packet, 0, $unfragoffset);

			if ($prevhdr == 0) {
				# 6 bytes into IPv6 header
				substr($unfrag, 6, 1) = $nexthdr;
			} else {
				# XXX not tested
				# We've read N extension headers
				# Wind back one header length ($prevhdrlen)
				# from the start of the unfragmentable part
				# ($unfragoffset).
				substr($unfrag, $unfragoffset-$prevhdrlen, 1) = $nexthdr;
			}

			$payload = $unfrag . $payload;
		}

		#
		# Fragmentable part length =
		#     packet payload length - length of extension headers read
		#     (add 8 bytes for the Fragment header)
		#
		$payloadlen -= ($exthdrlentotal+8);

		#
		# XXX We don't expunge old entries
		#
		if (exists $pending{$i}) {
			$pending{$i}->addfragment($offset, $payloadlen, $m,
					$payload) or
				print STDERR "addfrag: $i $offset $payloadlen $m failed\n";
		} else {
			$pending{$i} = Net::Pcap::Reassemble::Packet->new($i,
					$offset, $payloadlen, $m, $payload) or
				print STDERR "Packet: $i $offset $payloadlen $m failed\n";
		}

		print $pending{$i}->listfragments if $debug;

		# We get a packet if all the fragments have arrived or an
		# empty string if not.
		$packet = $pending{$i}->iscomplete;
		if ($packet) {
			delete $pending{$i};
			print "Fragment '$i' is complete.\n" if $debug;
		}

		last EXTHEADER;

	} # End: EXTHEADER

	return $packet;
}

#
# Read a standard IPv6 Extension Header. Extract the Next Header and
# Header Length values, and the payload.
#
sub _readIPv6Extheader ($) {

	my ($packet, $nexthdr, $hdrlen, $payload);

	$packet = shift or croak('Missing argument to _readIPv6Extheader()');

	($nexthdr, $hdrlen) = unpack('CC', $packet);

	$hdrlen = $hdrlen*8 + 8;
	print "Extension header is $hdrlen octets, nexthdr: $nexthdr\n" if $debug;

	# XXX not tested
	#     use substr?
	$payload = unpack("x$hdrlen a*", $packet);

	return($nexthdr, $hdrlen, $payload);
}

#
# Read an IPv6 Fragment Header. Extract the fragment's offset, ID, M
# flag and payload.
#
sub _readIPv6Fragheader ($) {

	my ($packet, $nexthdr, $offset, $m, $id, $payload);

	$packet = shift or croak('Missing argument to _readIPv6Fragheader()');

	($nexthdr, $offset, $id, $payload) = unpack('C x n N a*', $packet);

	$m        = $offset & 0x0001;
	$offset >>= 3;
	$offset  *= 8;

	print "Fragment! header: nexthdr:$nexthdr offset:$offset ".
		"id:$id,0x". unpack('H*', pack('N', $id)) ." m:$m ".
		length($packet) . ' ' . length($payload) ."\n" if $debug;

	$nexthdr = pack('C', $nexthdr);
	return ($nexthdr, $offset, $id, $m, $payload);
}

####

package Net::Pcap::Reassemble::Packet;

use strict;
use warnings;

use Carp;

#
# Constructor for a `Packet' object.
#
sub new ($$$$$$) {
	my $proto  = shift or croak;
	my $class  = ref($proto) || $proto;
	defined(my $id     = shift) or croak "No ID in $class constructor";
	defined(my $offset = shift) or croak "No offset in $class constructor";
	defined(my $length = shift) or croak "No length in $class constructor";
	defined(my $mf     = shift) or croak "No MF in $class constructor";
	defined(my $data   = shift) or croak "No data in $class constructor";

	#
	# Each `Packet' object contains:
	#  1. ID: IPv4: 'srcip dstip IPid protocol'
	#         IPv6: 'srcip dstip IPid'
	#  2. A list of Net::Pcap::Reassemble::Fragment object references
	#  3. The final octet, learned from the packet with MF==0.
	#  4. A `sorted' flag to indicate if the fragment list is sorted
	#
	my $self = {
		ID		=> $id,
		FRAGS		=> [],
		LASTOCTET	=> undef,
		SORTED		=> 1,
	};

	bless($self, $class);

	return undef if !$self->addfragment($offset, $length, $mf, $data);

	return $self;
}

#
# Add a fragment to a Packet object.
#
sub addfragment ($$$$$) {
	my $self = shift;
	ref($self) or croak;

	my ($offset, $length, $mf, $data) = @_ or croak;

	my $frag =
	  Net::Pcap::Reassemble::Fragment->new($offset, $length, $mf, $data);
	return undef if !$frag;

	# If this is the last fragment, save the last octet value in the
	# object.
	# XXX Check for more than one fragment with MF==0?
	$self->{LASTOCTET} = $offset+$length if !$mf;

	# The list can't be considered sorted any more.
	$self->{SORTED} = 0;

	# XXX Test for overlap?
	return push(@{$self->{FRAGS}}, $frag);
}

#
# Return a string showing the fragments that have been recieved by the object.
#
sub listfragments ($) {
	my $self = shift;
	ref($self) or croak;

	my ($s, $frag);

	$s .= "Packet ID:$self->{ID}\n";
	$s .= "Last octet:$self->{LASTOCTET}\n" if (defined $self->{LASTOCTET});
	foreach $frag (@{$self->{FRAGS}}) {
		$s .= 'Fragment ' . $frag->vitals . "\n";
	}

	return $s;
}

#
# Check if all the fragments for a Packet have been received. If they have,
# splice the fragment data back together and return to the caller. If they
# have not, return no data.
#
sub iscomplete ($) {
	my $self = shift;
	ref($self) or croak;

	my $nextfrag = 0;	# The first fragment starts at octet zero
	my $data     = '';
	my $frag;

	#
	# If we don't know LASTOCTET yet then we're missing at least the
	# final (MF==0) fragment so we don't need to proceed any further.
	#
	return if (!defined $self->{LASTOCTET});

	#
	# Sort the fragment list so we only need to scan it once.
	# If it was unordered we would need to scan through it repeatedly.
	# That said, sort() is pretty slow :)
	#
	FRAGMENT: foreach $frag (@{$self->_sortfragments}) {

		#
		# If the first octet in this fragment is the octet we're
		# searching for and the last octet is the last octet of the
		# complete datagram then we have all the packet data. If not,
		# the next fragment we search for is the one that starts where
		# this one ends.
		#
		if ($frag->start == $nextfrag) {
			last FRAGMENT if ($frag->end == $self->{LASTOCTET});
			$nextfrag = $frag->end;
			next FRAGMENT;
		}

		#
		# If we reach here, we're missing at least one fragment so
		# just give up.
		#
		return;
	}

	#
	# The datagram is complete. Splice the fragments' data together
	# to return the complete packet.
	#
	return $self->_data;
}

#
# Return concatenated fragment data.
# Warning: missing fragments are blithely ignored. Use iscomplete() for
#          a sanity-checked interface!
#
sub _data ($) {
	my $self = shift;
	ref($self) or croak;

	my ($frag, $data);

	foreach $frag (@{$self->_sortfragments}) {
		$data .= $frag->data;
	}

	return $data;
}

#
# Sort the fragment list by starting octet value and return a reference
# the list.
#
sub _sortfragments ($) {
	my $self = shift;
	ref($self) or croak;

	if (!$self->{SORTED}) {
		@{$self->{FRAGS}} = sort {$a->start<=>$b->start} @{$self->{FRAGS}};
		$self->{SORTED} = 1;
	}
	return $self->{FRAGS};
}

####

package Net::Pcap::Reassemble::Fragment;

use strict;
use warnings;

use Carp;

#
# Constructor for a `Fragment' object.
#
sub new ($$$$$) {
	my $proto  = shift or croak;
	my $class  = ref($proto) || $proto;
	defined(my $offset = shift) or croak "No offset in $class constructor";
	defined(my $length = shift) or croak "No length in $class constructor";
	defined(my $mf     = shift) or croak "No MF in $class constructor";
	defined(my $data   = shift) or croak "No data in $class constructor";

	#
	# Each `Fragment' object contains:
	#  1. Start octet
	#  2. End octet
	#  3. (M)ore (F)ragments flag (`MF' in IPv4; `M' in IPv6)
	#  4. Payload data
	#
	my $self = {
		START	=> $offset,
		END	=> $offset+$length,
		MF	=> $mf,
		DATA	=> $data,
	};

	bless($self, $class);
	return $self;
}

#
# Accessor function for start octet value.
#
sub start ($) {
	my $self = shift;
	ref($self) or croak;
	return $self->{START}
}

#
# Accessor function for end octet value.
#
sub end ($) {
	my $self = shift;
	ref($self) or croak;
	return $self->{END}
}

#
# Accessor function for MF/M flag.
#
sub mf ($) {
	my $self = shift;
	ref($self) or croak;
	return $self->{MF}
}

#
# Accessor function for fragment data.
#
sub data ($) {
	my $self = shift;
	ref($self) or croak;
	return $self->{DATA}
}

#
# Return a string listing a fragment's vital statistics.
#
sub vitals ($) {
	my $self = shift;
	ref($self) or croak;
	return 'start:'. $self->start .' end:'. $self->end .' mf:'. $self->mf;
}

####

1;

__END__

####

=head1 NAME

Net::Pcap::Reassemble - IP fragment reassembly for Net::Pcap

=head1 SYNOPSIS

 use Net::Pcap::Reassemble;

 my $pcap_t = Net::Pcap::open_offline($opt_p, \$err);
 if (!defined($pcap_t)) {
   print STDERR "Net::Pcap::open_offline returned error: $err\n";
   exit 1;
 }

 Net::Pcap::Reassemble::loop($pcap_t, -1, \&callback, "user data");

=head1 DESCRIPTION

This module performs reassembly of fragmented datagrams in libpcap
packet capture data returned by the B<Net::Pcap> C<loop()> function.
This module supports reassembly of IPv4 and IPv6 fragments.

=head1 FUNCTIONS

=over 4

=item loop($pcap, $count, \&callback, $user_data)

The C<loop()> function in B<Net::Pcap::Reassemble> is intended as a
seamless wrapper around the same function from B<Net::Pcap> and as such
it takes the same arguments. B<Net::Pcap::Reassemble>, however, will
only invoke the C<&callback> function when it has a complete packet.

The module will print debug information to stdout (mainly packet header
values) if the C<$debug> variable in the package namespace evaluates to
true:

 $Net::Pcap::Reassemble::debug = 1;

Layer 2 header data (typically an ethernet header) will be omitted from the
packet supplied to the callback function if the C<$stripl2> variable in the
package namespace evaluates to true:

 $Net::Pcap::Reassemble::stripl2 = 1;

=item flush()

The C<flush()> function destroys the data structures storing any
incomplete datagrams. This function can be called after C<loop()> has
returned to release memory used by the fragments of incomplete datagrams
(assuming your program continues executing after the C<loop()> finishes).

=back

=head1 OBJECTS

Data is represented internally using C<Net::Pcap::Reassemble::Packet>
and C<Net::Pcap::Reassemble::Fragment> class objects.

=over 4

=item Net::Pcap::Reassemble::Packet

Each `Packet' object represents a complete captured packet and contains:

=over 2

=item 1

An ID: 'srcip dstip IPid protocol' for IPv4; 'srcip dstip IPid' for IPv6

=item 2

A list of C<Net::Pcap::Reassemble::Fragment> object references

=item 3

The final octet, learned from the packet with MF==0

=item 4

A flag to indicate if the fragment list is sorted

=back

It has class functions to add a fragment to the Packet
(C<addfragment()>), return a string with information on the fragments
received so far (C<listfragments()>), and to test whether a datagram is
complete and return its data if it is (C<iscomplete()>).

=item Net::Pcap::Reassemble::Fragment

Each `Fragment' object represents an IP datagram fragment and contains:

=over 2

=item 1

Start octet

=item 2

End octet

=item 3

(M)ore (F)ragments flag (`MF' in IPv4; `M' in IPv6)

=item 4

Payload data

=back

It has class functions to return the data above (C<start()>, C<end()>,
C<mf()> and C<data()>), and a summary string for debugging (C<vitals()>).

=back

=head1 SEE ALSO

L<Net::Pcap>

=head1 BUGS

=over 4

=item *

Stale fragments are not aged out of the pending fragment list. We could look
at the pcap header for the capture time of each packet and age out based on
that.

=item *

This module offers no resistance against fragment overlap attacks, and
other such malarky.

=item *

loop() should accept an optional anonymous hash reference for option
passing.

=item *

Incomplete datagrams are left in limbo. Should be able to signal via an
option that the callback be invoked for individual fragments aswell as
the complete datagram.

=item *

The IP header in the packet supplied to the callback is from the first
datagram. Length and checksum values will be incorrect with respect to
the reassembled datagram that the callback sees. The layer 2 header, if
present, will be from the last datagram to be captured.

=back

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. (Being a speaker of British english,
I'd call it a "licence" though)

=head1 AUTHOR

James Raftery <james@now.ie>.

=cut

####
