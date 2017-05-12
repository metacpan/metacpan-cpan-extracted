use strict;
use warnings;
use Test::More;

use Plack::Test;
use Plack::Builder;

use HTTP::Request::Common;

my @content_types = (
    'text/html',
    'text/html; charset=utf8',
    'application/xhtml+xml',
    'application/xhtml+xml; charset=utf8',
);

for my $content_type (@content_types) {
    note "Content-Type: $content_type";

    my $app = sub {
        return [
            200, [ 'Content-Type' => $content_type ],
            ['<body>Hello World</body>']
        ];
    };
    $app = builder {
        enable 'AutoReloadCSS', interval => 999;
        $app;
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');

        is   $res->code, 200, 'response status 200';
        like $res->content, qr{// CSS auto-reload \(c\) Nikita Vasilyev};
        like $res->content, qr{document\.styleSheets\.start_autoreload\(999\)};
    };
}

done_testing;
