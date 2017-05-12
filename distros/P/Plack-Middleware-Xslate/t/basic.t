#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Plack::Builder;

my $app = builder {
    enable "Xslate",
        path => qr{^/}, root => 't/basic/', pass_through => 1;
    sub { [ 404, [], [ 'Not found' ] ] };
};

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/index.html');
            ok($res->is_success) || diag($res->content);
            my $rendered = <<'CONTENT';
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" type="text/css" href="/style.css" />
</head>
<body>
<h1>Hello world</h1>
</body>
</html>
CONTENT
            is($res->content, $rendered);
            is($res->header('Content-Length'), length($rendered));
        }

        {
            my $res = $cb->(GET '/missing.html');
            is($res->code, 404);
        }
    };

done_testing;
