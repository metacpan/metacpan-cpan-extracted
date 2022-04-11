use strict;
use warnings;
use PDL::LiteF;
use PDL::MatrixOps qw(identity);
use PDL::Complex;
use PDL::LinearAlgebra;
use PDL::LinearAlgebra::Trans qw //;
use PDL::LinearAlgebra::Complex;
use Test::More;

sub fapprox {
	my($a,$b) = @_;
	($a-$b)->abs->max < 0.001;
}
# PDL::Complex only
sub runtest {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($in, $method, $expected_cplx, $extra) = @_;
  $expected_cplx = $expected_cplx->[1] if ref $expected_cplx eq 'ARRAY';
  my @cplx = ref($expected_cplx) eq 'ARRAY' ? @$expected_cplx : $expected_cplx;
  $_ = PDL::Complex::r2C($_) for $in;
  my ($got) = $in->$method(map ref() && ref() ne 'CODE' ? PDL::Complex::r2C($_) : $_, @{$extra||[]});
  my $ok = grep fapprox($got, PDL::Complex::r2C($_)), @cplx;
  ok $ok, "PDL::Complex $method" or diag "got(".ref($got)."):$got\nexpected:@cplx";
}

my $aa = cplx random(2,2,2);
runtest($aa, 't', $aa->xchg(1,2));

$aa = sequence(2,2,2)->cplx + 1;
runtest($aa, '_norm', my $aa_exp = PDL::Complex->from_native(pdl <<'EOF'));
[
 [0.223606+0.223606i 0.670820+0.670820i]
 [0.410997+0.410997i 0.575396+0.575396i]
]
EOF
runtest($aa, '_norm', $aa_exp->abs, [1]);
runtest($aa, '_norm', $aa_exp->t, [0,1]);

do './t/common.pl'; die if $@;

done_testing;
