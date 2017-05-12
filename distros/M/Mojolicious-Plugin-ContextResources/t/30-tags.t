#!perl

use Mojo::Base -strict;
use lib qw(lib);

use Test::More tests => 8;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'ContextResources';

get '/stylesheet' => {template => 'foo/bar'};
get '/javascript' => {template => 'foo/baz'};

my $t = Test::Mojo->new;
$t  ->get_ok('/stylesheet')
    ->status_is(200)
    ->content_like(qr{Hello Stylesheet!})
    ->element_exists('html > head > link:nth-of-type(1)[href="/css/foo/bar.css"]')
;

#diag $t->tx->res->body;

$t  ->get_ok('/javascript')
    ->status_is(200)
    ->content_like(qr{Hello Javascript!})
    ->element_exists('html > body > footer > script:nth-of-type(1)[src="/js/foo/baz.js"]')
;


#diag $t->tx->res->body;

__DATA__
@@ foo/bar.html.ep
% layout 'default';

Hello Stylesheet!

@@ foo/baz.html.ep
% layout 'default';

Hello Javascript!

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
    <head>
        <title>Test</title>
        %= stylesheet_context;
    </head>
    <body>
        %= content
        <footer>
            %= javascript_context;
        </footer>
    </body>
</html>
