use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Time::HiRes;

package TestApp {
  use Mojolicious::Lite;
  plugin 'Statsd' => {adapter => 'Memory'};

  get '/' => sub {
    my $c = shift;
    $c->render(text => 'Hello Mojo!');
  };
}

subtest 'config' => sub {
  # adapter => name // object
  #  host / port
  # prefix  => ''
  # helper => ''

  subtest 'helper' => sub {
    my $app = Mojolicious->new;
    $app->plugin('Statsd' => {helper => 'foo'});

    ok eval { $app->foo }, 'custom helper is defined';
  };

  subtest 'prefix' => sub {
    my $app = Mojolicious->new;
    $app->plugin('Statsd' => {prefix => 'bar.'});

    is $app->stats->prefix(), 'bar.',
      'custom prefix is set';
  };

  subtest 'adapter - obj' => sub {
    my $blarg = bless {}, 'Blarg';

    my $app = Mojolicious->new;
    $app->plugin('Statsd' => {adapter => $blarg});

    is $app->stats->adapter(),
      $blarg,
      'adapter can be set directly';
  };

  subtest 'adapter - classname' => sub {
    my $app = Mojolicious->new;
    $app->plugin('Statsd' => {adapter => 'Statsd'});

    is
      ref $app->stats->adapter(),
      'Mojolicious::Plugin::Statsd::Adapter::Statsd',
      'adapter set by tail of classname';
  };
};


subtest 'Basic interface and adapter wiring' => sub {
  my $t = Test::Mojo->new('TestApp');

  ok my $stats = $t->app->stats, 'Stats helper is defined';

  $stats->prefix('');

  ok
    my $data = $stats->adapter->stats,
    'Got memory stats structure';

  ok $stats->increment('test1'), 'incremented test1 counter';
  is $data->{test1}, 1, 'recorded 1 hit for test1';

  ok $stats->decrement('test2'), 'decremented test2 counter';
  is $data->{test2}, -1, 'recorded -1 hit for test2';

  ok $stats->counter('test1', 2), 'bumped test1 by 2';
  is $data->{test1}, 3, 'recorded 2 hits for test1';

  ok $stats->counter(['test1', 'test3'], 1),
    'bumped test1 and test3 by 1';
  ok $data->{test1} == 4 && $data->{test3} == 1,
    'recorded hits for test1 and test3';

  ok $stats->timing('test4', 1000),
    'timing test4 for 1000ms';
  is ref(my $test4 = $data->{test4}), 'HASH',
    'created test4 timing structure';

  is $test4->{samples}, 1,    'test4 has 1 sample';
  is $test4->{avg},     1000, 'test4 avg is 1000';
  is $test4->{min},     1000, 'test4 min is 1000';
  is $test4->{max},     1000, 'test4 max is 1000';

  ok $stats->timing('test4', 500),
    'timing test4 for 500ms';
  is $test4->{samples}, 2,    'test4 has 1 sample';
  is $test4->{avg},     750,  'test4 avg is 750';
  is $test4->{min},     500,  'test4 min is 500';
  is $test4->{max},     1000, 'test4 max is 1000';

  ok $stats->timing('test5' => sub { sleep 0.1 }),
    'timing test5 with a coderef';

  subtest 'with_prefix' => sub {
    ok
      my $newstats = $stats->with_prefix('testing.'),
      'got new stats instance with added prefix "testing."';

    ok $newstats->increment('test5'),
      'incremented test5 counter';
    is $data->{'testing.test5'}, 1,
      'recorded 1 hit for testing.test5';
  };
};

done_testing();
