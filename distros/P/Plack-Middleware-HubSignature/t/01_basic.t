use strict;
use warnings;
use utf8;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::HubSignature;

my $base_app = sub { [200, [], ['OK']] };
my $app = Plack::Middleware::HubSignature->wrap($base_app,
    secret => 'secret1234',
);

test_psgi $app => sub {
    my $cb  = shift;

    my $req = POST '/', [
        payload => '{"hoge":"fuga"}',
    ], 'X-GitHub-Event' => 'hoge', 'X-Hub-Signature' => 'sha1=3dff16c4e20f299484409ebc093e983286f5d0c3';

    my $res = $cb->($req);
    is $res->content, 'OK';

    $req = POST '/', [
        payload => '{"hoge":"fuga"}',
    ], 'X-GitHub-Event' => 'hoge';

    $res = $cb->($req);
    is $res->content, 'Forbidden';
    is $res->code, 403;

    $req = POST '/', [
        payload => '{"hoge":"fuga"}',
    ], 'X-GitHub-Event' => 'hoge', 'X-Hub-Signature' => 'invalid signature';

    $res = $cb->($req);
    is $res->content, 'Forbidden';
};

done_testing;
