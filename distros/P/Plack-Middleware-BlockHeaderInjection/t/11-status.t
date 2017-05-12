use strict;
use warnings;

use Test::More;

use HTTP::Request;
use Plack::Builder;
use Plack::Request;
use Plack::Response;
use Plack::Test;
use Plack::Util;

my $app = sub {
    my $env = shift;

    my $req = Plack::Request->new($env);

    my $res = [ 200, [ 'Content-Type' => 'text/plain' ], [] ];

    if (my $l = $req->parameters->{l}) {
        $res->[0] = 302;
        Plack::Util::header_push($res->[1], 'Location' => $l);
    }

    $res;
};

$app = builder {
    enable "BlockHeaderInjection",
      status => 403;
    $app;
};

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;

        my $req = HTTP::Request->new( 'GET', '/' );
        my $res = $cb->($req);
        is $res->code, 200, 'HTTP 200';

        $req = HTTP::Request->new( 'GET', "/?l=/foo" );
        $res = $cb->($req);
        is $res->code, 302, 'HTTP 302';
        is $res->header('Location'), '/foo', 'Location';

        $req = HTTP::Request->new( 'GET', "/?l=/foo\%0D%0AX-Hacked: true" );
        $res = $cb->($req);
        is $res->code, 403, 'HTTP 403';
        is $res->header('Location'), undef, 'no Location';
        is $res->header('X-Hacked'), undef, 'no extra header';

};

done_testing;
