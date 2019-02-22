use strict;
use warnings FATAL => 'all';
use Test::More;
use Plack::Middleware::Matomo;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

my $pkg;

BEGIN {
    $pkg = "Plack::Middleware::Matomo";
    use_ok $pkg;
}
require_ok $pkg;

my $app = builder {
    enable "Plack::Middleware::Matomo",
        id_site => "my-repo",
        base_url => "http://localhost/matomo",
        view_paths            => ['record/(\w+)/*'],
        download_paths        => ['download/(\w+)/*'],
        oai_identifier_format => 'oai:test.server.org:%s',
        ;

    mount '/record/123' =>
        sub {[200, ['Content-Type' => 'text/plain'], ["Hello World"]]};
    mount '/download/123' =>
        sub {[200, ['Content-Type' => 'text/plain'], ["Hello World"]]};
    mount '/somethingelse' =>
        sub {[200, ['Content-Type' => 'text/plain'], ["Hello World"]]};
    mount '/matomo' => sub {[200, ['Content-Type' => 'text/plain'], ["Successfully tracked."]]};
};

test_psgi
    app    => $app,
    client => sub {
    my $cb = shift;

    {
        my $req = GET "http://localhost/record/123";
        my $res = $cb->($req);
        is $res->is_success, 1, "view request";
    }

    {
        my $req = GET "http://localhost/download/123";
        my $res = $cb->($req);
        is $res->is_success, 1, "download request";
    }

    {
        my $req = GET "http://localhost/somethingelse";
        my $res = $cb->($req);
        is $res->is_success, 1, "GET route";
    }

    };

done_testing;
