package Net::DNS::SEC::DSA;

#
# $Id: DSA.pm 1660 2018-04-03 14:12:42Z willem $
#
our $VERSION = (qw$LastChangedRevision: 1660 $)[1];


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
use Digest::SHA;
use MIME::Base64;

my %DSA = (
	3 => ['Digest::SHA'],
	6 => ['Digest::SHA'],
	);


sub sign {
	my ( $class, $sigdata, $private ) = @_;

	my $algorithm = $private->algorithm;			# digest sigdata
	my ( $object, @param ) = @{$DSA{$algorithm} || []};
	die 'private key not DSA' unless $object;
	my $hash = $object->new(@param);
	$hash->add($sigdata);

	my ( $p, $q, $g, $x, $y ) = map decode_base64( $private->$_ ),
			qw(prime subprime base private_value public_value);

	my $dsa = Net::DNS::SEC::libcrypto::DSA_new();
	Net::DNS::SEC::libcrypto::DSA_set0_pqg( $dsa, $p, $q, $g );
	Net::DNS::SEC::libcrypto::DSA_set0_key( $dsa, $y, $x );

	my $sig = Net::DNS::SEC::libcrypto::DSA_do_sign( $hash->digest, $dsa );

	Net::DNS::SEC::libcrypto::DSA_free($dsa);		# destroy private key

	return unless $sig;					# uncoverable branch true

	my $t = ( length($g) - 64 ) / 8;
	my ( $r, $s ) = Net::DNS::SEC::libcrypto::DSA_SIG_get0($sig);
	Net::DNS::SEC::libcrypto::DSA_SIG_free($sig);

	# both the R and S parameters need to be 20 octets:
	my $Rpad = 20 - length($r);
	my $Spad = 20 - length($s);
	pack "C x$Rpad a* x$Spad a*", $t, $r, $s;		# RFC2536, section 3
}


sub verify {
	my ( $class, $sigdata, $keyrr, $sigbin ) = @_;

	my $algorithm = $keyrr->algorithm;			# digest sigdata
	my ( $object, @param ) = @{$DSA{$algorithm} || []};
	die 'public key not DSA' unless $object;
	my $hash = $object->new(@param);
	$hash->add($sigdata);

	return unless $sigbin;

	my $key = $keyrr->keybin;				# public key
	my $len = 64 + 8 * unpack( 'C', $key );			# RFC2536, section 2
	my ( $q, $p, $g, $y ) = unpack "x a20 a$len a$len a$len", $key;

	my $dsa = Net::DNS::SEC::libcrypto::DSA_new();
	Net::DNS::SEC::libcrypto::DSA_set0_pqg( $dsa, $p, $q, $g );
	Net::DNS::SEC::libcrypto::DSA_set0_key( $dsa, $y, '' );

	my ( $r, $s ) = unpack 'x a20 a20', $sigbin;		# RFC2536, section 3

	my $dsasig = Net::DNS::SEC::libcrypto::DSA_SIG_new();
	Net::DNS::SEC::libcrypto::DSA_SIG_set0( $dsasig, $r, $s );

	my $vrfy = Net::DNS::SEC::libcrypto::DSA_do_verify( $hash->digest, $dsasig, $dsa );

	Net::DNS::SEC::libcrypto::DSA_free($dsa);
	Net::DNS::SEC::libcrypto::DSA_SIG_free($dsasig);
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

L<Net::DNS>, L<Net::DNS::SEC>, L<Digest::SHA>,
RFC2536,
L<OpenSSL|http://www.openssl.org/docs>

=cut

