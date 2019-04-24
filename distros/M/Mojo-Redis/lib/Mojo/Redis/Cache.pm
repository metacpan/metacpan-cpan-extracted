package Mojo::Redis::Cache;
use Mojo::Base -base;

use Mojo::JSON;
use Scalar::Util 'blessed';
use Storable    ();
use Time::HiRes ();

use constant OFFLINE => $ENV{MOJO_REDIS_CACHE_OFFLINE};

has connection => sub {
  OFFLINE ? shift->_offline_connection : shift->redis->_dequeue->encoding(undef);
};
has deserialize    => sub { \&Storable::thaw };
has default_expire => 600;
has namespace      => 'cache:mojo:redis';
has refresh        => 0;
has redis          => sub { Carp::confess('redis is required in constructor') };
has serialize      => sub { \&Storable::freeze };

sub compute_p {
  my $compute = pop;
  my $self    = shift;
  my $key     = join ':', $self->namespace, shift;
  my $expire  = shift || $self->default_expire;

  my $p = $self->refresh ? Mojo::Promise->new->resolve : $self->connection->write_p(GET => $key);
  return $p->then(sub {
    my $data = $_[0] ? $self->deserialize->(shift) : undef;
    return $self->_maybe_compute_p($key, $expire, $compute, $data) if $expire < 0;
    return $self->_compute_p($key, $expire, $compute) unless $data;
    return $data->[0];
  });
}

sub memoize_p {
  my ($self, $obj, $method) = (shift, shift, shift);
  my $args = ref $_[0] eq 'ARRAY' ? shift : [];
  my $expire = shift || $self->default_expire;
  my $key = join ':', '@M' => (ref($obj) || $obj), $method, Mojo::JSON::encode_json($args);

  return $self->compute_p($key, $expire, sub { $obj->$method(@$args) });
}

sub _compute_p {
  my ($self, $key, $expire, $compute) = @_;

  my $set = sub {
    my $data = shift;
    my @set
      = $expire < 0
      ? $self->serialize->([$data, _time() + -$expire])
      : ($self->serialize->([$data]), PX => 1000 * $expire);
    $self->connection->write_p(SET => $key => @set)->then(sub {$data});
  };

  my $data = $compute->();
  return (blessed $data and $data->can('then')) ? $data->then(sub { $set->(@_) }) : $set->($data);
}

sub _maybe_compute_p {
  my ($self, $key, $expire, $compute, $data) = @_;

  # Nothing in cache
  return $self->_compute_p($key => $expire, $compute)->then(sub { ($_[0], {computed => 1}) }) unless $data;

  # No need to refresh cache
  return ($data->[0], {expired => 0}) if $data->[1] and _time() < $data->[1];

  # Try to refresh, but use old data on error
  my $p = Mojo::Promise->new;
  eval {
    $self->_compute_p($key => $expire, $compute)->then(
      sub { $p->resolve(shift,      {computed => 1,     expired => 1}) },
      sub { $p->resolve($data->[0], {error    => $_[0], expired => 1}) },
    );
  } or do {
    $p->resolve($data->[0], {error => $@, expired => 1});
  };

  return $p;
}

sub _offline_connection {
  state $c = eval <<'HERE' or die $@;
package Mojo::Redis::Connection::Offline;
use Mojo::Base 'Mojo::Redis::Connection';
our $STORE = {}; # Meant for internal use only

sub write_p {
  my ($conn, $op, $key) = (shift, shift, shift);

  if ($op eq 'SET') {
    $STORE->{$conn->url}{$key} = [$_[0], defined $_[2] ? $_[2] + Mojo::Redis::Cache::_time() * 1000 : undef];
    return Mojo::Promise->new->resolve('OK');
  }
  else {
    my $val     = $STORE->{$conn->url}{$key} || [];
    my $expired = $val->[1] && $val->[1] < Mojo::Redis::Cache::_time() * 1000;
    delete $STORE->{$conn->url}{$key} if $expired;
    return Mojo::Promise->new->resolve($expired ? undef : $val->[0]);
  }
}

'Mojo::Redis::Connection::Offline';
HERE
  my $redis = shift->redis;
  return $c->new(url => $redis->url);
}

sub _time { Time::HiRes::time() }

1;

=encoding utf8

=head1 NAME

Mojo::Redis::Cache - Simple cache interface using Redis

=head1 SYNOPSIS

  use Mojo::Redis;

  my $redis = Mojo::Redis->new;
  my $cache = $redis->cache;

  # Cache and expire the data after 60.7 seconds
  $cache->compute_p("some:key", 60.7, sub {
    my $p = Mojo::Promise->new;
    Mojo::IOLoop->timer(0.1 => sub { $p->resolve("some data") });
    return $p;
  })->then(sub {
    my $some_key = shift;
  });

  # Cache and expire the data after default_expire() seconds
  $cache->compute_p("some:key", sub {
    return {some => "data"};
  })->then(sub {
    my $some_key = shift;
  });

  # Call $obj->get_some_slow_data() and cache the return value
  $cache->memoize_p($obj, "get_some_slow_data")->then(sub {
    my $data = shift;
  });

  # Call $obj->get_some_data_by_id({id => 42}) and cache the return value
  $cache->memoize_p($obj, "get_some_data_by_id", [{id => 42}])->then(sub {
    my $data = shift;
  });

