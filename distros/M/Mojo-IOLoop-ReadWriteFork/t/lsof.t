BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::Mojo;
use Test::More;

plan skip_all => 'TEST_LSOF=1' unless $ENV{TEST_LSOF};

eval 'use Test::Memory::Cycle;1' or Mojo::Util::monkey_patch(main => memory_cycle_ok => sub { });

my %tests   = (pipe => 3, pty => 2, pty3 => 3);
my $initial = lsof();

for my $type (sort keys %tests) {
  is lsof(), $initial, "$type before";
  my $rwf = Mojo::IOLoop::ReadWriteFork->new(conduit => {stderr => 1, stdout => 1, type => $type});
  my ($asset, $err);
  $rwf->on(stderr => sub { note "[ERR] $_[1]" });
  $rwf->run_and_capture_p(sub { print lsof() })->then(sub { $asset = shift })->catch(sub { $err = shift })->wait;
  last unless is $err,          undef,                    "$type success";
  last unless is $asset->slurp, $initial + $tests{$type}, "$type run_p";
  is lsof(), $initial, "$type after run";
  undef $rwf;
  is lsof(), $initial, "$type after undef";
  memory_cycle_ok($rwf, 'memory cycle after');
}

is lsof(), $initial, "all done ($initial)";

done_testing;

sub lsof {
  my $n = qx{lsof -p $$ | wc -l};
  return $n =~ m!(\d+)! ? $1 : -1;
}
