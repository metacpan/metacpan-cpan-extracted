package Net::DNS::SEC::ECCGOST;

#
# $Id: ECCGOST.pm 1758 2019-10-14 13:17:11Z willem $
#
our $VERSION = (qw$LastChangedRevision: 1758 $)[1];


=head1 NAME

Net::DNS::SEC::ECCGOST - DNSSEC ECC-GOST digital signature algorithm


=head1 SYNOPSIS

    require Net::DNS::SEC::ECCGOST;

    $validated = Net::DNS::SEC::ECCGOST->verify( $sigdata, $keyrr, $sigbin );


=head1 DESCRIPTION

Implementation of GOST R 34.10-2001 elliptic curve digital signature
verification procedure.

=head2 sign

Signature generation is not implemented.

=head2 verify

    $validated = Net::DNS::SEC::ECCGOST->verify( $sigdata, $keyrr, $sigbin );

Verifies the signature over the binary sigdata using the specified
public key resource record.

=cut


use strict;
use integer;
use warnings;

use constant Digest_GOST => defined( eval 'require Digest::GOST::CryptoPro' );
use constant ECCGOST_configured => Digest_GOST && Net::DNS::SEC::libcrypto->can('ECCGOST_verify');

BEGIN { die 'ECCGOST disabled or application has no "use Net::DNS::SEC"' unless ECCGOST_configured }

my %parameters = ( 12 => [840, 'Digest::GOST::CryptoPro'] );

sub _index { keys %parameters }


sub sign {
	die 'Russian Federation standard GOST R 34.10-2001 is obsolete';
}


sub verify {
	my ( $class, $sigdata, $keyrr, $sigbin ) = @_;

	my $algorithm = $keyrr->algorithm;
	my ( $nid, $object ) = @{$parameters{$algorithm} || []};
	die 'public key not ECC-GOST' unless $nid;
	my $hash = $object->new();
	$hash->add($sigdata);
	my $H = reverse $hash->digest;

	return unless $sigbin;

	my $eckey = Net::DNS::SEC::libcrypto::EC_KEY_new_ECCGOST();
	my ( $y, $x ) = unpack 'a32 a32', reverse $keyrr->keybin;    # public key
	Net::DNS::SEC::libcrypto::EC_KEY_set_public_key_affine_coordinates( $eckey, $x, $y );

	my ( $s, $r ) = unpack 'a32 a32', $sigbin;		# RFC5933, RFC4490
	Net::DNS::SEC::libcrypto::ECCGOST_verify( $H, $r, $s, $eckey );
}


1;

__END__

########################################

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

L<Net::DNS>, L<Net::DNS::SEC>, L<Digest::GOST>,
RFC4357, RFC4490, RFC5832, RFC5933, RFC7091

=cut

