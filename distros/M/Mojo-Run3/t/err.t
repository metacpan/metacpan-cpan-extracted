BEGIN {
  *CORE::GLOBAL::fork = sub { $! = 1; return undef };
  *CORE::GLOBAL::pipe = sub {
    $ENV{PIPE_OK} ? CORE::pipe($_[0], $_[1]) : do { $! = 2; undef }
  }
}

use Mojo::Base -strict;
use Mojo::Run3;
use Test::More;

subtest 'prepare filehandles' => sub {
  my $run3 = Mojo::Run3->new;
  my ($err, $finish, $start) = ('', 0, 0);
  $run3->on(error  => sub { $err = $_[1] });
  $run3->on(finish => sub { $finish++ });
  $run3->start(sub { $start++ });
  $run3->ioloop->one_tick;
  like $err, qr{Can't pipe}, 'error';
  is $start,             0, 'start';
  is $finish,            1, 'finished';
  is int($run3->status), 2, 'status';
};

subtest 'fork' => sub {
  local $ENV{PIPE_OK} = 1;
  my $run3 = Mojo::Run3->new;
  my ($err, $finish, $start) = ('', 0, 0);
  $run3->on(error  => sub { $err = $_[1] });
  $run3->on(finish => sub { $finish++ });
  $run3->start(sub { $start++ });
  $run3->ioloop->one_tick;
  like $err, qr{Can't fork}, 'error';
  is $start,             0, 'start';
  is $finish,            1, 'finished';
  is int($run3->status), 1, 'status';
};

done_testing;
