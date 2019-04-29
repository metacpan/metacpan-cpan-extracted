use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

package TestApp {
  use Mojolicious::Lite;
  plugin 'Statsd';

  get '/' => sub {
    my $c = shift;
    $c->render(text => 'Hello Mojo!');
  };
}

my $t = Test::Mojo->new('TestApp');

ok my $stats = $t->app->stats, 'Stats helper is defined';

can_ok $stats => qw(
  register
  adapter prefix
  with_prefix
  counter increment decrement
  timing
);

ok $stats->adapter, 'Stats has a default adapter';

is $stats->prefix, $t->app->moniker . '.',
  'Stats defaulted to moniker prefix';

if (my $prefixed_stats = $stats->with_prefix('frobnicate.')) {
  pass 'Got stats obj with extra prefix';

  isa_ok $prefixed_stats, ref $stats;

  is $prefixed_stats->prefix,
    sprintf('%s.%s.', $t->app->moniker, 'frobnicate'),
    'New stats obj has extra prefix added to original';
}
else {
  fail 'Got stats obj with extra prefix';
}

$t->get_ok('/')->status_is(200);

done_testing();
