package Mojo::Redis::Database;
use Mojo::Base -base;

use Scalar::Util 'blessed';

our @BASIC_COMMANDS = (
  'append',           'bgrewriteaof', 'bgsave',            'bitcount',
  'bitfield',         'bitop',        'bitpos',            'client',
  'cluster',          'config',       'command',           'dbsize',
  'debug',            'decr',         'decrby',            'del',
  'dump',             'echo',         'eval',              'evalsha',
  'exists',           'expire',       'expireat',          'flushall',
  'flushdb',          'geoadd',       'geohash',           'geopos',
  'geodist',          'georadius',    'georadiusbymember', 'get',
  'getbit',           'getrange',     'getset',            'hdel',
  'hexists',          'hget',         'hgetall',           'hincrby',
  'hincrbyfloat',     'hkeys',        'hlen',              'hmget',
  'hmset',            'hset',         'hsetnx',            'hstrlen',
  'hvals',            'info',         'incr',              'incrby',
  'incrbyfloat',      'keys',         'lastsave',          'lindex',
  'linsert',          'llen',         'lpop',              'lpush',
  'lpushx',           'lrange',       'lrem',              'lset',
  'ltrim',            'memory',       'mget',              'move',
  'mset',             'msetnx',       'object',            'persist',
  'pexpire',          'pexpireat',    'pttl',              'pfadd',
  'pfcount',          'pfmerge',      'ping',              'psetex',
  'publish',          'randomkey',    'readonly',          'readwrite',
  'rename',           'renamenx',     'role',              'rpop',
  'rpoplpush',        'rpush',        'rpushx',            'restore',
  'sadd',             'save',         'scard',             'script',
  'sdiff',            'sdiffstore',   'set',               'setbit',
  'setex',            'setnx',        'setrange',          'sinter',
  'sinterstore',      'sismember',    'slaveof',           'slowlog',
  'smembers',         'smove',        'sort',              'spop',
  'srandmember',      'srem',         'strlen',            'sunion',
  'sunionstore',      'time',         'touch',             'ttl',
  'type',             'unlink',       'xadd',              'xrange',
  'xrevrange',        'xlen',         'xread',             'xreadgroup',
  'xpending',         'zadd',         'zcard',             'zcount',
  'zincrby',          'zinterstore',  'zlexcount',         'zpopmax',
  'zpopmin',          'zrange',       'zrangebylex',       'zrangebyscore',
  'zrank',            'zrem',         'zremrangebylex',    'zremrangebyrank',
  'zremrangebyscore', 'zrevrange',    'zrevrangebylex',    'zrevrangebyscore',
  'zrevrank',         'zscore',       'zunionstore',
);

our @BLOCKING_COMMANDS = ('blpop', 'brpop', 'brpoplpush', 'bzpopmax', 'bzpopmin');

has redis => sub { Carp::confess('redis is required in constructor') };

__PACKAGE__->_add_method('bnb,p' => $_) for @BASIC_COMMANDS;
__PACKAGE__->_add_method('nb,p'  => $_) for @BLOCKING_COMMANDS;
__PACKAGE__->_add_method('bnb'   => qw(_exec EXEC));
__PACKAGE__->_add_method('bnb'   => qw(_discard DISCARD));
__PACKAGE__->_add_method('bnb'   => qw(_multi MULTI));
__PACKAGE__->_add_method('bnb,p' => "${_}_structured", $_) for qw(info xread);
__PACKAGE__->_add_method('bnb,p' => $_) for qw(unwatch watch);

sub call {
  my $cb   = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self = shift;
  my $p    = $self->connection($cb ? 0 : 1)->write_p(@_);

  # Non-blocking
  if ($cb) {
    $p->then(sub { $self->$cb('', @_) })->catch(sub { $self->$cb(shift, undef) });
    return $self;
  }

  # Blocking
  my ($err, @res);
  $p->then(sub { @res = @_ })->catch(sub { $err = shift })->wait;
  die $err if $err;
  return @res;
}

sub call_p {
  my $self = shift;
  return $self->connection->write_p(@_)->then(sub { $self = undef; @_ });
}

sub exec { delete $_[0]->{txn}; shift->_exec(@_) }

sub exec_p {
  my $self = shift;
  delete $self->{txn};
  return $self->connection->write_p('EXEC');
}

sub discard { delete $_[0]->{txn}; shift->_discard(@_) }

sub discard_p {
  my $self = shift;
  delete $self->{txn};
  return $self->connection->write_p('DISCARD');
}

sub multi {
  $_[0]->{txn} = ref $_[-1] eq 'CODE' ? 'default' : 'blocking';
  return shift->_multi(@_);
}

sub multi_p {
  my ($self, @p) = @_;
  $self->{txn} = 'default';
  my $p = $self->connection->write_p('MULTI');
  return @p ? $p->then(sub { Mojo::Promise->all(@p) }) : $p;
}

sub _add_method {
  my ($class, $types, $method, $op) = @_;
  my $caller  = caller;
  my $process = $caller->can(lc "_process_$method");

  $op ||= uc $method;

  for my $type (split /,/, $types) {
    Mojo::Util::monkey_patch(
      $caller,
      $type eq 'p' ? "${method}_p" : $method,
      $class->can("_generate_${type}_method")->($class, $op, $process)
    );
  }
}

sub connection {
  my $self = shift;

  # Back compat: $self->connection(Mojo::Redis::Connection->new);
  $self->{_conn_dequeue} = shift if blessed $_[0] and $_[0]->isa('Mojo::Redis::Connection');

  my $method = $_[0] ? '_blocking_connection' : '_dequeue';
  return $self->{"_conn$method"} ||= $self->redis->$method;
}

sub _generate_bnb_method {
  my ($class, $op, $process) = @_;

  return sub {
    my $cb   = ref $_[-1] eq 'CODE' ? pop : undef;
    my $self = shift;

    my $p = $self->connection($cb ? 0 : 1)->write_p($op, @_);
    $p = $p->then(sub { $self->$process(@_) }) if $process;

    # Non-blocking
    if ($cb) {
      $p->then(sub { $self->$cb('', @_) })->catch(sub { $self->$cb(shift, undef) });
      return $self;
    }

    # Blocking
    my ($err, $res);
    $p->then(sub { $res = shift })->catch(sub { $err = shift })->wait;
    die $err if defined $err;
    return $res;
  };
}

sub _generate_nb_method {
  my ($class, $op, $process) = @_;

  return sub {
    my ($self, $cb) = (shift, pop);
    $self->connection->write_p(@_)->then(sub { $self->$cb('', $process ? $self->$process(@_) : @_) })
      ->catch(sub { $self->$cb(shift, undef) });
    return $self;
  };
}

sub _generate_p_method {
  my ($class, $op, $process) = @_;

  return sub {
    my $self = shift;
    $self->connection->write_p($op => @_)->then(sub {
      return $process ? $self->$process(@_) : @_;
    });
  };
}

sub _process_geopos { [map { ref $_ ? +{lng => $_->[0], lat => $_->[1]} : undef } @{$_[1]}] }
sub _process_blpop  { reverse @{$_[1]} }
sub _process_brpop  { reverse @{$_[1]} }
sub _process_hgetall { +{@{$_[1]}} }

sub _process_info_structured {
  my $self    = shift;
  my $section = {};
  my %res;

  for (split /\r\n/, $_[0]) {
    if (/^\#\s+(\S+)/) {
      $section = $res{lc $1} = {};
    }
    elsif (/(\S+):(\S+)/) {
      $section->{$1} = $2;
    }
  }

  return keys %res == 1 ? $section : \%res;
}

