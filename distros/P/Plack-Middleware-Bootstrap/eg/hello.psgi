use strict;
use warnings;
use Plack::Builder;

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/html' ], [ "<h1>Hello</h1>\n<p>World!</p>" ] ];
};

builder {
    enable "Bootstrap";
    $app;
};
