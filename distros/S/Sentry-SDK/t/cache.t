use Mojo::Base -strict, -signatures;

use Mojo::Util 'dumper';
use Sentry::Cache;
use Test::Spec;

describe 'Sentry::Cache' => sub {
  my $cache;

  before each => sub {
    $cache = Sentry::Cache->new;
  };

  it 'set()' => sub {
    $cache->set(foo => 'bar');

    is_deeply $cache->_cache => { foo => 'bar' };
  };

  it 'get()' => sub {
    $cache->set(foo => 'bar');
    is $cache->get('foo') => 'bar';
  };

  it 'get_instance()' => sub {
    Sentry::Cache->get_instance()->set(foo => 'bar');

    is(Sentry::Cache->get_instance()->get('foo') => 'bar');
    is $cache->get('foo') => undef;
  };
};

runtests;
