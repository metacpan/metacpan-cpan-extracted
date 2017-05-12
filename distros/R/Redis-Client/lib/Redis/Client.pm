package Redis::Client;
$Redis::Client::VERSION = '0.015';
use Moose;
use IO::Socket::INET ();
use Carp 'croak';
use utf8;
use namespace::sweep 0.003;

# ABSTRACT: Perl client for Redis 2.4 and up

has 'host'         => ( is => 'ro', isa => 'Str', default => 'localhost' );
has 'port'         => ( is => 'ro', isa => 'Int', default => 6379 );
has 'pass'         => ( is => 'ro', isa => 'Maybe[Str]', default => undef );

with 'Redis::Client::Role::URP';

BEGIN { 
    # maps Redis commands to arity; arrayref specifies a range
    my %COMMANDS = 
      ( # key commands
        DEL         => [ 1, undef ],
        EXISTS      => 1,
        EXPIRE      => 2,
        EXPIREAT    => 2,
        KEYS        => 1,
        MOVE        => 2,
        OBJECT      => [ 1, undef ],
        PERSIST     => 1,
        RANDOMKEY   => 0,
        RENAME      => 2,
        RENAMENX    => 2,
        SORT        => [ 1, undef ],
        TTL         => 1,
        TYPE        => 1,
        EVAL        => [ 3, undef ],
       
        # string commands
        APPEND      => 2,
        DECR        => 1,
        DECRBY      => 2, 
        GET         => 1,
        GETBIT      => 2,
        GETRANGE    => 3,
        GETSET      => 2,
        INCR        => 1,
        INCRBY      => 2,
        MGET        => [ 1, undef ],
        MSET        => [ 2, undef ],
        MSETNX      => [ 2, undef ],
        SET         => 2,
        SETBIT      => 3,
        SETEX       => 3,
        SETNX       => 2,
        SETRANGE    => 3,
        STRLEN      => 1,

        # list commands
        BLPOP       => [ 1, undef ],
        BRPOP       => [ 1, undef ],
        BRPOPLPUSH  => 3,
        LINDEX      => 2,
        LINSERT     => 4,
        LLEN        => 1,
        LPOP        => 1,
        LPUSH       => [ 2, undef ],
        LPUSHX      => 2,
        LRANGE      => 3,
        LREM        => 3,
        LSET        => 3,
        LTRIM       => 3,
        RPOP        => 1,
        RPOPLPUSH   => 2,
        RPUSH       => [ 2, undef ],
        RPUSHX      => 2,

        # hash commands
        HDEL        => [ 2, undef ],
        HEXISTS     => 2,
        HGET        => 2,
        HGETALL     => 1,
        HINCRBY     => 3,
        HINCRBYFLOAT    => 3,
        HKEYS       => 1,
        HLEN        => 1,
        HMGET       => [ 2, undef ],
        HMSET       => [ 3, undef ],
        HSET        => 3,
        HSETNX      => 3,
        HVALS       => 1,

        # set commands
        SADD        => [ 2, undef ],
        SCARD       => 1,
        SDIFF       => [ 1, undef ],
        SDIFFSTORE  => [ 2, undef ],
        SINTER      => [ 1, undef ],
        SINTERSTORE => [ 2, undef ],
        SISMEMBER   => 2,
        SMEMBERS    => 1,
        SMOVE       => 3,
        SPOP        => 1,
        SRANDMEMBER => 1,
        SREM        => [ 2, undef ],
        SUNION      => [ 1, undef ],
        SUNIONSTORE => [ 2, undef ],

        # zset commands
        ZADD        => [ 3, undef ],
        ZCARD       => 1,
        ZCOUNT      => 3,
        ZINCRBY     => 3,
        ZINTERSTORE => [ 3, undef ],
        ZRANGE      => [ 3, undef ],
        ZRANGEBYSCORE => 3,
        ZRANK       => 2,
        ZREM        => [ 2, undef ],
        ZREMRANGEBYRANK => 3,
        ZREMRANGEBYSCORE => [ 3, undef ],
        ZREVRANK    => 2,
        ZSCORE      => 2,
        ZUNIONSTORE => [ 3, undef ],

        # connection commands
        AUTH        => 1,
        ECHO        => 1,
        PING        => 0,
        QUIT        => 0,
        SELECT      => 1,

        # server commands
        BGREWRITEAOF => 0,
        BGSAVE      => 0,
        'CONFIG GET' => 1,
        'CONFIG SET' => 2,
        'CONFIG RESETSTAT' => 0,
        DBSIZE      => 0,
        'DEBUG OBJECT' => 1,
        'DEBUG SEGFAULT' => 0,
        FLUSHALL    => 0,
        FLUSHDB     => 0,
        INFO        => 0,
        LASTSAVE    => 0,
        SAVE        => 0,
        SHUTDOWN    => 0,
        SLAVEOF     => 2,
        SLOWLOG     => [ 1, 2 ],
        SYNC        => 0,
      );

    foreach my $cmd ( keys %COMMANDS ) { 
        my $meth = sub { 
            my $self = shift;
            my @args = @_;

            my $args_num = $COMMANDS{$cmd};

            my $msg = sprintf 'Redis %s command requires %s argument(s)', $cmd, do { 
                if ( ref $args_num ) { 
                      ( defined $args_num->[1] ? sprintf( 'between %s and %s', @$args_num ) 
                                               : sprintf( 'at least %s', $args_num->[0] )
                      );
                } else { 
                    $args_num;
                }
            };

            croak $msg if (     ref $args_num ) && ( @args < $args_num->[0] );
            croak $msg if (     ref $args_num ) && ( defined $args_num->[1] ) && ( @args > $args_num->[1] );
            croak $msg if ( not ref $args_num ) && ( @args != $args_num );

            return $self->send_command( $cmd, @args );
        };

        # some commands have spaces in their names. yeesh.
        my $meth_name = lc $cmd;
        $meth_name =~ s/\s/_/g;

        __PACKAGE__->meta->add_method( $meth_name => $meth );
    }
};


