package Net::DNS::SEC::RSA;

#
# $Id: RSA.pm 1763 2020-02-02 21:48:03Z willem $
#
our $VERSION = (qw$LastChangedRevision: 1763 $)[1];


=head1 NAME

Net::DNS::SEC::RSA - DNSSEC RSA digital signature algorithm


=head1 SYNOPSIS

    require Net::DNS::SEC::RSA;

    $signature = Net::DNS::SEC::RSA->sign( $sigdata, $private );

    $validated = Net::DNS::SEC::RSA->verify( $sigdata, $keyrr, $sigbin );


=head1 DESCRIPTION

Implementation of RSA digital signature
generation and verification procedures.

=head2 sign

    $signature = Net::DNS::SEC::RSA->sign( $sigdata, $private );

Generates the wire-format signature from the sigdata octet string
and the appropriate private key object.

=head2 verify

    $validated = Net::DNS::SEC::RSA->verify( $sigdata, $keyrr, $sigbin );

Verifies the signature over the sigdata octet string using the specified
public key resource record.

=cut

use strict;
use integer;
use warnings;
use MIME::Base64;

use constant RSA_configured => Net::DNS::SEC::libcrypto->can('EVP_PKEY_assign_RSA');

BEGIN { die 'RSA disabled or application has no "use Net::DNS::SEC"' unless RSA_configured }


my %parameters = (
	1  => sub { Net::DNS::SEC::libcrypto::EVP_md5() },
	5  => sub { Net::DNS::SEC::libcrypto::EVP_sha1() },
	7  => sub { Net::DNS::SEC::libcrypto::EVP_sha1() },
	8  => sub { Net::DNS::SEC::libcrypto::EVP_sha256() },
	10 => sub { Net::DNS::SEC::libcrypto::EVP_sha512() },
	);

sub _index { keys %parameters }


sub sign {
	my ( $class, $sigdata, $private ) = @_;

	my $index = $private->algorithm;
	my $evpmd = $parameters{$index} || die 'private key not RSA';

	my ( $n, $e, $d, $p, $q ) = map decode_base64( $private->$_ ),
			qw(Modulus PublicExponent PrivateExponent Prime1 Prime2);

	my $rsa = Net::DNS::SEC::libcrypto::RSA_new();
	Net::DNS::SEC::libcrypto::RSA_set0_factors( $rsa, $p, $q );
	Net::DNS::SEC::libcrypto::RSA_set0_key( $rsa, $n, $e, $d );

	my $evpkey = Net::DNS::SEC::libcrypto::EVP_PKEY_new();
	Net::DNS::SEC::libcrypto::EVP_PKEY_assign_RSA( $evpkey, $rsa );

	Net::DNS::SEC::libcrypto::EVP_sign( $sigdata, $evpkey, &$evpmd );
}


sub verify {
	my ( $class, $sigdata, $keyrr, $sigbin ) = @_;

	my $index = $keyrr->algorithm;
	my $evpmd = $parameters{$index} || die 'public key not RSA';

	return unless $sigbin;

	my $keybin = $keyrr->keybin;				# public key
	my ( $short, $long ) = unpack( 'Cn', $keybin );		# RFC3110, section 2
	my $keyfmt = $short ? "x a$short a*" : "x3 a$long a*";
	my ( $exponent, $modulus ) = unpack( $keyfmt, $keybin );

	my $rsa = Net::DNS::SEC::libcrypto::RSA_new();
	Net::DNS::SEC::libcrypto::RSA_set0_key( $rsa, $modulus, $exponent, '' );

	my $evpkey = Net::DNS::SEC::libcrypto::EVP_PKEY_new();
	Net::DNS::SEC::libcrypto::EVP_PKEY_assign_RSA( $evpkey, $rsa );

	Net::DNS::SEC::libcrypto::EVP_verify( $sigdata, $sigbin, $evpkey, &$evpmd );
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
that the above copyright notice appear in all copies and that both that
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
RFC8017, RFC3110,
L<OpenSSL|http://www.openssl.org/docs>

=cut

