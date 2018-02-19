package Net::DNS::SEC::ECDSA;

#
# $Id: ECDSA.pm 1626 2018-01-31 09:48:15Z willem $
#
our $VERSION = (qw$LastChangedRevision: 1626 $)[1];


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

use strict;
use integer;
use warnings;
use Carp;
use Digest::SHA;
use MIME::Base64;

my %ECDSA = (
	13 => [415, 'Digest::SHA', 256],
	14 => [715, 'Digest::SHA', 384],
	);


sub sign {
	my ( $class, $sigdata, $private ) = @_;

	my $algorithm = $private->algorithm;			# digest sigdata
	my ( $NID, $object, @param ) = @{$ECDSA{$algorithm} || []};
	die 'private key not ECDSA' unless $object;
	my $hash = $object->new(@param);
	$hash->add($sigdata);
	my $digest = $hash->digest;

	my $key = decode_base64( $private->PrivateKey );	# private key
	my $len = length $key;

	my $eckey = Net::DNS::SEC::libcrypto::EC_KEY_dup( _curve($NID) );
	Net::DNS::SEC::libcrypto::EC_KEY_set_private_key( $eckey, $key );

	my $sig = Net::DNS::SEC::libcrypto::ECDSA_do_sign( $digest, $eckey );

	Net::DNS::SEC::libcrypto::EC_KEY_free($eckey);		# destroy private key

	return unless $sig;					# uncoverable branch true

	my ( $r, $s ) = Net::DNS::SEC::libcrypto::ECDSA_SIG_get0($sig);
	Net::DNS::SEC::libcrypto::ECDSA_SIG_free($sig);

	# both the R and S parameters need to be zero padded:
	my $Rpad = $len - length($r);
	my $Spad = $len - length($s);
	pack "x$Rpad a* x$Spad a*", $r, $s;
}


sub verify {
	my ( $class, $sigdata, $keyrr, $sigbin ) = @_;

	my $algorithm = $keyrr->algorithm;			# digest sigdata
	my ( $NID, $object, @param ) = @{$ECDSA{$algorithm} || []};
	die 'public key not ECDSA' unless $object;
	my $hash = $object->new(@param);
	$hash->add($sigdata);
	my $digest = $hash->digest;

	return unless $sigbin;

	my $key = $keyrr->keybin;				# public key
	my $len = length($key) >> 1;
	my ( $x, $y ) = unpack "a$len a*", $key;

	my $eckey = Net::DNS::SEC::libcrypto::EC_KEY_dup( _curve($NID) );
	Net::DNS::SEC::libcrypto::EC_KEY_set_public_key_affine_coordinates( $eckey, $x, $y );

	my ( $r, $s ) = unpack( "a$len a*", $sigbin );		# signature

	my $sig = Net::DNS::SEC::libcrypto::ECDSA_SIG_new();
	Net::DNS::SEC::libcrypto::ECDSA_SIG_set0( $sig, $r, $s );

	my $vrfy = Net::DNS::SEC::libcrypto::ECDSA_do_verify( $digest, $sig, $eckey );

	Net::DNS::SEC::libcrypto::EC_KEY_free($eckey);
	Net::DNS::SEC::libcrypto::ECDSA_SIG_free($sig);
	return $vrfy;
}


########################################

{
	my %ECkey;

	sub _curve {
		my $nid = shift;
		return $ECkey{$nid} if $ECkey{$nid};
		$ECkey{$nid} = Net::DNS::SEC::libcrypto::EC_KEY_new_by_curve_name($nid);
	}

	END {
		foreach ( grep defined, values %ECkey ) {
			Net::DNS::SEC::libcrypto::EC_KEY_free($_);
		}
	}
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
RFC6090, RFC6605,
L<OpenSSL|http://www.openssl.org/docs>

=cut

