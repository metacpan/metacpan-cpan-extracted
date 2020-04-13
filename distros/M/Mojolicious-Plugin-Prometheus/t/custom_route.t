use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;


my $t = Test::Mojo->new;

my $under = app->routes->under('/secret' =>sub {
  my $c = shift;
  return 1 if $c->req->url->to_abs->userinfo eq 'Bender:rocks';
  $c->res->headers->www_authenticate('Basic');
  $c->render(text => 'Authentication required!', status => 401);
  return undef;
});

plugin Prometheus => {route => $under};

$t->get_ok('//Bender:rocks@/secret/metrics')->status_is(200)->content_type_like(qr(^text/plain))
  ->content_like(qr/http_request_duration_seconds/);

done_testing();
