######################################################################
# Test suite for OAuth::Cmdline
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use Test::More;
use JSON qw( from_json );
use OAuth::Cmdline::Smartthings;

SKIP: { 

    if(! exists $ENV{"LIVE_TESTS"}) {
        skip "- only with LIVE_TESTS", 1;
    }

    my $oauth = OAuth::Cmdline::Smartthings->new;

    my $json = $oauth->http_get( $oauth->base_uri . 
        "/api/smartapps/endpoints" );

    if( !defined $json ) {
        die "Can't get endpoints";
    }

    my $uri = from_json( $json )->[ 0 ]->{ uri } . "/switches";
    my $data = $oauth->http_get( $uri );
    is $data, q/[{"name":"Outlet","value":"on"}]/, "report on switches";
}

done_testing;
