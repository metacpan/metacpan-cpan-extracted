use t::Helper;

use Mojolicious::Lite;
plugin CGI => {route => '/auth', script => cgi_script('env.cgi'), env => {}};

my $t = Test::Mojo->new;

$t->get_ok('/auth')->status_is(200)->status_is(200)
  ->content_like(qr{^REMOTE_USER=}m, 'REMOTE_USER=');

$t->get_ok($t->tx->req->url->clone->userinfo('Aladdin:foopass'), {'Authorization' => ''})
  ->status_is(200)->content_like(qr{^REMOTE_USER=Aladdin$}m, 'REMOTE_USER=Aladdin');

$t->get_ok(
  $t->tx->req->url->clone->userinfo('whatever:foopass'),
  {'Authorization' => 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=='}
)->status_is(200)->content_like(qr{^REMOTE_USER=Aladdin$}m, 'REMOTE_USER=Aladdin');

done_testing;
