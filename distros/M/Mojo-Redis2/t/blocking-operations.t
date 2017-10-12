use Mojo::Base -strict;
use Mojo::Redis2;
use Mojo::Util 'dumper';
use Test::More;

plan skip_all => 'Cannot test on Win32' if $^O eq 'MSWin32';
plan skip_all => $@ unless eval { Mojo::Redis2::Server->start };

my $redis = Mojo::Redis2->new;
my @res;

Mojo::IOLoop->delay(
  sub {
    my ($delay) = @_;
    $redis->blpop(foo => 3, $delay->begin);
    $redis->brpop(foo => 2, $delay->begin);
    $redis->lpush(foo => 1, 2, 3, $delay->begin);
  },
  sub {
    my $delay = shift;
    push @res, @_;
    $redis->brpoplpush(foo => bar => 3, $delay->begin);
  },
  sub {
    my $delay = shift;
    push @res, @_;
    $redis->lrange(bar => 0, -1, $delay->begin);
  },
  sub {
    my $delay = shift;
    push @res, @_;
    Mojo::IOLoop->stop;
  },
);
Mojo::IOLoop->start;

is_deeply(
  \@res,
  [
    '', [foo => 3], # blpop
    '', [foo => 1], # brpop
    '', 3,          # lpush
    '', 2,          # brpoplpush
    '', [2],        # lrange
  ],
  'brpop+blpop+brpoplpush',
) or diag dumper \@res;

done_testing;
