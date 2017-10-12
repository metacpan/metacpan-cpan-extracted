use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;
use Mojo::Util 'dumper';

plan skip_all => 'Cannot test on Win32' if $^O eq 'MSWin32';
plan skip_all => $@ unless eval { Mojo::Redis2::Server->start };

my $redis = Mojo::Redis2->new;
my (@res, @commands);

{
  no warnings 'redefine';
  *Mojo::Redis2::Transaction::_op_to_command = sub {
    my $cmd = shift->Mojo::Redis2::_op_to_command(@_);
    push @commands, $cmd;
    $cmd;
  };
}

{
  my $txn = $redis->multi;

  for my $illegal (qw( blpop brpop brpoplpush multi psubscribe publish subscribe )) {
    eval { $txn->$illegal; };
    like $@, qr{Cannot call $illegal}, "Cannot call $illegal()";
  }

  is_deeply \@commands, [], 'no commands sent';
}

diag 'exec+discard';
@commands = ();
for my $action (qw( exec discard )) {
  my $txn = $redis->multi;

  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $txn->incr(foo => $delay->begin)->incrby(foo => 41, $delay->begin);
    },
    sub {
      my ($delay, $ping_err, $ping, $incr_err, $incr) = @_;
      $txn->$action($delay->begin);
    },
    sub {
      my ($delay, @action_res) = @_;
      push @res, @action_res;
      $redis->get(foo => $delay->begin);
    },
    sub {
      my ($delay, $get_err, $get) = @_;
      push @res, $get;
      Mojo::IOLoop->stop;
    },
  );
  Mojo::IOLoop->start;
}

is_deeply(
  \@commands,
  [
    "*1\r\n\$5\r\nMULTI\r\n",
    "*2\r\n\$4\r\nINCR\r\n\$3\r\nfoo\r\n",
    "*3\r\n\$6\r\nINCRBY\r\n\$3\r\nfoo\r\n\$2\r\n41\r\n",
    "*1\r\n\$4\r\nEXEC\r\n",
    "*1\r\n\$5\r\nMULTI\r\n",
    "*2\r\n\$4\r\nINCR\r\n\$3\r\nfoo\r\n",
    "*3\r\n\$6\r\nINCRBY\r\n\$3\r\nfoo\r\n\$2\r\n41\r\n",
    "*1\r\n\$7\r\nDISCARD\r\n"
  ],
  'commands sent in right order'
) or diag dumper \@commands;

is_deeply(
  \@res,
  [
    '', [qw( 1 42 )], 42,
    '', 'OK', 42,
  ],
  'exec once, discard once',
) or diag dumper \@res;

{
  @commands = ();
  diag 'reuse';
  my $txn = $redis->multi;
  $txn->set(foo => 3);
  $txn->incrby(foo => 10);
  $txn->exec;
  is $redis->get('foo'), 13, 'exec()';

  $txn->set(foo => 4);
  $txn->incrby(foo => 11);
  is $redis->get('foo'), 13, 'not yet exec()';
  $txn->exec;
  is $redis->get('foo'), 15, 'exec()';

  $txn->set(foo => 7);
  $txn->incrby(foo => 7);
}

is $redis->get('foo'), 15, 'discard on out of scope';
is_deeply(
  \@commands,
  [
    "*1\r\n\$5\r\nMULTI\r\n",
    "*3\r\n\$3\r\nSET\r\n\$3\r\nfoo\r\n\$1\r\n3\r\n",
    "*3\r\n\$6\r\nINCRBY\r\n\$3\r\nfoo\r\n\$2\r\n10\r\n",
    "*1\r\n\$4\r\nEXEC\r\n",

    "*1\r\n\$5\r\nMULTI\r\n",
    "*3\r\n\$3\r\nSET\r\n\$3\r\nfoo\r\n\$1\r\n4\r\n",
    "*3\r\n\$6\r\nINCRBY\r\n\$3\r\nfoo\r\n\$2\r\n11\r\n",
    "*1\r\n\$4\r\nEXEC\r\n",

    "*1\r\n\$5\r\nMULTI\r\n",
    "*3\r\n\$3\r\nSET\r\n\$3\r\nfoo\r\n\$1\r\n7\r\n",
    "*3\r\n\$6\r\nINCRBY\r\n\$3\r\nfoo\r\n\$1\r\n7\r\n",
    "*1\r\n\$7\r\nDISCARD\r\n"
  ],
  'the same txn object can be re-used',
) or diag dumper \@commands;

{
  my $txn = $redis->multi;
  is $txn->watch('foo'), 'OK', 'watch()';
  is $txn->incr('foo'), 'QUEUED', 'incr()';
  is $redis->set('foo', -100), 'OK', 'set()';
  is_deeply $txn->exec, [], 'exec() after watch()';
}

done_testing;
