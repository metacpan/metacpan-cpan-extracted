package Net::DNS::SEC::DSA;

#
# $Id: DSA.pm 1763 2020-02-02 21:48:03Z willem $
#
our $VERSION = (qw$LastChangedRevision: 1763 $)[1];


=head1 NAME

Net::DNS::SEC::DSA - DNSSEC DSA digital signature algorithm


=head1 SYNOPSIS

    require Net::DNS::SEC::DSA;

    $signature = Net::DNS::SEC::DSA->sign( $sigdata, $private );

    $validated = Net::DNS::SEC::DSA->verify( $sigdata, $keyrr, $sigbin );


=head1 DESCRIPTION

Implementation of DSA digital signature
generation and verification procedures.

=head2 sign

    $signature = Net::DNS::SEC::DSA->sign( $sigdata, $private );

Generates the wire-format signature from the sigdata octet string
and the appropriate private key object.

=head2 verify

    $validated = Net::DNS::SEC::DSA->verify( $sigdata, $keyrr, $sigbin );

Verifies the signature over the sigdata octet string using the specified
public key resource record.

=cut

use strict;
use integer;
use warnings;
use MIME::Base64;

use constant DSA_configured => Net::DNS::SEC::libcrypto->can('EVP_PKEY_assign_DSA');

BEGIN { die 'DSA disabled or application has no "use Net::DNS::SEC"' unless DSA_configured }


my %parameters = (
	3 => sub { Net::DNS::SEC::libcrypto::EVP_sha1() },
	6 => sub { Net::DNS::SEC::libcrypto::EVP_sha1() },
	);

sub _index { keys %parameters }


sub sign {
	my ( $class, $sigdata, $private ) = @_;

	my $index = $private->algorithm;
	my $evpmd = $parameters{$index} || die 'private key not DSA';

	my ( $p, $q, $g, $x, $y ) = map decode_base64( $private->$_ ),
			qw(prime subprime base private_value public_value);
	my $t = ( length($g) - 64 ) / 8;

	my $dsa = Net::DNS::SEC::libcrypto::DSA_new();
	Net::DNS::SEC::libcrypto::DSA_set0_pqg( $dsa, $p, $q, $g );
	Net::DNS::SEC::libcrypto::DSA_set0_key( $dsa, $y, $x );

	my $evpkey = Net::DNS::SEC::libcrypto::EVP_PKEY_new();
	Net::DNS::SEC::libcrypto::EVP_PKEY_assign_DSA( $evpkey, $dsa );

	my $asn1 = Net::DNS::SEC::libcrypto::EVP_sign( $sigdata, $evpkey, &$evpmd );
	_ASN1decode( $asn1, $t );
}


sub verify {
	my ( $class, $sigdata, $keyrr, $sigbin ) = @_;

	my $index = $keyrr->algorithm;
	my $evpmd = $parameters{$index} || die 'public key not DSA';

	return unless $sigbin;

	my $key = $keyrr->keybin;				# public key
	my $len = 64 + 8 * unpack( 'C', $key );			# RFC2536, section 2
	my ( $q, $p, $g, $y ) = unpack "x a20 a$len a$len a$len", $key;

	my $dsa = Net::DNS::SEC::libcrypto::DSA_new();
	Net::DNS::SEC::libcrypto::DSA_set0_pqg( $dsa, $p, $q, $g );
	Net::DNS::SEC::libcrypto::DSA_set0_key( $dsa, $y, '' );

	my $evpkey = Net::DNS::SEC::libcrypto::EVP_PKEY_new();
	Net::DNS::SEC::libcrypto::EVP_PKEY_assign_DSA( $evpkey, $dsa );

	my $asn1 = _ASN1encode($sigbin);
	Net::DNS::SEC::libcrypto::EVP_verify( $sigdata, $asn1, $evpkey, &$evpmd );
}


########################################

sub _ASN1encode {
	my @part = unpack 'x a20 a20', shift;			# discard "t"
	my $length;
	foreach (@part) {
		s/^[\000]+//;
		s/^$/\000/;
		s/^(?=[\200-\377])/\000/;
		$_ = pack 'C2 a*', 2, length, $_;
		$length += length;
	}
	pack 'C2 a* a*', 0x30, $length, @part;
}

sub _ASN1decode {
	my ( $asn1, $t ) = @_;
	my $n	 = unpack 'x3 C',	   $asn1;
	my $m	 = unpack "x5 x$n C",	   $asn1;
	my @part = unpack "x4 a$n x2 a$m", $asn1;
	pack 'C a* a*', $t, map substr( pack( 'x20 a*', $_ ), -20 ), @part;
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
RFC2536,
L<OpenSSL|http://www.openssl.org/docs>

=cut