sub _process_xread_structured {
  return $_[1] unless ref $_[1] eq 'ARRAY';
  return {map { ($_->[0] => $_->[1]) } @{$_[1]}};
}

sub DESTROY {
  my $self = shift;

  if (my $txn = delete $self->{txn}) {
    $self->connection(1)->write_p('DISCARD')->wait if $txn eq 'blocking';
  }
  elsif (my $redis = $self->{redis} and my $conn = $self->{_conn_dequeue}) {
    $redis->_enqueue($conn);
  }
}

1;

=encoding utf8

=head1 NAME

Mojo::Redis::Database - Execute basic redis commands

=head1 SYNOPSIS

  use Mojo::Redis;

  my $redis = Mojo::Redis->new;
  my $db    = $redis->db;

  # Blocking
  say "foo=" .$db->get("foo");

  # Non-blocking
  $db->get(foo => sub { my ($db, $res) = @_; say "foo=$res" });

  # Promises
  $db->get_p("foo")->then(sub { my ($res) = @_; say "foo=$res" });

See L<https://github.com/jhthorsen/mojo-redis/blob/master/examples/twitter.pl>
for example L<Mojolicious> application.

=head1 DESCRIPTION

L<Mojo::Redis::Database> has methods for sending and receiving structured
data to the Redis server.

=head1 ATTRIBUTES

=head2 redis

  $conn = $db->redis;
  $db = $db->redis(Mojo::Redis->new);

Holds a L<Mojo::Redis> object used to create the connections to talk with Redis.

=head1 METHODS

=head2 append

  $int     = $db->append($key, $value);
  $db      = $db->append($key, $value, sub { my ($db, $err, $int) = @_ });
  $promise = $db->append_p($key, $value);

Append a value to a key.

See L<https://redis.io/commands/append> for more information.

=head2 bgrewriteaof

  $ok      = $db->bgrewriteaof;
  $db      = $db->bgrewriteaof(sub { my ($db, $err, $ok) = @_ });
  $promise = $db->bgrewriteaof_p;

Asynchronously rewrite the append-only file.

See L<https://redis.io/commands/bgrewriteaof> for more information.

=head2 bgsave

  $ok      = $db->bgsave;
  $db      = $db->bgsave(sub { my ($db, $err, $ok) = @_ });
  $promise = $db->bgsave_p;

Asynchronously save the dataset to disk.

See L<https://redis.io/commands/bgsave> for more information.

=head2 bitcount

  $int     = $db->bitcount($key, [start end]);
  $db      = $db->bitcount($key, [start end], sub { my ($db, $err, $int) = @_ });
  $promise = $db->bitcount_p($key, [start end]);

Count set bits in a string.

See L<https://redis.io/commands/bitcount> for more information.

=head2 bitfield

  $res     = $db->bitfield($key, [GET type offset], [SET type offset value], [INCRBY type offset increment], [OVERFLOW WRAP|SAT|FAIL]);
  $db      = $db->bitfield($key, [GET type offset], [SET type offset value], [INCRBY type offset increment], [OVERFLOW WRAP|SAT|FAIL], sub { my ($db, $err, $res) = @_ });
  $promise = $db->bitfield_p($key, [GET type offset], [SET type offset value], [INCRBY typeoffset increment], [OVERFLOW WRAP|SAT|FAIL]);

Perform arbitrary bitfield integer operations on strings.

See L<https://redis.io/commands/bitfield> for more information.

=head2 bitop

  $int     = $db->bitop($operation, $destkey, $key [key ...]);
  $db      = $db->bitop($operation, $destkey, $key [key ...], sub { my ($db, $err, $int) = @_ });
  $promise = $db->bitop_p($operation, $destkey, $key [key ...]);

Perform bitwise operations between strings.

See L<https://redis.io/commands/bitop> for more information.

=head2 bitpos

  $int     = $db->bitpos($key, $bit, [start], [end]);
  $db      = $db->bitpos($key, $bit, [start], [end], sub { my ($db, $err, $int) = @_ });
  $promise = $db->bitpos_p($key, $bit, [start], [end]);

Find first bit set or clear in a string.

See L<https://redis.io/commands/bitpos> for more information.

=head2 blpop

  $db      = $db->blpop($key [key ...], $timeout, sub { my ($db, $val, $key) = @_ });
  $promise = $db->blpop_p($key [key ...], $timeout);

Remove and get the first element in a list, or block until one is available.

See L<https://redis.io/commands/blpop> for more information.

=head2 brpop

  $db      = $db->brpop($key [key ...], $timeout, sub { my ($db, $val, $key) = @_ });
  $promise = $db->brpop_p($key [key ...], $timeout);

Remove and get the last element in a list, or block until one is available.

See L<https://redis.io/commands/brpop> for more information.

=head2 brpoplpush

  $db      = $db->brpoplpush($source, $destination, $timeout, sub { my ($db, $err, $array_ref) = @_ });
  $promise = $db->brpoplpush_p($source, $destination, $timeout);

Pop a value from a list, push it to another list and return it; or block until one is available.

See L<https://redis.io/commands/brpoplpush> for more information.

=head2 bzpopmax

  $db      = $db->bzpopmax($key [key ...], $timeout, sub { my ($db, $err, $array_ref) = @_ });
  $promise = $db->bzpopmax_p($key [key ...], $timeout);

Remove and return the member with the highest score from one or more sorted sets, or block until one is available.

See L<https://redis.io/commands/bzpopmax> for more information.

=head2 bzpopmin

  $db      = $db->bzpopmin($key [key ...], $timeout, sub { my ($db, $err, $array_ref) = @_ });
  $promise = $db->bzpopmin_p($key [key ...], $timeout);

Remove and return the member with the lowest score from one or more sorted sets, or block until one is available.

See L<https://redis.io/commands/bzpopmin> for more information.

=head2 call

  $res = $db->call($command => @args);
  $db  = $db->call($command => @args, sub { my ($db, $err, $res) = @_; });

Same as L</call_p>, but either blocks or passes the result into a callback.

=head2 call_p

  $promise = $db->call_p($command => @args);
  $promise = $db->call_p(GET => "some:key");

Used to send a custom command to the Redis server.

=head2 client

  $res     = $db->client(@args);
  $db      = $db->client(@args, sub { my ($db, $err, $res) = @_ });
  $promise = $db->client_p(@args);

Run a "CLIENT" command on the server. C<@args> can be:

=over 2

=item * KILL [ip:port] [ID client-id] [TYPE normal|master|slave|pubsub] [ADDR ip:port] [SKIPME yes/no]

=item * LIST

=item * GETNAME

=item * PAUSE timeout

=item * REPLY [ON|OFF|SKIP]

=item * SETNAME connection-name

=back

See L<https://redis.io/commands#server> for more information.

=head2 connection

  $non_blocking_connection = $db->connection(0);
  $blocking_connection     = $db->connection(1);

Returns a L<Mojo::Redis::Connection> object. The default is to return a
connection suitable for non-blocking methods, but passing in a true value will
return the connection used for blocking methods.

  # Blocking
  my $res = $db->get("some:key");

  # Non-blocking
  $db->get_p("some:key");
  $db->get("some:key", sub { ... });

=head2 cluster

  $res     = $db->cluster(@args);
  $db      = $db->cluster(@args, sub { my ($db, $err, $res) = @_ });
  $promise = $db->cluster_p(@args);

Used to execute cluster commands.

See L<https://redis.io/commands#cluster> for more information.

=head2 command

  $array_ref = $db->command(@args);
  $db        = $db->command(@args, sub { my ($db, $err, $array_ref) = @_ });
  $promise   = $db->command_p(@args);

Get array of Redis command details.

=over 2

