use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Prometheus';

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $counter = app->prometheus->new_counter(name => 'test_counter',
  help => 'Test counter',);

$counter->inc(5);

my $t = Test::Mojo->new;

$t->get_ok('/metrics')->status_is(200)->content_type_like(qr(^text/plain))
  ->content_like(qr/test_counter 5/);

done_testing();
