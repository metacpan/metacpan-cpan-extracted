use Mojo::Base -strict;
use lib qw(lib);

use Test::More tests => 6;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'UniqueTagHelpers';

my $t = Test::Mojo->new;

note 'Unique Mojo::URL';

get '/test' => {template => 'test'};
$t  ->get_ok('/test')
    ->status_is(200)
    ->element_exists('html > head > script:nth-of-type(1)[src="js/head.js"]')
    ->element_exists_not('html > head > script:nth-of-type(2)[src="js/head.js"]')
    ->element_exists('html > body > footer > script:nth-of-type(1)[src="js/foot.js"]')
    ->element_exists_not('html > body > footer > script:nth-of-type(2)[src="js/foot.js"]')
;

#diag $t->tx->res->body;

__DATA__
@@ test.html.ep
% layout 'default';

% javascript_for 'header' => url_for 'js/head.js';
% javascript_for 'header' => url_for 'js/head.js';
% javascript_for 'header' => url_for 'js/head.js';

% javascript_for 'footer' => url_for 'js/foot.js';
% javascript_for 'footer' => url_for 'js/foot.js';
% javascript_for 'footer' => url_for 'js/foot.js';


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
    <head>
        <title>LinkedUrl</title>
        %= javascript_for 'header';
    </head>
    <body>
        <%= content %>
        <footer>
            %= javascript_for 'footer';
        </footer>
    </body>
</html


