#!perl

use strict;
use warnings;

use Test::More;

use LWP::UserAgent;
use PAUSE::Packages;

SKIP: {
    skip 'Enable live tests via PP_LIVE_TEST=1', 1 unless $ENV{PP_LIVE_TEST};
    {
        my $pp = PAUSE::Packages->new();

        ok( $pp->release( 'Acme-Urinal' ), 'has Acme-Urinal release.' );
    }

    {
        my $pp = PAUSE::Packages->new();
        ok( $pp->from_cache, 'is cached via HTTP::Tiny' );
    }

    {
        my $pp = PAUSE::Packages->new( ua => LWP::UserAgent->new);
        ok( $pp->from_cache, 'is cached via LWP::UserAgent' );
    }

}

done_testing();
