use Test::More;
use File::Find;

if (($ENV{HARNESS_PERL_SWITCHES} || '') =~ /Devel::Cover/) {
  plan skip_all => 'HARNESS_PERL_SWITCHES =~ /Devel::Cover/';
}
if (!eval 'use Test::Pod; 1') {
  *Test::Pod::pod_file_ok = sub {
  SKIP: { skip "pod_file_ok(@_) (Test::Pod is required)", 1 }
  };
}
if (!eval 'use Test::Pod::Coverage; 1') {
  *Test::Pod::Coverage::pod_coverage_ok = sub {
  SKIP: { skip "pod_coverage_ok(@_) (Test::Pod::Coverage is required)", 1 }
  };
}
if (!eval 'use Test::CPAN::Changes; 1') {
  *Test::CPAN::Changes::changes_file_ok = sub {
  SKIP: { skip "changes_ok(@_) (Test::CPAN::Changes is required)", 4 }
  };
}

find({wanted => sub { /\.pm$/ and push @files, $File::Find::name }, no_chdir => 1}, -e 'blib' ? 'blib' : 'lib',);

plan tests => @files * 3 + 4;

my @hidden = qw(
  append bitcount bitop bitpos decr decrby del echo exists expire expireat get getbit getrange getset hdel
  hexists hget hgetall hincrby hincrbyfloat hkeys hlen hmget hmset hset hsetnx hvals incr incrby
  incrbyfloat keys lindex linsert llen lpop lpush lpushx lrange lrem lset ltrim mget move mset msetnx
  persist pexpire pexpireat ping psetex pttl publish randomkey rename renamenx rpop rpoplpush rpush rpushx
  sadd scard sdiff sdiffstore set setbit setex setnx setrange sinter sinterstore sismember smembers smove
  sort spop srandmember srem strlen sunion sunionstore ttl type zadd zcard zcount zincrby zinterstore
  zlexcount zrange zrangebylex zrangebyscore zrank zrem zremrangebylex zremrangebyrank zremrangebyscore
  zrevrange zrevrangebylex zrevrangebyscore zrevrank zscore zunionstore
);

for my $file (@files) {
  my $module = $file;
  $module =~ s,\.pm$,,;
  $module =~ s,.*/?lib/,,;
  $module =~ s,/,::,g;
  ok eval "use $module; 1", "use $module" or diag $@;
  Test::Pod::pod_file_ok($file);
  Test::Pod::Coverage::pod_coverage_ok($module, {also_private => [qr/^[A-Z_]+$/, @hidden]});
}

Test::CPAN::Changes::changes_file_ok();
