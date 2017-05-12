use Test::More;
use strict; use warnings FATAL => 'all';

{ package
    BareConsumer; use strict; use warnings;
  use Moo;
  with 'MooX::Role::DependsOn';
}

my $nA = BareConsumer->new;
my $nB = BareConsumer->new;
my $nD = BareConsumer->new;
my $nE = BareConsumer->new;

ok !$nA->has_dependencies, '! has_dependencies ok';
$nA->depends_on($nB, $nD);   # A deps on B, D
ok $nA->has_dependencies,  'has_dependencies ok';

my $nC = BareConsumer->new(
  depends_on => [ $nD, $nE ] # C deps on D, E
);

$nB->depends_on($nC, $nE);   # B deps on C, E

my @deplist = $nA->depends_on;
is_deeply \@deplist,
  [ $nB, $nD ],
  'depends_on list ok'
    or diag explain \@deplist;

my @result = $nA->dependency_schedule;

is_deeply \@result,
  [ $nD, $nE, $nC, $nB, $nA ],
  'simple deps resolved ok'
    or diag explain \@result;

# resolved node cb:
my $count = 0;
my $cb = sub {
  my ($root, $state) = @_;
  ok $root == $nA, 'cb first arg ok';
  ok $state, 'cb second arg ok';
  my $node = $state->node;
  for ($count) {
    if ($_ == 0) {
      ok $node == $nD, 'got node D'; last
    }
    if ($_ == 1) {
      ok $node == $nE, 'got node E'; last
    }
    if ($_ == 2) {
      ok $node == $nC, 'got node C'; last
    }
    if ($_ == 3) {
      ok $node == $nB, 'got node B'; last
    }
    if ($_ == 4) {
      ok $node == $nA, 'got node A'; last
    }
  }
  ok ref $state->resolved_array  eq 'ARRAY', 'resolved_array ok';
  ok ref $state->unresolved_hash eq 'HASH',  'unresolved_hash ok';
  $count++
};
@result = $nA->dependency_schedule(
  resolved_callback => $cb
);
ok $count == 5, 'callback called 5 times' or diag $count;
is_deeply \@result,
  [ $nD, $nE, $nC, $nB, $nA ],
  'simple with callback resolved ok'
    or diag explain \@result;

eval {; $nA->dependency_schedule(resolved_callback => 'foo') };
like $@, qr/Expected/, 'bad callback dies ok';
eval {; $nA->dependency_schedule(resolved_callback => []) };
like $@, qr/Expected/, 'bad callback dies ok';


# circular dep:

$nD->depends_on($nB);  # D deps on B, B deps on C, C deps on D
eval {; $nA->dependency_schedule };
like $@, qr/Circular dependency/i, 'circular dep died ok';

# schedule w/ callback returning false
my $cb_called = 0;
eval {; 
  $nA->dependency_schedule(
    circular_dep_callback => sub {
      $cb_called++;
      my (undef, $state) = @_;
      ok ref $state->resolved_array eq 'ARRAY', 'resolved_array ok';
      ok ref $state->unresolved_hash eq 'HASH', 'unresolved_hash ok';
      ok $state->node->does('MooX::Role::DependsOn'), 'node ok';
      ok $state->edge->does('MooX::Role::DependsOn'), 'edge ok';
      0
    },
  );
};
ok $cb_called, 'circular dep cb called ok';
like $@, qr/Circular dependency/i, 
  'circular dep cb returning false died ok';

# schedule w/ callback returning true
eval {;
  $nA->dependency_schedule(
    circular_dep_callback => sub { 1 }
  )
};
ok !$@, 'circular dep cb returning true continued ok';

ok $nD->clear_dependencies, 'clear_dependencies ok';
ok !$nD->has_dependencies,  'cleared dependencies';

eval {; $nD->depends_on(foo => 1) };
ok $@, 'bad depends_on dies ok';

done_testing
