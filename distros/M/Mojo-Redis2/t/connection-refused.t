use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;

plan skip_all => 'TEST_SLOW=1' unless $ENV{TEST_SLOW};

my $port = Mojo::IOLoop::Server->generate_port;
my $redis = Mojo::Redis2->new(url => "redis://127.0.42.123:$port");
my ($err, $res);

my $got = 0;
Mojo::IOLoop->delay(
  sub {
    my ($delay) = @_;
    $redis->get(foo => $delay->begin) for (0 .. 2);
  },
  sub {
    (my $delay, $err, $res) = @_;
    $got = @_;
    Mojo::IOLoop->stop;
  },
);
Mojo::IOLoop->start;
is $got, 7, 'all ops completed';

is eval { $redis->get('foo'); 1 }, undef, 'get failed';
my $e = $@;
is $res, undef,           'get foo';
like $e, qr{\[GET foo\]}, 'connection failed';

{
  local $TODO = 'Fail because of i18n';
  like $e, qr{$err}, "sync contains async error ($err)";
}

done_testing;
