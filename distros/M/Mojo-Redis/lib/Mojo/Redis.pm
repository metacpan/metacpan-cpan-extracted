package Mojo::Redis;
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::URL;
use Mojo::Redis::Connection;
use Mojo::Redis::Cache;
use Mojo::Redis::Cursor;
use Mojo::Redis::Database;
use Mojo::Redis::PubSub;
use Scalar::Util 'blessed';

our $VERSION = '3.24';

$ENV{MOJO_REDIS_URL} ||= 'redis://localhost:6379';

has encoding        => 'UTF-8';
has max_connections => 5;

has protocol_class => do {
  my $class = $ENV{MOJO_REDIS_PROTOCOL};
  $class ||= eval { require Protocol::Redis::XS; Protocol::Redis::XS->VERSION('0.06'); 'Protocol::Redis::XS' };
  $class ||= 'Protocol::Redis::Faster';
  eval "require $class; 1" or die $@;
  $class;
};

has pubsub => sub {
  my $pubsub = Mojo::Redis::PubSub->new(redis => $_[0]);
  Scalar::Util::weaken($pubsub->{redis});
  return $pubsub;
};

has url => sub { Mojo::URL->new($ENV{MOJO_REDIS_URL}) };

sub cache { Mojo::Redis::Cache->new(redis => shift, @_) }
sub cursor { Mojo::Redis::Cursor->new(redis => shift, command => [@_ ? @_ : (scan => 0)]) }
sub db { Mojo::Redis::Database->new(redis => shift) }

sub new {
  my $class = shift;
  return $class->SUPER::new(@_) unless @_ % 2 and ref $_[0] ne 'HASH';
  my $url = shift;
  $url = Mojo::URL->new($url) unless blessed $url and $url->isa('Mojo::URL');
  return $class->SUPER::new(url => $url, @_);
}

sub _connection {
  my ($self, %args) = @_;

  $args{ioloop} ||= Mojo::IOLoop->singleton;
  my $conn = Mojo::Redis::Connection->new(
    encoding => $self->encoding,
    protocol => $self->protocol_class->new(api => 1),
    url      => $self->url->clone,
    %args
  );

  Scalar::Util::weaken($self);
  $conn->on(connect => sub { $self->emit(connection => $_[0]) });
  $conn;
}

sub _blocking_connection {
  my $self = shift->_fork_safety;

  # Existing connection
  my $conn = $self->{blocking_connection};
  return $conn->encoding($self->encoding) if $conn and $conn->is_connected;

  # New connection
  return $self->{blocking_connection} = $self->_connection(ioloop => $conn ? $conn->ioloop : Mojo::IOLoop->new);
}

sub _dequeue {
  my $self = shift->_fork_safety;

  # Exsting connection
  while (my $conn = shift @{$self->{queue} || []}) { return $conn->encoding($self->encoding) if $conn->is_connected }

  # New connection
  return $self->_connection;
}

sub _enqueue {
  my ($self, $conn) = @_;
  my $queue = $self->{queue} ||= [];
  push @$queue, $conn if $conn->is_connected and $conn->url eq $self->url and $conn->ioloop eq Mojo::IOLoop->singleton;
  shift @$queue while @$queue > $self->max_connections;
}

sub _fork_safety {
  my $self = shift;
  delete @$self{qw(blocking_connection pid queue)} unless ($self->{pid} //= $$) eq $$;    # Fork-safety
  $self;
}

1;

=encoding utf8

=head1 NAME

Mojo::Redis - Redis driver based on Mojo::IOLoop

=head1 SYNOPSIS

=head2 Blocking

  use Mojo::Redis;
  my $redis = Mojo::Redis->new;
  warn $redis->db->get("mykey");

=head2 Promises

  $redis->db->get_p("mykey")->then(sub {
    print "mykey=$_[0]\n";
  })->catch(sub {
    warn "Could not fetch mykey: $_[0]";
  })->wait;

=head2 Pipelining

Pipelining is built into the API by sending a lot of commands and then use
L<Mojo::Promise/all> to wait for all the responses.

  Mojo::Promise->all(
    $db->set_p($key, 10),
    $db->incrby_p($key, 9),
    $db->incr_p($key),
    $db->get_p($key),
    $db->incr_p($key),
    $db->get_p($key),
  )->then(sub {
    @res = map {@$_} @_;
  })->wait;

=head1 DESCRIPTION

L<Mojo::Redis> is a Redis driver that use the L<Mojo::IOLoop>, which makes it
integrate easily with the L<Mojolicious> framework.

It tries to mimic the same interface as L<Mojo::Pg>, L<Mojo::mysql> and
L<Mojo::SQLite>, but the methods for talking to the database vary.

This module is in no way compatible with the 1.xx version of L<Mojo::Redis>
and this version also tries to fix a lot of the confusing methods in
L<Mojo::Redis2> related to pubsub.

This module is currently EXPERIMENTAL, and bad design decisions will be fixed
without warning. Please report at
L<https://github.com/jhthorsen/mojo-redis/issues> if you find this module
useful, annoying or if you simply find bugs. Feedback can also be sent to
C<jhthorsen@cpan.org>.

=head1 EVENTS

=head2 connection

  $cb = $redis->on(connection => sub { my ($redis, $connection) = @_; });

Emitted when L<Mojo::Redis::Connection> connects to the Redis.

=head1 ATTRIBUTES

=head2 encoding

  $str   = $redis->encoding;
  $redis = $redis->encoding("UTF-8");

The value of this attribute will be passed on to
L<Mojo::Redis::Connection/encoding> when a new connection is created. This
means that updating this attribute will not change any connection that is
in use.

Default value is "UTF-8".

=head2 max_connections

  $int   = $redis->max_connections;
  $redis = $redis->max_connections(5);

Maximum number of idle database handles to cache for future use, defaults to
5. (Default is subject to change)

=head2 protocol_class

  $str   = $redis->protocol_class;
  $redis = $redis->protocol_class("Protocol::Redis::XS");

Default to L<Protocol::Redis::XS> if the optional module is available and at
least version 0.06, or falls back to L<Protocol::Redis::Faster>.

=head2 pubsub

  $pubsub = $redis->pubsub;

Lazy builds an instance of L<Mojo::Redis::PubSub> for this object, instead of
returning a new instance like L</db> does.

=head2 url

  $url   = $redis->url;
  $redis = $redis->url(Mojo::URL->new("redis://localhost/3"));

Holds an instance of L<Mojo::URL> that describes how to connect to the Redis server.

=head1 METHODS

=head2 db

  $db = $redis->db;

Returns an instance of L<Mojo::Redis::Database>.

=head2 cache

  $cache = $redis->cache(%attrs);

Returns an instance of L<Mojo::Redis::Cache>.

=head2 cursor

  $cursor = $redis->cursor(@command);

Returns an instance of L<Mojo::Redis::Cursor> with
L<Mojo::Redis::Cursor/command> set to the arguments passed. See
L<Mojo::Redis::Cursor/new>. for possible commands.

=head2 new

  $redis = Mojo::Redis->new("redis://localhost:6379/1");
  $redis = Mojo::Redis->new(Mojo::URL->new->host("/tmp/redis.sock"));
  $redis = Mojo::Redis->new(\%attrs);
  $redis = Mojo::Redis->new(%attrs);

Object constructor. Can coerce a string into a L<Mojo::URL> and set L</url>
if present.

=head1 AUTHORS

Jan Henning Thorsen - C<jhthorsen@cpan.org>

Dan Book - C<grinnz@grinnz.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Jan Henning Thorsen.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::Redis2>.

=cut
