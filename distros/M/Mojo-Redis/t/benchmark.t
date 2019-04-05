use Mojo::Base -strict;
use Test::More;
use Benchmark qw(cmpthese timeit timestr :hireswallclock);

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{MOJO_REDIS_URL} = $ENV{TEST_ONLINE};
plan skip_all => 'TEST_BENCHMARK=500'            unless my $n_times          = $ENV{TEST_BENCHMARK};

my @classes   = qw(Mojo::Redis Mojo::Redis2);
my @protocols = qw(Protocol::Redis Protocol::Redis::Faster Protocol::Redis::XS);
my $key       = "test:benchmark:$0";
my %t;

for my $class (@classes) {
  eval "require $class;1" or next;

  for my $protocol (@protocols) {
    eval "require $protocol;1" or next;
    my $redis = $class->new->protocol_class($protocol);

    my ($bm, $lrange) = run($redis->isa('Mojo::Redis2') ? $redis : $redis->db, $protocol);
    is_deeply $lrange, [reverse 0 .. $n_times - 1], sprintf '%s/%s %s', ref $redis, $protocol, timestr $bm;

    my $bm_key = join '/', $redis->isa('Mojo::Redis2') ? 'Redis2' : 'Redis',
      $protocol =~ m!Protocol::Redis::(\w+)! ? $1 : 'PP';
    $t{$bm_key} = $bm;
  }
}

compare(qw(Redis/Faster Redis2/Faster));
compare(qw(Redis/Faster Redis/PP));
cmpthese(\%t) if $ENV{HARNESS_IS_VERBOSE};

done_testing;

sub compare {
  my ($an, $bn) = @_;
  return diag "Cannot compare $an and $bn" unless my $ao = $t{$an} and my $bo = $t{$bn};
  ok $ao->cpu_a <= $bo->cpu_a, sprintf '%s (%ss) is not slower than %s (%ss)', $an, $ao->cpu_a, $bn, $bo->cpu_a;
}

sub run {
  my $db = shift;

  $db->del($key);

  my ($lpush, $lrange);
  my $i  = 0;
  my $bm = timeit(
    $n_times,
    sub {
      $lpush = $db->lpush($key => $i++);
      $lrange = $db->lrange($key => 0, -1);
    }
  );

  $db->del($key);

  return $bm, $lrange;
}
