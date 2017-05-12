use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;
use Mojo::UserAgent::DigestAuth;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

get '/blocking' => sub {
  my $c = shift;
  my $tx = $c->ua->$_request_with_digest_auth(get => 'http://user:passwd@httpbin.org/digest-auth/auth/user/passwd');
  $c->render(json => $tx->res->json);
};

get '/nonblocking' => sub {
  my $c = shift;
  $c->delay(
    sub {
      my $d = shift;
      $c->ua->$_request_with_digest_auth(
        get => 'http://user:passwd@httpbin.org/digest-auth/auth/user/passwd' => $d->begin);
      $c->ua->max_redirects(2)->get('http://www.google.com' => $d->begin);
    },
    sub {
      $c->render(json => $_[1]->res->json);
    }
  );
};

my $t = Test::Mojo->new;

$t->get_ok('/blocking')->status_is(200)->json_is('/user', 'user');
$t->get_ok('/nonblocking')->status_is(200)->json_is('/user', 'user');

done_testing;
