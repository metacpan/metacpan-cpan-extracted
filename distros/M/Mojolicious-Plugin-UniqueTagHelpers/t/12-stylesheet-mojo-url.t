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
    ->element_exists('html > head > link:nth-of-type(1)[href="css/head.css"]')
    ->element_exists_not('html > head > link:nth-of-type(2)[href="css/head.css"]')
    ->element_exists('html > body > footer > link:nth-of-type(1)[href="css/foot.css"]')
    ->element_exists_not('html > body > footer > link:nth-of-type(2)[href="css/foot.css"]')
;

#diag $t->tx->res->body;

__DATA__
@@ test.html.ep
% layout 'default';

% stylesheet_for 'header' => url_for 'css/head.css';
% stylesheet_for 'header' => url_for 'css/head.css';
% stylesheet_for 'header' => url_for 'css/head.css';

% stylesheet_for 'footer' => url_for 'css/foot.css';
% stylesheet_for 'footer' => url_for 'css/foot.css';
% stylesheet_for 'footer' => url_for 'css/foot.css';

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
    <head>
        <title>LinkedUrl</title>
        %= stylesheet_for 'header';
    </head>
    <body>
        <%= content %>
        <footer>
            %= stylesheet_for 'footer';
        </footer>
    </body>
</html


