use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;

plan skip_all => 'Cannot test on Win32' if $^O eq 'Win32';

# not sure if setting requirepass and path matter,
# but adding it for the sake of complexity
plan skip_all => $@ unless eval { Mojo::Redis2::Server->start(requirepass => 's3cret') };
my $url = Mojo::URL->new($ENV{MOJO_REDIS_URL})->path(3);
my $redis = Mojo::Redis2->new(url => $url);
my @res;

Mojo::IOLoop->delay(
  sub {
    my ($delay) = @_;
    my @cb = ($delay->begin, $delay->begin);
    $redis->set(foo => 42 => $delay->begin);
    $redis->set(bar => 24 => $delay->begin);
    $redis->get(foo   => $delay->begin);
    $redis->get(other => $delay->begin);
    $redis->once(
      connection => sub {
        my ($redis, $info) = @_;
        $redis->get(foo => $cb[0]);
        Mojo::IOLoop->remove($info->{id});
        $redis->get(bar => $cb[1]);
      }
    );
  },
  sub {
    (my $delay, @res) = @_;
    Mojo::IOLoop->stop;
  },
);
Mojo::IOLoop->start;

#diag Data::Dumper::Dumper(\@res);
is_deeply(
  \@res,
  [
    '', '42',     # get foo $cb[0]
    '', '24',     # get bar $cb[1]
    '', 'OK',     # set foo
    '', 'OK',     # set bar
    '', '42',     # get foo
    '', undef,    # get other
  ],
  'delay result'
);

done_testing;
