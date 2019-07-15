use Mojo::Base -strict;
use Benchmark qw(cmpthese timeit :hireswallclock);
use Mojo::Promisify qw(promisify promisify_call);
use Test::More;

# This is not really a test. It's just for getting information about speed.
# Usage:
# TEST_BENCHMARK=20000 prove -vl t/benchmark.t

plan skip_all => 'TEST_BENCHMARK=5000'
  unless my $n_times = $ENV{TEST_BENCHMARK};

package Some::NonBlockingClass;
use Mojo::Base -base;

sub get_stuff_by_id {
  my ($self, $id, $cb) = @_;
  Mojo::IOLoop->next_tick(sub { $self->$cb($self->{err}, $id) });
  die 'Yikes!' unless $id;
  return $self;
}

Mojo::Promisify::promisify_patch(__PACKAGE__, 'get_stuff_by_id');

package main;

my $nb_obj = Some::NonBlockingClass->new;
my $called = 0;
my %t;

my $compiled_cb = promisify $nb_obj, 'get_stuff_by_id';
$t{code}  = run_p(sub { $compiled_cb->(@_) });
$t{call}  = run_p(sub { promisify_call($nb_obj, 'get_stuff_by_id', @_) });
$t{patch} = run_p(sub { $nb_obj->get_stuff_by_id_p(@_) });

$t{original} = timeit(
  $n_times,
  sub {
    $nb_obj->get_stuff_by_id(42, sub { $called++; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
  }
);

$t{promise} = timeit(
  $n_times,
  sub {
    Mojo::Promise->new->resolve(42)->then(sub { $called++ })->wait;
  }
);

cmpthese(\%t) if $ENV{HARNESS_IS_VERBOSE};

is $called, $n_times * 5, "called $called";
done_testing;

sub run_p {
  my $time_cb = shift;
  return timeit(
    $n_times,
    sub {
      $time_cb->(42)->then(sub { $called++ })->wait;
    }
  );
}
