use strict;
use warnings;
use Test::More tests => 57+8+8+6+4;
use Statistics::CaseResampling ':all';
use List::Util ('min', 'max');

# erf and erf^-1
is_approx(approx_erf(0), 0);
is_approx(approx_erf(1.), -approx_erf(-1.));
cmp_ok(approx_erf(100), '<=', 1);
cmp_ok(approx_erf(100), '>', 0.95);

is_approx(approx_erf_inv(approx_erf(0.4)), 0.4);
is_approx(approx_erf_inv(approx_erf(0.2)), 0.2);
is_approx(approx_erf_inv(approx_erf(0.6)), 0.6);
eval {approx_erf_inv(0)};
ok(!!$@);
eval {approx_erf_inv(1)};
ok(!!$@);
eval {approx_erf_inv(-1)};
ok(!!$@);
eval {approx_erf_inv(100)};
ok(!!$@);


# nsigma <-> alpha (the lazy version)
is_approx(nsigma_to_alpha(alpha_to_nsigma(0.05)), 0.05);
is_approx(nsigma_to_alpha(alpha_to_nsigma(0.01)), 0.01);
is_approx(nsigma_to_alpha(alpha_to_nsigma(0.10)), 0.10);


my $sample = [1..11];
is_approx(mean($sample), (1+2+3+4+5+6+7+8+9+10+11)/11, "mean of example is correct");
is_approx(median($sample), 6, "median of example is correct");
is_approx(median_absolute_deviation($sample), 3, "MAD of example is correct");

my $resample = resample($sample);

ok(ref($resample) && ref($resample) eq 'ARRAY');
is(scalar(@$resample), 11);
cmp_ok(min(@$resample), '>=', 1);
cmp_ok(max(@$resample), '<=', 11);

my $medians = resample_medians($sample, 30);
ok(ref($medians) && ref($medians) eq 'ARRAY');
is(scalar(@$medians), 30);
cmp_ok(min(@$medians), '>=', 1);
cmp_ok(max(@$medians), '<=', 11);

my $means = resample_means($sample, 30);
ok(ref($means) && ref($means) eq 'ARRAY');
is(scalar(@$means), 30);
cmp_ok(min(@$means), '>=', 1);
cmp_ok(max(@$means), '<=', 11);

my @tests = (
  [  [1], 1  ],
  [  [1,2], 1  ],
  [  [1,2,3], 2  ],
  [  [1,2,3,4], 2  ],
  [  [4,3,2,1], 2  ],
  [  [4,1,2,3], 2  ],
  [  [5,4,1,2,3], 3  ],
);
for my $test (@tests) {
  my ($data, $result) = @$test;
  is_approx(median($data), $result, "[@$data] has median $result");
  my $k = int(@$data/2) + (@$data & 1);
  my $kth = select_kth($data, $k);
  my $median = median($data);
  is_approx(median($data), $kth, "[@$data] median() and select_kth() agree");
}

eval {select_kth([1..10], -3)};
ok($@);
eval {select_kth([1..10], 0)};
ok($@);
eval {select_kth([1..10], 11)};
ok($@);
eval {select_kth([1..10], 10)};
ok(!$@);
eval {select_kth([1..10], 1)};
ok(!$@);

foreach my $i (1..5) {
  is_approx(select_kth([5..9], $i), $i+4, "selecting ${i}th works");
}

sub is_approx {
  cmp_ok($_[0]+1.e-9, '>=', $_[1], $_[2]);
  cmp_ok($_[0]-1.e-9, '<=', $_[1], $_[2]);
}