=item * empty list

=item * COUNT

=item * GETKEYS

=item * INFO command-name [command-name]

=back

See L<https://redis.io/commands/command> for more information.

=head2 dbsize

  $int     = $db->dbsize;
  $db      = $db->dbsize(sub { my ($db, $err, $int) = @_ });
  $promise = $db->dbsize_p;

Return the number of keys in the selected database.

See L<https://redis.io/commands/dbsize> for more information.

=head2 decr

  $num     = $db->decr($key);
  $db      = $db->decr($key, sub { my ($db, $err, $num) = @_ });
  $promise = $db->decr_p($key);

Decrement the integer value of a key by one.

See L<https://redis.io/commands/decr> for more information.

=head2 decrby

  $num     = $db->decrby($key, $decrement);
  $db      = $db->decrby($key, $decrement, sub { my ($db, $err, $num) = @_ });
  $promise = $db->decrby_p($key, $decrement);

Decrement the integer value of a key by the given number.

See L<https://redis.io/commands/decrby> for more information.

=head2 del

  $ok      = $db->del($key [key ...]);
  $db      = $db->del($key [key ...], sub { my ($db, $err, $ok) = @_ });
  $promise = $db->del_p($key [key ...]);

Delete a key.

See L<https://redis.io/commands/del> for more information.

=head2 discard

See L</discard_p>.

=head2 discard_p

  $ok      = $db->discard;
  $db      = $db->discard(sub { my ($db, $err, $ok) = @_ });
  $promise = $db->discard_p;

Discard all commands issued after MULTI.

See L<https://redis.io/commands/discard> for more information.

=head2 dump

  $ok      = $db->dump($key);
  $db      = $db->dump($key, sub { my ($db, $err, $ok) = @_ });
  $promise = $db->dump_p($key);

Return a serialized version of the value stored at the specified key.

See L<https://redis.io/commands/dump> for more information.

=head2 echo

  $res     = $db->echo($message);
  $db      = $db->echo($message, sub { my ($db, $err, $res) = @_ });
  $promise = $db->echo_p($message);

Echo the given string.

See L<https://redis.io/commands/echo> for more information.

