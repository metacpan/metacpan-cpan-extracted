use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

use Mojolicious::Lite;
get '/blocking' => sub {
  my $c  = shift;
  my $tx = $c->ua->get('http://user:passwd@httpbin.org/digest-auth/auth/user/passwd');
  $c->render(json => $tx->res->json);
};

get '/nonblocking' => sub {
  my $c = shift;

  return Mojo::Promise->all(
    $c->ua->get_p('http://user:passwd@httpbin.org/digest-auth/auth/user/passwd'),
    $c->ua->max_redirects(2)->get_p('http://www.google.com'),
  )->then(
    sub {
      my @tx = map { $_->[0] } @_;
      $c->render(json => $tx[0]->res->json);
    }
  );
};

my $t = Test::Mojo->new;
$t->app->ua->with_roles('+DigestAuth');

$t->get_ok('/blocking')->status_is(200)->json_is('/user', 'user');
$t->get_ok('/nonblocking')->status_is(200)->json_is('/user', 'user');

done_testing;
