use Mojo::Base -strict;
use Test::More;
use Mojo::IOLoop::ReadWriteFork;

my $fork = Mojo::IOLoop::ReadWriteFork->new;
my ($exit_value, $signal);

$fork->on(
  close => sub {
    (my $self, $exit_value, $signal) = @_;
    Mojo::IOLoop->stop;
  }
);

$fork->run('__INVALID_PROGRAM_NAME_THAT_DOES_NOT_EXIST__');
Mojo::IOLoop->start;

is $exit_value, 2, 'exit_value';
is $signal,     0, 'signal';

done_testing;
