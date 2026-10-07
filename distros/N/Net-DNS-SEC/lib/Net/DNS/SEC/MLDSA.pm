package Net::DNS::SEC::MLDSA;

use strict;
use warnings;

our $VERSION = (qw$Id: MLDSA.pm 2063 2026-10-05 11:02:58Z willem $)[2];


=head1 NAME

Net::DNS::SEC::MLDSA - DNSSEC Module-Lattice digital signature algorithm


=head1 SYNOPSIS

	require Net::DNS::SEC::MLDSA;

	$signature = Net::DNS::SEC::MLDSA->sign( $sigdata, $private );

	$validated = Net::DNS::SEC::MLDSA->verify( $sigdata, $keyrr, $sigbin );


=head1 DESCRIPTION

Implementation of Module-Lattice digital signature
generation and verification procedures.

=head2 sign

	$signature = Net::DNS::SEC::MLDSA->sign( $sigdata, $private );

Generates the wire-format signature from the sigdata octet string
and the appropriate private key object.

=head2 verify

	$validated = Net::DNS::SEC::MLDSA->verify( $sigdata, $keyrr, $signature );

Verifies the signature over the sigdata octet string using the specified
public key resource record.

=cut

use integer;
use MIME::Base64;

use constant MLDSA_configured => Net::DNS::SEC::libcrypto->can('EVP_PKEY_new_MLDSA');

BEGIN { die 'MLDSA disabled or application has no "use Net::DNS::SEC"' unless MLDSA_configured }


my %parameters = ( 18 => ['ML-DSA-44', 1312, 2420], );

sub _index	{ return keys %parameters }
sub _deprecate	{ return my @empty }


sub sign {
	my ( $class, $sigdata, $private ) = @_;

	my $algorithm = $private->algorithm;
	my ( $flavour, $keylen ) = @{$parameters{$algorithm} || []};
	return unless $flavour;

	my $rawkey = decode_base64( $private->PrivateKey );
	my $evpkey = Net::DNS::SEC::libcrypto::EVP_PKEY_new_MLDSA( $flavour, $rawkey );

	return Net::DNS::SEC::libcrypto::EVP_sign( $sigdata, $evpkey );
}


sub verify {
	my ( $class, $sigdata, $keyrr, $signature ) = @_;

	my $algorithm = $keyrr->algorithm;
	my ( $flavour, $keylen, $siglen ) = @{$parameters{$algorithm} || []};
	return unless $flavour;

	return unless $signature;

	my $rawkey = pack "a$keylen", $keyrr->keybin;
	my $evpkey = Net::DNS::SEC::libcrypto::EVP_PKEY_new_MLDSA( $flavour, $rawkey );

	my $sigbin = pack "a$siglen", $signature;
	return Net::DNS::SEC::libcrypto::EVP_verify( $sigdata, $sigbin, $evpkey );
}


1;
__END__

########################################

=head1 ACKNOWLEDGMENT

Thanks are due to Eric Young and the many developers and
contributors to the OpenSSL cryptographic library.


=head1 COPYRIGHT

Copyright (c)2026 Dick Franks.

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
RFC8032, RFC8080,
L<OpenSSL|http://www.openssl.org/docs>

=cut

