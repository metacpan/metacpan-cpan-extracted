use Mojo::Base -strict;
use lib qw(lib);

use Test::More tests => 6;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'UniqueTagHelpers';

my $t = Test::Mojo->new;

note 'Unique javascript';

get '/test' => {template => 'test'};
$t  ->get_ok('/test')
    ->status_is(200)
    ->element_exists('html > head > script:nth-of-type(1)')
    ->element_exists_not('html > head > script:nth-of-type(2)')
    ->element_exists('html > body > footer > script:nth-of-type(1)')
    ->element_exists_not('html > body > footer > script:nth-of-type(2)')
;

#diag $t->tx->res->body;

__DATA__
@@ test.html.ep
% layout 'default';

% javascript_for 'header' => begin
    window.alert('Hello World!');
% end
% javascript_for 'header' => begin
    window.alert('Hello World!');
% end
% javascript_for 'header' => begin
    window.alert('Hello World!');
% end

% javascript_for 'footer' => begin
    window.alert('Goodbye World!');
% end
% javascript_for 'footer' => begin
    window.alert('Goodbye World!');
% end
% javascript_for 'footer' => begin
    window.alert('Goodbye World!');
% end

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


