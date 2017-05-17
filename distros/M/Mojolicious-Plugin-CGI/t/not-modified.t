use lib '.';
use t::Helper;

use Mojolicious::Lite;
plugin CGI => ['/not-modified' => cgi_script('not-modified.pl')];

Test::Mojo->new->get_ok('/not-modified' => {'If-None-Match' => 'ABC'})->status_is(304)
  ->header_is('X-Test' => 'if-none-match seen: ABC');

done_testing;
