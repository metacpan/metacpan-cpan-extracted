package Net::DNS::RR::EUI48;

use strict;
use warnings;
our $VERSION = (qw$Id: EUI48.pm 2003 2025-01-21 12:06:06Z willem $)[2];

use base qw(Net::DNS::RR);


=head1 NAME

Net::DNS::RR::EUI48 - DNS EUI48 resource record

=cut

use integer;


sub _decode_rdata {			## decode rdata from wire-format octet string
	my ( $self, $data, $offset ) = @_;

	$self->{address} = unpack "\@$offset a6", $$data;
	return;
}


sub _encode_rdata {			## encode rdata as wire-format octet string
	my $self = shift;

	return pack 'a6', $self->{address};
}


sub _format_rdata {			## format rdata portion of RR string.
	my $self = shift;

	return $self->address;
}


sub _parse_rdata {			## populate RR from rdata in argument list
	my ( $self, @argument ) = @_;

	$self->address(@argument);
	return;
}


sub address {
	my ( $self, $address ) = @_;
	$self->{address} = pack 'C6', map { hex($_) } split /[:-]/, $address if $address;
	return defined(wantarray) ? join( '-', unpack 'H2H2H2H2H2H2', $self->{address} ) : undef;
}


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	$rr = Net::DNS::RR->new('name IN EUI48 address');

	$rr = Net::DNS::RR->new(
			name	=> 'example.com',
			type	=> 'EUI48',
			address => '00-00-5e-00-53-2a'
			);

=head1 DESCRIPTION

DNS resource records for 48-bit Extended Unique Identifier (EUI48).

The EUI48 resource record is used to represent IEEE Extended Unique
Identifiers used in various layer-2 networks, ethernet for example.

EUI48 addresses SHOULD NOT be published in the public DNS.
RFC7043 describes potentially severe privacy implications resulting
from indiscriminate publication of link-layer addresses in the DNS.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 address
The address field is a 6-octet layer-2 address in network byte order.

The presentation format is hexadecimal separated by "-".


=head1 COPYRIGHT

Copyright (c)2013 Dick Franks.

All rights reserved.

Package template (c)2009,2012 O.M.Kolkman and R.W.Franks.


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the original copyright notices appear in all copies and that both
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


=head1 SEE ALSO

L<perl> L<Net::DNS> L<Net::DNS::RR>
L<RFC7043|https://iana.org/go/rfc7043>

=cut
