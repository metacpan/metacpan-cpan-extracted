#!perl

use strict;
use warnings;

use Test2::V0;
use Test2::Require::Internet;

use HTTP::Request::Common;
use HTTP::Status qw/ :constants /;
use HTTP::Tiny;
use Plack::Test;
use WWW::Mechanize::Chrome;

use CHI;
use Log::Log4perl qw/ :easy /;

use Plack::App::Prerender;

Log::Log4perl->easy_init($ERROR);

my $mech = eval {
    WWW::Mechanize::Chrome->new(
        headless         => 1,
        separate_session => 1,
    );
};

skip_all("Cannot start chrome browser") unless $mech;

$SIG{INT} = sub {
    $mech->close;
    exit 1;
} if $mech;

my $cache = CHI->new( driver => 'Memory', global => 1 );

my $handler = Plack::App::Prerender->new(
    mech    => $mech,
    rewrite => 'https://httpbin.org',
    cache   => $cache,
    wait    => 5,
);

test_psgi
    app    => $handler->to_app,
    client => sub {

        my $cb  = shift;
        my $req = GET '/';
        my $res = $cb->($req);

        is $res->code, HTTP_OK, join( " ", $req->method, $req->uri );

        like $res->content, qr/react-text/, 'has dynamic text';

};

$mech->close;

done_testing;
