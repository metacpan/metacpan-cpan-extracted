#!perl -w
use strict;
#use utf8;
use Encode qw/encode_utf8/;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

use Plack::Middleware::UnicodePictogramFallback::TypeCast;

my $sun_unicode  = "\xE2\x98\x80";
my $copy_unicode = encode_utf8 "\x{00A9}";
my $sake_unicode = encode_utf8 "\x{1F3EA}";
my $app = sub {
    [200, ['Content-Type' => 'text/html', 'Content-Length' => 16], ["<body>sake:$sake_unicode, (c):$copy_unicode, 晴れ:$sun_unicode</body>"]];
};

$app = Plack::Middleware::UnicodePictogramFallback::TypeCast->wrap($app,
    template => '<img src="/img/emoticon/%s.gif" />'
);

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET 'http://localhost/');
    is $res->code, 200;

    like $res->content, qr!emoticon/sun\.gif!;
    ok !$res->headers->content_length;
};

done_testing;
