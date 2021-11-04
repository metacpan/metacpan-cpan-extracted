package Net::DNS::SEC::EdDSA;

use strict;
use warnings;

our $VERSION = (qw$Id: EdDSA.pm 1853 2021-10-11 10:40:59Z willem $)[2];


=head1 NAME

Net::DNS::SEC::EdDSA - DNSSEC EdDSA digital signature algorithm


=head1 SYNOPSIS

    require Net::DNS::SEC::EdDSA;

    $signature = Net::DNS::SEC::EdDSA->sign( $sigdata, $private );

    $validated = Net::DNS::SEC::EdDSA->verify( $sigdata, $keyrr, $sigbin );


=head1 DESCRIPTION

Implementation of EdDSA Edwards curve digital signature
generation and verification procedures.

=head2 sign

    $signature = Net::DNS::SEC::EdDSA->sign( $sigdata, $private );

Generates the wire-format signature from the sigdata octet string
and the appropriate private key object.

=head2 verify

    $validated = Net::DNS::SEC::EdDSA->verify( $sigdata, $keyrr, $signature );

Verifies the signature over the sigdata octet string using the specified
public key resource record.

=cut

use integer;
use MIME::Base64;

use constant EdDSA_configured => Net::DNS::SEC::libcrypto->can('EVP_PKEY_new_raw_public_key');

BEGIN { die 'EdDSA disabled or application has no "use Net::DNS::SEC"' unless EdDSA_configured }


my %parameters = (
	15 => [1087, 32, 64],
	16 => [1088, 57, 114],
	);

sub _index { return keys %parameters }


sub sign {
	my ( $class, $sigdata, $private ) = @_;

	my $algorithm = $private->algorithm;
	my ( $nid, $keylen ) = @{$parameters{$algorithm} || []};
	die 'private key not EdDSA' unless $nid;

	my $rawkey = pack "a$keylen", decode_base64( $private->PrivateKey );
	my $evpkey = Net::DNS::SEC::libcrypto::EVP_PKEY_new_raw_private_key( $nid, $rawkey );

	return Net::DNS::SEC::libcrypto::EVP_sign( $sigdata, $evpkey );
}


sub verify {
	my ( $class, $sigdata, $keyrr, $signature ) = @_;

	my $algorithm = $keyrr->algorithm;
	my ( $nid, $keylen, $siglen ) = @{$parameters{$algorithm} || []};
	die 'public key not EdDSA' unless $nid;

	return unless $signature;

	my $rawkey = pack "a$keylen", $keyrr->keybin;
	my $evpkey = Net::DNS::SEC::libcrypto::EVP_PKEY_new_raw_public_key( $nid, $rawkey );

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
RFC8032, RFC8080,
L<OpenSSL|http://www.openssl.org/docs>

=cut

