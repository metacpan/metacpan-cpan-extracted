use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

BEGIN {
  eval 'use Test::Memory::Cycle;1' or Mojo::Util::monkey_patch(main => memory_cycle_ok => sub { });
}

my $rwf = Mojo::IOLoop::ReadWriteFork->new;
my ($output, $exit_value, $signal, $spawn) = ('', -1, -1, 0);

memory_cycle_ok $rwf, 'no cycle after new()';

$rwf->on(error  => sub { diag $_[1] });
$rwf->on(spawn  => sub { $spawn++ });
$rwf->on(finish => sub { ($exit_value, $signal) = @_[1, 2]; Mojo::IOLoop->stop });
$rwf->on(
  read => sub {
    $_[0]->write("line one\n") unless $output;
    $output .= $_[1];
  }
);

$rwf->run_p(
  sub {
    print join(" ", @_), "\n";
    my $input = <STDIN>;
    print $input;
    print "line two\n";
    die "Oops";
  },
  qw(some args),
)->wait;

like $rwf->pid, qr{^[1-9]\d+$}, 'got pid' or diag $rwf->pid;
like $output, qr{^some args\nline one\nline two\nOops at t/run-callback\.t.* line }s, 'got stdout from callback'
  or diag $output;
is $spawn,      1,   'spawn';
is $exit_value, 255, 'exit_value';
is $signal,     0,   'signal';

memory_cycle_ok $rwf, 'no cycle after run_p has completed';

done_testing;
