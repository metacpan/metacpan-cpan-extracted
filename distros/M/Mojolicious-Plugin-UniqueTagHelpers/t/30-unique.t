use Mojo::Base -strict;
use lib qw(lib);

use Test::More tests => 4;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'UniqueTagHelpers';

my $t = Test::Mojo->new;

note 'Unique content';

get '/test' => {template => 'test'};
$t  ->get_ok('/test')
    ->status_is(200)
    ->element_exists('html > body > footer > div.abc:nth-of-type(1)')
    ->element_exists_not('html > body > footer > div.abc:nth-of-type(2)')
;

#diag $t->tx->res->body;

__DATA__
@@ test.html.ep
% layout 'default';

% unique_for 'footer' => '<div class="abc"></div>';
% unique_for 'footer' => '<div class="abc"></div>';
% unique_for 'footer' => '<div class="abc"></div>';

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
    <head>
        <title>LinkedUrl</title>
        %= content_for 'header';
    </head>
    <body>
        <%= content %>
        <footer>
            %= content_for 'footer';
        </footer>
    </body>
</html


