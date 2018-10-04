use Mojo::Base -strict;
use Test::More;
use Mojo::UserAgent;

plan skip_all => $@ unless eval 'require CHI;1';

my $url
  = 'https://supergirl:for-testing@www.google.com/search?source=hp&ei=yXXXXXXzXXX00yXXz5XXXX&btnG=X%C3%B8y&q=mojolicious&gs_l=xyz-xy.3..0x000y0l0j0i00x00x0y0.000000.000000.0.000000.00.00.0.0.0.0.000.0000.0.0x0y0.0.0....0...0z.1.00.xyz-xy..00.0.0000.0..0.0.0xYZz00yZ0z';

my $driver = ua()->cache_driver;
is $driver->get($url), undef, 'get';

$driver->set($url, "GET /chi\r\n");
is_deeply $driver->get($url), "GET /chi\r\n", 'get after set';
is +ua()->cache_driver->get($url), undef, 'get fresh object';

$driver->remove($url);
is $driver->get($url), undef, 'get after remove';

isnt ua()->cache_driver, Mojo::UserAgent::Role::Cache->cache_driver_singleton, 'not using cache_driver_singleton';

is Mojo::UserAgent::Role::Cache->cache_driver_singleton($driver), 'Mojo::UserAgent::Role::Cache',
  'set cache_driver_singleton';
is $driver, Mojo::UserAgent::Role::Cache->cache_driver_singleton, 'using cache_driver_singleton';

done_testing;

sub ua {
  my $chi = CHI->new(driver => 'Memory', datastore => {});
  return Mojo::UserAgent->with_roles('+Cache')->new(cache_driver => $chi);
}
