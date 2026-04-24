use v5.24;
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
        clean => 1;
    $app;
};

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;

        my $req = HTTP::Request->new( 'GET', '/' );
        my $res = $cb->($req);
        is $res->code, 200, 'HTTP 200';

        $req = HTTP::Request->new( 'GET', '/?l=/foo%0D%0AX-Hacked:+Yuck' );
        $res = $cb->($req);
        is $res->code, 302, 'HTTP 302';
        is $res->header('Location'), '/foo X-Hacked: Yuck', 'Location';


};

done_testing;
