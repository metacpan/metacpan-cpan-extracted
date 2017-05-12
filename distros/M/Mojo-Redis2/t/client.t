use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;

plan skip_all => 'Cannot test on Win32' if $^O eq 'Win32';
plan skip_all => $@ unless eval { Mojo::Redis2::Server->start };

my $redis = Mojo::Redis2->new;
my ($addr, $err, @res);

{
  is_deeply $redis->client->name('foo'), 'OK', 'CLIENT SETNAME';
  is_deeply $redis->client->name, 'foo', 'CLIENT GETNAME';

  @res = ();
  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $redis->client->name($delay->begin);
    },
    sub {
      my ($delay, $err, $res) = @_;
      push @res, $err, $res;
      $redis->client->name(bar => $delay->begin);
    },
    sub {
      my ($delay, $err, $res) = @_;
      push @res, $err, $res;
      $redis->client->name($delay->begin);
    },
    sub {
      my ($delay, $err, $res) = @_;
      push @res, $err, $res;
      Mojo::IOLoop->stop;
    },
  );
  Mojo::IOLoop->start;

  is_deeply \@res, [ '', undef, '', 'OK', '', 'bar' ], 'async GET/SETNAME';
}

{
  my $list = $redis->client->list;
  is int(keys %$list), 2, 'got two connections';

  my $conn = $list->{(grep { $list->{$_}{name} ne 'foo' } keys %$list)[0]};
  is $conn->{name}, 'bar', 'list name=bar';
  is $conn->{db}, 0, 'list db=0';

  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $redis->client->list($delay->begin);
    },
    sub {
      my ($delay, $err, $res) = @_;
      @res = ($err, $res);
      Mojo::IOLoop->stop;
    },
  );
  Mojo::IOLoop->start;

  is int(keys %{$res[1]}), 2, 'got two connections async' or diag $res[0];
  $addr = (keys %{$res[1]})[0];
}

{
  eval { $redis->client->kill('some-client') };
  like $@, qr{No such client}, 'No such client';
  is $redis->client->kill($addr), 'OK', "kill $addr";
}

done_testing;
