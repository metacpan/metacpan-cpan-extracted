use Mojo::Base -strict;
use lib qw(lib);

use Test::More tests => 6;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'UniqueTagHelpers';

my $t = Test::Mojo->new;

note 'Unique stylesheet';

get '/test' => {template => 'test'};
$t  ->get_ok('/test')
    ->status_is(200)
    ->element_exists('html > head > style:nth-of-type(1)')
    ->element_exists_not('html > head > style:nth-of-type(2)')
    ->element_exists('html > body > footer > style:nth-of-type(1)')
    ->element_exists_not('html > body > footer > style:nth-of-type(2)')
;

#diag $t->tx->res->body;

__DATA__
@@ test.html.ep
% layout 'default';

% stylesheet_for 'header' => begin
    body { width: 100% }
% end;
% stylesheet_for 'header' => begin
    body { width: 100% }
% end;
% stylesheet_for 'header' => begin
    body { width: 100% }
% end;

% stylesheet_for 'footer' => begin
    body { height: 100% }
% end;
% stylesheet_for 'footer' => begin
    body { height: 100% }
% end;
% stylesheet_for 'footer' => begin
    body { height: 100% }
% end;

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


