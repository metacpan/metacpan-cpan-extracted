use t::Helper;

my $this_will_mess_up;

use Mojolicious::Lite;

plugin CGI => {support_semicolon_in_query_string => 1};

app->hook(
  before_dispatch => sub {
    my $c = shift;
    $this_will_mess_up = $c->req->url->query->param('a');
  }
);

plugin CGI => {route => '/env/basic', script => cgi_script('env.cgi'), env => {}};

my $t = Test::Mojo->new;

$t->get_ok('/env/basic/foo?a=1;b=2')->status_is(200)
  ->content_like(qr{^QUERY_STRING=a=1;b=2}m, 'QUERY_STRING with semicolon');

local $TODO = 'mojolicious cannot parse query with semicolon';
is $this_will_mess_up, '1', 'not messed up';

done_testing;
