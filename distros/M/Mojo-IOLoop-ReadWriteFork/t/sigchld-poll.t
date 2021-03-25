BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;
use Time::HiRes 'usleep';

# This test will check if the recurring waitpid function works

my $sigchld    = Mojo::IOLoop::ReadWriteFork::SIGCHLD->singleton;
my $fork       = Mojo::IOLoop::ReadWriteFork->new;
my $exit_value = 24;

ok !$sigchld->is_waiting, 'no forks';

my $close_p = Mojo::Promise->new;
$fork->once(finish => sub { $exit_value = $_[1]; $close_p->resolve });
$fork->once(
  spawn => sub {
    is_deeply [keys %{$sigchld->pids}], [$fork->pid], 'one pid after fork';
  }
);

$fork->start(program => sub { usleep 0.2; $! = 42; });
Mojo::Promise->race(Mojo::Promise->timeout(1), Mojo::Promise->all(Mojo::Promise->timer(0.5), $close_p))->wait;

ok !$sigchld->is_waiting, 'no forks after waitpid';
is_deeply [keys %{$sigchld->pids}], [], 'no pids after waitpid';
is $exit_value, 42, 'exit_value';

done_testing;
