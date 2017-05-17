use lib '.';
use t::Helper;

use Mojolicious::Lite;
plugin CGI => ['/nph-borked' => cgi_script('nph-borked.pl')];

Test::Mojo->new->get_ok('/nph-borked', {})->status_is(403)
  ->content_like(qr'This is the borked paywall');

done_testing;
