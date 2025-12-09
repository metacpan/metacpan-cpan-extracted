use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Test::More;

# Benchmark tests run ONLY when TEST_BENCH=1
if (!$ENV{TEST_BENCH}) {
  plan skip_all => 'Set TEST_BENCH=1 to run benchmarks';
}

eval { require Benchmark; 1 } or plan skip_all => "Benchmark module required";
Benchmark->import(':all');

eval { require Mojo::Collection;     1 } or plan skip_all => "Mojo::Collection required";
eval { require Mojo::Collection::XS; 1 } or plan skip_all => "Mojo::Collection::XS required";

diag "Running benchmarks: Pure Perl vs Mojo::Collection vs Mojo::Collection::XS";
diag "Perl version: $^V";
diag "TEST_BENCH=1 → benchmark enabled";

my $SIZE = $ENV{BENCH_SIZE} || 200_000;
diag "Benchmark size: $SIZE items";

# Prepare data
my @data = map { {id => $_, score => ($_ * 7) % 101, flag => ($_ & 1) ? 0 : 1, name => "item$_",} } 1 .. $SIZE;

my $pure_mojo = Mojo::Collection->new(@data);        # Mojo::Collection (pure Perl)
my $xs_mojo   = Mojo::Collection::XS->new(@data);    # Mojo::Collection::XS (XS-backed)
my $pure_perl = [@data];                             # raw Perl arrayref for baselines

my $work = sub {
  my ($row) = @_;
  my $v = $row->{score};
  $v += length($row->{name});
  $v ^= ($row->{id} & 0xFF);
  $v += $row->{flag};
  return $v;
};

# Actual benchmark
diag "Running benchmark over XS helpers: while_fast, while_ultra, each_fast, map_fast, map_ultra, grep_fast";

my %benchmarks = (
  perl_for_sum => sub {    # pure Perl baseline
    my $sum = 0;
    $sum += $work->($_) for @$pure_perl;
    return $sum;
  },
  perl_map_size => sub {    # pure Perl map baseline
    my $out = [map { $work->($_) } @$pure_perl];
    return scalar @$out;
  },
  perl_grep_even_size => sub {    # pure Perl grep baseline
    my $out = [grep { ($work->($_) & 1) == 0 } @$pure_perl];
    return scalar @$out;
  },
  mojo_each_sum => sub {          # Mojo::Collection (pure Perl impl)
    my $sum = 0;
    $pure_mojo->each(sub { $sum += $work->($_[0]) });
    return $sum;
  },
  xs_each_fast_sum => sub {       # XS each_fast
    my $sum = 0;
    $xs_mojo->each_fast(sub { $sum += $work->($_[0]) });
    return $sum;
  },
  xs_while_fast_sum => sub {      # XS while_fast
    my $sum = 0;
    $xs_mojo->while_fast(sub { $sum += $work->($_[0]) });
    return $sum;
  },
  xs_while_ultra_sum => sub {     # XS while_ultra
    my $sum = 0;
    $xs_mojo->while_ultra(sub { my ($e) = @_; $sum += $work->($e) });
    return $sum;
  },
  mojo_map_list => sub {          # Mojo::Collection map (list)
    my $out = $pure_mojo->map(sub { $work->($_[0]) });
    return $out->size;
  },
  xs_map_fast_list => sub {       # XS map_fast (list)
    my $out = $xs_mojo->map_fast(sub { $work->($_[0]) });
    return $out->size;
  },
  mojo_map_scalar => sub {        # Mojo::Collection map (scalar-ish)
    my $out = $pure_mojo->map(sub { $work->($_[0]) + 1 });
    return $out->size;
  },
  xs_map_ultra_scalar => sub {    # XS map_ultra
    my $out = $xs_mojo->map_ultra(sub { my ($e) = @_; $work->($e) + 1 });
    return $out->size;
  },
  mojo_grep_even => sub {         # Mojo::Collection grep
    my $out = $pure_mojo->grep(sub { ($work->($_[0]) & 1) == 0 });
    return $out->size;
  },
  xs_grep_fast_even => sub {      # XS grep_fast
    my $out = $xs_mojo->grep_fast(sub { my ($e) = @_; ($work->($e) & 1) == 0 });
    return $out->size;
  },
);

diag "Benchmarks: " . join(', ', sort keys %benchmarks);

my $results = timethese($ENV{BENCH_COUNT} || -3, \%benchmarks);

cmpthese($results);

pass "Benchmark executed successfully";

done_testing;
