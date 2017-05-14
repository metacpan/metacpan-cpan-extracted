#!/usr/bin/env perl

#----------------------------------------------------------------------
# DEPRECATED. Use tls-sni-02 if possible.
#
# cf. https://tools.ietf.org/html/draft-ietf-acme-acme-01#section-7.3
#----------------------------------------------------------------------

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use Digest::SHA ();

use Net_ACME_Example ();

Net_ACME_Example::do_example(
    sub {
        my ( $domain, $cmb_ar, $reg ) = @_;

        return if @$cmb_ar > 1;

        my $c = $cmb_ar->[0];

        return if $c->type() ne 'tls-sni-01';

        my $kauthz = $c->make_key_authz( $reg->key() );

        my $sha = Digest::SHA::sha256_hex($kauthz);
        my $sha_first = substr( $sha, 0, length($sha) / 2, q<> );

        my $san = "$sha_first.$sha.acme.invalid";

        print "Build an X.509 certificate with exactly the following “dNSName”$/";
        print "in the “subjectAltName” extension:$/$/";

        print "\t$san$/$/";

        print "… then make TLS connections to $domain:https serve up the$/";
        print "certificate when the client’s SNI header is the value above.$/";

        <STDIN>;

        return $c;
    }
);
