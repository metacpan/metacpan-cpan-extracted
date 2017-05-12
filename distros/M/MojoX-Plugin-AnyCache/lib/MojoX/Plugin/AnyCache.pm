package MojoX::Plugin::AnyCache;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.04';

has '_raw';
has 'app';
has 'backend';
has 'config';

sub register {
  my ($self, $app, $config) = @_;

  $self->app($app);
  $self->config($config);
  $app->helper(cache => sub { $self });

  if(exists $config->{backend}) {
    eval {
      eval "require $config->{backend};";
      warn "Require failed: $@" if $self->config->{debug} && $@;
      my $backend = $config->{backend}->new;
      $backend->config($config);
      $self->backend($backend);
      my $method = "init";
      $backend->$method() if $backend->can($method);
    };
    die("Failed to load backend $config->{backend}: $@") if $@;
  }
}

sub check_mode {
  my ($self, $cb) = @_;
  die("No backend available") if !$self->backend;
  die("Backend " . ref($self->backend) ." doesn't support asynchronous requests") if $cb && !$self->backend->support_async;
  die("Backend " . ref($self->backend) ." doesn't support synchronous requests") if !$cb && !$self->backend->support_sync;
}

sub raw {
    my ($self) = @_;

    my $clone = $self->new;

    # Deep copy
    $clone->app    ( $self->app     );
    $clone->backend( $self->backend );
    $clone->config ( $self->config  );

    $clone->_raw(1);

    return $clone;
}

sub get {
  my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
  my ($self, $key) = @_;
  $self->check_mode($cb);
  if( !$self->_raw && (my $serialiser = $self->backend->get_serialiser)) {
    return $self->backend->get($key, sub { $cb->($serialiser->deserialise(@_)) }) if $cb;
    return $serialiser->deserialise($self->backend->get($key));
  } else {
    return $self->backend->get($key, sub { $cb->(@_) }) if $cb;
    return $self->backend->get($key);
  }
}

sub set {
  my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
  my ($self, $key, $value, $ttl) = @_;
  $self->check_mode($cb);
  if( !$self->_raw && (my $serialiser = $self->backend->get_serialiser)) {
    return $self->backend->set($key, $serialiser->serialise($value), $ttl, sub { $cb->(@_) }) if $cb;
    return $self->backend->set($key => $serialiser->serialise($value), $ttl);
  } else {
    return $self->backend->set($key, $value, $ttl, sub { $cb->(@_) }) if $cb;
    return $self->backend->set($key => $value, $ttl);
  }
}

sub incr {
  my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
  my ($self, $key, $amount) = @_;
  $self->check_mode($cb);
  return $self->backend->incr($key, $amount, sub { $cb->(@_) }) if $cb;
  return $self->backend->incr($key => $amount);
}

sub decr {
  my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
  my ($self, $key, $amount) = @_;
  $self->check_mode($cb);
  return $self->backend->decr($key, $amount, sub { $cb->(@_) }) if $cb;
  return $self->backend->decr($key => $amount);
}

sub del {
  my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
  my ($self, $key) = @_;
  $self->check_mode($cb);
  return $self->backend->del($key, sub { $cb->(@_) }) if $cb;
  return $self->backend->del($key);
}

sub ttl {
  my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
  my ($self, $key) = @_;
  $self->check_mode($cb);
  return $self->backend->ttl($key, sub { $cb->(@_) }) if $cb;
  return $self->backend->ttl($key);
}

sub increment { shift->incr(@_) }
sub decrement { shift->decr(@_) }
sub delete { shift->del(@_) }

1;

=encoding utf8

=head1 NAME

MojoX::Plugin::AnyCache - Cache plugin with blocking and non-blocking support

=head1 SYNOPSIS

  $app->plugin('MojoX::Plugin::AnyCache' => {
    backend => 'MojoX::Plugin::AnyCache::Backend::Redis',
    server => '127.0.0.1:6379',
  });

  # For synchronous backends (blocking)
  $app->cache->set('key', 'value');
  my $value = $app->cache->get('key');

  # For asynchronous backends (non-blocking)
  $app->cache->set('key', 'value' => sub {
    # ...
  });
  $app->cache->get('key' => sub {
    my $value = shift;
    # ...
  });

=head1 DESCRIPTION

MojoX::Plugin::AnyCache provides an interface to both blocking and non-blocking
caching backends, for example Redis or Memcached.

It also has a built-in replicator backend (L<MojoX::Plugin::AnyCache::Backend::Replicator>)
which automatically replicates values across multiple backend cache nodes.

=head2 SERIALISATION

The cache backend module supports an optional serialiser module.

  $app->plugin('MojoX::Plugin::AnyCache' => {
    backend => 'MojoX::Plugin::AnyCache::Backend::Redis',
    server => '127.0.0.1:6379',
    serialiser => 'MojoX::Plugin::AnyCache::Serialiser::MessagePack'
  });

=head4 SERIALISER WARNING

If you use a serialiser, C<incr> or C<decr> a value, then retrieve
the value using C<get>, the value returned is deserialised.

With the FakeSerialiser used in tests, this means C<1> is translated to an C<A>.

This 'bug' can be avoided by reading the value from the cache backend
directly, bypassing the backend serialiser:

  $self->cache->set('foo', 1);
  $self->cache->backend->get('foo');

=head2 TTL / EXPIRES

=head3 Redis

Full TTL support is available with a Redis backend. Pass the TTL (in seconds)
to the C<set> method.

  $cache->set("key", "value", 10);

  $cache->set("key", "value", 10, sub {
    # ...
  });

And to get the TTL (seconds remaining until expiry)

  my $ttl = $cache->ttl("key");

  $cache->ttl("key", sub {
    my ($ttl) = @_;
    # ...
  });

=head3 Memcached

Full TTL set support is available with a Memcached backend. Pass the TTL (in seconds)
to the C<set> method.

  $cache->set("key", "value", 10);

  $cache->set("key", "value", 10, sub {
    # ...
  });

Unlike a Redis backend, 'get' TTL mode in Memcached is emulated, and the time
remaining is calculated using timestamps, and stored in a separate prefixed key.

To enable this, set C<get_ttl_support> on the backend:

  $cache->backend->get_ttl_support(1);

This must be done before setting a value. You can then get the TTL as normal:

  my $ttl = $cache->ttl("key");

  $cache->ttl("key", sub {
    my ($ttl) = @_;
    # ...
  });
