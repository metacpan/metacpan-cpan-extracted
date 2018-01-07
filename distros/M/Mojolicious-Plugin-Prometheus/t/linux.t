use Mojo::Base -strict;

use Test::More;

if ($^O eq 'linux') {
  use Mojolicious::Lite;
  use Test::Mojo;
  plugin 'Prometheus';

  get '/' => sub {
    my $c = shift;
    $c->render(text => 'Hello Mojo!');
  };

  my $t = Test::Mojo->new;
  $t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');

  # Only Linux supported by Net::Prometheus process collector
  $t->get_ok('/metrics')->status_is(200)->content_type_like(qr(^text/plain))
    ->content_like(qr/process_cpu_seconds_total/);
}
else {
  plan skip_all => 'Test irrelevant outside Linux';
}

done_testing();
