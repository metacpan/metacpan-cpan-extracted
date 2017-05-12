package Postgredis;

use Mojo::Pg;
use v5.20;
use experimental 'signatures';
use strict;

our $VERSION=0.03;

sub new {
    my $s = shift;
    my @a = @_;
    my %args;
    %args = ( namespace => $_[0] ) if @_==1;
    bless \%args, $s;
}

sub namespace($s,$new=undef) {
    $s->{namespace} = $new if @_==2;
    $s->{namespace};
}

sub _pg($s) {
    state $db;
    return $db if defined($db);
    $db = Mojo::Pg->new;
    $ENV{PG_CONNECT_STR} and do { $db = $db->from_string( $ENV{PG_CONNECT_STR} ) };
    $ENV{PG_CONNECT_DSN} and do { $db = $db->dsn($ENV{PG_CONNECT_DSN}) };
    $db;
}

sub pg($s) { $s->_pg->db; }

sub _create_tables($s) {
    my $table = $s->namespace;
    $s->_query(<<DONE);
    create table $table (
        k varchar not null primary key,
        v jsonb
    )
DONE
    $s->_query(<<DONE);
    create table $table\_sorted (
        k varchar not null,
        v jsonb not null,
        score real not null,
    primary key (k, v)
    )
DONE
    $s->_query(<<DONE);
    create index on $table\_sorted (k,score)
DONE
}

sub _drop_tables($s) {
    my $table = $s->namespace;
    $s->_query("drop table if exists $table");
    $s->_query("drop table if exists $table\_sorted");
}

sub _tables_exist($s) {
    my $res = $s->_query(q[select 1 from information_schema.tables where table_name = ?],
		$s->namespace);
	return $res->rows > 0;
}

sub _query($s,$str, @more) {
    my $namespace = $s->namespace;
    $str =~ s/\bredis\b/$namespace/;
    $str =~ s/\bredis_sorted\b/$namespace\_sorted/;
    return $s->pg->query($str, @more);
}

sub maybe_init($s) {
	$s->flushdb unless $s->_tables_exist;
    $s;
}

sub flushdb($s) {
    $s->_drop_tables if $s->_tables_exist;
    $s->_create_tables;
    return $s;
}

sub default_ttl { }

sub set($s,$key,$value) {
  my $res;
  $res = $s->_query("update redis set v = ?::jsonb where k = ?", { json => $value }, $key);
  return 1 if $res->rows > 0;
  $s->_query("insert into redis (k, v) values (?,?::jsonb)", $key, { json => $value } );
  return 1;
}

sub get($s,$k) {
    return $s->_query("select v from redis where k=?",$k)->expand->array->[0];
}

sub del($s,$k) {
    $s->_query("delete from redis where k=?",$k);
}

sub keys($s,$pat) {
    $pat =~ s/\*/%/g;
    return $s->_query("select k from redis where k like ?",$pat)->arrays->flatten;
}

sub exists($s,$k) {
    my $got = $s->_query("select * from redis where k=?",$k);
    return $got->rows > 0;
}

sub hset($s,$key,$hkey,$value) {
    my $res = $s->_query("select v from redis where k = ?", $key)->expand;
    my $json = $res->rows ? $res->hash->{v} : {};
    $json->{$hkey} = $value;
    $res = $s->_query("update redis set v = ?::jsonb where k = ?",{json=>$json},$key);
    return 1 if $res->rows > 0;
    $res = $s->_query("insert into redis (k, v) values (?,?::jsonb)",$key, {json=>$json});
    return 1;
}

sub hdel($s,$key,$hkey) {
    my $json = $s->_query("select v from redis where k = ?", $key)->expand->hash->{v};
    exists($json->{$hkey}) or return 0;
    delete $json->{$hkey} or return 0;
    $s->_query("update redis set v = ?::jsonb where k = ?",{json=>$json},$key);
}

