package Net::DNS::RR::L32;

use strict;
use warnings;
our $VERSION = (qw$Id: L32.pm 2003 2025-01-21 12:06:06Z willem $)[2];

use base qw(Net::DNS::RR);


=head1 NAME

Net::DNS::RR::L32 - DNS L32 resource record

=cut

use integer;


sub _decode_rdata {			## decode rdata from wire-format octet string
	my ( $self, $data, $offset ) = @_;

	@{$self}{qw(preference locator32)} = unpack "\@$offset n a4", $$data;
	return;
}


sub _encode_rdata {			## encode rdata as wire-format octet string
	my $self = shift;

	return pack 'n a4', $self->{preference}, $self->{locator32};
}


sub _format_rdata {			## format rdata portion of RR string.
	my $self = shift;

	return join ' ', $self->preference, $self->locator32;
}


sub _parse_rdata {			## populate RR from rdata in argument list
	my ( $self, @argument ) = @_;

	for (qw(preference locator32)) { $self->$_( shift @argument ) }
	return;
}


sub preference {
	my ( $self, @value ) = @_;
	for (@value) { $self->{preference} = 0 + $_ }
	return $self->{preference} || 0;
}


sub locator32 {
	my $self = shift;
	my $prfx = shift;

	$self->{locator32} = pack 'C* @4', split /\./, $prfx if defined $prfx;

	return $self->{locator32} ? join( '.', unpack 'C4', $self->{locator32} ) : undef;
}


my $function = sub {			## sort RRs in numerically ascending order.
	return $Net::DNS::a->{'preference'} <=> $Net::DNS::b->{'preference'};
};

__PACKAGE__->set_rrsort_func( 'preference', $function );

__PACKAGE__->set_rrsort_func( 'default_sort', $function );


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	$rr = Net::DNS::RR->new('name IN L32 preference locator32');

	$rr = Net::DNS::RR->new(
			name	   => 'example.com',
			type	   => 'L32',
			preference => 10,
			locator32  => '10.1.02.0'
			);

=head1 DESCRIPTION

Class for DNS 32-bit Locator (L32) resource records.

The L32 resource record is used to hold 32-bit Locator values for
ILNPv4-capable nodes.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 preference

	$preference = $rr->preference;
	$rr->preference( $preference );

A 16 bit unsigned integer in network byte order that indicates the
relative preference for this L32 record among other L32 records
associated with this owner name.  Lower values are preferred over
higher values.

=head2 locator32

 $locator32 = $rr->locator32;

The Locator32 field is an unsigned 32-bit integer in network byte
order that has the same syntax and semantics as a 32-bit IPv4
routing prefix.


=head1 COPYRIGHT

Copyright (c)2012 Dick Franks.

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
L<RFC6742|https://iana.org/go/rfc6742>

=cut
