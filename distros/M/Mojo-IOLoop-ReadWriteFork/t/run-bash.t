use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

$ENV{PATH} ||= '';
plan skip_all => 'bash is missing' unless grep { -x "$_/bash" } split /:/, $ENV{PATH};

my $rwf = Mojo::IOLoop::ReadWriteFork->new;
my ($closed, $n, $output) = (0, 0, '');

$rwf->on(error  => sub { diag $_[1]; $n++ > 20 && exit });
$rwf->on(finish => sub { $closed++;  Mojo::IOLoop->stop });

note 'Set $! to test that it does not trigger "error" event';
$rwf->on(read => sub { $! = 2; $output .= $_[1]; $n++ > 20 && exit });

{
  local $ENV{YIKES} = 'too cool';
  $rwf->start(program => 'bash', program_args => [-c => 'echo $YIKES foo bar baz'], conduit => 'pty');
}

is $rwf->pid, 0, 'no pid' or diag $rwf->pid;
Mojo::IOLoop->timer(3 => sub { Mojo::IOLoop->stop });    # guard
Mojo::IOLoop->start;
like $rwf->pid, qr{^[1-9]\d+$},                    'got pid'                or diag $rwf->pid;
like $output,   qr/^too cool foo bar baz\W{1,2}$/, 'got stdout from "echo"' or diag $output;
is $closed, 1, 'got close event';
ok !$rwf->{stdin_write}, 'stdin_write handle was cleaed up';
ok !$rwf->{stdout_read}, 'stdout_read handle was cleaed up';

done_testing;
