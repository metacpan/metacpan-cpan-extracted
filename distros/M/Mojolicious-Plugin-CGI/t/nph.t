use t::Helper;

use Mojolicious::Lite;
plugin CGI => ['/nph' => cgi_script('nph.pl')];

Test::Mojo->new->get_ok('/nph', {})->status_is(403)->content_like(qr'This is the paywall');

done_testing;
