use Test::More;
use File::Find;

plan skip_all => 'No such directory: .git' unless $ENV{TEST_ALL} or -d '.git';
plan skip_all => 'HARNESS_PERL_SWITCHES =~ /Devel::Cover/' if +($ENV{HARNESS_PERL_SWITCHES} || '') =~ /Devel::Cover/;

for (qw(
  Test::CPAN::Changes::changes_file_ok+VERSION!4
  Test::Pod::Coverage::pod_coverage_ok+VERSION!1
  Test::Pod::pod_file_ok+VERSION!1
  Test::Spelling::pod_file_spelling_ok+has_working_spellchecker!1
))
{
  my ($fqn, $module, $sub, $check, $skip_n) = /^((.*)::(\w+))\+(\w+)!(\d+)$/;
  next if eval "use $module;$module->$check";
  no strict qw(refs);
  no warnings qw(redefine);
  *$fqn = sub {
  SKIP: { skip "$sub(@_) ($module is required)", $skip_n }
  };
}

my @files;
find({wanted => sub { /\.pm$/ and push @files, $File::Find::name }, no_chdir => 1}, -e 'blib' ? 'blib' : 'lib');
plan tests => @files * 4 + 4;

Test::Spelling::add_stopwords(<DATA>)
  if Test::Spelling->can('has_working_spellchecker') && Test::Spelling->has_working_spellchecker;

for my $file (@files) {
  my $module = $file;
  $module =~ s,\.pm$,,;
  $module =~ s,.*/?lib/,,;
  $module =~ s,/,::,g;
  ok eval "use $module; 1", "use $module" or diag $@;
  Test::Pod::pod_file_ok($file);
  Test::Pod::Coverage::pod_coverage_ok($module, {also_private => [qr/^[A-Z_]+$/]});
  Test::Spelling::pod_file_spelling_ok($file);
}

Test::CPAN::Changes::changes_file_ok();

__DATA__
ADDR
AUTH
GETKEYS
GETNAME
HSCAN
Henning
HyperLogLog
HyperLogLogs
Lua
PSUBSCRIBE
Pipelining
SETNAME
SKIPME
SSCAN
Thorsen
XRANGE
ZSCAN
bgrewriteaof
bgsave
bitcount
bitop
bitpos
blpop
brpop
brpoplpush
bzpopmax
bzpopmin
cardinality
dbsize
decr
decrby
del
differnet
entires
evalsha
expireat
flushall
flushdb
geoadd
geodist
geohash
geopos
georadius
georadiusbymember
geospatial
getbit
getrange
getset
hdel
hexists
hget
hgetall
hincrby
hincrbyfloat
hkeys
hlen
hmget
hmset
hset
hsetnx
hstrlen
hvals
incr
incrby
incrbyfloat
ioloop
keyspace
lastsave
lindex
linsert
llen
lpop
lpush
lpushx
lrange
lrem
lset
ltrim
mget
mset
msetnx
pexpire
pexpireat
pfadd
pfcount
pfmerge
psetex
psubscribe
pttl
pubsub
randomkey
readonly
readwrite
redis
redis
renamenx
resends
rpop
rpoplpush
rpush
rpushx
sadd
scard
sdiff
sdiffstore
setbit
setex
setnx
setrange
sinter
sinterstore
sismember
slaveof
slowlog
smembers
smove
spop
srandmember
srem
sunion
sunionstore
ttl
unlisten
unwatch
usecase
xadd
xlen
xpending
xrange
xread
xreadgroup
xrevrange
zadd
zcard
zcount
zincrby
zinterstore
zlexcount
zpopmax
zpopmin
zrange
zrangebylex
zrangebyscore
zrank
zrem
zremrangebylex
zremrangebyrank
zremrangebyscore
zrevrange
zrevrangebylex
zrevrangebyscore
zrevrank
zscore
zunionstore