See L<https://github.com/jhthorsen/mojo-redis/blob/master/examples/cache.pl>
for example L<Mojolicious> application.

=head1 DESCRIPTION

L<Mojo::Redis::Cache> provides a simple interface for caching data in the
Redis database. There is no "check if exists", "get" or "set" methods in this
class. Instead, both L</compute_p> and L</memoize_p> will fetch the value
from Redis, if the given compute function / method has been called once, and
the cached data is not expired.

If you need to check if the value exists, then you can manually look up the
the key using L<Mojo::Redis::Database/exists>.

=head1 ENVIRONMENT VARIABLES

=head2 MOJO_REDIS_CACHE_OFFLINE

Set C<MOJO_REDIS_CACHE_OFFLINE> to 1 if you want to use this cache without a
real Redis backend. This can be useful in unit tests.

=head1 ATTRIBUTES

=head2 connection

  $conn  = $cache->connection;
  $cache = $cache->connection(Mojo::Redis::Connection->new);

Holds a L<Mojo::Redis::Connection> object.

=head2 default_expire

  $num  = $cache->default_expire;
  $cache = $cache->default_expire(600);

Holds the default expire time for cached data.

=head2 deserialize

  $cb   = $cache->deserialize;
  $cache = $cache->deserialize(\&Mojo::JSON::decode_json);

Holds a callback used to deserialize data from Redis.

=head2 namespace

  $str  = $cache->namespace;
  $cache = $cache->namespace("cache:mojo:redis");

Prefix for the cache key.

=head2 redis

  $conn = $cache->redis;
  $cache = $cache->redis(Mojo::Redis->new);

Holds a L<Mojo::Redis> object used to create the connection to talk with Redis.

=head2 refresh

  $bool = $cache->refresh;
  $cache = $cache->refresh(1);

Will force the cache to be computed again if set to a true value.

=head2 serialize

  $cb   = $cache->serialize;
  $cache = $cache->serialize(\&Mojo::JSON::encode_json);

Holds a callback used to serialize before storing the data in Redis.

=head1 METHODS

=head2 compute_p

  $promise = $cache->compute_p($key => $expire => $compute_function);
  $promise = $cache->compute_p($key => $expire => sub { return "data" });
  $promise = $cache->compute_p($key => $expire => sub { return Mojo::Promise->new });

This method will store the return value from the C<$compute_function> the
first time it is called and pass the same value to L<Mojo::Promise/then>.
C<$compute_function> will not be called the next time, if the C<$key> is
still present in Redis, but instead the cached value will be passed on to
L<Mojo::Promise/then>.

C<$key> will be prefixed by L</namespace> resulting in "namespace:some-key".

C<$expire> is the number of seconds before the cache should expire, and will
default to L</default_expire> unless passed in. The last argument is a
callback used to calculate cached value.

C<$expire> can also be a negative number. This will result in serving old cache
in the case where the C<$compute_function> fails. An example usecase would be
if you are fetching Twitter updates for your website, but instead of throwing
an exception if Twitter is down, you will serve old data instead. Note that the
fulfilled promise will get two variables passed in:

  $promise->then(sub { my ($data, $info) = @_ });

C<$info> is a hash and can have these keys:

=over 2

=item * computed

Will be true if the C<$compute_function> was called successfully and C<$data>
is fresh.

=item * expired

Will be true if C<$data> is expired. If this key is present and false, it will
indicate that the C<$data> is within the expiration period. The C<expired> key
can be found together with both L</computed> and L</error>.

=item * error

Will hold a string if the C<$compute_function> failed.

=back

Negative C<$expire> is currently EXPERIMENTAL, but unlikely to go away.

=head2 memoize_p

  $promise = $cache->memoize_p($obj, $method_name, \@args, $expire);
  $promise = $cache->memoize_p($class, $method_name, \@args, $expire);

L</memoize_p> behaves the same way as L</compute_p>, but has a convenient
interface for calling methods on an object. One of the benefits is that you
do not have to come up with your own cache key. This method is pretty much
the same as:

  $promise = $cache->compute_p(
    join(":", $cache->namespace, "@M", ref($obj), $method_name, serialize(\@args)),
    $expire,
    sub { return $obj->$method_name(@args) }
  );

See L</compute_p> regarding C<$expire>.

=head1 SEE ALSO

L<Mojo::Redis>

=cut
