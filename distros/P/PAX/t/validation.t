use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAX::Differential;
use PAX::Benchmark;

my $pax = "$FindBin::Bin/../bin/pax";
my $fixture = "$FindBin::Bin/fixtures/simple.pl";

my $diff = PAX::Differential->new(pax_bin => $pax)->compare_capture($fixture);
ok($diff->{pass}, 'differential capture passes for simple fixture');
is($diff->{comparison}{stock_exit}, 0, 'stock Perl exits cleanly');
is($diff->{comparison}{pax_exit}, 0, 'PAX capture exits cleanly');

my $bench = PAX::Benchmark->new(pax_bin => $pax, iterations => 1)->run_capture_benchmark($fixture);
is($bench->{benchmark_class}, 'capture_overhead', 'benchmark class recorded');
is($bench->{iterations}, 1, 'benchmark iterations recorded');
ok($bench->{mean_seconds} >= 0, 'benchmark mean recorded');
ok(ref $bench->{memory_impact} eq 'HASH', 'capture benchmark records memory impact');
ok(exists $bench->{memory_impact}{delta_rss_kb}, 'capture benchmark records memory delta field');

my $runtime = PAX::Benchmark->new(pax_bin => $pax, iterations => 1)->run_runtime_benchmark($fixture);
is($runtime->{benchmark_class}, 'runtime', 'runtime benchmark class recorded');
ok(defined $runtime->{reference_mean_seconds}, 'reference timing recorded');
ok(defined $runtime->{capture_mean_seconds}, 'capture timing recorded');
ok(exists $runtime->{native_available}, 'native availability recorded');
ok(ref $runtime->{memory_impact} eq 'HASH', 'runtime benchmark records memory impact');

done_testing;

=pod

=head1 NAME

t/validation.t - regression coverage for top-level validation and gate-oriented acceptance behavior

=head1 DESCRIPTION

This test exercises top-level validation and gate-oriented acceptance behavior. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for top-level validation and gate-oriented acceptance behavior. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/validation.t

=head1 WHY IT EXISTS

PAX uses this test to keep top-level validation and gate-oriented acceptance behavior from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
