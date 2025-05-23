package Net::DNS::RR::A;

use strict;
use warnings;
our $VERSION = (qw$Id: A.pm 2003 2025-01-21 12:06:06Z willem $)[2];

use base qw(Net::DNS::RR);


=head1 NAME

Net::DNS::RR::A - DNS A resource record

=cut

use integer;


sub _decode_rdata {			## decode rdata from wire-format octet string
	my ( $self, $data, $offset ) = @_;

	$self->{address} = unpack "\@$offset a4", $$data;
	return;
}


sub _encode_rdata {			## encode rdata as wire-format octet string
	my $self = shift;

	return pack 'a4', $self->{address};
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


my $pad = pack 'x4';

sub address {
	my ( $self, $addr ) = @_;

	return join '.', unpack 'C4', $self->{address} . $pad unless defined $addr;

	# Note: pack masks overlarge values, mostly without warning
	my @part = split /\./, $addr;
	my $last = pop(@part);
	return $self->{address} = pack 'C4', @part, (0) x ( 3 - @part ), $last;
}


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	$rr = Net::DNS::RR->new('name IN A address');

	$rr = Net::DNS::RR->new(
			name	=> 'example.com',
			type	=> 'A',
			address => '192.0.2.1'
			);

=head1 DESCRIPTION

Class for DNS Address (A) resource records.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 address

	$IPv4_address = $rr->address;
	$rr->address( $IPv4_address );

Version 4 IP address represented using dotted-quad notation.


=head1 COPYRIGHT

Copyright (c)1997 Michael Fuhr. 

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
L<RFC1035(3.4.1)|https://iana.org/go/rfc1035#section-3.4.1>

=cut
