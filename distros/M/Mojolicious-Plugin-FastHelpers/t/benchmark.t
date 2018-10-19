use Mojo::Base -strict;
use Test::More;
use Benchmark qw(cmpthese timeit timestr :hireswallclock);
use Mojolicious;

plan skip_all => 'TEST_BENCHMARK=10000' unless my $n_times = $ENV{TEST_BENCHMARK};

my %tests = (App => app());
my %res;

$tests{Ctrl} = $tests{App}->build_controller;

for my $plugin (qw(Normal FastHelpers)) {
  $tests{App}->plugin($plugin) if $plugin eq 'FastHelpers';
  for my $part (sort keys %tests) {
    my $name = join '::', $part, $plugin;
    my $obj  = $tests{$part};
    my $res  = 0;
    $res{$name} = timeit $n_times, sub { $res += $obj->dummy };
    is $res, 42 * $n_times, sprintf '%s %s', $name, timestr $res{$name};
  }
}

compare(qw(App::FastHelpers App::Normal));
compare(qw(Ctrl::FastHelpers Ctrl::Normal));
cmpthese(\%res) if $ENV{HARNESS_IS_VERBOSE};

done_testing;

sub app {
  my $app = Mojolicious->new;
  $app->helper(dummy => sub {42});
  $app;
}

sub compare {
  my ($an, $bn) = @_;
  return diag "Cannot compare $an and $bn" unless my $ao = $res{$an} and my $bo = $res{$bn};
  ok $ao->cpu_a <= $bo->cpu_a, sprintf '%s (%ss) is not slower than %s (%ss)', $an, $ao->cpu_a, $bn, $bo->cpu_a;
}
