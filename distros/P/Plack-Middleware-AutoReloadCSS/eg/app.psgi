use strict;
use warnings;

use FindBin;
use Plack::Builder;

my $app = sub {
    return [
        200,
        [ 'Content-Type' => 'text/html' ],
        [
            '<head><link rel="stylesheet" href="/css/main.css" type="text/css" /></head>',
            '<body>Hello World</body>',
        ]
    ];
};

$app = builder {
    enable 'Plack::Middleware::Static',
        path => qr{^/css/},
        root => "$FindBin::Bin/static";
    enable 'AutoReloadCSS', interval => 1000;
    $app;
};