=head2 eval

  $res     = $db->eval($script, $numkeys, $key [key ...], $arg [arg ...]);
  $db      = $db->eval($script, $numkeys, $key [key ...], $arg [arg ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->eval_p($script, $numkeys, $key [key ...], $arg [arg ...]);

Execute a Lua script server side.

See L<https://redis.io/commands/eval> for more information.

=head2 evalsha

  $res     = $db->evalsha($sha1, $numkeys, $key [key ...], $arg [arg ...]);
  $db      = $db->evalsha($sha1, $numkeys, $key [key ...], $arg [arg ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->evalsha_p($sha1, $numkeys, $key [key ...], $arg [arg ...]);

Execute a Lua script server side.

See L<https://redis.io/commands/evalsha> for more information.

=head2 exec

See L</exec_p>.

=head2 exec_p

  $array_ref = $db->exec;
  $db        = $db->exec(sub { my ($db, $err, $array_ref) = @_ });
  $promise   = $db->exec_p;

Execute all commands issued after L</multi>.

See L<https://redis.io/commands/exec> for more information.

=head2 exists

  $int     = $db->exists($key [key ...]);
  $db      = $db->exists($key [key ...], sub { my ($db, $err, $int) = @_ });
  $promise = $db->exists_p($key [key ...]);

Determine if a key exists.

See L<https://redis.io/commands/exists> for more information.

=head2 expire

  $int     = $db->expire($key, $seconds);
  $db      = $db->expire($key, $seconds, sub { my ($db, $err, $int) = @_ });
  $promise = $db->expire_p($key, $seconds);

Set a key's time to live in seconds.

See L<https://redis.io/commands/expire> for more information.

=head2 expireat

  $int     = $db->expireat($key, $timestamp);
  $db      = $db->expireat($key, $timestamp, sub { my ($db, $err, $int) = @_ });
  $promise = $db->expireat_p($key, $timestamp);

Set the expiration for a key as a UNIX timestamp.

See L<https://redis.io/commands/expireat> for more information.

=head2 flushall

  $str     = $db->flushall([ASYNC]);
  $db      = $db->flushall([ASYNC], sub { my ($db, $err, $str) = @_ });
  $promise = $db->flushall_p([ASYNC]);

Remove all keys from all databases.

See L<https://redis.io/commands/flushall> for more information.

=head2 flushdb

  $str     = $db->flushdb([ASYNC]);
  $db      = $db->flushdb([ASYNC], sub { my ($db, $err, $str) = @_ });
  $promise = $db->flushdb_p([ASYNC]);

Remove all keys from the current database.

See L<https://redis.io/commands/flushdb> for more information.

=head2 geoadd

  $res     = $db->geoadd($key, $longitude latitude member [longitude latitude member ...]);
  $db      = $db->geoadd($key, $longitude latitude member [longitude latitude member ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->geoadd_p($key, $longitude latitude member [longitude latitude member ...]);

Add one or more geospatial items in the geospatial index represented using a sorted set.

See L<https://redis.io/commands/geoadd> for more information.

=head2 geodist

  $res     = $db->geodist($key, $member1, $member2, [unit]);
  $db      = $db->geodist($key, $member1, $member2, [unit], sub { my ($db, $err, $res) = @_ });
  $promise = $db->geodist_p($key, $member1, $member2, [unit]);

Returns the distance between two members of a geospatial index.

See L<https://redis.io/commands/geodist> for more information.

=head2 geohash

  $res     = $db->geohash($key, $member [member ...]);
  $db      = $db->geohash($key, $member [member ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->geohash_p($key, $member [member ...]);

Returns members of a geospatial index as standard geohash strings.

See L<https://redis.io/commands/geohash> for more information.

=head2 geopos

  $array_ref = $db->geopos($key, $member [member ...]);
  $db        = $db->geopos($key, $member [member ...], sub { my ($db, $err, $array_ref) = @_ });
  $promise   = $db->geopos_p($key, $member [member ...]);

Returns longitude and latitude of members of a geospatial index:

  [{lat => $num, lng => $num}, ...]

See L<https://redis.io/commands/geopos> for more information.

=head2 georadius

  $res     = $db->georadius($key, $longitude, $latitude, $radius, $m|km|ft|mi, [WITHCOORD],[WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key]);
  $db      = $db->georadius($key, $longitude, $latitude, $radius, $m|km|ft|mi, [WITHCOORD],[WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key], sub { my ($db, $err, $res) = @_ });
  $promise = $db->georadius_p($key, $longitude, $latitude, $radius, $m|km|ft|mi, [WITHCOORD], [WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key]);

Query a sorted set representing a geospatial index to fetch members matching a given maximum distance from a point.

See L<https://redis.io/commands/georadius> for more information.

=head2 georadiusbymember

  $res     = $db->georadiusbymember($key, $member, $radius, $m|km|ft|mi, [WITHCOORD], [WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key]);
  $db      = $db->georadiusbymember($key, $member, $radius, $m|km|ft|mi, [WITHCOORD], [WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key], sub { my ($db, $err, $res) = @_ });
  $promise = $db->georadiusbymember_p($key, $member, $radius, $m|km|ft|mi, [WITHCOORD], [WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key]);

Query a sorted set representing a geospatial index to fetch members matching a given maximum distance from a member.

See L<https://redis.io/commands/georadiusbymember> for more information.

=head2 get

  $res     = $db->get($key);
  $db      = $db->get($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->get_p($key);

Get the value of a key.

See L<https://redis.io/commands/get> for more information.

=head2 getbit

  $res     = $db->getbit($key, $offset);
  $db      = $db->getbit($key, $offset, sub { my ($db, $err, $res) = @_ });
  $promise = $db->getbit_p($key, $offset);

Returns the bit value at offset in the string value stored at key.

See L<https://redis.io/commands/getbit> for more information.

=head2 getrange

  $res     = $db->getrange($key, $start, $end);
  $db      = $db->getrange($key, $start, $end, sub { my ($db, $err, $res) = @_ });
  $promise = $db->getrange_p($key, $start, $end);

Get a substring of the string stored at a key.

See L<https://redis.io/commands/getrange> for more information.

=head2 getset

  $res     = $db->getset($key, $value);
  $db      = $db->getset($key, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->getset_p($key, $value);

Set the string value of a key and return its old value.

See L<https://redis.io/commands/getset> for more information.

=head2 hdel

  $res     = $db->hdel($key, $field [field ...]);
  $db      = $db->hdel($key, $field [field ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->hdel_p($key, $field [field ...]);

Delete one or more hash fields.

See L<https://redis.io/commands/hdel> for more information.

=head2 hexists

  $res     = $db->hexists($key, $field);
  $db      = $db->hexists($key, $field, sub { my ($db, $err, $res) = @_ });
  $promise = $db->hexists_p($key, $field);

Determine if a hash field exists.

See L<https://redis.io/commands/hexists> for more information.

=head2 hget

  $res     = $db->hget($key, $field);
  $db      = $db->hget($key, $field, sub { my ($db, $err, $res) = @_ });
  $promise = $db->hget_p($key, $field);

Get the value of a hash field.

See L<https://redis.io/commands/hget> for more information.

=head2 hgetall

  $res     = $db->hgetall($key);
  $db      = $db->hgetall($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->hgetall_p($key);

Get all the fields and values in a hash. The returned value from Redis is
automatically turned into a hash-ref for convenience.

See L<https://redis.io/commands/hgetall> for more information.

=head2 hincrby

  $res     = $db->hincrby($key, $field, $increment);
  $db      = $db->hincrby($key, $field, $increment, sub { my ($db, $err, $res) = @_ });
  $promise = $db->hincrby_p($key, $field, $increment);

Increment the integer value of a hash field by the given number.

See L<https://redis.io/commands/hincrby> for more information.

=head2 hincrbyfloat

  $res     = $db->hincrbyfloat($key, $field, $increment);
  $db      = $db->hincrbyfloat($key, $field, $increment, sub { my ($db, $err, $res) = @_ });
  $promise = $db->hincrbyfloat_p($key, $field, $increment);

Increment the float value of a hash field by the given amount.

See L<https://redis.io/commands/hincrbyfloat> for more information.

=head2 hkeys

  $res     = $db->hkeys($key);
  $db      = $db->hkeys($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->hkeys_p($key);

Get all the fields in a hash.

See L<https://redis.io/commands/hkeys> for more information.

=head2 hlen

  $res     = $db->hlen($key);
  $db      = $db->hlen($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->hlen_p($key);

Get the number of fields in a hash.

See L<https://redis.io/commands/hlen> for more information.

=head2 hmget

  $res     = $db->hmget($key, $field [field ...]);
  $db      = $db->hmget($key, $field [field ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->hmget_p($key, $field [field ...]);

Get the values of all the given hash fields.

See L<https://redis.io/commands/hmget> for more information.

=head2 hmset

  $res     = $db->hmset($key, $field => $value [field value ...]);
  $db      = $db->hmset($key, $field => $value [field value ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->hmset_p($key, $field => $value [field value ...]);

Set multiple hash fields to multiple values.

See L<https://redis.io/commands/hmset> for more information.

=head2 hset

  $res     = $db->hset($key, $field, $value);
  $db      = $db->hset($key, $field, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->hset_p($key, $field, $value);

Set the string value of a hash field.

See L<https://redis.io/commands/hset> for more information.

=head2 hsetnx

  $res     = $db->hsetnx($key, $field, $value);
  $db      = $db->hsetnx($key, $field, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->hsetnx_p($key, $field, $value);

Set the value of a hash field, only if the field does not exist.

See L<https://redis.io/commands/hsetnx> for more information.

=head2 hstrlen

  $res     = $db->hstrlen($key, $field);
  $db      = $db->hstrlen($key, $field, sub { my ($db, $err, $res) = @_ });
  $promise = $db->hstrlen_p($key, $field);

Get the length of the value of a hash field.

See L<https://redis.io/commands/hstrlen> for more information.

=head2 hvals

  $res     = $db->hvals($key);
  $db      = $db->hvals($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->hvals_p($key);

Get all the values in a hash.

See L<https://redis.io/commands/hvals> for more information.

=head2 info

  $res     = $db->info($section);
  $db      = $db->info($section, sub { my ($db, $err, $res) = @_ });
  $promise = $db->info_p($section);

Get information and statistics about the server. See also L</info_structured>.

See L<https://redis.io/commands/info> for more information.

=head2 info_structured

Same as L</info>, but the result is a hash-ref where the keys are the different
sections, with key/values in a sub hash. Will only be key/values if <$section>
is specified.

=head2 incr

  $res     = $db->incr($key);
  $db      = $db->incr($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->incr_p($key);

Increment the integer value of a key by one.

See L<https://redis.io/commands/incr> for more information.

=head2 incrby

  $res     = $db->incrby($key, $increment);
  $db      = $db->incrby($key, $increment, sub { my ($db, $err, $res) = @_ });
  $promise = $db->incrby_p($key, $increment);

Increment the integer value of a key by the given amount.

See L<https://redis.io/commands/incrby> for more information.

=head2 incrbyfloat

  $res     = $db->incrbyfloat($key, $increment);
  $db      = $db->incrbyfloat($key, $increment, sub { my ($db, $err, $res) = @_ });
  $promise = $db->incrbyfloat_p($key, $increment);

Increment the float value of a key by the given amount.

See L<https://redis.io/commands/incrbyfloat> for more information.

=head2 keys

  $res     = $db->keys($pattern);
  $db      = $db->keys($pattern, sub { my ($db, $err, $res) = @_ });
  $promise = $db->keys_p($pattern);

Find all keys matching the given pattern.

See L<https://redis.io/commands/keys> for more information.

=head2 lastsave

  $res     = $db->lastsave;
  $db      = $db->lastsave(sub { my ($db, $err, $res) = @_ });
  $promise = $db->lastsave_p;

Get the UNIX time stamp of the last successful save to disk.

See L<https://redis.io/commands/lastsave> for more information.

=head2 lindex

  $res     = $db->lindex($key, $index);
  $db      = $db->lindex($key, $index, sub { my ($db, $err, $res) = @_ });
  $promise = $db->lindex_p($key, $index);

Get an element from a list by its index.

See L<https://redis.io/commands/lindex> for more information.

=head2 linsert

  $res     = $db->linsert($key, $BEFORE|AFTER, $pivot, $value);
  $db      = $db->linsert($key, $BEFORE|AFTER, $pivot, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->linsert_p($key, $BEFORE|AFTER, $pivot, $value);

Insert an element before or after another element in a list.

See L<https://redis.io/commands/linsert> for more information.

=head2 llen

  $res     = $db->llen($key);
  $db      = $db->llen($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->llen_p($key);

Get the length of a list.

See L<https://redis.io/commands/llen> for more information.

=head2 lpop

  $res     = $db->lpop($key);
  $db      = $db->lpop($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->lpop_p($key);

Remove and get the first element in a list.

See L<https://redis.io/commands/lpop> for more information.

=head2 lpush

  $res     = $db->lpush($key, $value [value ...]);
  $db      = $db->lpush($key, $value [value ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->lpush_p($key, $value [value ...]);

Prepend one or multiple values to a list.

See L<https://redis.io/commands/lpush> for more information.

=head2 lpushx

  $res     = $db->lpushx($key, $value);
  $db      = $db->lpushx($key, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->lpushx_p($key, $value);

Prepend a value to a list, only if the list exists.

See L<https://redis.io/commands/lpushx> for more information.

=head2 lrange

  $res     = $db->lrange($key, $start, $stop);
  $db      = $db->lrange($key, $start, $stop, sub { my ($db, $err, $res) = @_ });
  $promise = $db->lrange_p($key, $start, $stop);

Get a range of elements from a list.

See L<https://redis.io/commands/lrange> for more information.

=head2 lrem

  $res     = $db->lrem($key, $count, $value);
  $db      = $db->lrem($key, $count, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->lrem_p($key, $count, $value);

Remove elements from a list.

See L<https://redis.io/commands/lrem> for more information.

=head2 lset

  $res     = $db->lset($key, $index, $value);
  $db      = $db->lset($key, $index, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->lset_p($key, $index, $value);

Set the value of an element in a list by its index.

See L<https://redis.io/commands/lset> for more information.

=head2 ltrim

  $res     = $db->ltrim($key, $start, $stop);
  $db      = $db->ltrim($key, $start, $stop, sub { my ($db, $err, $res) = @_ });
  $promise = $db->ltrim_p($key, $start, $stop);

Trim a list to the specified range.

See L<https://redis.io/commands/ltrim> for more information.

=head2 mget

  $res     = $db->mget($key [key ...]);
  $db      = $db->mget($key [key ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->mget_p($key [key ...]);

Get the values of all the given keys.

See L<https://redis.io/commands/mget> for more information.

=head2 move

  $res     = $db->move($key, $db);
  $db      = $db->move($key, $db, sub { my ($db, $err, $res) = @_ });
  $promise = $db->move_p($key, $db);

Move a key to another database.

See L<https://redis.io/commands/move> for more information.

=head2 mset

  $res     = $db->mset($key value [key value ...]);
  $db      = $db->mset($key value [key value ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->mset_p($key value [key value ...]);

Set multiple keys to multiple values.

See L<https://redis.io/commands/mset> for more information.

=head2 msetnx

  $res     = $db->msetnx($key value [key value ...]);
  $db      = $db->msetnx($key value [key value ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->msetnx_p($key value [key value ...]);

Set multiple keys to multiple values, only if none of the keys exist.

See L<https://redis.io/commands/msetnx> for more information.

=head2 multi

See L</multi_p>.

=head2 multi_p

  $res     = $db->multi;
  $db      = $db->multi(sub { my ($db, $err, $res) = @_ });
  $promise = $db->multi_p;
  $promise = $db->multi_p(@promises);

Mark the start of a transaction block. Commands issued after L</multi> will
automatically be discarded if C<$db> goes out of scope. Need to call
L</exec> to commit the queued commands to Redis.

When calling L</multi_p>, you can directly pass in the new instructions:

  $db->multi_p(
    $db->set_p("x:y:z" => 1011),
    $db->get_p("x:y:z"),
    $db->incr_p("x:y:z"),
    $db->incrby_p("x:y:z" => -10),
  )->then(sub {
  });

See L<https://redis.io/commands/multi> for more information.

=head2 object

  $res     = $db->object($subcommand, [arguments [arguments ...]]);
  $db      = $db->object($subcommand, [arguments [arguments ...]], sub { my ($db, $err, $res) =@_ });
  $promise = $db->object_p($subcommand, [arguments [arguments ...]]);

Inspect the internals of Redis objects.

See L<https://redis.io/commands/object> for more information.

=head2 persist

  $res     = $db->persist($key);
  $db      = $db->persist($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->persist_p($key);

Remove the expiration from a key.

See L<https://redis.io/commands/persist> for more information.

=head2 pexpire

  $res     = $db->pexpire($key, $milliseconds);
  $db      = $db->pexpire($key, $milliseconds, sub { my ($db, $err, $res) = @_ });
  $promise = $db->pexpire_p($key, $milliseconds);

Set a key's time to live in milliseconds.

See L<https://redis.io/commands/pexpire> for more information.

=head2 pexpireat

  $res     = $db->pexpireat($key, $milliseconds-timestamp);
  $db      = $db->pexpireat($key, $milliseconds-timestamp, sub { my ($db, $err, $res) = @_ });
  $promise = $db->pexpireat_p($key, $milliseconds-timestamp);

Set the expiration for a key as a UNIX timestamp specified in milliseconds.

See L<https://redis.io/commands/pexpireat> for more information.

=head2 pfadd

  $res     = $db->pfadd($key, $element [element ...]);
  $db      = $db->pfadd($key, $element [element ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->pfadd_p($key, $element [element ...]);

Adds the specified elements to the specified HyperLogLog.

See L<https://redis.io/commands/pfadd> for more information.

=head2 pfcount

  $res     = $db->pfcount($key [key ...]);
  $db      = $db->pfcount($key [key ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->pfcount_p($key [key ...]);

Return the approximated cardinality of the set(s) observed by the HyperLogLog at key(s).

See L<https://redis.io/commands/pfcount> for more information.

=head2 pfmerge

  $res     = $db->pfmerge($destkey, $sourcekey [sourcekey ...]);
  $db      = $db->pfmerge($destkey, $sourcekey [sourcekey ...], sub { my ($db, $err, $res) = @_});
  $promise = $db->pfmerge_p($destkey, $sourcekey [sourcekey ...]);

Merge N different HyperLogLogs into a single one.

See L<https://redis.io/commands/pfmerge> for more information.

=head2 ping

  $res     = $db->ping([message]);
  $db      = $db->ping([message], sub { my ($db, $err, $res) = @_ });
  $promise = $db->ping_p([message]);

Ping the server.

See L<https://redis.io/commands/ping> for more information.

=head2 psetex

  $res     = $db->psetex($key, $milliseconds, $value);
  $db      = $db->psetex($key, $milliseconds, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->psetex_p($key, $milliseconds, $value);

Set the value and expiration in milliseconds of a key.

See L<https://redis.io/commands/psetex> for more information.

=head2 pttl

  $res     = $db->pttl($key);
  $db      = $db->pttl($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->pttl_p($key);

Get the time to live for a key in milliseconds.

See L<https://redis.io/commands/pttl> for more information.

=head2 publish

  $res     = $db->publish($channel, $message);
  $db      = $db->publish($channel, $message, sub { my ($db, $err, $res) = @_ });
  $promise = $db->publish_p($channel, $message);

Post a message to a channel.

See L<https://redis.io/commands/publish> for more information.

=head2 randomkey

  $res     = $db->randomkey;
  $db      = $db->randomkey(sub { my ($db, $err, $res) = @_ });
  $promise = $db->randomkey_p;

Return a random key from the keyspace.

See L<https://redis.io/commands/randomkey> for more information.

=head2 readonly

  $res     = $db->readonly();
  $db      = $db->readonly(, sub { my ($db, $res) = @_ });
  $promise = $db->readonly_p();

Enables read queries for a connection to a cluster slave node.

See L<https://redis.io/commands/readonly> for more information.

=head2 readwrite

  $res     = $db->readwrite();
  $db      = $db->readwrite(, sub { my ($db, $res) = @_ });
  $promise = $db->readwrite_p();

Disables read queries for a connection to a cluster slave node.

See L<https://redis.io/commands/readwrite> for more information.

=head2 rename

  $res     = $db->rename($key, $newkey);
  $db      = $db->rename($key, $newkey, sub { my ($db, $err, $res) = @_ });
  $promise = $db->rename_p($key, $newkey);

Rename a key.

See L<https://redis.io/commands/rename> for more information.

=head2 renamenx

  $res     = $db->renamenx($key, $newkey);
  $db      = $db->renamenx($key, $newkey, sub { my ($db, $err, $res) = @_ });
  $promise = $db->renamenx_p($key, $newkey);

Rename a key, only if the new key does not exist.

See L<https://redis.io/commands/renamenx> for more information.

=head2 role

  $res     = $db->role;
  $db      = $db->role(sub { my ($db, $err, $res) = @_ });
  $promise = $db->role_p;

Return the role of the instance in the context of replication.

See L<https://redis.io/commands/role> for more information.

=head2 rpop

  $res     = $db->rpop($key);
  $db      = $db->rpop($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->rpop_p($key);

Remove and get the last element in a list.

See L<https://redis.io/commands/rpop> for more information.

=head2 rpoplpush

  $res     = $db->rpoplpush($source, $destination);
  $db      = $db->rpoplpush($source, $destination, sub { my ($db, $err, $res) = @_ });
  $promise = $db->rpoplpush_p($source, $destination);

Remove the last element in a list, prepend it to another list and return it.

See L<https://redis.io/commands/rpoplpush> for more information.

=head2 rpush

  $res     = $db->rpush($key, $value [value ...]);
  $db      = $db->rpush($key, $value [value ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->rpush_p($key, $value [value ...]);

Append one or multiple values to a list.

See L<https://redis.io/commands/rpush> for more information.

=head2 rpushx

  $res     = $db->rpushx($key, $value);
  $db      = $db->rpushx($key, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->rpushx_p($key, $value);

Append a value to a list, only if the list exists.

See L<https://redis.io/commands/rpushx> for more information.

=head2 restore

  $res     = $db->restore($key, $ttl, $serialized-value, [REPLACE]);
  $db      = $db->restore($key, $ttl, $serialized-value, [REPLACE], sub { my ($db, $err, $res) = @_ });
  $promise = $db->restore_p($key, $ttl, $serialized-value, [REPLACE]);

Create a key using the provided serialized value, previously obtained using DUMP.

See L<https://redis.io/commands/restore> for more information.

=head2 sadd

  $res     = $db->sadd($key, $member [member ...]);
  $db      = $db->sadd($key, $member [member ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->sadd_p($key, $member [member ...]);

Add one or more members to a set.

See L<https://redis.io/commands/sadd> for more information.

=head2 save

  $res     = $db->save;
  $db      = $db->save(sub { my ($db, $err, $res) = @_ });
  $promise = $db->save_p;

Synchronously save the dataset to disk.

See L<https://redis.io/commands/save> for more information.

=head2 scard

  $res     = $db->scard($key);
  $db      = $db->scard($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->scard_p($key);

Get the number of members in a set.

See L<https://redis.io/commands/scard> for more information.

=head2 script

  $res     = $db->script($sub_command, @args);
  $db      = $db->script($sub_command, @args, sub { my ($db, $err, $res) = @_ });
  $promise = $db->script_p($sub_command, @args);

Execute a script command.

See L<https://redis.io/commands/script-debug>,
L<https://redis.io/commands/script-exists>,
L<https://redis.io/commands/script-flush>,
L<https://redis.io/commands/script-kill> or
L<https://redis.io/commands/script-load> for more information.

=head2 sdiff

  $res     = $db->sdiff($key [key ...]);
  $db      = $db->sdiff($key [key ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->sdiff_p($key [key ...]);

Subtract multiple sets.

See L<https://redis.io/commands/sdiff> for more information.

=head2 sdiffstore

  $res     = $db->sdiffstore($destination, $key [key ...]);
  $db      = $db->sdiffstore($destination, $key [key ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->sdiffstore_p($destination, $key [key ...]);

Subtract multiple sets and store the resulting set in a key.

See L<https://redis.io/commands/sdiffstore> for more information.

=head2 set

  $res     = $db->set($key, $value, [expiration EX seconds|PX milliseconds], [NX|XX]);
  $db      = $db->set($key, $value, [expiration EX seconds|PX milliseconds], [NX|XX], sub {my ($db, $err, $res) = @_ });
  $promise = $db->set_p($key, $value, [expiration EX seconds|PX milliseconds], [NX|XX]);

Set the string value of a key.

See L<https://redis.io/commands/set> for more information.

=head2 setbit

  $res     = $db->setbit($key, $offset, $value);
  $db      = $db->setbit($key, $offset, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->setbit_p($key, $offset, $value);

Sets or clears the bit at offset in the string value stored at key.

See L<https://redis.io/commands/setbit> for more information.

=head2 setex

  $res     = $db->setex($key, $seconds, $value);
  $db      = $db->setex($key, $seconds, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->setex_p($key, $seconds, $value);

Set the value and expiration of a key.

See L<https://redis.io/commands/setex> for more information.

=head2 setnx

  $res     = $db->setnx($key, $value);
  $db      = $db->setnx($key, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->setnx_p($key, $value);

Set the value of a key, only if the key does not exist.

See L<https://redis.io/commands/setnx> for more information.

=head2 setrange

  $res     = $db->setrange($key, $offset, $value);
  $db      = $db->setrange($key, $offset, $value, sub { my ($db, $err, $res) = @_ });
  $promise = $db->setrange_p($key, $offset, $value);

Overwrite part of a string at key starting at the specified offset.

See L<https://redis.io/commands/setrange> for more information.

=head2 sinter

  $res     = $db->sinter($key [key ...]);
  $db      = $db->sinter($key [key ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->sinter_p($key [key ...]);

Intersect multiple sets.

See L<https://redis.io/commands/sinter> for more information.

=head2 sinterstore

  $res     = $db->sinterstore($destination, $key [key ...]);
  $db      = $db->sinterstore($destination, $key [key ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->sinterstore_p($destination, $key [key ...]);

Intersect multiple sets and store the resulting set in a key.

See L<https://redis.io/commands/sinterstore> for more information.

=head2 sismember

  $res     = $db->sismember($key, $member);
  $db      = $db->sismember($key, $member, sub { my ($db, $err, $res) = @_ });
  $promise = $db->sismember_p($key, $member);

Determine if a given value is a member of a set.

See L<https://redis.io/commands/sismember> for more information.

=head2 slaveof

  $res     = $db->slaveof($host, $port);
  $db      = $db->slaveof($host, $port, sub { my ($db, $err, $res) = @_ });
  $promise = $db->slaveof_p($host, $port);

Make the server a slave of another instance, or promote it as master.

See L<https://redis.io/commands/slaveof> for more information.

=head2 slowlog

  $res     = $db->slowlog($subcommand, [argument]);
  $db      = $db->slowlog($subcommand, [argument], sub { my ($db, $err, $res) = @_ });
  $promise = $db->slowlog_p($subcommand, [argument]);

Manages the Redis slow queries log.

See L<https://redis.io/commands/slowlog> for more information.

=head2 smembers

  $res     = $db->smembers($key);
  $db      = $db->smembers($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->smembers_p($key);

Get all the members in a set.

See L<https://redis.io/commands/smembers> for more information.

=head2 smove

  $res     = $db->smove($source, $destination, $member);
  $db      = $db->smove($source, $destination, $member, sub { my ($db, $err, $res) = @_ });
  $promise = $db->smove_p($source, $destination, $member);

Move a member from one set to another.

See L<https://redis.io/commands/smove> for more information.

=head2 sort

  $res     = $db->sort($key, [BY pattern], [LIMIT offset count], [GET pattern [GET pattern ...]], [ASC|DESC], [ALPHA], [STORE destination]);
  $db      = $db->sort($key, [BY pattern], [LIMIT offset count], [GET pattern [GET pattern ...]], [ASC|DESC], [ALPHA], [STORE destination], sub { my ($db, $err, $res) = @_ });
  $promise = $db->sort_p($key, [BY pattern], [LIMIT offset count], [GET pattern [GET pattern ...]], [ASC|DESC], [ALPHA], [STORE destination]);

Sort the elements in a list, set or sorted set.

See L<https://redis.io/commands/sort> for more information.

=head2 spop

  $res     = $db->spop($key, [count]);
  $db      = $db->spop($key, [count], sub { my ($db, $err, $res) = @_ });
  $promise = $db->spop_p($key, [count]);

Remove and return one or multiple random members from a set.

See L<https://redis.io/commands/spop> for more information.

=head2 srandmember

  $res     = $db->srandmember($key, [count]);
  $db      = $db->srandmember($key, [count], sub { my ($db, $err, $res) = @_ });
  $promise = $db->srandmember_p($key, [count]);

Get one or multiple random members from a set.

See L<https://redis.io/commands/srandmember> for more information.

=head2 srem

  $res     = $db->srem($key, $member [member ...]);
  $db      = $db->srem($key, $member [member ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->srem_p($key, $member [member ...]);

Remove one or more members from a set.

See L<https://redis.io/commands/srem> for more information.

=head2 strlen

  $res     = $db->strlen($key);
  $db      = $db->strlen($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->strlen_p($key);

Get the length of the value stored in a key.

See L<https://redis.io/commands/strlen> for more information.

=head2 sunion

  $res     = $db->sunion($key [key ...]);
  $db      = $db->sunion($key [key ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->sunion_p($key [key ...]);

Add multiple sets.

See L<https://redis.io/commands/sunion> for more information.

=head2 sunionstore

  $res     = $db->sunionstore($destination, $key [key ...]);
  $db      = $db->sunionstore($destination, $key [key ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->sunionstore_p($destination, $key [key ...]);

Add multiple sets and store the resulting set in a key.

See L<https://redis.io/commands/sunionstore> for more information.

=head2 time

  $res     = $db->time;
  $db      = $db->time(sub { my ($db, $err, $res) = @_ });
  $promise = $db->time_p;

Return the current server time.

See L<https://redis.io/commands/time> for more information.

=head2 touch

  $res     = $db->touch($key [key ...]);
  $db      = $db->touch($key [key ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->touch_p($key [key ...]);

Alters the last access time of a key(s). Returns the number of existing keys specified.

See L<https://redis.io/commands/touch> for more information.

=head2 ttl

  $res     = $db->ttl($key);
  $db      = $db->ttl($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->ttl_p($key);

Get the time to live for a key.

See L<https://redis.io/commands/ttl> for more information.

=head2 type

  $res     = $db->type($key);
  $db      = $db->type($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->type_p($key);

Determine the type stored at key.

See L<https://redis.io/commands/type> for more information.

=head2 unlink

  $res     = $db->unlink($key [key ...]);
  $db      = $db->unlink($key [key ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->unlink_p($key [key ...]);

Delete a key asynchronously in another thread. Otherwise it is just as DEL, but non blocking.

See L<https://redis.io/commands/unlink> for more information.

=head2 unwatch

  $res     = $db->unwatch;
  $db      = $db->unwatch(sub { my ($db, $err, $res) = @_ });
  $promise = $db->unwatch_p;

Forget about all watched keys.

See L<https://redis.io/commands/unwatch> for more information.

=head2 watch

  $res     = $db->watch($key [key ...]);
  $db      = $db->watch($key [key ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->watch_p($key [key ...]);

Watch the given keys to determine execution of the MULTI/EXEC block.

See L<https://redis.io/commands/watch> for more information.

=head2 xadd

  $res     = $db->xadd($key, $ID, $field string [field string ...]);
  $db      = $db->xadd($key, $ID, $field string [field string ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->xadd_p($key, $ID, $field string [field string ...]);

Appends a new entry to a stream.

See L<https://redis.io/commands/xadd> for more information.

=head2 xlen

  $res     = $db->xlen($key);
  $db      = $db->xlen($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->xlen_p($key);

Return the number of entires in a stream.

See L<https://redis.io/commands/xlen> for more information.

=head2 xpending

  $res     = $db->xpending($key, $group, [start end count], [consumer]);
  $db      = $db->xpending($key, $group, [start end count], [consumer], sub { my ($db, $err, $res) = @_ });
  $promise = $db->xpending_p($key, $group, [start end count], [consumer]);

Return information and entries from a stream consumer group pending entries list, that are messages fetched but never acknowledged.

See L<https://redis.io/commands/xpending> for more information.

=head2 xrange

  $res     = $db->xrange($key, $start, $end, [COUNT count]);
  $db      = $db->xrange($key, $start, $end, [COUNT count], sub { my ($db, $err, $res) = @_ });
  $promise = $db->xrange_p($key, $start, $end, [COUNT count]);

Return a range of elements in a stream, with IDs matching the specified IDs interval.

See L<https://redis.io/commands/xrange> for more information.

=head2 xread

  $res     = $db->xread([COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...]);
  $db      = $db->xread([COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->xread_p([COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...]);

Return never seen elements in multiple streams, with IDs greater than the ones reported by the caller for each stream. Can block.

See L<https://redis.io/commands/xread> for more information.

=head2 xread_structured

Same as L</xread>, but the result is a data structure like this:

  {
    $stream_name => [
      [ $id1 => [@data1] ],
      [ $id2 => [@data2] ],
      ...
    ]
  }

This method is currently EXPERIMENTAL, but will only change if bugs are
discovered.

=head2 xreadgroup

  $res     = $db->xreadgroup($GROUP group consumer, [COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...]);
  $db      = $db->xreadgroup($GROUP group consumer, [COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->xreadgroup_p($GROUP group consumer, [COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...]);

Return new entries from a stream using a consumer group, or access the history of the pending entries for a given consumer. Can block.

See L<https://redis.io/commands/xreadgroup> for more information.

=head2 xrevrange

  $res     = $db->xrevrange($key, $end, $start, [COUNT count]);
  $db      = $db->xrevrange($key, $end, $start, [COUNT count], sub { my ($db, $err, $res) = @_ });
  $promise = $db->xrevrange_p($key, $end, $start, [COUNT count]);

Return a range of elements in a stream, with IDs matching the specified IDs interval, in reverse order (from greater to smaller IDs) compared to XRANGE.

See L<https://redis.io/commands/xrevrange> for more information.

=head2 zadd

  $res     = $db->zadd($key, [NX|XX], [CH], [INCR], $score member [score member ...]);
  $db      = $db->zadd($key, [NX|XX], [CH], [INCR], $score member [score member ...], sub {my ($db, $err, $res) = @_ });
  $promise = $db->zadd_p($key, [NX|XX], [CH], [INCR], $score member [score member ...]);

Add one or more members to a sorted set, or update its score if it already exists.

See L<https://redis.io/commands/zadd> for more information.

=head2 zcard

  $res     = $db->zcard($key);
  $db      = $db->zcard($key, sub { my ($db, $err, $res) = @_ });
  $promise = $db->zcard_p($key);

Get the number of members in a sorted set.

See L<https://redis.io/commands/zcard> for more information.

=head2 zcount

  $res     = $db->zcount($key, $min, $max);
  $db      = $db->zcount($key, $min, $max, sub { my ($db, $err, $res) = @_ });
  $promise = $db->zcount_p($key, $min, $max);

Count the members in a sorted set with scores within the given values.

See L<https://redis.io/commands/zcount> for more information.

=head2 zincrby

  $res     = $db->zincrby($key, $increment, $member);
  $db      = $db->zincrby($key, $increment, $member, sub { my ($db, $err, $res) = @_ });
  $promise = $db->zincrby_p($key, $increment, $member);

Increment the score of a member in a sorted set.

See L<https://redis.io/commands/zincrby> for more information.

=head2 zinterstore

  $res     = $db->zinterstore($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX]);
  $db      = $db->zinterstore($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX], sub { my ($db, $err, $res) = @_ });
  $promise = $db->zinterstore_p($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX]);

Intersect multiple sorted sets and store the resulting sorted set in a new key.

See L<https://redis.io/commands/zinterstore> for more information.

=head2 zlexcount

  $res     = $db->zlexcount($key, $min, $max);
  $db      = $db->zlexcount($key, $min, $max, sub { my ($db, $err, $res) = @_ });
  $promise = $db->zlexcount_p($key, $min, $max);

Count the number of members in a sorted set between a given lexicographical range.

See L<https://redis.io/commands/zlexcount> for more information.

=head2 zpopmax

  $res     = $db->zpopmax($key, [count]);
  $db      = $db->zpopmax($key, [count], sub { my ($db, $err, $res) = @_ });
  $promise = $db->zpopmax_p($key, [count]);

Remove and return members with the highest scores in a sorted set.

See L<https://redis.io/commands/zpopmax> for more information.

=head2 zpopmin

  $res     = $db->zpopmin($key, [count]);
  $db      = $db->zpopmin($key, [count], sub { my ($db, $err, $res) = @_ });
  $promise = $db->zpopmin_p($key, [count]);

Remove and return members with the lowest scores in a sorted set.

See L<https://redis.io/commands/zpopmin> for more information.

=head2 zrange

  $res     = $db->zrange($key, $start, $stop, [WITHSCORES]);
  $db      = $db->zrange($key, $start, $stop, [WITHSCORES], sub { my ($db, $err, $res) = @_ });
  $promise = $db->zrange_p($key, $start, $stop, [WITHSCORES]);

Return a range of members in a sorted set, by index.

See L<https://redis.io/commands/zrange> for more information.

=head2 zrangebylex

  $res     = $db->zrangebylex($key, $min, $max, [LIMIT offset count]);
  $db      = $db->zrangebylex($key, $min, $max, [LIMIT offset count], sub { my ($db, $err, $res) = @_ });
  $promise = $db->zrangebylex_p($key, $min, $max, [LIMIT offset count]);

Return a range of members in a sorted set, by lexicographical range.

See L<https://redis.io/commands/zrangebylex> for more information.

=head2 zrangebyscore

  $res     = $db->zrangebyscore($key, $min, $max, [WITHSCORES], [LIMIT offset count]);
  $db      = $db->zrangebyscore($key, $min, $max, [WITHSCORES], [LIMIT offset count], sub {my ($db, $err, $res) = @_ });
  $promise = $db->zrangebyscore_p($key, $min, $max, [WITHSCORES], [LIMIT offset count]);

Return a range of members in a sorted set, by score.

See L<https://redis.io/commands/zrangebyscore> for more information.

=head2 zrank

  $res     = $db->zrank($key, $member);
  $db      = $db->zrank($key, $member, sub { my ($db, $err, $res) = @_ });
  $promise = $db->zrank_p($key, $member);

Determine the index of a member in a sorted set.

See L<https://redis.io/commands/zrank> for more information.

=head2 zrem

  $res     = $db->zrem($key, $member [member ...]);
  $db      = $db->zrem($key, $member [member ...], sub { my ($db, $err, $res) = @_ });
  $promise = $db->zrem_p($key, $member [member ...]);

Remove one or more members from a sorted set.

See L<https://redis.io/commands/zrem> for more information.

=head2 zremrangebylex

  $res     = $db->zremrangebylex($key, $min, $max);
  $db      = $db->zremrangebylex($key, $min, $max, sub { my ($db, $err, $res) = @_ });
  $promise = $db->zremrangebylex_p($key, $min, $max);

Remove all members in a sorted set between the given lexicographical range.

See L<https://redis.io/commands/zremrangebylex> for more information.

=head2 zremrangebyrank

  $res     = $db->zremrangebyrank($key, $start, $stop);
  $db      = $db->zremrangebyrank($key, $start, $stop, sub { my ($db, $err, $res) = @_ });
  $promise = $db->zremrangebyrank_p($key, $start, $stop);

Remove all members in a sorted set within the given indexes.

See L<https://redis.io/commands/zremrangebyrank> for more information.

=head2 zremrangebyscore

  $res     = $db->zremrangebyscore($key, $min, $max);
  $db      = $db->zremrangebyscore($key, $min, $max, sub { my ($db, $err, $res) = @_ });
  $promise = $db->zremrangebyscore_p($key, $min, $max);

Remove all members in a sorted set within the given scores.

See L<https://redis.io/commands/zremrangebyscore> for more information.

=head2 zrevrange

  $res     = $db->zrevrange($key, $start, $stop, [WITHSCORES]);
  $db      = $db->zrevrange($key, $start, $stop, [WITHSCORES], sub { my ($db, $err, $res) = @_ });
  $promise = $db->zrevrange_p($key, $start, $stop, [WITHSCORES]);

Return a range of members in a sorted set, by index, with scores ordered from high to low.

See L<https://redis.io/commands/zrevrange> for more information.

=head2 zrevrangebylex

  $res     = $db->zrevrangebylex($key, $max, $min, [LIMIT offset count]);
  $db      = $db->zrevrangebylex($key, $max, $min, [LIMIT offset count], sub { my ($db, $err, $res) = @_ });
  $promise = $db->zrevrangebylex_p($key, $max, $min, [LIMIT offset count]);

Return a range of members in a sorted set, by lexicographical range, ordered from higher to lower strings.

See L<https://redis.io/commands/zrevrangebylex> for more information.

=head2 zrevrangebyscore

  $res     = $db->zrevrangebyscore($key, $max, $min, [WITHSCORES], [LIMIT offset count]);
  $db      = $db->zrevrangebyscore($key, $max, $min, [WITHSCORES], [LIMIT offset count], sub { my ($db, $err, $res) = @_ });
  $promise = $db->zrevrangebyscore_p($key, $max, $min, [WITHSCORES], [LIMIT offset count]);

Return a range of members in a sorted set, by score, with scores ordered from high to low.

See L<https://redis.io/commands/zrevrangebyscore> for more information.

=head2 zrevrank

  $res     = $db->zrevrank($key, $member);
  $db      = $db->zrevrank($key, $member, sub { my ($db, $err, $res) = @_ });
  $promise = $db->zrevrank_p($key, $member);

Determine the index of a member in a sorted set, with scores ordered from high to low.

See L<https://redis.io/commands/zrevrank> for more information.

=head2 zscore

  $res     = $db->zscore($key, $member);
  $db      = $db->zscore($key, $member, sub { my ($db, $err, $res) = @_ });
  $promise = $db->zscore_p($key, $member);

Get the score associated with the given member in a sorted set.

See L<https://redis.io/commands/zscore> for more information.

=head2 zunionstore

  $res     = $db->zunionstore($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX]);
  $db      = $db->zunionstore($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX], sub { my ($db, $err, $res) = @_ });
  $promise = $db->zunionstore_p($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX]);

Add multiple sorted sets and store the resulting sorted set in a new key.

See L<https://redis.io/commands/zunionstore> for more information.

=head1 SEE ALSO

L<Mojo::Redis>.

=cut
