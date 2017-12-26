use strict;
use warnings;
use Test::More tests => 6;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::SDT') };

my $sdt = Statistics::SDT->new(
	correction => 1,
  	precision_s => 2,
);
isa_ok($sdt, 'Statistics::SDT');

eval {
    $sdt->init(
      hits => 50,
  	signal_trials => 50,
	false_alarms => 17,
  	noise_trials => 25,
    );
};
ok(!$@);


my %refvals = (
	dprime => 1.86,
	Ad => .91,
	Ap => .82,
);

my $v;

foreach (qw/dprime Ad Ap/) {
	$v = $sdt->sens($_);
    ok( about_equal($v, $refvals{$_}), "Sensitivity $_ : $v = $refvals{$_}");
}

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}

1;