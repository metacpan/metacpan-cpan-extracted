use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

BEGIN {
  eval 'use Test::Memory::Cycle;1' or Mojo::Util::monkey_patch(main => memory_cycle_ok => sub { });
}

my $fork = Mojo::IOLoop::ReadWriteFork->new;
my ($output, $exit_value, $signal, $spawn) = ('', -1, -1, 0);

memory_cycle_ok $fork, 'no cycle after new()';

$fork->on(error  => sub { diag $_[1] });
$fork->on(spawn  => sub { $spawn++ });
$fork->on(finish => sub { ($exit_value, $signal) = @_[1, 2]; Mojo::IOLoop->stop });
$fork->on(
  read => sub {
    memory_cycle_ok $fork, 'no cycle inside read' unless $output;
    $fork->write("line one\n") unless $output;
    $output .= $_[1];
  }
);

memory_cycle_ok $fork, 'no cycle after on()';

$fork->run_p(
  sub {
    print join(" ", @_), "\n";
    my $input = <STDIN>;
    print $input;
    print "line two\n";
    die "Oops";
  },
  qw(some args),
)->wait;

memory_cycle_ok $fork, 'no cycle after Mojo::IOLoop->start';

like $fork->pid, qr{^[1-9]\d+$}, 'got pid' or diag $fork->pid;
like $output, qr{^some args\nline one\nline two\nOops at t/run-callback\.t.* line }s, 'got stdout from callback'
  or diag $output;
is $spawn,      1,   'spawn';
is $exit_value, 255, 'exit_value';
is $signal,     0,   'signal';

done_testing;
