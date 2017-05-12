#!perl -w

use strict;
use Test::More;

use Plack::Handler::CLI;
use Plack::Request;

sub hello {
    my($env) = @_;
    my $req = Plack::Request->new($env);

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

open $out, '>', \$s;
$cli->run(\&hello, ['http://localhost?lang=Foo']);
like $s, qr/Status: \s+ 200/xmsi, 'status';
like $s, qr{Hello, Foo world!}, 'content';

$cli = Plack::Handler::CLI->new(
    stdout       => $out,
    need_headers => 0,
);

sub hello2 {
    my $req = Plack::Request->new(@_);

    is $req->path_info, '/a/b/c', 'path_info';
    is $req->uri, 'http://localhost/a/b/c?foo=bar%3Dbaz';
    is $req->param('foo'), 'bar=baz';

    return [
        200,
        ['Content-Type' => 'text/plain'],
        ['Hello, world!'],
   ];
}

open $out, '>', \$s;
$cli->run(\&hello2, ['--foo' => 'bar=baz', 'a', 'b', 'c']);
unlike $s, qr/Status: \s+ 200/xmsi, 'need_headers => 0';
is $s, 'Hello, world!';

open $out, '>', \$s;
$cli->run(\&hello2, ['--foo' => 'bar=baz', 'http://localhost/a/b/c']);
unlike $s, qr/Status: \s+ 200/xmsi, 'need_headers => 0';
is $s, 'Hello, world!';

open $out, '>', \$s;
$cli->run(\&hello2, ['http://localhost/a/b/c?foo=bar%3Dbaz']);
unlike $s, qr/Status: \s+ 200/xmsi, 'need_headers => 0';
is $s, 'Hello, world!';

done_testing;
