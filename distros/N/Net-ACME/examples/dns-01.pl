#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use Digest::SHA  ();
use MIME::Base64 ();

use Net_ACME_Example ();

Net_ACME_Example::do_example(
    sub {
        my ( $domain, $cmb_ar, $reg ) = @_;

        return if @$cmb_ar > 1;

        my $c = $cmb_ar->[0];

        return if $c->type() ne 'dns-01';

        my $kauthz = $c->make_key_authz( $reg->key() );

        my $sha = Digest::SHA::sha256($kauthz);
        my $b64 = MIME::Base64::encode_base64url($sha);

        print "Create a TXT record for “_acme-challenge.$domain.”$/";
        print "with the following value:$/$/";

        print "\t$b64$/$/";

        <STDIN>;

        return $c;
    }
);
