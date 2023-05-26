use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use IPC::ShareLite;

my $ipc = IPC::ShareLite->new(-key => time(), -create => 1, -destroy => 1);
plugin 'Prometheus' => { shm_key => $ipc->key };

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

post '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};


my $t = Test::Mojo->new;

for my $i (1 .. 100) {
  $t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');
  $t->post_ok('/' => json => {hello => 'somedata'})->status_is(200)
    ->content_is('Hello Mojo!');
}

$t->get_ok('/metrics')->status_is(200)->content_type_like(qr(^text/plain))
  ->content_like(qr/http_requests_total\{worker="\d+",method="GET",code="200"\} 100/);

$t->get_ok('/metrics')->status_is(200)->content_type_like(qr(^text/plain))
  ->content_like(qr/http_request_duration_seconds_count\{worker="\d+",method="GET"\} 101/);

done_testing();
