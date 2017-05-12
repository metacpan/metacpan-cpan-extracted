package Template_Basic;
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Mojo;
use Mojolicious::Plugin::PlackMiddleware;
use Mojo::Message::Request;
use Mojo::Message::Response;

use Test::More tests => 12;

{
    my $ioh = Mojolicious::Plugin::PlackMiddleware::_PSGIInput->new('543');
    my $buf;
    $ioh->read($buf, 1);
    is($buf, '5');
    $ioh->read($buf, 1);
    is($buf, '4');
    $ioh->read($buf, 1);
    is($buf, '3');
    $ioh->read($buf, 1);
    is($buf, '');
}
{
    my $ioh = Mojolicious::Plugin::PlackMiddleware::_PSGIInput->new('543');
    my $buf;
    $ioh->read($buf, 2);
    is($buf, '54');
    $ioh->read($buf, 2);
    is($buf, '3');
    $ioh->read($buf, 2);
    is($buf, '');
}
{
    my $ioh = Mojolicious::Plugin::PlackMiddleware::_PSGIInput->new('abcde');
    my $buf;
    $ioh->read($buf, 2);
    is($buf, 'ab');
    $ioh->read($buf, 2, 3);
    is($buf, 'de');
}

{
    my $psgi_res = [
        200,
        [a => 1, a => 2, b => 3, c => 4],
        [],
    ];
    
    my $mojo_res =
        Mojolicious::Plugin::PlackMiddleware::psgi_res_to_mojo_res($psgi_res);
    
    is_deeply(
        $mojo_res->headers->to_hash(1), {a =>[1,2], b => [3], c => [4]});
}

# req-env roundtrip
{
    my $mojo_req = Mojo::Message::Request->new;
    $mojo_req->parse("GET /foo/bar/baz.html HTTP/1.0\x0d\x0a");
    $mojo_req->parse("Host: 127.0.0.1\x0d\x0a");
    $mojo_req->parse("X-FOO: foo1\x0d\x0a");
    $mojo_req->parse("X-FOO: foo2\x0d\x0a");
    $mojo_req->parse("Content-Type: text/plain\x0d\x0a\x0d\x0a");
    
    my $plack_env =
        Mojolicious::Plugin::PlackMiddleware::mojo_req_to_psgi_env($mojo_req);
    is $plack_env->{'HTTP_X_FOO'}, 'foo1, foo2', 'right value';
    
    my $mojo_req2 =
        Mojolicious::Plugin::PlackMiddleware::psgi_env_to_mojo_req($plack_env);
    is $mojo_req2->headers->to_hash->{'X-FOO'}, 'foo1, foo2', 'roundtrip ok';
}

1;

__END__
