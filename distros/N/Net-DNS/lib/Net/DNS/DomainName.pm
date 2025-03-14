package Net::DNS::DomainName;

use strict;
use warnings;

our $VERSION = (qw$Id: DomainName.pm 2005 2025-01-28 13:22:10Z willem $)[2];


=head1 NAME

Net::DNS::DomainName - DNS name representation

=head1 SYNOPSIS

	use Net::DNS::DomainName;

	$object = Net::DNS::DomainName->new('example.com');
	$name = $object->name;
	$data = $object->encode;

	( $object, $next ) = Net::DNS::DomainName->decode( \$data, $offset );

=head1 DESCRIPTION

The Net::DNS::DomainName module implements the concrete representation
of DNS domain names used within DNS packets.

Net::DNS::DomainName defines methods for encoding and decoding wire
format octet strings. All other behaviour is inherited from
Net::DNS::Domain.

The Net::DNS::DomainName1035 and Net::DNS::DomainName2535 packages
implement disjoint domain name subtypes which provide the name
compression and canonicalisation specified by RFC1035 and RFC2535.
These are necessary to meet the backward compatibility requirements
introduced by RFC3597.

=cut


use base qw(Net::DNS::Domain);

use integer;
use Carp;


=head1 METHODS

=head2 new

	$object = Net::DNS::DomainName->new('example.com');

Creates a domain name object which identifies the domain specified
by the character string argument.


=head2 decode

	$object = Net::DNS::DomainName->decode( \$buffer, $offset, $hash );

	( $object, $next ) = Net::DNS::DomainName->decode( \$buffer, $offset, $hash );

Creates a domain name object which represents the DNS domain name
identified by the wire-format data at the indicated offset within
the data buffer.

The argument list consists of a reference to a scalar containing the
wire-format data and specified offset. The optional reference to a
hash table provides improved efficiency of decoding compressed names
by exploiting already cached compression pointers.

The returned offset value indicates the start of the next item in the
data buffer.

=cut

sub decode {
	my $label  = [];
	my $self   = bless {label => $label}, shift;
	my $buffer = shift;					# reference to data buffer
	my $offset = shift || 0;				# offset within buffer
	my $linked = shift;					# caller's compression index
	my $cache  = $linked;
	$cache->{$offset} = $self;				# hashed objectref by offset

	my $buflen = length $$buffer;
	my $index  = $offset;

	while ( $index < $buflen ) {
		my $header = unpack( "\@$index C", $$buffer )
				|| return wantarray ? ( $self, ++$index ) : $self;

		if ( $header < 0x40 ) {				# non-terminal label
			push @$label, substr( $$buffer, ++$index, $header );
			$index += $header;

		} elsif ( $header < 0xC0 ) {			# deprecated extended label types
			croak 'unimplemented label type';

		} else {					# compression pointer
			my $link = 0x3FFF & unpack( "\@$index n", $$buffer );
			croak 'corrupt compression pointer' unless $link < $offset;
			croak 'invalid compression pointer' unless $linked;

			# uncoverable condition false
			$self->{origin} = $cache->{$link} ||= __PACKAGE__->decode( $buffer, $link, $cache );
			return wantarray ? ( $self, $index + 2 ) : $self;
		}
	}
	croak 'corrupt wire-format data';
}


=head2 encode

	$data = $object->encode;

Returns the wire-format representation of the domain name suitable
for inclusion in a DNS packet buffer.

=cut

sub encode {
	return join '', map { pack 'C a*', length($_), $_ } shift->_wire, '';
}


=head2 canonical

	$data = $object->canonical;

Returns the canonical wire-format representation of the domain name
as defined in RFC2535(8.1).

=cut

sub canonical {
	my @label = shift->_wire;
	for (@label) {
		tr /\101-\132/\141-\172/;
	}
	return join '', map { pack 'C a*', length($_), $_ } @label, '';
}


########################################

package Net::DNS::DomainName1035;	## no critic ProhibitMultiplePackages
our @ISA = qw(Net::DNS::DomainName);

=head1 Net::DNS::DomainName1035

Net::DNS::DomainName1035 implements a subclass of domain name
objects which are to be encoded using the compressed wire format
defined in RFC1035.

	$data = $object->encode( $offset, $hash );

The arguments are the offset within the packet data where
the domain name is to be stored and a reference to a hash table used
to index compressed names within the packet.

Note that RFC3597 implies that only the RR types defined in RFC1035(3.3)
are eligible for compression of domain names occuring in RDATA.

If the hash reference is undefined, encode() returns the lower case
uncompressed canonical representation defined in RFC2535(8.1).

=cut

sub encode {
	my $self   = shift;
	my $offset = shift || 0;				# offset in data buffer
	my $hash   = shift || return $self->canonical;		# hashed offset by name

	my @labels = $self->_wire;
	my $data   = '';
	while (@labels) {
		my $name = join( '.', @labels );

		return $data . pack( 'n', 0xC000 | $hash->{$name} ) if defined $hash->{$name};

		my $label  = shift @labels;
		my $length = length $label;
		$data .= pack( 'C a*', $length, $label );

		next unless $offset < 0x4000;
		$hash->{$name} = $offset;
		$offset += 1 + $length;
	}
	return $data .= pack 'x';
}


########################################

package Net::DNS::DomainName2535;	## no critic ProhibitMultiplePackages
our @ISA = qw(Net::DNS::DomainName);

=head1 Net::DNS::DomainName2535

Net::DNS::DomainName2535 implements a subclass of domain name
objects which are to be encoded using uncompressed wire format.

	$data = $object->encode( $offset, $hash );

The arguments are the offset within the packet data where
the domain name is to be stored and a reference to a hash table used
to index names already encoded within the packet.

If the hash reference is undefined, encode() returns the lower case
uncompressed canonical representation defined in RFC2535(8.1).

Note that RFC3597, and latterly RFC4034, specifies that the lower case
canonical form is to be used for RR types defined prior to RFC3597.

=cut

sub encode {
	my ( $self, $offset, $hash ) = @_;
	return $self->canonical unless defined $hash;
	my $name = join '.', my @labels = $self->_wire;
	$hash->{$name} = $offset if $offset < 0x4000;
	return join '', map { pack 'C a*', length($_), $_ } @labels, '';
}

1;
__END__


########################################

=head1 COPYRIGHT

Copyright (c)2009-2011 Dick Franks.

All rights reserved.


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

L<perl> L<Net::DNS> L<Net::DNS::Domain>
L<RFC1035|https://iana.org/go/rfc1035>
L<RFC2535|https://iana.org/go/rfc2535>
L<RFC3597|https://iana.org/go/rfc3597>
L<RFC4034|https://iana.org/go/rfc4034>

=cut

