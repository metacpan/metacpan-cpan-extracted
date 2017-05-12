#!perl -w
use strict;
use warnings;
use utf8;

use Plack::Builder;

my $valid_html = q{
<html>
<head><title>hoge</title></head>
<body bgcolor="#000" style="color: #FFF"><h1>fuga</h1></body>
</html>
};

my $error_html = q{
<html>
<head><title>hoge</title></head>
<body bgcolor="#000" style="color: #FFF"><h1>fuga</h1><fuga>hoge</fuga></body>
</html>
};

builder {
    enable 'HTMLLint';
    mount '/text' => sub {
        return [200, ['Content-Type' => 'text/plain'], [ 'OK' ]];
    };
    mount '/valid_html' => sub {
        return [200, ['Content-Type' => 'text/html'], [$valid_html]];
    };
    mount '/error_html' => sub {
        return [200, ['Content-Type' => 'text/html'], [$error_html]];
    };
};
