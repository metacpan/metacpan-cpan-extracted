use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;

plan skip_all => 'Cannot test on Win32' if $^O eq 'MSWin32';
plan skip_all => $@ unless eval { Mojo::Redis2::Server->start };

my $redis = Mojo::Redis2->new;
my $backend = $redis->backend;
my ($err, @res);

{
  is $backend->config(dbfilename => 'foo.rdb'), 'OK', 'CONFIG SET dbfilename';
  is_deeply $backend->config('dbfilenam*'), { dbfilename => 'foo.rdb' }, 'CONFIG GET dbfilenam*';

  @res = ();
  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      is $backend->config(dbfilename => 'bar.rdb' => $delay->begin), $backend, 'config return backend';
      is $backend->config(dbfilename => $delay->begin), $backend, 'config return backend';
    },
    sub {
      my $delay = shift;
      push @res, @_;
      Mojo::IOLoop->stop;
    },
  );
  Mojo::IOLoop->start;

  is_deeply \@res, [ '', 'OK', '', 'bar.rdb' ], 'async';
  is $backend->config('dbfilename'), 'bar.rdb', 'CONFIG GET dbfilename';
}

done_testing;
