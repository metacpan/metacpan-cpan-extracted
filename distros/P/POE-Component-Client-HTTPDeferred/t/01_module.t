use Test::Base;

use t::Util;

plan tests => 5;

use HTTP::Request::Common;
use POE::Component::Client::HTTPDeferred;

run_session {
    my $ua = POE::Component::Client::HTTPDeferred->new;
    my $d  = $ua->request( GET 'http://www.google.com/' );

    isa_ok( $d, 'POE::Component::Client::HTTPDeferred::Deferred' );

    $d->addBoth(sub {
        my $res = shift;

        isa_ok( $res, 'HTTP::Response' );
        like( $res->code, qr/^(200|302)$/, 'status is 200 or 302' );
        like( $res->base, qr/google/, 'base url ok' );
        like( $res->content, qr/google/i, 'content probably ok' );

        $ua->shutdown;
    });
};

