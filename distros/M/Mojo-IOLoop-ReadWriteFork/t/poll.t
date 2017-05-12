BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;
use Time::HiRes 'usleep';

# This test will check if the recurring waitpid function works

my $fork       = Mojo::IOLoop::ReadWriteFork->new;
my $exit_value = 24;

ok !$fork->ioloop->reactor->{forks}, 'undefined forks';

$fork->on(close => sub { $exit_value = $_[1]; Mojo::IOLoop->stop; });
$fork->start(program => sub { usleep 0.2; $! = 42; });

Mojo::IOLoop->timer(1 => sub { Mojo::IOLoop->stop });    # guard
Mojo::IOLoop->start;

is_deeply $fork->ioloop->reactor->{forks}, {}, 'no forks after waitpid';
is $exit_value, 42, 'exit_value';

done_testing;
