use lib '.';
use t::Helper;

use Mojolicious::Lite;
plugin CGI => ['/not-found' => cgi_script('not-found.pl')];

Test::Mojo->new->get_ok('/not-found', {})->status_is(404)->content_like(qr'This page is missing');

done_testing;
