#!/usr/bin/env perl

#----------------------------------------------------------------------
# DEPRECATED. Use tls-sni-02 or a different challenge method.
#
# tls-sni-01 literally just parrots back the requested SNI query, fancified
# into a subjectAltName. Thus, any server can answer this challenge
# by using no information other than what’s in the challenge request. This
# allows people who don’t control a given domain to have LE issue them a
# certificate for one:
#
# - Server A hosts “mysite.test” as well as an HTTPS server that responds
#   to any tls-sni-01 request with an appropriate self-signed certificate,
#   based on the contents of the SNI query.
#
# - Attacker requests a cert via ACME for “mysite.test”.
#
# - Since the request to server A contains exactly what server A needs to
#   put into the challenge response, the challenge will succeed, and the
#   Attacker will receive a certificate.
#
#----------------------------------------------------------------------
# cf. https://tools.ietf.org/html/draft-ietf-acme-acme-01#section-7.3
#
# The specification above is more complex than this little implementation;
# however, in practice, the below seems to be all that Boulder
# (Let’s Encrypt) asks for to execute the challenge. Given that tls-sni-01
# is deprecated anyway, any change here seems unlikely.
#----------------------------------------------------------------------

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use Digest::SHA ();

use Net_ACME_Example ();

Net_ACME_Example::do_example(
    sub {
        my ( $domain, $cmb_ar, $key_jwk ) = @_;

        return if @$cmb_ar > 1;

        my $c = $cmb_ar->[0];

        return if $c->type() ne 'tls-sni-01';

        my $kauthz = $c->make_key_authz( $key_jwk );

        my $sha = Digest::SHA::sha256_hex($kauthz);
        my $sha_first = substr( $sha, 0, length($sha) / 2, q<> );

        my $san = "$sha_first.$sha.acme.invalid";

        print "Build an X.509 certificate with exactly the following “dNSName”$/";
        print "in the “subjectAltName” extension:$/$/";

        print "\t$san$/$/";

        print "… then make TLS connections to $domain:https serve up the$/";
        print "certificate when the client’s SNI header is the value above.$/$/";

        print "NOTE THE INHERENT PROBLEM WITH THIS LOGIC: the response to the$/";
        print "tls-sni-01 challenge needs no connection to the party requesting$/";
        print "the authz except what’s given in the challenge itself.$/";

        <STDIN>;

        return $c;
    }
);
