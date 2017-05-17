use lib '.';
use t::Helper;

use Mojolicious::Lite;
plugin CGI => {
  route  => '/user/:id',
  script => cgi_script('env.cgi'),
  before => sub {
    my $c     = shift;
    my $query = $c->req->url->query;

    $query->param(id          => $c->stash('id'));
    $query->param(other_value => 123);
  },
};

Test::Mojo->new->get_ok('/user/42')->status_is(200)
  ->content_like(qr{^QUERY_STRING=id=42}m,             'QUERY_STRING=id=42')
  ->content_like(qr{^QUERY_STRING=.*other_value=123}m, 'QUERY_STRING=...other_value=123');

done_testing;
