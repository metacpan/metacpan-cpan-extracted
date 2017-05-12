#!perl -w
use strict;
use Test::Requires qw(Router::Simple);
use Test::More;

use Plack::Handler::CLI;
use Plack::Request;

my $router = Router::Simple->new();

$router->connect('/',      {controller => 'Root', action => 'index'});
$router->connect('/hello', {controller => 'Root', action => 'hello'});

sub hello {
    my($env) = @_;
    my $req = Plack::Request->new($env);

    note 'PATH_INFO=', $env->{REQUEST_URI};
    note 'PATH_INFO=', $env->{PATH_INFO};
    my $p = $router->match($env);

    ok $p, 'router matched';
    is $p->{controller}, 'Root';

    my $lang = $req->param('lang');
    return [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [ "Hello, $lang world!" ],
   ];
}

my $s = '';
my $out;
open $out, '>', \$s;
my $cli = Plack::Handler::CLI->new(stdout => $out);

$cli->run(\&hello, ['--lang' => 'PSGI/CLI']);
like $s, qr/Status: \s+ 200/xmsi, 'status';
like $s, qr{Hello, PSGI/CLI world!}, 'content';

open $out, '>', \$s;
$cli->run(\&hello, ['--lang=Foo']);
like $s, qr/Status: \s+ 200/xmsi, 'status';
like $s, qr{Hello, Foo world!}, 'content';

$cli = Plack::Handler::CLI->new(
    stdout       => $out,
    need_headers => 0,
);

open $out, '>', \$s;
$cli->run(sub {
    my($env) = @_;
    my $req = Plack::Request->new($env);

    is $req->path_info, '/hello', 'path_info';
    is $req->uri, 'http://localhost/hello?foo=bar%3Dbaz';
    is $req->param('foo'), 'bar=baz';

    my $p = $router->match($env);
    is $p->{controller}, 'Root';
    is $p->{action},     'hello';

    return [
        200,
        ['Content-Type' => 'text/plain'],
        ['Hello, world!'],
   ];
}, ['--foo' => 'bar=baz', 'hello']);

unlike $s, qr/Status: \s+ 200/xmsi, 'need_headers => 0';
is $s, 'Hello, world!';

done_testing;
