#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/../lib";

use Net::ACME::Constants ();

use Net_ACME_Example ();

Net_ACME_Example::do_example(
    sub {
        my ( $domain, $cmb_ar, $reg ) = @_;

        return if @$cmb_ar > 1;

        my $c = $cmb_ar->[0];

        return if $c->type() ne 'http-01';

        my $token            = $c->token();
        my $key_authz        = $c->make_key_authz( $reg->key() );
        my $uri_to_be_loaded = "http://$domain/$Net::ACME::Constants::HTTP_01_CHALLENGE_DCV_DIR_IN_DOCROOT/$token";

        print "Now make it so that:$/$/\t$uri_to_be_loaded$/$/… contains this content:$/$/\t$key_authz$/";
        <STDIN>;

        return $c;
    }
);
