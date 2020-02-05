#!/usr/bin/env perl

package t::Net::Curl::Promiser::Select_setopt_fail;

use strict;
use warnings;
use autodie;

use parent qw( Test::Class::Tiny );

use Test::More;
use Test::FailWarnings;
use Test::Deep;
use Test::Fatal;

use Net::Curl::Promiser::Select ();
use Net::Curl::Multi;

__PACKAGE__->runtests() if !caller;

sub T2_setopt_confirm_fails {
    my $curl = Net::Curl::Promiser::Select->new();

    for my $opt ( qw( SOCKETFUNCTION  SOCKETDATA ) ) {
        my $fullopt = "CURLMOPT_$opt";

        cmp_deeply(
            exception { $curl->setopt( Net::Curl::Multi->can($fullopt)->(), sub {} ) },
            all(
                re( qr<$fullopt> ),
                re( qr<Net::Curl::Promiser::Select> ),
            ),
            "set $fullopt",
        );
    }
}

1;
