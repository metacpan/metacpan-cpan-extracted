package Net::DNS::SEC::ECDSA;

use strict;
use warnings;

our $VERSION = (qw$Id: ECDSA.pm 1853 2021-10-11 10:40:59Z willem $)[2];


=head1 NAME

Net::DNS::SEC::ECDSA - DNSSEC ECDSA digital signature algorithm


=head1 SYNOPSIS

    require Net::DNS::SEC::ECDSA;

    $signature = Net::DNS::SEC::ECDSA->sign( $sigdata, $private );

    $validated = Net::DNS::SEC::ECDSA->verify( $sigdata, $keyrr, $sigbin );


=head1 DESCRIPTION

Implementation of ECDSA elliptic curve digital signature
generation and verification procedures.

=head2 sign

    $signature = Net::DNS::SEC::ECDSA->sign( $sigdata, $private );

Generates the wire-format signature from the sigdata octet string
and the appropriate private key object.

=head2 verify

    $validated = Net::DNS::SEC::ECDSA->verify( $sigdata, $keyrr, $sigbin );

Verifies the signature over the sigdata octet string using the specified
public key resource record.

=cut

use integer;
use MIME::Base64;

use constant ECDSA_configured => Net::DNS::SEC::libcrypto->can('EVP_PKEY_new_ECDSA');

BEGIN { die 'ECDSA disabled or application has no "use Net::DNS::SEC"' unless ECDSA_configured }


my %parameters = (
	13 => [415, 32, Net::DNS::SEC::libcrypto::EVP_sha256()],
	14 => [715, 48, Net::DNS::SEC::libcrypto::EVP_sha384()],
	);

sub _index { return keys %parameters }


sub sign {
	my ( $class, $sigdata, $private ) = @_;

	my $algorithm = $private->algorithm;
	my ( $nid, $keylen, $evpmd ) = @{$parameters{$algorithm} || []};
	die 'private key not ECDSA' unless $nid;

	my $rawkey = pack "a$keylen", decode_base64( $private->PrivateKey );
	my $evpkey = Net::DNS::SEC::libcrypto::EVP_PKEY_new_ECDSA( $nid, $rawkey, '' );

	my $asn1 = Net::DNS::SEC::libcrypto::EVP_sign( $sigdata, $evpkey, $evpmd );
	return _ASN1decode( $asn1, $keylen );
}


sub verify {
	my ( $class, $sigdata, $keyrr, $sigbin ) = @_;

	my $algorithm = $keyrr->algorithm;
	my ( $nid, $keylen, $evpmd ) = @{$parameters{$algorithm} || []};
	die 'public key not ECDSA' unless $nid;

	return unless $sigbin;

	my ( $x, $y ) = unpack "a$keylen a$keylen", $keyrr->keybin;
	my $evpkey = Net::DNS::SEC::libcrypto::EVP_PKEY_new_ECDSA( $nid, $x, $y );

	my $asn1 = _ASN1encode( $sigbin, $keylen );
	return Net::DNS::SEC::libcrypto::EVP_verify( $sigdata, $asn1, $evpkey, $evpmd );
}


########################################

sub _ASN1encode {
	my ( $sig, $size ) = @_;
	my @part = unpack "a$size a$size", $sig;
	my $length;
	foreach (@part) {
		s/^[\000]+//;
		s/^$/\000/;
		s/^(?=[\200-\377])/\000/;
		$_ = pack 'C2 a*', 2, length, $_;
		$length += length;
	}
	return pack 'C2 a* a*', 0x30, $length, @part;
}

sub _ASN1decode {
	my ( $asn1, $size ) = @_;
	my $n	 = unpack 'x3 C',	   $asn1;
	my $m	 = unpack "x5 x$n C",	   $asn1;
	my @part = unpack "x4 a$n x2 a$m", $asn1;
	return pack 'a* a*', map { substr( pack( "x$size a*", $_ ), -$size ) } @part;
}


1;

__END__

########################################

=head1 ACKNOWLEDGMENT

Thanks are due to Eric Young and the many developers and
contributors to the OpenSSL cryptographic library.


=head1 COPYRIGHT

Copyright (c)2014,2018 Dick Franks.

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

L<Net::DNS>, L<Net::DNS::SEC>,
RFC6090, RFC6605,
L<OpenSSL|http://www.openssl.org/docs>

=cut

