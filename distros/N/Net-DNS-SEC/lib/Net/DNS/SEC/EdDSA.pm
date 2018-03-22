package Net::DNS::SEC::EdDSA;

#
# $Id: EdDSA.pm 1646 2018-03-12 12:52:45Z willem $
#
our $VERSION = (qw$LastChangedRevision: 1646 $)[1];


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

use strict;
use integer;
use warnings;
use MIME::Base64;

my %EdDSA = (
	15 => [ sub { Net::DNS::SEC::libcrypto::ED25519_sign(@_) },
		sub { Net::DNS::SEC::libcrypto::ED25519_verify(@_) },
		sub { Net::DNS::SEC::libcrypto::ED25519_public_from_private(@_) },
		32
		],
	16 => [ sub { Net::DNS::SEC::libcrypto::ED448_sign(@_) },
		sub { Net::DNS::SEC::libcrypto::ED448_verify(@_) },
		sub { Net::DNS::SEC::libcrypto::ED448_public_from_private(@_) },
		57
		],
	);


sub sign {
	my ( $class, $sigdata, $private ) = @_;

	my $algorithm = $private->algorithm;
	my ( $sign, $verify, $private2public, $keylen ) = @{$EdDSA{$algorithm} || []};
	die 'private key not EdDSA' unless $keylen;

	my $key = decode_base64( $private->PrivateKey );	# private key
	my $pub = &$private2public($key);			# public key

	&$sign( $sigdata, $pub, $key );
}


sub verify {
	my ( $class, $sigdata, $keyrr, $signature ) = @_;

	my $algorithm = $keyrr->algorithm;
	my ( $sign, $verify, $private2public, $keylen ) = @{$EdDSA{$algorithm} || []};
	die 'public key not EdDSA' unless $keylen;

	return unless $signature;

	my $keybin = pack "a$keylen", $keyrr->keybin;		# public key

	my $siglen = $keylen << 1;
	my $sigbin = pack "a$siglen", $signature;

	&$verify( $sigdata, $sigbin, $keybin );
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
RFC8032, RFC8080,
L<OpenSSL|http://www.openssl.org/docs>

=cut

