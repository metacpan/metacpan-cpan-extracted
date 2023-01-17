BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Mojo::Base -strict;
use Mojo::Run3;
use Test::Mojo;
use Test::More;
use version;

plan skip_all => 'TEST_LSOF=1' unless $ENV{TEST_LSOF};

eval 'use Test::Memory::Cycle;1' or Mojo::Util::monkey_patch(
  main => memory_cycle_ok => sub {
    skip 'Test::Memory::Cycle';
  }
);

my @drivers = qw(pipe pty);
my $initial = lsof();
my $todo    = version->parse($^V)->numify < 5.026 ? "Perl $^V" : undef;

for my $driver (@drivers) {
  subtest $driver => sub {
    is lsof(), $initial, 'lsof before new';
    my $run3   = Mojo::Run3->new(driver => $driver);
    my $stdout = '';
    $run3->on(stderr => sub { diag "STDERR <<< $_[1]" });
    $run3->on(stdout => sub { $stdout .= $_[1] });
    $run3->run_p(sub { print lsof() })->wait;
    memory_cycle_ok($run3, 'memory cycle');

    local $TODO = $todo;
    is $stdout, $initial + 3, 'lsof in child';
    is lsof(),  $initial,     'lsof after run';
    undef $run3;
    is lsof(), $initial, 'lsof after undef';
  };
}

subtest 'force run3 out of scope' => sub {
  my $run3 = Mojo::Run3->new(driver => 'pty');
  $run3->on(stdout => sub { Mojo::IOLoop->stop });
  $run3->start(sub { print 'started'; sleep 2 });
  Mojo::IOLoop->start;
  my $pid = $run3->pid;
  undef $run3;

  local $TODO = $todo;
  is lsof(), $initial, 'lsof after undef';
  Mojo::Promise->timer(0.1)->wait;
  is kill(0 => $pid), 0, 'killed nothing' or diag "kill $pid ($$)";
};

subtest 'close other' => sub {
  my $run3 = Mojo::Run3->new;
  my %read = (stderr => '', stdout => '');
  $run3->on(stderr => sub { $read{stderr} .= $_[1] });
  $run3->on(stdout => sub { $read{stdout} .= $_[1] });

  $run3->run_p(sub {
    my ($run3) = @_;
    system "lsof -p $$ | grep 'PIPE\\|FIFO' | grep $$ | wc -l 1>&2";
    $run3->close('other');
    system "lsof -p $$ | grep 'PIPE\\|FIFO' | grep $$ | wc -l";
  })->wait;

  chomp $read{stderr};
  chomp $read{stdout};

  ok $read{stderr} > $read{stdout}, 'before close other';
  like $read{stdout}, qr{^4\b}, 'after close other';
};

done_testing;

sub lsof {
  my $n = qx{lsof -p $$ | wc -l};
  return $n =~ m!(\d+)! ? $1 : -1;
}
