# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Numeric-Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use Config;
use Test::More;
my $skips;
BEGIN {
  my $miss_d = -f "t/sinl.t" ? '.' : '..';
  $skips = do {local $/; open F, "$miss_d/miss.miss" and scalar <F>};
  close F;
  if ($skips =~ /\b (sinl|logl) \b/x) {
    plan skip_all => "I could not find $1() in your headers" ;
  } elsif (not $Config{d_longdbl}) {
    plan skip_all => 'I could not find long double support in your Perl' ;
  } else {
    plan tests => 4 ;
  }
  $skips =~ s/\s*\Z//;
  warn "build detected the following missing features: $skips\n" if $skips;
  use_ok('Numeric::LL_Array',
    qw( packId_d d2D1_assign access_D D0_sin D0_cbrt))
};

my $d3  = pack packId_d, 3;
my $dd3 = ' ' x ($Config{longdblsize} || 16);	# pack 'D' may be missing
d2D1_assign($d3, $dd3, 0, 0, 0, "", "");
D0_sin($dd3);
ok(abs(access_D($dd3) - sin 3) < 1e-15 , '... sinl(3) correct');

if (0) {	# even trunc() may be missing...
  $d3  = pack packId_d, -33.7;
  d2D1_assign($d3, $dd3, 0, 0, 0, "", "");
  D0_trunc($dd3);
  is(access_D($dd3), -33, '... trunc(-33.7) correct');
}

$d3  = pack packId_d, 1.331e-3;
d2D1_assign($d3, $dd3, 0, 0, 0, "", "");
D0_cbrt($dd3);
ok(abs(access_D($dd3) - 0.11) < 1e-15 , '... cbrt(1.331e-3) correct');

$d3  = pack packId_d, -1.331e-3;
d2D1_assign($d3, $dd3, 0, 0, 0, "", "");
D0_cbrt($dd3);
ok(abs(access_D($dd3) + 0.11) < 1e-15 , '... cbrt(-1.331e-3) correct');