sub hget($s,$key,$hkey) {
    my $json = $s->_query("select v from redis where k = ?", $key)->expand->hash->{v};
    return $json->{$hkey};
}

sub hgetall($s,$key) {
    my $res = $s->_query("select v from redis where k = ?", $key)->expand;
    return {} unless $res->rows;
    return $res->hash->{v};
}

sub sadd($s,$key,$value) {
    $s->hset($key,$value,1);
}

sub srem($s,$key,$value) {
    my $json = $s->_query("select v from redis where k = ?", $key)->expand->hashes;
    $json &&= $json->[0]{v};
    delete $json->{$value};
    $s->_query("update redis set v = ?::jsonb where k = ?",{json=>$json},$key);
    return 1;
}

sub smembers($s,$k) {
    my $j = $s->hgetall($k);
    return [ CORE::keys(%$j) ]
}

sub incr($s,$k) {
    my $exists = $s->_query("select 1 from pg_class where relname = ?", $k);
    $k =~ /^[a-z0-9:_]+$/ or die "bad sequence name $k";
    unless ($exists->rows) {
        $s->_query("create sequence $k start 1");
    }
    my $next = $s->_query("select nextval(?)",$k)->arrays->flatten;
    return $next->[0];
}

sub zadd($s,$key,$score,$val) {
    $s->_query("insert into redis_sorted (k,score,v) values (?,?,?::jsonb)",
        $key, $score,{ json => $val });
}

sub zscore($s,$key,$val) {
    return $s->_query("select score from redis_sorted where k = ? and v = ?::jsonb",
        $key, { json => $val })->array->[0];
}

sub zrem($s,$key,$val) {
    $s->_query("delete from redis_sorted where k = ? and v = ?::jsonb", $key, { json => $val } );
}

sub zrangebyscore($s,$key,$min,$max) {
    return $s->_query("select v from redis_sorted where k = ? and score >= ?
        and score <= ? order by score, v::text", $key, $min, $max)
    ->expand->arrays->flatten;
}

1;

=head1 NAME

Postgredis -- PostgreSQL and Redis mashup

=head1 SYNOPSIS

     my $db = Postgredis->new('test');
     $db->set(favorite_color => "blue");
     $db->hset("joe", name => "Joe", age => 50 );

=head1 DESCRIPTION

Postgredis is an experimental implementation of a subset of the
Redis primitives using Postgres as a backend.

The interface provides methods corresponding to Redis commands
which are translated into SQL queries on two tables.  The
two tables are a key-value table and a key-sortkey-value
table.  The values use the native JSON datatype in Postgres.
For this, postgres 9.4 or higher is required.

=head1 METHODS

Most of the methods are self explanatory -- see L<http://redis.io> for
further descriptions.

=head2 Database operations

    maybe_init($s)
    flushdb($s)

=head2 Key operations

    set($s,$key,$value)
    get($s,$k)
    del($s,$k)
    keys($s,$pat)
    exists($s,$k)

=head2 Hash operations

    hset($s,$key,$hkey,$value)
    hdel($s,$key,$hkey)
    hget($s,$key,$hkey)
    hgetall($s,$key)

=head2 Set operations

    sadd($s,$key,$value)
    srem($s,$key,$value)
    smembers($s,$k)

=head2 Sorted set operations

    zadd($s,$key,$val,$score)
    zscore($s,$key,$val)
    zrem($s,$key,$val)
    zrangebyscore($s,$key,$min,$max)

=head2 String operations

    incr($s,$k)

=head1 MOTIVATION

The Redis primitives provide flexible representations of loosely structured data,
but indexing and querying the data can be a challenge.  PostgreSQL provides
robust persistent data storage with flexible options for indexing and querying,
but relational schema design may be costly and insufficiently flexible.
Postgres as a backend is a compromise between the two.

=head1 SEE ALSO

L<RedisDB>, L<Mojo::Pg>

=head1 AUTHOR

Brian Duggan C<bduggan@cpan.org>

=cut
