# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
package Net::EPP::Protocol;
use bytes;
use Carp;
use vars qw($THRESHOLD);
use strict;

=pod

=head1 NAME

Net::EPP::Protocol - Low-level functions useful for both EPP clients and
servers.

=head1 SYNOPSIS

	#!/usr/bin/perl
	use Net::EPP::Protocol;
	use IO::Socket;
	use strict;

	# create a socket:

	my $socket = IO::Socket::INET->new( ... );

	# send a frame down the socket:

	Net::EPP::Protocol->send_frame($socket, $xml);

	# get a frame from the socket:

	my $xml = Net::EPP::Protocol->get_frame($socket);

=head1 DESCRIPTION

EPP is the Extensible Provisioning Protocol. EPP (defined in RFC 4930)
is an application layer client-server protocol for the provisioning and
management of objects stored in a shared central repository. Specified
in XML, the protocol defines generic object management operations and an
extensible framework that maps protocol operations to objects. As of
writing, its only well-developed application is the provisioning of
Internet domain names, hosts, and related contact details.

This module implements functions that are common to both EPP clients and
servers that implement the TCP transport as defined in RFC 4934. The
main consumer of this module is currently L<Net::EPP::Client>.

=head1 VARIABLES

=head2 $Net::EPP::Protocol::THRESHOLD

At least one EPP server implementation sends an unframed plain text error
message when a client connects from an unauthorised address. As a result, when
the first four bytes of the message are unpacked, the client tries to read and
allocate a very large amount of memory.

If the apparent frame length received from a server exceeds the value of
C<$Net::EPP::Protocol::THRESHOLD>, the C<get_frame()> method will croak.

The default value is 1GB.

=cut

BEGIN {
	our $THRESHOLD = 1000000000;
}

=pod

=head1 METHODS

	my $xml = Net::EPP::Protocol->get_frame($socket);

This method reads a frame from the socket and returns a scalar
containing the XML. C<$socket> must be an L<IO::Handle> or one of its
subclasses (ie C<IO::Socket::*>).

If the transmission fails for whatever reason, this method will
C<croak()>, so be sure to enclose it in an C<eval()>.

=cut

sub get_frame {
	my ($class, $fh) = @_;

	my $hdr;
	if (!defined($fh->read($hdr, 4))) {
		croak("Got a bad frame length from peer - connection closed?");

	} else {
		my $length = (unpack('N', $hdr) - 4);
		if ($length < 0) {
			croak("Got a bad frame length from peer - connection closed?");

		} elsif (0 == $length) {
			croak('Frame length is zero');

		} elsif ($length > $THRESHOLD) {
			croak("Frame length is $length which exceeds $THRESHOLD");

		} else {
			my $xml = '';
			my $buffer;
			while (length($xml) < $length) {
				$buffer = '';
				$fh->read($buffer, ($length - length($xml)));
				last if (length($buffer) == 0); # in case the socket has closed
				$xml .= $buffer;
			}

			return $xml;

		}
	}
}

=pod

	Net::EPP::Protocol->send_frame($socket, $xml);

This method prepares an RFC 4934 compliant EPP frame and transmits it to
the remote peer. C<$socket> must be an L<IO::Handle> or one of its
subclasses (ie C<IO::Socket::*>).

If the transmission fails for whatever reason, this method will
C<croak()>, so be sure to enclose it in an C<eval()>. Otherwise, it will
return a true value.

=cut

sub send_frame {
	my ($class, $fh, $xml) = @_;
	$fh->print($class->prep_frame($xml));
	$fh->flush;
	return 1;
}

=pod

	my $frame = Net::EPP::Protocol->prep_frame($xml);

This method returns the XML frame in "wire format" with the protocol
header prepended to it. The return value can be printed directly to an
open socket, for example:

	print STDOUT Net::EPP::Protocol->prep_frame($frame->toString);

=cut

sub prep_frame {
	my ($class, $xml) = @_;
	return pack('N', length($xml) + 4).$xml;
}

=pod

=head1 AUTHOR

CentralNic Ltd (L<http://www.centralnic.com/>).

=head1 COPYRIGHT

This module is (c) 2016 CentralNic Ltd. This module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * L<Net::EPP::Client>

=item * RFCs 4930 and RFC 4934, available from L<http://www.ietf.org/>.

=item * The CentralNic EPP site at L<http://www.centralnic.com/resellers/epp>.

=back

=cut

1;
