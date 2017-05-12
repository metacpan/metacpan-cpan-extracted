use strict;
use warnings;

use FindBin;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Digest::MD5 qw( md5_hex );

my $app = builder {
    enable 'DefaultDocument',
        '/favicon\.ico$' => "$FindBin::Bin/htdocs/favicon.ico",
        '/default.txt'   => "$FindBin::Bin/htdocs/default.txt",
        '/missing.txt'   => "$FindBin::Bin/htdocs/missing.txt";
    sub { [ 404, [], [ '' ] ] };
};

test_psgi $app, sub {
    my $cb = shift;

    my $res;
    $res = $cb->(GET 'http://localhost/favicon.ico');
    is $res->code, 200;
    is md5_hex($res->content), '75c6a605d7c93af389d28fbba960d500';
    is $res->headers->header('Content-Type'), 'image/vnd.microsoft.icon';

    $res = $cb->(GET 'http://localhost/default.txt');
    is $res->code, 200;
    is md5_hex($res->content), '256f98c0960a2aa6bad72dfb6e1f98bf';
    is $res->headers->header('Content-Type'), 'text/plain';
    
    $res = $cb->(GET 'http://localhost/404.txt');
    is $res->code, 404;
    is $res->headers->header('Content-Type'), undef;

    $res = $cb->(GET 'http://localhost/missing.txt');
    is $res->code, 404;
    is $res->headers->header('Content-Type'), undef;
};

done_testing;
