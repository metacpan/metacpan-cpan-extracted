package Net::DNS::SEC::RSA;

#
# $Id: RSA.pm 1626 2018-01-31 09:48:15Z willem $
#
our $VERSION = (qw$LastChangedRevision: 1626 $)[1];


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
use Carp;
use Digest::SHA;
use MIME::Base64;

eval { require Digest::MD5 };		## deprecated ##

my %RSA = (
	1  => ['MD5',	 'Digest::MD5'],
	5  => ['SHA1',	 'Digest::SHA'],
	7  => ['SHA1',	 'Digest::SHA'],
	8  => ['SHA256', 'Digest::SHA', 256],
	10 => ['SHA512', 'Digest::SHA', 512],
	);


sub sign {
	my ( $class, $sigdata, $private ) = @_;

	my $algorithm = $private->algorithm;			# digest sigdata
	my ( $mnemonic, $object, @param ) = @{$RSA{$algorithm} || []};
	die 'public key not RSA' unless $object;
	my $hash = $object->new(@param);
	$hash->add($sigdata);

	my $nid = Net::DNS::SEC::libcrypto::get_NID($mnemonic);
	my $rsa = Net::DNS::SEC::libcrypto::RSA_new();

	my ( $n, $e, $d, $p, $q ) = map decode_base64( $private->$_ ),
			qw(Modulus PublicExponent PrivateExponent Prime1 Prime2);

	Net::DNS::SEC::libcrypto::RSA_set0_factors( $rsa, $p, $q );
	Net::DNS::SEC::libcrypto::RSA_set0_key( $rsa, $n, $e, $d );

	my $sig = Net::DNS::SEC::libcrypto::RSA_sign( $nid, $hash->digest, $rsa );

	Net::DNS::SEC::libcrypto::RSA_free($rsa);		# destroy private key
	return $sig;
}


sub verify {
	my ( $class, $sigdata, $keyrr, $sigbin ) = @_;

	my $algorithm = $keyrr->algorithm;			# digest sigdata
	my ( $mnemonic, $object, @param ) = @{$RSA{$algorithm} || []};
	die 'public key not RSA' unless $object;
	my $hash = $object->new(@param);
	$hash->add($sigdata);

	return unless $sigbin;

	my $nid = Net::DNS::SEC::libcrypto::get_NID($mnemonic);
	my $rsa = Net::DNS::SEC::libcrypto::RSA_new();

	my $keybin = $keyrr->keybin;				# public key
	my ( $short, $long ) = unpack( 'Cn', $keybin );		# RFC3110, section 2
	my $keyfmt = $short ? "x a$short a*" : "x3 a$long a*";
	my ( $exponent, $modulus ) = unpack( $keyfmt, $keybin );

	Net::DNS::SEC::libcrypto::RSA_set0_key( $rsa, $modulus, $exponent, '' );

	my $vrfy = Net::DNS::SEC::libcrypto::RSA_verify( $nid, $hash->digest, $sigbin, $rsa );

	Net::DNS::SEC::libcrypto::RSA_free($rsa);
	return $vrfy;
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

