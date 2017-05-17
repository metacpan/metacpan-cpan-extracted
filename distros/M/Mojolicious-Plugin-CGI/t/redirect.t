use lib '.';
use t::Helper;

use Mojolicious::Lite;
plugin CGI => ['/redirect' => cgi_script('redirect.pl')];

Test::Mojo->new->get_ok('/redirect', {})->status_is(302)
  ->header_is('Location' => 'http://somewhereelse.com')->content_is('');

done_testing;
