use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Prometheus';

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

post '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');

$t->post_ok('/'  => json => {hello => 'somedata'})->status_is(200)->content_is('Hello Mojo!');

$t->get_ok('/metrics')->status_is(200)->content_type_like(qr(^text/plain))->content_like(qr/http_request_duration_seconds_count\{method="GET"\} 1/);

done_testing();
