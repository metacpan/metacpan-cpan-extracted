use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

$ENV{PATH} ||= '';
plan skip_all => 'bash is missing' unless grep { -x "$_/bash" } split /:/, $ENV{PATH};

my $fork   = Mojo::IOLoop::ReadWriteFork->new;
my $output = '';
my $n      = 0;
my $closed = 0;

$fork->on(
  error => sub {
    my ($fork, $error) = @_;
    diag $error;
    $n++ > 20 and exit;
  }
);
$fork->on(
  close => sub {
    $closed++;
    Mojo::IOLoop->stop;
  }
);
$fork->on(
  read => sub {
    my ($fork, $buffer, $writer) = @_;
    $output .= $buffer;
    $n++ > 20 and exit;
  }
);

{
  local $ENV{YIKES} = 'too cool';
  $fork->start(program => 'bash', program_args => [-c => 'echo $YIKES foo bar baz'], conduit => 'pty');
}

is $fork->pid, 0, 'no pid' or diag $fork->pid;
Mojo::IOLoop->timer(3 => sub { Mojo::IOLoop->stop });    # guard
Mojo::IOLoop->start;
like $fork->pid, qr{^[1-9]\d+$}, 'got pid' or diag $fork->pid;
like $output, qr/^too cool foo bar baz\W{1,2}$/, 'got stdout from "echo"' or diag $output;
is $closed, 1, 'got close event';
ok !$fork->{stdin_write}, 'stdin_write handle was cleaed up';
ok !$fork->{stdout_read}, 'stdout_read handle was cleaed up';

done_testing;
