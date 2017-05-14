#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use Net_ACME_Example ();

Net_ACME_Example::do_example(
    sub {
        my ( $domain, $cmb_ar, $reg ) = @_;

        return if @$cmb_ar > 1;

        my $c = $cmb_ar->[0];

        return if $c->type() ne 'http-01';

        print "Give the local docroot for “$domain”: ";
        my $docroot = <STDIN>;
        chomp $docroot;

        my $handler = $c->create_handler(
            $docroot,
            $reg->key(),    #jwk
        );

        return $c;
    }
);
