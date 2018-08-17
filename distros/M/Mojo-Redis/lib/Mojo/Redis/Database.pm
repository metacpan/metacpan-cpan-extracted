package Mojo::Redis::Database;
use Mojo::Base -base;

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

has connection => sub { shift->redis->_dequeue };
has redis      => sub { Carp::confess('redis is required in constructor') };

__PACKAGE__->_add_method('bnb,p' => $_) for @BASIC_COMMANDS;
__PACKAGE__->_add_method('nb,p'  => $_) for @BLOCKING_COMMANDS;
__PACKAGE__->_add_method('bnb'   => qw(_exec EXEC));
__PACKAGE__->_add_method('bnb'   => qw(_discard DISCARD));
__PACKAGE__->_add_method('bnb'   => qw(_multi MULTI));
__PACKAGE__->_add_method('bnb,p' => qw(info_structured info));
__PACKAGE__->_add_method('bnb,p' => $_) for qw(unwatch watch);

sub call {
  my $cb   = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self = shift;
  my $p    = ($cb ? $self->connection : $self->redis->_blocking_connection)->write_p(@_);

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
  my $self = shift;
  $self->{txn} = 'default';
  return $self->connection->write_p('MULTI');
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

sub _generate_bnb_method {
  my ($class, $op, $process) = @_;

  return sub {
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $self = shift;

    my $p = ($cb ? $self->connection : $self->redis->_blocking_connection)->write_p($op, @_);
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

sub DESTROY {
  my $self = shift;

  if (my $txn = delete $self->{txn}) {
    $self->redis->_blocking_connection->write_p('DISCARD')->wait if $txn eq 'blocking';
  }
  elsif (my $redis = $self->{redis} and my $conn = $self->{connection}) {
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

=head2 connection

  $conn = $self->connection;
  $self = $self->connection(Mojo::Redis::Connection->new);

Holds a L<Mojo::Redis::Connection> object.

=head2 redis

  $conn = $self->connection;
  $self = $self->connection(Mojo::Redis::Connection->new);

Holds a L<Mojo::Redis> object used to create the connections to talk with Redis.

=head1 METHODS

=head2 append

  $int     = $self->append($key, $value);
  $self    = $self->append($key, $value, sub { my ($self, $err, $int) = @_ });
  $promise = $self->append_p($key, $value);

Append a value to a key.

See L<https://redis.io/commands/append> for more information.

=head2 bgrewriteaof

  $ok      = $self->bgrewriteaof;
  $self    = $self->bgrewriteaof(sub { my ($self, $err, $ok) = @_ });
  $promise = $self->bgrewriteaof_p;

Asynchronously rewrite the append-only file.

See L<https://redis.io/commands/bgrewriteaof> for more information.

=head2 bgsave

  $ok      = $self->bgsave;
  $self    = $self->bgsave(sub { my ($self, $err, $ok) = @_ });
  $promise = $self->bgsave_p;

Asynchronously save the dataset to disk.

See L<https://redis.io/commands/bgsave> for more information.

=head2 bitcount

  $int     = $self->bitcount($key, [start end]);
  $self    = $self->bitcount($key, [start end], sub { my ($self, $err, $int) = @_ });
  $promise = $self->bitcount_p($key, [start end]);

Count set bits in a string.

See L<https://redis.io/commands/bitcount> for more information.

=head2 bitfield

  $res     = $self->bitfield($key, [GET type offset], [SET type offset value], [INCRBY type offset increment], [OVERFLOW WRAP|SAT|FAIL]);
  $self    = $self->bitfield($key, [GET type offset], [SET type offset value], [INCRBY type offset increment], [OVERFLOW WRAP|SAT|FAIL], sub { my ($self, $err, $res) = @_ });
  $promise = $self->bitfield_p($key, [GET type offset], [SET type offset value], [INCRBY typeoffset increment], [OVERFLOW WRAP|SAT|FAIL]);

Perform arbitrary bitfield integer operations on strings.

See L<https://redis.io/commands/bitfield> for more information.

=head2 bitop

  $int     = $self->bitop($operation, $destkey, $key [key ...]);
  $self    = $self->bitop($operation, $destkey, $key [key ...], sub { my ($self, $err, $int) = @_ });
  $promise = $self->bitop_p($operation, $destkey, $key [key ...]);

Perform bitwise operations between strings.

See L<https://redis.io/commands/bitop> for more information.

=head2 bitpos

  $int     = $self->bitpos($key, $bit, [start], [end]);
  $self    = $self->bitpos($key, $bit, [start], [end], sub { my ($self, $err, $int) = @_ });
  $promise = $self->bitpos_p($key, $bit, [start], [end]);

Find first bit set or clear in a string.

See L<https://redis.io/commands/bitpos> for more information.

=head2 blpop

  $self    = $self->blpop($key [key ...], $timeout, sub { my ($self, $val, $key) = @_ });
  $promise = $self->blpop_p($key [key ...], $timeout);

Remove and get the first element in a list, or block until one is available.

See L<https://redis.io/commands/blpop> for more information.

=head2 brpop

  $self    = $self->brpop($key [key ...], $timeout, sub { my ($self, $val, $key) = @_ });
  $promise = $self->brpop_p($key [key ...], $timeout);

Remove and get the last element in a list, or block until one is available.

See L<https://redis.io/commands/brpop> for more information.

=head2 brpoplpush

  $self    = $self->brpoplpush($source, $destination, $timeout, sub { my ($self, $err, $array_ref) = @_ });
  $promise = $self->brpoplpush_p($source, $destination, $timeout);

Pop a value from a list, push it to another list and return it; or block until one is available.

See L<https://redis.io/commands/brpoplpush> for more information.

=head2 bzpopmax

  $self    = $self->bzpopmax($key [key ...], $timeout, sub { my ($self, $err, $array_ref) = @_ });
  $promise = $self->bzpopmax_p($key [key ...], $timeout);

Remove and return the member with the highest score from one or more sorted sets, or block until one is available.

See L<https://redis.io/commands/bzpopmax> for more information.

=head2 bzpopmin

  $self    = $self->bzpopmin($key [key ...], $timeout, sub { my ($self, $err, $array_ref) = @_ });
  $promise = $self->bzpopmin_p($key [key ...], $timeout);

Remove and return the member with the lowest score from one or more sorted sets, or block until one is available.

See L<https://redis.io/commands/bzpopmin> for more information.

=head2 call

  $res  = $self->call($command => @args);
  $self = $self->call($command => @args, sub { my ($self, $err, $res) = @_; });

Same as L</call_p>, but either blocks or passes the result into a callback.

=head2 call_p

  $promise = $self->call_p($command => @args);
  $promise = $self->call_p(GET => "some:key");

Used to send a custom command to the Redis server.

=head2 client

  $res     = $self->client(@args);
  $self    = $self->client(@args, sub { my ($self, $err, $res) = @_ });
  $promise = $self->client_p(@args);

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

=head2 cluster

  $res     = $self->cluste3r(@args);
  $self    = $self->cluste3r(@args, sub { my ($self, $err, $res) = @_ });
  $promise = $self->cluste3r_p(@args);

Used to execute cluster commands.

See L<https://redis.io/commands#cluster> for more information.

=head2 command

  $array_ref = $self->command(@args);
  $self      = $self->command(@args, sub { my ($self, $err, $array_ref) = @_ });
  $promise   = $self->command_p(@args);

Get array of Redis command details.

=over 2

=item * empty list

=item * COUNT

=item * GETKEYS

=item * INFO command-name [command-name]

=back

See L<https://redis.io/commands/command> for more information.

=head2 dbsize

  $int     = $self->dbsize;
  $self    = $self->dbsize(sub { my ($self, $err, $int) = @_ });
  $promise = $self->dbsize_p;

Return the number of keys in the selected database.

See L<https://redis.io/commands/dbsize> for more information.

=head2 decr

  $num     = $self->decr($key);
  $self    = $self->decr($key, sub { my ($self, $err, $num) = @_ });
  $promise = $self->decr_p($key);

Decrement the integer value of a key by one.

See L<https://redis.io/commands/decr> for more information.

=head2 decrby

  $num     = $self->decrby($key, $decrement);
  $self    = $self->decrby($key, $decrement, sub { my ($self, $err, $num) = @_ });
  $promise = $self->decrby_p($key, $decrement);

Decrement the integer value of a key by the given number.

See L<https://redis.io/commands/decrby> for more information.

=head2 del

  $ok      = $self->del($key [key ...]);
  $self    = $self->del($key [key ...], sub { my ($self, $err, $ok) = @_ });
  $promise = $self->del_p($key [key ...]);

Delete a key.

See L<https://redis.io/commands/del> for more information.

=head2 discard

See L</discard_p>.

=head2 discard_p

  $ok      = $self->discard;
  $self    = $self->discard(sub { my ($self, $err, $ok) = @_ });
  $promise = $self->discard_p;

Discard all commands issued after MULTI.

See L<https://redis.io/commands/discard> for more information.

=head2 dump

  $ok      = $self->dump($key);
  $self    = $self->dump($key, sub { my ($self, $err, $ok) = @_ });
  $promise = $self->dump_p($key);

Return a serialized version of the value stored at the specified key.

See L<https://redis.io/commands/dump> for more information.

=head2 echo

  $res     = $self->echo($message);
  $self    = $self->echo($message, sub { my ($self, $err, $res) = @_ });
  $promise = $self->echo_p($message);

Echo the given string.

See L<https://redis.io/commands/echo> for more information.

=head2 eval

  $res     = $self->eval($script, $numkeys, $key [key ...], $arg [arg ...]);
  $self    = $self->eval($script, $numkeys, $key [key ...], $arg [arg ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->eval_p($script, $numkeys, $key [key ...], $arg [arg ...]);

Execute a Lua script server side.

See L<https://redis.io/commands/eval> for more information.

=head2 evalsha

  $res     = $self->evalsha($sha1, $numkeys, $key [key ...], $arg [arg ...]);
  $self    = $self->evalsha($sha1, $numkeys, $key [key ...], $arg [arg ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->evalsha_p($sha1, $numkeys, $key [key ...], $arg [arg ...]);

Execute a Lua script server side.

See L<https://redis.io/commands/evalsha> for more information.

=head2 exec

See L</exec_p>.

=head2 exec_p

  $array_ref = $self->exec;
  $self      = $self->exec(sub { my ($self, $err, $array_ref) = @_ });
  $promise   = $self->exec_p;

Execute all commands issued after L</multi>.

See L<https://redis.io/commands/exec> for more information.

=head2 exists

  $int     = $self->exists($key [key ...]);
  $self    = $self->exists($key [key ...], sub { my ($self, $err, $int) = @_ });
  $promise = $self->exists_p($key [key ...]);

Determine if a key exists.

See L<https://redis.io/commands/exists> for more information.

=head2 expire

  $int     = $self->expire($key, $seconds);
  $self    = $self->expire($key, $seconds, sub { my ($self, $err, $int) = @_ });
  $promise = $self->expire_p($key, $seconds);

Set a key's time to live in seconds.

See L<https://redis.io/commands/expire> for more information.

=head2 expireat

  $int     = $self->expireat($key, $timestamp);
  $self    = $self->expireat($key, $timestamp, sub { my ($self, $err, $int) = @_ });
  $promise = $self->expireat_p($key, $timestamp);

Set the expiration for a key as a UNIX timestamp.

See L<https://redis.io/commands/expireat> for more information.

=head2 flushall

  $str     = $self->flushall([ASYNC]);
  $self    = $self->flushall([ASYNC], sub { my ($self, $err, $str) = @_ });
  $promise = $self->flushall_p([ASYNC]);

Remove all keys from all databases.

See L<https://redis.io/commands/flushall> for more information.

=head2 flushdb

  $str     = $self->flushdb([ASYNC]);
  $self    = $self->flushdb([ASYNC], sub { my ($self, $err, $str) = @_ });
  $promise = $self->flushdb_p([ASYNC]);

Remove all keys from the current database.

See L<https://redis.io/commands/flushdb> for more information.

=head2 geoadd

  $res     = $self->geoadd($key, $longitude latitude member [longitude latitude member ...]);
  $self    = $self->geoadd($key, $longitude latitude member [longitude latitude member ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->geoadd_p($key, $longitude latitude member [longitude latitude member ...]);

Add one or more geospatial items in the geospatial index represented using a sorted set.

See L<https://redis.io/commands/geoadd> for more information.

=head2 geodist

  $res     = $self->geodist($key, $member1, $member2, [unit]);
  $self    = $self->geodist($key, $member1, $member2, [unit], sub { my ($self, $err, $res) = @_ });
  $promise = $self->geodist_p($key, $member1, $member2, [unit]);

Returns the distance between two members of a geospatial index.

See L<https://redis.io/commands/geodist> for more information.

=head2 geohash

  $res     = $self->geohash($key, $member [member ...]);
  $self    = $self->geohash($key, $member [member ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->geohash_p($key, $member [member ...]);

Returns members of a geospatial index as standard geohash strings.

See L<https://redis.io/commands/geohash> for more information.

=head2 geopos

  $array_ref = $self->geopos($key, $member [member ...]);
  $self      = $self->geopos($key, $member [member ...], sub { my ($self, $err, $array_ref) = @_ });
  $promise   = $self->geopos_p($key, $member [member ...]);

Returns longitude and latitude of members of a geospatial index:

  [{lat => $num, lng => $num}, ...]

See L<https://redis.io/commands/geopos> for more information.

=head2 georadius

  $res     = $self->georadius($key, $longitude, $latitude, $radius, $m|km|ft|mi, [WITHCOORD],[WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key]);
  $self    = $self->georadius($key, $longitude, $latitude, $radius, $m|km|ft|mi, [WITHCOORD],[WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key], sub { my ($self, $err, $res) = @_ });
  $promise = $self->georadius_p($key, $longitude, $latitude, $radius, $m|km|ft|mi, [WITHCOORD], [WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key]);

Query a sorted set representing a geospatial index to fetch members matching a given maximum distance from a point.

See L<https://redis.io/commands/georadius> for more information.

=head2 georadiusbymember

  $res     = $self->georadiusbymember($key, $member, $radius, $m|km|ft|mi, [WITHCOORD], [WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key]);
  $self    = $self->georadiusbymember($key, $member, $radius, $m|km|ft|mi, [WITHCOORD], [WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key], sub { my ($self, $err, $res) = @_ });
  $promise = $self->georadiusbymember_p($key, $member, $radius, $m|km|ft|mi, [WITHCOORD], [WITHDIST], [WITHHASH], [COUNT count], [ASC|DESC], [STORE key], [STOREDIST key]);

Query a sorted set representing a geospatial index to fetch members matching a given maximum distance from a member.

See L<https://redis.io/commands/georadiusbymember> for more information.

=head2 get

  $res     = $self->get($key);
  $self    = $self->get($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->get_p($key);

Get the value of a key.

See L<https://redis.io/commands/get> for more information.

=head2 getbit

  $res     = $self->getbit($key, $offset);
  $self    = $self->getbit($key, $offset, sub { my ($self, $err, $res) = @_ });
  $promise = $self->getbit_p($key, $offset);

Returns the bit value at offset in the string value stored at key.

See L<https://redis.io/commands/getbit> for more information.

=head2 getrange

  $res     = $self->getrange($key, $start, $end);
  $self    = $self->getrange($key, $start, $end, sub { my ($self, $err, $res) = @_ });
  $promise = $self->getrange_p($key, $start, $end);

Get a substring of the string stored at a key.

See L<https://redis.io/commands/getrange> for more information.

=head2 getset

  $res     = $self->getset($key, $value);
  $self    = $self->getset($key, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->getset_p($key, $value);

Set the string value of a key and return its old value.

See L<https://redis.io/commands/getset> for more information.

=head2 hdel

  $res     = $self->hdel($key, $field [field ...]);
  $self    = $self->hdel($key, $field [field ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->hdel_p($key, $field [field ...]);

Delete one or more hash fields.

See L<https://redis.io/commands/hdel> for more information.

=head2 hexists

  $res     = $self->hexists($key, $field);
  $self    = $self->hexists($key, $field, sub { my ($self, $err, $res) = @_ });
  $promise = $self->hexists_p($key, $field);

Determine if a hash field exists.

See L<https://redis.io/commands/hexists> for more information.

=head2 hget

  $res     = $self->hget($key, $field);
  $self    = $self->hget($key, $field, sub { my ($self, $err, $res) = @_ });
  $promise = $self->hget_p($key, $field);

Get the value of a hash field.

See L<https://redis.io/commands/hget> for more information.

=head2 hgetall

  $res     = $self->hgetall($key);
  $self    = $self->hgetall($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->hgetall_p($key);

Get all the fields and values in a hash.

See L<https://redis.io/commands/hgetall> for more information.

=head2 hincrby

  $res     = $self->hincrby($key, $field, $increment);
  $self    = $self->hincrby($key, $field, $increment, sub { my ($self, $err, $res) = @_ });
  $promise = $self->hincrby_p($key, $field, $increment);

Increment the integer value of a hash field by the given number.

See L<https://redis.io/commands/hincrby> for more information.

=head2 hincrbyfloat

  $res     = $self->hincrbyfloat($key, $field, $increment);
  $self    = $self->hincrbyfloat($key, $field, $increment, sub { my ($self, $err, $res) = @_ });
  $promise = $self->hincrbyfloat_p($key, $field, $increment);

Increment the float value of a hash field by the given amount.

See L<https://redis.io/commands/hincrbyfloat> for more information.

=head2 hkeys

  $res     = $self->hkeys($key);
  $self    = $self->hkeys($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->hkeys_p($key);

Get all the fields in a hash.

See L<https://redis.io/commands/hkeys> for more information.

=head2 hlen

  $res     = $self->hlen($key);
  $self    = $self->hlen($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->hlen_p($key);

Get the number of fields in a hash.

See L<https://redis.io/commands/hlen> for more information.

=head2 hmget

  $res     = $self->hmget($key, $field [field ...]);
  $self    = $self->hmget($key, $field [field ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->hmget_p($key, $field [field ...]);

Get the values of all the given hash fields.

See L<https://redis.io/commands/hmget> for more information.

=head2 hmset

  $res     = $self->hmset($key, $field => $value [field value ...]);
  $self    = $self->hmset($key, $field => $value [field value ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->hmset_p($key, $field => $value [field value ...]);

Set multiple hash fields to multiple values.

See L<https://redis.io/commands/hmset> for more information.

=head2 hset

  $res     = $self->hset($key, $field, $value);
  $self    = $self->hset($key, $field, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->hset_p($key, $field, $value);

Set the string value of a hash field.

See L<https://redis.io/commands/hset> for more information.

=head2 hsetnx

  $res     = $self->hsetnx($key, $field, $value);
  $self    = $self->hsetnx($key, $field, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->hsetnx_p($key, $field, $value);

Set the value of a hash field, only if the field does not exist.

See L<https://redis.io/commands/hsetnx> for more information.

=head2 hstrlen

  $res     = $self->hstrlen($key, $field);
  $self    = $self->hstrlen($key, $field, sub { my ($self, $err, $res) = @_ });
  $promise = $self->hstrlen_p($key, $field);

Get the length of the value of a hash field.

See L<https://redis.io/commands/hstrlen> for more information.

=head2 hvals

  $res     = $self->hvals($key);
  $self    = $self->hvals($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->hvals_p($key);

Get all the values in a hash.

See L<https://redis.io/commands/hvals> for more information.

=head2 info

  $res     = $self->info($section);
  $self    = $self->info($section, sub { my ($self, $err, $res) = @_ });
  $promise = $self->info_p($section);

Get information and statistics about the server. See also L</info_structured>.

See L<https://redis.io/commands/info> for more information.

=head2 info_structured

Same as L</info>, but the result is a hash-ref where the keys are the different
sections, with key/values in a sub hash. Will only be key/values if <$section>
is specified.

=head2 incr

  $res     = $self->incr($key);
  $self    = $self->incr($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->incr_p($key);

Increment the integer value of a key by one.

See L<https://redis.io/commands/incr> for more information.

=head2 incrby

  $res     = $self->incrby($key, $increment);
  $self    = $self->incrby($key, $increment, sub { my ($self, $err, $res) = @_ });
  $promise = $self->incrby_p($key, $increment);

Increment the integer value of a key by the given amount.

See L<https://redis.io/commands/incrby> for more information.

=head2 incrbyfloat

  $res     = $self->incrbyfloat($key, $increment);
  $self    = $self->incrbyfloat($key, $increment, sub { my ($self, $err, $res) = @_ });
  $promise = $self->incrbyfloat_p($key, $increment);

Increment the float value of a key by the given amount.

See L<https://redis.io/commands/incrbyfloat> for more information.

=head2 keys

  $res     = $self->keys($pattern);
  $self    = $self->keys($pattern, sub { my ($self, $err, $res) = @_ });
  $promise = $self->keys_p($pattern);

Find all keys matching the given pattern.

See L<https://redis.io/commands/keys> for more information.

=head2 lastsave

  $res     = $self->lastsave;
  $self    = $self->lastsave(sub { my ($self, $err, $res) = @_ });
  $promise = $self->lastsave_p;

Get the UNIX time stamp of the last successful save to disk.

See L<https://redis.io/commands/lastsave> for more information.

=head2 lindex

  $res     = $self->lindex($key, $index);
  $self    = $self->lindex($key, $index, sub { my ($self, $err, $res) = @_ });
  $promise = $self->lindex_p($key, $index);

Get an element from a list by its index.

See L<https://redis.io/commands/lindex> for more information.

=head2 linsert

  $res     = $self->linsert($key, $BEFORE|AFTER, $pivot, $value);
  $self    = $self->linsert($key, $BEFORE|AFTER, $pivot, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->linsert_p($key, $BEFORE|AFTER, $pivot, $value);

Insert an element before or after another element in a list.

See L<https://redis.io/commands/linsert> for more information.

=head2 llen

  $res     = $self->llen($key);
  $self    = $self->llen($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->llen_p($key);

Get the length of a list.

See L<https://redis.io/commands/llen> for more information.

=head2 lpop

  $res     = $self->lpop($key);
  $self    = $self->lpop($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->lpop_p($key);

Remove and get the first element in a list.

See L<https://redis.io/commands/lpop> for more information.

=head2 lpush

  $res     = $self->lpush($key, $value [value ...]);
  $self    = $self->lpush($key, $value [value ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->lpush_p($key, $value [value ...]);

Prepend one or multiple values to a list.

See L<https://redis.io/commands/lpush> for more information.

=head2 lpushx

  $res     = $self->lpushx($key, $value);
  $self    = $self->lpushx($key, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->lpushx_p($key, $value);

Prepend a value to a list, only if the list exists.

See L<https://redis.io/commands/lpushx> for more information.

=head2 lrange

  $res     = $self->lrange($key, $start, $stop);
  $self    = $self->lrange($key, $start, $stop, sub { my ($self, $err, $res) = @_ });
  $promise = $self->lrange_p($key, $start, $stop);

Get a range of elements from a list.

See L<https://redis.io/commands/lrange> for more information.

=head2 lrem

  $res     = $self->lrem($key, $count, $value);
  $self    = $self->lrem($key, $count, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->lrem_p($key, $count, $value);

Remove elements from a list.

See L<https://redis.io/commands/lrem> for more information.

=head2 lset

  $res     = $self->lset($key, $index, $value);
  $self    = $self->lset($key, $index, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->lset_p($key, $index, $value);

Set the value of an element in a list by its index.

See L<https://redis.io/commands/lset> for more information.

=head2 ltrim

  $res     = $self->ltrim($key, $start, $stop);
  $self    = $self->ltrim($key, $start, $stop, sub { my ($self, $err, $res) = @_ });
  $promise = $self->ltrim_p($key, $start, $stop);

Trim a list to the specified range.

See L<https://redis.io/commands/ltrim> for more information.

=head2 mget

  $res     = $self->mget($key [key ...]);
  $self    = $self->mget($key [key ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->mget_p($key [key ...]);

Get the values of all the given keys.

See L<https://redis.io/commands/mget> for more information.

=head2 move

  $res     = $self->move($key, $db);
  $self    = $self->move($key, $db, sub { my ($self, $err, $res) = @_ });
  $promise = $self->move_p($key, $db);

Move a key to another database.

See L<https://redis.io/commands/move> for more information.

=head2 mset

  $res     = $self->mset($key value [key value ...]);
  $self    = $self->mset($key value [key value ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->mset_p($key value [key value ...]);

Set multiple keys to multiple values.

See L<https://redis.io/commands/mset> for more information.

=head2 msetnx

  $res     = $self->msetnx($key value [key value ...]);
  $self    = $self->msetnx($key value [key value ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->msetnx_p($key value [key value ...]);

Set multiple keys to multiple values, only if none of the keys exist.

See L<https://redis.io/commands/msetnx> for more information.

=head2 multi

See L</multi_p>.

=head2 multi_p

  $res     = $self->multi;
  $self    = $self->multi(sub { my ($self, $err, $res) = @_ });
  $promise = $self->multi_p;

Mark the start of a transaction block. Commands issued after L</multi> will
automatically be discarded if C<$self> goes out of scope. Need to call
L</exec> to commit the queued commands to Redis.

See L<https://redis.io/commands/multi> for more information.

=head2 object

  $res     = $self->object($subcommand, [arguments [arguments ...]]);
  $self    = $self->object($subcommand, [arguments [arguments ...]], sub { my ($self, $err, $res) =@_ });
  $promise = $self->object_p($subcommand, [arguments [arguments ...]]);

Inspect the internals of Redis objects.

See L<https://redis.io/commands/object> for more information.

=head2 persist

  $res     = $self->persist($key);
  $self    = $self->persist($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->persist_p($key);

Remove the expiration from a key.

See L<https://redis.io/commands/persist> for more information.

=head2 pexpire

  $res     = $self->pexpire($key, $milliseconds);
  $self    = $self->pexpire($key, $milliseconds, sub { my ($self, $err, $res) = @_ });
  $promise = $self->pexpire_p($key, $milliseconds);

Set a key's time to live in milliseconds.

See L<https://redis.io/commands/pexpire> for more information.

=head2 pexpireat

  $res     = $self->pexpireat($key, $milliseconds-timestamp);
  $self    = $self->pexpireat($key, $milliseconds-timestamp, sub { my ($self, $err, $res) = @_ });
  $promise = $self->pexpireat_p($key, $milliseconds-timestamp);

Set the expiration for a key as a UNIX timestamp specified in milliseconds.

See L<https://redis.io/commands/pexpireat> for more information.

=head2 pfadd

  $res     = $self->pfadd($key, $element [element ...]);
  $self    = $self->pfadd($key, $element [element ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->pfadd_p($key, $element [element ...]);

Adds the specified elements to the specified HyperLogLog.

See L<https://redis.io/commands/pfadd> for more information.

=head2 pfcount

  $res     = $self->pfcount($key [key ...]);
  $self    = $self->pfcount($key [key ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->pfcount_p($key [key ...]);

Return the approximated cardinality of the set(s) observed by the HyperLogLog at key(s).

See L<https://redis.io/commands/pfcount> for more information.

=head2 pfmerge

  $res     = $self->pfmerge($destkey, $sourcekey [sourcekey ...]);
  $self    = $self->pfmerge($destkey, $sourcekey [sourcekey ...], sub { my ($self, $err, $res) = @_});
  $promise = $self->pfmerge_p($destkey, $sourcekey [sourcekey ...]);

Merge N different HyperLogLogs into a single one.

See L<https://redis.io/commands/pfmerge> for more information.

=head2 ping

  $res     = $self->ping([message]);
  $self    = $self->ping([message], sub { my ($self, $err, $res) = @_ });
  $promise = $self->ping_p([message]);

Ping the server.

See L<https://redis.io/commands/ping> for more information.

=head2 psetex

  $res     = $self->psetex($key, $milliseconds, $value);
  $self    = $self->psetex($key, $milliseconds, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->psetex_p($key, $milliseconds, $value);

Set the value and expiration in milliseconds of a key.

See L<https://redis.io/commands/psetex> for more information.

=head2 pttl

  $res     = $self->pttl($key);
  $self    = $self->pttl($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->pttl_p($key);

Get the time to live for a key in milliseconds.

See L<https://redis.io/commands/pttl> for more information.

=head2 publish

  $res     = $self->publish($channel, $message);
  $self    = $self->publish($channel, $message, sub { my ($self, $err, $res) = @_ });
  $promise = $self->publish_p($channel, $message);

Post a message to a channel.

See L<https://redis.io/commands/publish> for more information.

=head2 randomkey

  $res     = $self->randomkey;
  $self    = $self->randomkey(sub { my ($self, $err, $res) = @_ });
  $promise = $self->randomkey_p;

Return a random key from the keyspace.

See L<https://redis.io/commands/randomkey> for more information.

=head2 readonly

  $res     = $self->readonly();
  $self    = $self->readonly(, sub { my ($self, $res) = @_ });
  $promise = $self->readonly_p();

Enables read queries for a connection to a cluster slave node.

See L<https://redis.io/commands/readonly> for more information.

=head2 readwrite

  $res     = $self->readwrite();
  $self    = $self->readwrite(, sub { my ($self, $res) = @_ });
  $promise = $self->readwrite_p();

Disables read queries for a connection to a cluster slave node.

See L<https://redis.io/commands/readwrite> for more information.

=head2 rename

  $res     = $self->rename($key, $newkey);
  $self    = $self->rename($key, $newkey, sub { my ($self, $err, $res) = @_ });
  $promise = $self->rename_p($key, $newkey);

Rename a key.

See L<https://redis.io/commands/rename> for more information.

=head2 renamenx

  $res     = $self->renamenx($key, $newkey);
  $self    = $self->renamenx($key, $newkey, sub { my ($self, $err, $res) = @_ });
  $promise = $self->renamenx_p($key, $newkey);

Rename a key, only if the new key does not exist.

See L<https://redis.io/commands/renamenx> for more information.

=head2 role

  $res     = $self->role;
  $self    = $self->role(sub { my ($self, $err, $res) = @_ });
  $promise = $self->role_p;

Return the role of the instance in the context of replication.

See L<https://redis.io/commands/role> for more information.

=head2 rpop

  $res     = $self->rpop($key);
  $self    = $self->rpop($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->rpop_p($key);

Remove and get the last element in a list.

See L<https://redis.io/commands/rpop> for more information.

=head2 rpoplpush

  $res     = $self->rpoplpush($source, $destination);
  $self    = $self->rpoplpush($source, $destination, sub { my ($self, $err, $res) = @_ });
  $promise = $self->rpoplpush_p($source, $destination);

Remove the last element in a list, prepend it to another list and return it.

See L<https://redis.io/commands/rpoplpush> for more information.

=head2 rpush

  $res     = $self->rpush($key, $value [value ...]);
  $self    = $self->rpush($key, $value [value ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->rpush_p($key, $value [value ...]);

Append one or multiple values to a list.

See L<https://redis.io/commands/rpush> for more information.

=head2 rpushx

  $res     = $self->rpushx($key, $value);
  $self    = $self->rpushx($key, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->rpushx_p($key, $value);

Append a value to a list, only if the list exists.

See L<https://redis.io/commands/rpushx> for more information.

=head2 restore

  $res     = $self->restore($key, $ttl, $serialized-value, [REPLACE]);
  $self    = $self->restore($key, $ttl, $serialized-value, [REPLACE], sub { my ($self, $err, $res) = @_ });
  $promise = $self->restore_p($key, $ttl, $serialized-value, [REPLACE]);

Create a key using the provided serialized value, previously obtained using DUMP.

See L<https://redis.io/commands/restore> for more information.

=head2 sadd

  $res     = $self->sadd($key, $member [member ...]);
  $self    = $self->sadd($key, $member [member ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->sadd_p($key, $member [member ...]);

Add one or more members to a set.

See L<https://redis.io/commands/sadd> for more information.

=head2 save

  $res     = $self->save;
  $self    = $self->save(sub { my ($self, $err, $res) = @_ });
  $promise = $self->save_p;

Synchronously save the dataset to disk.

See L<https://redis.io/commands/save> for more information.

=head2 scard

  $res     = $self->scard($key);
  $self    = $self->scard($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->scard_p($key);

Get the number of members in a set.

See L<https://redis.io/commands/scard> for more information.

=head2 script

  $res     = $self->script($sub_command, @args);
  $self    = $self->script($sub_command, @args, sub { my ($self, $err, $res) = @_ });
  $promise = $self->script_p($sub_command, @args);

Execute a script command.

See L<https://redis.io/commands/script-debug>,
L<https://redis.io/commands/script-exists>,
L<https://redis.io/commands/script-flush>,
L<https://redis.io/commands/script-kill> or
L<https://redis.io/commands/script-load> for more information.

=head2 sdiff

  $res     = $self->sdiff($key [key ...]);
  $self    = $self->sdiff($key [key ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->sdiff_p($key [key ...]);

Subtract multiple sets.

See L<https://redis.io/commands/sdiff> for more information.

=head2 sdiffstore

  $res     = $self->sdiffstore($destination, $key [key ...]);
  $self    = $self->sdiffstore($destination, $key [key ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->sdiffstore_p($destination, $key [key ...]);

Subtract multiple sets and store the resulting set in a key.

See L<https://redis.io/commands/sdiffstore> for more information.

=head2 set

  $res     = $self->set($key, $value, [expiration EX seconds|PX milliseconds], [NX|XX]);
  $self    = $self->set($key, $value, [expiration EX seconds|PX milliseconds], [NX|XX], sub {my ($self, $err, $res) = @_ });
  $promise = $self->set_p($key, $value, [expiration EX seconds|PX milliseconds], [NX|XX]);

Set the string value of a key.

See L<https://redis.io/commands/set> for more information.

=head2 setbit

  $res     = $self->setbit($key, $offset, $value);
  $self    = $self->setbit($key, $offset, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->setbit_p($key, $offset, $value);

Sets or clears the bit at offset in the string value stored at key.

See L<https://redis.io/commands/setbit> for more information.

=head2 setex

  $res     = $self->setex($key, $seconds, $value);
  $self    = $self->setex($key, $seconds, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->setex_p($key, $seconds, $value);

Set the value and expiration of a key.

See L<https://redis.io/commands/setex> for more information.

=head2 setnx

  $res     = $self->setnx($key, $value);
  $self    = $self->setnx($key, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->setnx_p($key, $value);

Set the value of a key, only if the key does not exist.

See L<https://redis.io/commands/setnx> for more information.

=head2 setrange

  $res     = $self->setrange($key, $offset, $value);
  $self    = $self->setrange($key, $offset, $value, sub { my ($self, $err, $res) = @_ });
  $promise = $self->setrange_p($key, $offset, $value);

Overwrite part of a string at key starting at the specified offset.

See L<https://redis.io/commands/setrange> for more information.

=head2 sinter

  $res     = $self->sinter($key [key ...]);
  $self    = $self->sinter($key [key ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->sinter_p($key [key ...]);

Intersect multiple sets.

See L<https://redis.io/commands/sinter> for more information.

=head2 sinterstore

  $res     = $self->sinterstore($destination, $key [key ...]);
  $self    = $self->sinterstore($destination, $key [key ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->sinterstore_p($destination, $key [key ...]);

Intersect multiple sets and store the resulting set in a key.

See L<https://redis.io/commands/sinterstore> for more information.

=head2 sismember

  $res     = $self->sismember($key, $member);
  $self    = $self->sismember($key, $member, sub { my ($self, $err, $res) = @_ });
  $promise = $self->sismember_p($key, $member);

Determine if a given value is a member of a set.

See L<https://redis.io/commands/sismember> for more information.

=head2 slaveof

  $res     = $self->slaveof($host, $port);
  $self    = $self->slaveof($host, $port, sub { my ($self, $err, $res) = @_ });
  $promise = $self->slaveof_p($host, $port);

Make the server a slave of another instance, or promote it as master.

See L<https://redis.io/commands/slaveof> for more information.

=head2 slowlog

  $res     = $self->slowlog($subcommand, [argument]);
  $self    = $self->slowlog($subcommand, [argument], sub { my ($self, $err, $res) = @_ });
  $promise = $self->slowlog_p($subcommand, [argument]);

Manages the Redis slow queries log.

See L<https://redis.io/commands/slowlog> for more information.

=head2 smembers

  $res     = $self->smembers($key);
  $self    = $self->smembers($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->smembers_p($key);

Get all the members in a set.

See L<https://redis.io/commands/smembers> for more information.

=head2 smove

  $res     = $self->smove($source, $destination, $member);
  $self    = $self->smove($source, $destination, $member, sub { my ($self, $err, $res) = @_ });
  $promise = $self->smove_p($source, $destination, $member);

Move a member from one set to another.

See L<https://redis.io/commands/smove> for more information.

=head2 sort

  $res     = $self->sort($key, [BY pattern], [LIMIT offset count], [GET pattern [GET pattern ...]], [ASC|DESC], [ALPHA], [STORE destination]);
  $self    = $self->sort($key, [BY pattern], [LIMIT offset count], [GET pattern [GET pattern ...]], [ASC|DESC], [ALPHA], [STORE destination], sub { my ($self, $err, $res) = @_ });
  $promise = $self->sort_p($key, [BY pattern], [LIMIT offset count], [GET pattern [GET pattern ...]], [ASC|DESC], [ALPHA], [STORE destination]);

Sort the elements in a list, set or sorted set.

See L<https://redis.io/commands/sort> for more information.

=head2 spop

  $res     = $self->spop($key, [count]);
  $self    = $self->spop($key, [count], sub { my ($self, $err, $res) = @_ });
  $promise = $self->spop_p($key, [count]);

Remove and return one or multiple random members from a set.

See L<https://redis.io/commands/spop> for more information.

=head2 srandmember

  $res     = $self->srandmember($key, [count]);
  $self    = $self->srandmember($key, [count], sub { my ($self, $err, $res) = @_ });
  $promise = $self->srandmember_p($key, [count]);

Get one or multiple random members from a set.

See L<https://redis.io/commands/srandmember> for more information.

=head2 srem

  $res     = $self->srem($key, $member [member ...]);
  $self    = $self->srem($key, $member [member ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->srem_p($key, $member [member ...]);

Remove one or more members from a set.

See L<https://redis.io/commands/srem> for more information.

=head2 strlen

  $res     = $self->strlen($key);
  $self    = $self->strlen($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->strlen_p($key);

Get the length of the value stored in a key.

See L<https://redis.io/commands/strlen> for more information.

=head2 sunion

  $res     = $self->sunion($key [key ...]);
  $self    = $self->sunion($key [key ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->sunion_p($key [key ...]);

Add multiple sets.

See L<https://redis.io/commands/sunion> for more information.

=head2 sunionstore

  $res     = $self->sunionstore($destination, $key [key ...]);
  $self    = $self->sunionstore($destination, $key [key ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->sunionstore_p($destination, $key [key ...]);

Add multiple sets and store the resulting set in a key.

See L<https://redis.io/commands/sunionstore> for more information.

=head2 time

  $res     = $self->time;
  $self    = $self->time(sub { my ($self, $err, $res) = @_ });
  $promise = $self->time_p;

Return the current server time.

See L<https://redis.io/commands/time> for more information.

=head2 touch

  $res     = $self->touch($key [key ...]);
  $self    = $self->touch($key [key ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->touch_p($key [key ...]);

Alters the last access time of a key(s). Returns the number of existing keys specified.

See L<https://redis.io/commands/touch> for more information.

=head2 ttl

  $res     = $self->ttl($key);
  $self    = $self->ttl($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->ttl_p($key);

Get the time to live for a key.

See L<https://redis.io/commands/ttl> for more information.

=head2 type

  $res     = $self->type($key);
  $self    = $self->type($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->type_p($key);

Determine the type stored at key.

See L<https://redis.io/commands/type> for more information.

=head2 unlink

  $res     = $self->unlink($key [key ...]);
  $self    = $self->unlink($key [key ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->unlink_p($key [key ...]);

Delete a key asynchronously in another thread. Otherwise it is just as DEL, but non blocking.

See L<https://redis.io/commands/unlink> for more information.

=head2 unwatch

  $res     = $self->unwatch;
  $self    = $self->unwatch(sub { my ($self, $err, $res) = @_ });
  $promise = $self->unwatch_p;

Forget about all watched keys.

See L<https://redis.io/commands/unwatch> for more information.

=head2 watch

  $res     = $self->watch($key [key ...]);
  $self    = $self->watch($key [key ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->watch_p($key [key ...]);

Watch the given keys to determine execution of the MULTI/EXEC block.

See L<https://redis.io/commands/watch> for more information.

=head2 xadd

  $res     = $self->xadd($key, $ID, $field string [field string ...]);
  $self    = $self->xadd($key, $ID, $field string [field string ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->xadd_p($key, $ID, $field string [field string ...]);

Appends a new entry to a stream.

See L<https://redis.io/commands/xadd> for more information.

=head2 xlen

  $res     = $self->xlen($key);
  $self    = $self->xlen($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->xlen_p($key);

Return the number of entires in a stream.

See L<https://redis.io/commands/xlen> for more information.

=head2 xpending

  $res     = $self->xpending($key, $group, [start end count], [consumer]);
  $self    = $self->xpending($key, $group, [start end count], [consumer], sub { my ($self, $err, $res) = @_ });
  $promise = $self->xpending_p($key, $group, [start end count], [consumer]);

Return information and entries from a stream consumer group pending entries list, that are messages fetched but never acknowledged.

See L<https://redis.io/commands/xpending> for more information.

=head2 xrange

  $res     = $self->xrange($key, $start, $end, [COUNT count]);
  $self    = $self->xrange($key, $start, $end, [COUNT count], sub { my ($self, $err, $res) = @_ });
  $promise = $self->xrange_p($key, $start, $end, [COUNT count]);

Return a range of elements in a stream, with IDs matching the specified IDs interval.

See L<https://redis.io/commands/xrange> for more information.

=head2 xread

  $res     = $self->xread([COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...]);
  $self    = $self->xread([COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->xread_p([COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...]);

Return never seen elements in multiple streams, with IDs greater than the ones reported by the caller for each stream. Can block.

See L<https://redis.io/commands/xread> for more information.

=head2 xreadgroup

  $res     = $self->xreadgroup($GROUP group consumer, [COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...]);
  $self    = $self->xreadgroup($GROUP group consumer, [COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->xreadgroup_p($GROUP group consumer, [COUNT count], [BLOCK milliseconds], $STREAMS, $key [key ...], $ID [ID ...]);

Return new entries from a stream using a consumer group, or access the history of the pending entries for a given consumer. Can block.

See L<https://redis.io/commands/xreadgroup> for more information.

=head2 xrevrange

  $res     = $self->xrevrange($key, $end, $start, [COUNT count]);
  $self    = $self->xrevrange($key, $end, $start, [COUNT count], sub { my ($self, $err, $res) = @_ });
  $promise = $self->xrevrange_p($key, $end, $start, [COUNT count]);

Return a range of elements in a stream, with IDs matching the specified IDs interval, in reverse order (from greater to smaller IDs) compared to XRANGE.

See L<https://redis.io/commands/xrevrange> for more information.

=head2 zadd

  $res     = $self->zadd($key, [NX|XX], [CH], [INCR], $score member [score member ...]);
  $self    = $self->zadd($key, [NX|XX], [CH], [INCR], $score member [score member ...], sub {my ($self, $err, $res) = @_ });
  $promise = $self->zadd_p($key, [NX|XX], [CH], [INCR], $score member [score member ...]);

Add one or more members to a sorted set, or update its score if it already exists.

See L<https://redis.io/commands/zadd> for more information.

=head2 zcard

  $res     = $self->zcard($key);
  $self    = $self->zcard($key, sub { my ($self, $err, $res) = @_ });
  $promise = $self->zcard_p($key);

Get the number of members in a sorted set.

See L<https://redis.io/commands/zcard> for more information.

=head2 zcount

  $res     = $self->zcount($key, $min, $max);
  $self    = $self->zcount($key, $min, $max, sub { my ($self, $err, $res) = @_ });
  $promise = $self->zcount_p($key, $min, $max);

Count the members in a sorted set with scores within the given values.

See L<https://redis.io/commands/zcount> for more information.

=head2 zincrby

  $res     = $self->zincrby($key, $increment, $member);
  $self    = $self->zincrby($key, $increment, $member, sub { my ($self, $err, $res) = @_ });
  $promise = $self->zincrby_p($key, $increment, $member);

Increment the score of a member in a sorted set.

See L<https://redis.io/commands/zincrby> for more information.

=head2 zinterstore

  $res     = $self->zinterstore($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX]);
  $self    = $self->zinterstore($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX], sub { my ($self, $err, $res) = @_ });
  $promise = $self->zinterstore_p($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX]);

Intersect multiple sorted sets and store the resulting sorted set in a new key.

See L<https://redis.io/commands/zinterstore> for more information.

=head2 zlexcount

  $res     = $self->zlexcount($key, $min, $max);
  $self    = $self->zlexcount($key, $min, $max, sub { my ($self, $err, $res) = @_ });
  $promise = $self->zlexcount_p($key, $min, $max);

Count the number of members in a sorted set between a given lexicographical range.

See L<https://redis.io/commands/zlexcount> for more information.

=head2 zpopmax

  $res     = $self->zpopmax($key, [count]);
  $self    = $self->zpopmax($key, [count], sub { my ($self, $err, $res) = @_ });
  $promise = $self->zpopmax_p($key, [count]);

Remove and return members with the highest scores in a sorted set.

See L<https://redis.io/commands/zpopmax> for more information.

=head2 zpopmin

  $res     = $self->zpopmin($key, [count]);
  $self    = $self->zpopmin($key, [count], sub { my ($self, $err, $res) = @_ });
  $promise = $self->zpopmin_p($key, [count]);

Remove and return members with the lowest scores in a sorted set.

See L<https://redis.io/commands/zpopmin> for more information.

=head2 zrange

  $res     = $self->zrange($key, $start, $stop, [WITHSCORES]);
  $self    = $self->zrange($key, $start, $stop, [WITHSCORES], sub { my ($self, $err, $res) = @_ });
  $promise = $self->zrange_p($key, $start, $stop, [WITHSCORES]);

Return a range of members in a sorted set, by index.

See L<https://redis.io/commands/zrange> for more information.

=head2 zrangebylex

  $res     = $self->zrangebylex($key, $min, $max, [LIMIT offset count]);
  $self    = $self->zrangebylex($key, $min, $max, [LIMIT offset count], sub { my ($self, $err, $res) = @_ });
  $promise = $self->zrangebylex_p($key, $min, $max, [LIMIT offset count]);

Return a range of members in a sorted set, by lexicographical range.

See L<https://redis.io/commands/zrangebylex> for more information.

=head2 zrangebyscore

  $res     = $self->zrangebyscore($key, $min, $max, [WITHSCORES], [LIMIT offset count]);
  $self    = $self->zrangebyscore($key, $min, $max, [WITHSCORES], [LIMIT offset count], sub {my ($self, $err, $res) = @_ });
  $promise = $self->zrangebyscore_p($key, $min, $max, [WITHSCORES], [LIMIT offset count]);

Return a range of members in a sorted set, by score.

See L<https://redis.io/commands/zrangebyscore> for more information.

=head2 zrank

  $res     = $self->zrank($key, $member);
  $self    = $self->zrank($key, $member, sub { my ($self, $err, $res) = @_ });
  $promise = $self->zrank_p($key, $member);

Determine the index of a member in a sorted set.

See L<https://redis.io/commands/zrank> for more information.

=head2 zrem

  $res     = $self->zrem($key, $member [member ...]);
  $self    = $self->zrem($key, $member [member ...], sub { my ($self, $err, $res) = @_ });
  $promise = $self->zrem_p($key, $member [member ...]);

Remove one or more members from a sorted set.

See L<https://redis.io/commands/zrem> for more information.

=head2 zremrangebylex

  $res     = $self->zremrangebylex($key, $min, $max);
  $self    = $self->zremrangebylex($key, $min, $max, sub { my ($self, $err, $res) = @_ });
  $promise = $self->zremrangebylex_p($key, $min, $max);

Remove all members in a sorted set between the given lexicographical range.

See L<https://redis.io/commands/zremrangebylex> for more information.

=head2 zremrangebyrank

  $res     = $self->zremrangebyrank($key, $start, $stop);
  $self    = $self->zremrangebyrank($key, $start, $stop, sub { my ($self, $err, $res) = @_ });
  $promise = $self->zremrangebyrank_p($key, $start, $stop);

Remove all members in a sorted set within the given indexes.

See L<https://redis.io/commands/zremrangebyrank> for more information.

=head2 zremrangebyscore

  $res     = $self->zremrangebyscore($key, $min, $max);
  $self    = $self->zremrangebyscore($key, $min, $max, sub { my ($self, $err, $res) = @_ });
  $promise = $self->zremrangebyscore_p($key, $min, $max);

Remove all members in a sorted set within the given scores.

See L<https://redis.io/commands/zremrangebyscore> for more information.

=head2 zrevrange

  $res     = $self->zrevrange($key, $start, $stop, [WITHSCORES]);
  $self    = $self->zrevrange($key, $start, $stop, [WITHSCORES], sub { my ($self, $err, $res) = @_ });
  $promise = $self->zrevrange_p($key, $start, $stop, [WITHSCORES]);

Return a range of members in a sorted set, by index, with scores ordered from high to low.

See L<https://redis.io/commands/zrevrange> for more information.

=head2 zrevrangebylex

  $res     = $self->zrevrangebylex($key, $max, $min, [LIMIT offset count]);
  $self    = $self->zrevrangebylex($key, $max, $min, [LIMIT offset count], sub { my ($self, $err, $res) = @_ });
  $promise = $self->zrevrangebylex_p($key, $max, $min, [LIMIT offset count]);

Return a range of members in a sorted set, by lexicographical range, ordered from higher to lower strings.

See L<https://redis.io/commands/zrevrangebylex> for more information.

=head2 zrevrangebyscore

  $res     = $self->zrevrangebyscore($key, $max, $min, [WITHSCORES], [LIMIT offset count]);
  $self    = $self->zrevrangebyscore($key, $max, $min, [WITHSCORES], [LIMIT offset count], sub { my ($self, $err, $res) = @_ });
  $promise = $self->zrevrangebyscore_p($key, $max, $min, [WITHSCORES], [LIMIT offset count]);

Return a range of members in a sorted set, by score, with scores ordered from high to low.

See L<https://redis.io/commands/zrevrangebyscore> for more information.

=head2 zrevrank

  $res     = $self->zrevrank($key, $member);
  $self    = $self->zrevrank($key, $member, sub { my ($self, $err, $res) = @_ });
  $promise = $self->zrevrank_p($key, $member);

Determine the index of a member in a sorted set, with scores ordered from high to low.

See L<https://redis.io/commands/zrevrank> for more information.

=head2 zscore

  $res     = $self->zscore($key, $member);
  $self    = $self->zscore($key, $member, sub { my ($self, $err, $res) = @_ });
  $promise = $self->zscore_p($key, $member);

Get the score associated with the given member in a sorted set.

See L<https://redis.io/commands/zscore> for more information.

=head2 zunionstore

  $res     = $self->zunionstore($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX]);
  $self    = $self->zunionstore($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX], sub { my ($self, $err, $res) = @_ });
  $promise = $self->zunionstore_p($destination, $numkeys, $key [key ...], [WEIGHTS weight [weight ...]], [AGGREGATE SUM|MIN|MAX]);

Add multiple sorted sets and store the resulting sorted set in a new key.

See L<https://redis.io/commands/zunionstore> for more information.

=head1 SEE ALSO

L<Mojo::Redis>.

=cut
