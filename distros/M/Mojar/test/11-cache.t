use Mojo::Base -strict;
use Test::More;
use Mojar::Cache;
use Mojar::Util 'dumper';

my $cache = Mojar::Cache->new;

subtest q{get} => sub {
  $cache->set(foo => 'bar');
  is $cache->get('foo'), 'bar', 'right result';
  $cache->set(bar => 'baz');
  is $cache->get('foo'), 'bar', 'still right result for first';
  is $cache->get('bar'), 'baz', 'and right result for second';
  $cache->set(baz => 'yada');
  is $cache->get('bar'), 'baz',  'still right result for second';
  is $cache->get('baz'), 'yada', 'and right result for third';
  $cache->set(yada => 23);
  is $cache->get('baz'), 'yada', 'still right result for third';
  is $cache->get('yada'), 23,    'and right result for fourth';
};

$cache = Mojar::Cache->new;

subtest q{set} => sub {
  $cache->set(foo => 'bar');
  is $cache->get('foo'), 'bar',  'right result';
  $cache->set(bar => 'baz');
  is $cache->get('foo'), 'bar',  'still right result for first';
  is $cache->get('bar'), 'baz',  'and right result for second';
  $cache->set(baz => 'yada');
  is $cache->get('foo'), 'bar',  'still right result for first';
  is $cache->get('bar'), 'baz',  'still right result for second';
  is $cache->get('baz'), 'yada', 'and right result for third';
  $cache->set(yada => 23);
  is $cache->get('bar'), 'baz',  'still right result for second';
  is $cache->get('baz'), 'yada', 'still right result for third';
  is $cache->get('yada'), 23,    'and right result for fourth';
};

subtest q{remove} => sub {
  $cache->remove('bar');
  is $cache->get('bar'), undef,  'has been removed (from start)';
  $cache->remove('yada');
  is $cache->get('yada'), undef, 'has been removed (from end)';
  is $cache->get('baz'), 'yada', 'still right result';
};

subtest q{on_get_error} => sub {
  $cache->{store} = [];
  my $e;
  eval { $cache->get('baz') } or $e = $@;
  like $e, qr/Not a HASH ref/, 'expected exception';

  ok $cache->on_get_error(sub { 1 }), 'set new cb';
  $e = undef;
  eval { $cache->get('baz'); 1 } or $e = $@;
  ok ! defined($e), 'no exception';
};

subtest q{on_set_error} => sub {
  $cache->{store} = [];
  my $e;
  eval { $cache->set('baz' => 2) } or $e = $@;
  like $e, qr/Not a HASH ref/, 'expected exception';
};

$cache = Mojar::Cache->new;

subtest q{compute} => sub {
  ok $cache->set(foo => 'Foo')->set(bar => 'Bar'), 'set';
  is $cache->compute(foo => sub { 'me' . 'ow' }), 'Foo', 'existing value';

  is $cache->compute(z => sub { 'me' . 'ow' }), 'meow', 'computed value';
  is $cache->get('z'), 'meow', 'cached value';
};

subtest q{max_keys} => sub {
  ok $cache->max_keys(1), 'max_keys';
  ok $cache->set(foo => 'Foo'), 'set existing';
  ok $cache->is_valid('bar'), 'limits ignored';
  is $cache->get('bar'), 'Bar', 'limits ignored';

  ok $cache->set(bub => 'Bub'), 'set brand new';
  ok ! $cache->is_valid('bar'), 'limits imposed';
  is scalar(keys %{$cache->{store}}), 1, 'correct size limit';
};

done_testing();
