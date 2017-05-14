#!/usr/bin/env perl

#XXX Untested!!

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

        return if $c->type() ne 'tls-sni-02';

        my $token  = $c->token();
        my $kauthz = $c->make_key_authz( $reg->key() );

        my @sans = map {
            my $sha = Digest::SHA::sha256_hex($_);
            my $sha_first = substr( $sha, 0, length($sha) / 2, q<> );

            "$sha_first.$sha.$_.acme.invalid";
        } ( $token, $kauthz );

        print "Build an X.509 certificate with exactly the following “dNSName”s$/" print "in the “subjectAltName” extension:$/$/";

        print map { "\t$_$/$/" } @sans;

        print "… then make TLS connections to $domain:https serve up the$/";
        print "certificate in response to an SNI query that matches the first$/";
        print "value shown above.$/";

        <STDIN>;

        return $c;
    }
);

