use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;

{
  my $redis = Mojo::Redis2->new;
  is $redis->url, 'redis://localhost:6379', 'url() is set';
  is $redis->protocol_class, $ENV{MOJO_REDIS_PROTOCOL}, 'protocol_class';
}

{
  local $ENV{MOJO_REDIS_URL} = 'redis://x:z@localhost:42/3';
  my $redis = Mojo::Redis2->new;
  is $redis->url->host, 'localhost', 'url() host';
  is $redis->url->path->[0], '3', 'url() path';
  is $redis->url->port,     '42',  'url() port';
  is $redis->url->userinfo, 'x:z', 'url() userinfo';
}

{
  my @args;
  no warnings 'redefine';
  local *Mojo::IOLoop::client = sub { @args = ($_[1]); $_[2]->($_[0], '', Mojo::IOLoop::Stream->new) };
  local *Mojo::Redis2::_dequeue = sub { push @args, $_[1]; };

  Mojo::Redis2->new(url => "10.0.0.42")->_connect({});
  is_deeply $args[0], {address => '10.0.0.42', port => 6379}, 'host';

  Mojo::Redis2->new(url => "redis://10.0.0.42:6380")->_connect({});
  is_deeply $args[0], {address => '10.0.0.42', port => 6380}, 'protocol, host, port';

  Mojo::Redis2->new(url => "10.0.0.42:6380/2")->_connect({});
  is_deeply $args[0], {address => '10.0.0.42', port => 6380}, 'host, port, db';
  is_deeply $args[1]{queue}, [[undef, qw(SELECT 2)]], 'select';

  Mojo::Redis2->new(url => "redis://x:s3cret\@10.0.0.42:6379/3")->_connect({});
  is_deeply $args[0], {address => '10.0.0.42', port => 6379}, 'protocol, auth, host, port, db';
  is_deeply $args[1]{queue}, [[undef, qw(AUTH s3cret)], [undef, qw(SELECT 3)]], 'auth+select';
}

done_testing;