foreach my $func( 'lpush', 'rpush' ) { 
    around $func => sub { 
        my ( $orig, $self, @args ) = @_;

        my $rcmd = uc $func;
        croak 'Redis $rcmd requires 2 or more arguments'
          unless @args >= 2;

        $self->$orig( @args );
    };
}

# don't try to send commands on disconnected socket
after quit => sub { 
    my $self = shift;
    $self->_clear_sock;
};



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Redis::Client - Perl client for Redis 2.4 and up

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Redis::Client;

    my $client = Redis::Client->new( host => 'localhost', port => 6379 );

    # work with strings
    $client->set( some_key => 'myval' );
    my $str_val = $client->get( 'some_key' );
    print $str_val;        # myval

    # work with lists
    $client->lpush( some_list => 1, 2, 3 );
    my $list_elem = $client->lindex( some_list => 2 );
    print $list_elem;      # 3

    # work with hashes
    $client->hset( 'some_hash', foobar => 42 );
    my $hash_val = $client->hget( 'some_hash', 'foobar' );
    print $hash_val;      # 42

=head1 DESCRIPTION

Redis::Client is a Perl-native client for the Redis (L<http://redis.io>) key/value store.
Redis supports storage and retrieval of strings, ordered lists, hashes, sets, and ordered sets.

Redis::Client uses the new binary-safe Unified Request Protocol to implement all of its commands.
This requires that Redis::Client be able to get accurate byte-length counts of all strings passed
to it. Therefore, if you are working with character data, it MUST be encoded to a binary form
(e.g. UTF-8) before you send it to Redis; otherwise the string lengths may be counted 
incorrectly and the requests will fail. Redis guarantees round-trip safety for binary data.

This distribution includes classes for working with Redis data via C<tie> based objects
that map Redis items to native Perl data types. See the documentation for those modules for
usage:

=over

=item * L<Redis::Client::String>

=item * L<Redis::Client::List>

=item * L<Redis::Client::Hash>

=item * L<Redis::Client::Set>

=item * L<Redis::Client::Zset>

=back

=head1 INSTALLATION

Redis::Client can be installed the usual way via CPAN. In order to run the test suite, Redis::Client
needs to know about a Redis server that it can talk to. Make sure to set the following environment
variables prior to installing this distribution or running the test suite.

=over

=item * C<PERL_REDIS_TEST_SERVER> - the hostname of the Redis server (default localhost).

=item * C<PERL_REDIS_TEST_PORT> - the port number of the Redis server (default 6379).

=item * C<PERL_REDIS_TEST_PASSWORD> - (optional) the Redis server password (default C<undef>).

=back

All keys generated by the test suite will have the prefix C<perl_redis_test>. Unless something 
goes wrong, they'll all be deleted when each test is completed.

=head1 CLASS METHODS

=head2 new

Constructor. Returns a new C<Redis::Client> object for talking to a Redis server. Throws a fatal error
if a connection cannot be obtained.

=over

=item * C<host>

The hostname of the Redis server. Defaults to C<localhost>.

=item * C<port>

The port number of the Redis server. Defaults to C<6379>.

=back

Redis connection passwords are not currently supported.

    my $client = Redis::Client->new( host => 'foo.example.com', port => 1234 );

=head1 KEY METHODS

=head2 del

Redis L<DEL|http://redis.io/commands/del> command.

Deletes keys. Takes a list of key names. Returns the number of keys deleted.

    $client->del( 'foo', 'bar', 'baz' );

=head2 type

Redis L<TYPE|http://redis.io/commands/type> command.

Retrieves the type of a key. Takes the key name and returns one of C<string>, C<list>, 
C<hash>, C<set>, or C<zset>.

    my $type = $client->type( 'some_key' );

=head1 STRING METHODS

=head2 get

Redis L<GET|http://redis.io/commands/get> command.

Retrieves a string value associated with a key. Takes one key name. Returns C<undef> if the
key does not exist. If the key is associated with something other than a string,
a fatal error is thrown.

    print $client->get( 'mykey' );

=head2 append

Redis L<APPEND|http://redis.io/commands/append> command.

Appends a value to the end of a string. Takes the key name and a value to append.
Returns the new length of the string. If the key is not a string, a fatal error
is thrown.

    my $new_length = $client->append( mykey => 'foobar' );

=head2 decr

Redis L<DECR|http://redis.io/commands/decr> command.

Decrements a number stored in a string. Takes the key name and returns the decremented
value. If the key does not exist, zero is assumed and decremented to -1. If the key
is not a string, a fatal error is thrown.

    my $new_val = $client->decr( 'my_num' );

=head2 decrby

Redis L<DECRBY|http://redis.io/commands/decrby> command.

Decrements a number stored in a string by a certain amount. Takes the key name and
the amount by which to decrement. Returns the new value. If the key is not a string,
a fatal error is thrown.

    my $new_val = $client->decrby( 'my_num', 3 );

=head2 get

Redis L<GET|http://redis.io/commands/get> command.

Returns the value of a string. Takes the key name. If the key is not a string, a
fatal error is thrown.

    my $val = $client->get( 'my_key' );

=head2 getbit

Redis L<GETBIT|http://redis.io/commands/getbit> command.

Returns the value of one bit in a string. Takes the key name and the offset of
the bit. If the offset is beyond the length of the string, C<0> is returned.
If the key is not a string, a fatal error is thrown.

    my $bit = $client->getbit( 'my_key', 4 );    # fifth bit from left

=head2 getrange

Redis L<GETRANGE|http://redis.io/commands/getrange> command.

Returns a substring of a string, specified by a range. Takes the key name and
the start and end offset of the range. Negative numbers count from the end.
If the key is not a string, a fatal error is thrown.

    my $substr = $client->getrange( 'my_key', 3, 5 );
    my $substr = $client->getrange( 'my_key', -5, -1 );  # last five 

=head2 getset

Redis L<GETSET|http://redis.io/commands/getset> command.

Sets the value of a string and returns the old value atomically. Takes the
key name and the new value. If the key is not a string, a fatal error is
thrown. If the key does not exist, it is created and C<undef> is returned.

    my $old_val = $client->getset( my_key => 'new value' );

=head2 incr

Redis L<INCR|http://redis.io/commands/incr> command.

Increments a number stored in a string. Takes the key name and returns the incremented
value. If the key does not exist, zero is assumed and incremented to 1. If the key
is not a string, a fatal error is thrown.

    my $new_val = $client->incr( 'my_num' );

=head2 incrby

Redis L<INCRBY|http://redis.io/commands/incrby> command.

Increments a number stored in a string by a certain amount. Takes the key name and
the amount by which to increment. Returns the new value. If the key is not a string,
a fatal error is thrown.

    my $new_val = $client->incrby( 'my_num', 3 );

=head2 mget

Redis L<MGET|http://redis.io/commands/mget> command.

Gets the values of multiple strings. Takes the list of key names to get. If a
key does not exist or if it is not a string, C<undef> will be returned in its
place.

    my @vals = $client->mget( 'foo', 'bar', baz' );
    print $vals[2];    # value of baz

=head2 mset

Redis L<MSET|http://redis.io/commands/mset> command.

Sets the values of multiple strings. Takes a list of key/value pairs to set.
If a key does not exist, it will be created. If a key is not a string, it will
be silently converted to one. Therefore, use with caution.

    $client->mset( foo => 1, bar => 2, baz => 3 );

=head2 msetnx

Redis L<MSETNX|http://redis.io/commands/msetnx> command.

Atomically sets the values of multiple strings, only if I<none> of the keys yet exist.
Returns 1 on success, 0 otherwise. 

    my $it_worked = $client->msetnx( foo => 1, bar => 2, baz => 3 );

=head2 set

Redis L<SET|http://redis.io/commands/set> command.

Sets the value of a string. Takes the key name and a value. 

    $client->set( my_key => 'foobar' );

=head2 setbit

Redis L<SETBIT|http://redis.io/commands/setbit> command.

Sets the value of one bit in a string. Takes the key name, offset of the bit, and
new value. Returns the original value of the bit. If the key is not a string or
if the bit value is not 0 or 1, a fatal error is thrown.

    my $old_bit = $client->setbit( 'my_key', 3, 1 );

=head2 setex

Redis L<SETEX|http://redis.io/commands/setex> command.

Sets the value of a string and its expiration time in seconds. Takes the key name,
the expiration time, and the value. 

    $client->setex( 'my_key', 5, 'foo' );   # goes bye-bye in 5 secs.

=head2 setnx

Redis L<SETNX|http://redis.io/commands/setnx> command.

Sets the value of a string, only if it I<does not> yet exist. Takes the key name
and value. Returns 1 on success, 0 otherwise.

    my $key_was_set = $client->setnx( my_key => 'foobar' ); 

=head2 setrange

Redis L<SETRANGE|http://redis.io/commands/setrange> command.

Sets the value of a substring of a string. Takes the key name, the offset, and 
a replacement string. Returns the length of the modified string. If the key
is not a string, a fatal error is thrown.

    $client->set( my_key => "I'm a teapot." );
    my $new_length = $client->setrange( 'my_key', 6, 'foobar' ); # I'm a foobar.

=head2 strlen

Redis L<STRLEN|http://redis.io/commands/strlen> command.

Returns the length of a string. Takes the key name. If the key is not a string, 
a fatal error is thrown.

    my $length = $client->strlength( 'my_key' );

=head1 LIST METHODS

=head2 blpop

Redis L<BLPOP|http://redis.io/commands/blpop> command.

Blocking left list pop. Takes a list of keys to poll and a timeout in seconds. Returns
a two-element list containing the name of the list and the popped value on 
success, C<undef> otherwise. Returns immediately if a value is waiting on any 
of the specified lists, otherwise waits for a value to appear or the timeout
to expire. A timeout of zero waits forever. 

    my ( $list, $value ) = $client->blpop( 'list1', 'list2', 5 ); # wait 5 secs

See L<lpop> for the non-blocking version.

=head2 brpop

Redis L<BRPOP|http://redis.io/commands/brpop> command.

Blocking right list pop. Takes a list of keys to poll and a timeout in seconds. Returns
a two-element list containing the name of the list and the popped value on 
success, C<undef> otherwise. Returns immediately if a value is waiting on any
of the specified lists, otherwise waits for a value to appear or the timeout
to expire. A timeout of zero waits forever.

    my ( $list, $value ) = $client->brpop( 'list1', 'list2', 5 ); # wait 5 secs

See L<rpop> for the non-blocking version.

=head2 brpoplpush

Redis L<BRPOPLPUSH|http://redis.io/commands/brpoplpush> command.

Blocking atomic right list pop with left list push. Takes the source to pop, the 
destination list to push, and a timeout value. Returns the element being popped
from the source and pushed to the destination, or C<undef> if it times out. A 
timeout of zero waits forever.

    my $val = $client->brpoplpush( 'source_list', 'dest_list', 5 ); 

See L<rpoplpush> for the non-blocking version.

=head2 lindex

Redis L<LINDEX|http://redis.io/commands/lindex> command.

Retrieves the value stored at a particular index in a list. Takes the list name
and the numeric index. 

    my $val = $client->lindex( 'my_list', 42 );

=head2 lset

Redis L<LSET|http://redis.io/commands/lset> command.

Sets the value at a particular index in a list. Takes the list name, the numeric
index, and the new value.

    $client->lset( 'my_list', 42, 'yippee!' );

=head2 llen

Redis L<LLEN|http://redis.io/commands/llen> command.

Retrieves the number of items in a list. Takes the list name.

    my $length = $client->llen( 'my_list' );

=head2 ltrim

Redis L<LTRIM|http://redis.io/commands/ltrim> command.

Removes all elements of a list outside of the specified range. Takes the list 
name, start index, and stop index. All keys between the start and stop indices
(inclusive) will be preserved. The rest will be deleted. The list is shifted down
if the start index is not zero. The stop index C<-1> can be used to select everything
until the end of the list.

    # get rid of first two elements.
    $client->ltrim( 'my_list', 2, -1 );

=head2 rpush

Redis L<RPUSH|http://redis.io/commands/rpush> command.

Adds items to the end of a list, analogous to the Perl C<push> operator. Takes 
the list name and a list of items to add. Returns the length of the list when
done.

    my $new_length = $client->rpush( my_list => 42, 43, 'narf', 'poit' );

=head2 rpop

Redis L<RPOP|http://redis.io/commands/rpop> command.

Removes and returns the last element of a list, analogous to the Perl C<pop>
operator. 

    my $last = $client->rpop( 'my_list' );

=head2 lpush

Redis L<LPUSH|http://redis.io/commands/lpush> command.

Adds items to the beginning of a list, analogous to the Perl C<unshift> operator. 
Takes the list name and a list of items to add. Returns the length of the list 
when done.

    my $new_length = $client->lpush( my_list => 1, 2, 3 );

=head2 lpop

Redis L<LPOP|http://redis.io/commands/lpop> command.

Removes and returns the first element of a list, analogous to the Perl C<shift>
operator. 

    my $first = $client->lpop( 'my_list' );

=head1 HASH METHODS

=head2 hdel

Redis L<HDEL|http://redis.io/commands/hdel> command.

Deletes keys from a hash. Takes the name of a hash and a list of key names to delete. 
Returns the number of keys deleted. Returns zero if the hash does not exist, or if
none of the keys specified exist in the hash. 

    $client->hdel( 'myhash', 'foo', 'bar', 'baz' );

=head2 hexists

Redis L<HEXISTS|http://redis.io/commands/hexists> command.

Returns a true value if a key exists in a hash. Takes a hash name and the key name.

    blah() if $client->hexists( 'myhash', 'foo' );

=head2 hget

Redis L<HGET|http://redis.io/commands/hget> command.

Retrieves a value associated with a key in a hash. Takes the name of the hash
and the key within the hash. Returns C<undef> if the hash or the key within the
hash does not exist. (Use L</hexists> to determine if a key exists at all.)

    # sets the value for 'key' in the hash 'foo'
    $client->hset( 'foo', key => 42 );

    print $client->hget( 'foo', 'key' );   # 42

=head2 hgetall

Redis L<HGETALL|http://redis.io/commands/hgetall> command.

Retrieves all of the keys and values in a hash. Takes the name of the hash
and returns a list of key/value pairs. 

    my %hash = $client->hgetall( 'myhash' );

=head2 hkeys

Redis L<HKEYS|http://redis.io/commands/hkeys> command.

Retrieves a list of all the keys in a hash. Takes the name of the hash and
returns a list of keys.

    my @keys = $client->hkeys( 'myhash' );

=head2 hlen

Redis L<HLEN|http://redis.io/commands/hlen> command.

Retrieves the number of keys in a hash. Takes the name of the hash.

    my $size = $client->hlen( 'myhash' );

=head2 hmget

Redis L<HMGET|http://redis.io/commands/hmget> command.

Retrieves a list of values associated with the given keys in a hash. Takes
the name of the hash and a list of keys. If a given key does not exist, 
C<undef> will be returned in the corresponding location in the result list.

    my @values = $client->hmget( 'myhash', 'key1', 'key2', 'key3' );

=head2 hmset

Redis L<HMSET|http://redis.io/commands/hmset> command.

Sets a list of key/value pairs in a hash. Takes the hash name and a list of
keys and values to set. 

    $client->hmset( 'myhash', foo => 1, bar => 2, baz => 3 );

=head2 hvals

Redis L<HVALS|http://redis.io/commands/hvals> command.

Retrieves a list of all the values in a given hash. Takes the hash name.

    my @values = $client->hvals( 'myhash' );

=head1 SET METHODS

=head2 sadd

Redis L<SADD|http://redis.io/commands/sadd> command.

Adds members to a set. Takes the names of the set and the members to add.

    $client->sadd( 'myset', 'foo', 'bar', 'baz' );

=head2 srem

Redis L<SREM|http://redis.io/commands/srem> command.

Removes members from a set. Takes the names of the set and the members
to remove.

    $client->srem( 'myset', 'foo', 'baz' );

=head2 smembers

Redis L<SMEMBERS|http://redis.io/commands/smembers> command.

Returns a list of all members in a set, in no particular order. Takes
the name of the set.

    my @members = $client->smembers( 'myset' );

=head2 sismember

Redis L<SISMEMBER|http://redis.io/commands/sismember> command.

Returns a true value if the given member is in a set. Takes the names
of the set and the member.

    if ( $client->sismember( 'myset', foo' ) ) { ... }

=head1 SORTED SET METHODS

=head2 zadd

Redis L<ZADD|http://redis.io/commands/zadd> command.

Adds members to a sorted set (zset). Takes the sorted set name and a list of
score/member pairs. 

    $client->zadd( 'myzset', 1 => 'foo', 2 => 'bar', 3 => 'baz' );

(The ordering of the scores and member names may seem backwards if you think
of zsets as rough analogs of hashes. That's just how Redis does it.)

=head2 zcard

Redis L<ZCARD|http://redis.io/commands/zcard> command.

Returns the cardinality (size) of a sorted set. Takes the name of the sorted set.

    my $size = $client->zcard( 'myzset' );

=head2 zcount

Redis L<ZCOUNT|http://redis.io/commands/zcount> command.

Returns the number of members in a sorted set with scores between two values.
Takes the name of the sorted set and the minimum and maximum

    my $count = $client->zcount( 'myzset', $min, $max );

=head2 zrange

Redis L<ZRANGE|http://redis.io/commands/zrange> command.

Returns all the members of a sorted set with scores between two values. Takes the
name of the sorted set, a minimum and maximum, and an optional boolean to 
control whether or not the scores are returned along with the members.

    my @members = $client->zrange( 'myzset', $min, $max );
    my %members_scores = $client->zrange( 'myzset', $min, $max, 1 );

=head2 zrank  

Redis L<ZRANK|http://redis.io/commands/zrank> command.

Returns the index of a member within a sorted. set. Takes the names of the
sorted set and the member.

    my $rank = $client->zrank( 'myzset', 'foo' );

=head2 zscore  

Redis L<ZSCORE|http://redis.io/commands/zscore> command.

Returns the score associated with a member in a sorted set. Takes the names
of the sorted set and the member.

    my $score = $client->zscore( 'myzset', 'foo' );

=head1 CONNECTION METHODS

=head2 echo

Redis L<ECHO|http://redis.io/commands/echo> command.

Returns whatever you send it. Useful for testing only. Takes one argument.

    print $client->echo( "Hello, World!" );

=encoding utf8

=head1 CAVEATS

This early release is not feature-complete. I've implemented all the Redis
commands that I use, but there are several that are not yet implemented. There
is also no support for Redis publish/subscribe, but I intend to add that
soon. Patches welcome. :)

The L<MONITOR|http://redis.io/commands/monitor> command will probably not be
supported any time soon since it would require some kind of asynchronous 
solution and does not use the URP.

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Redis::Client::Role::URP>

=back

=head1 AUTHOR

Mike Friedman <friedo@friedo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Friedman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
