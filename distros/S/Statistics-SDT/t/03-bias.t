use strict;
use warnings;
use Test::More tests => 8;
use constant EPS => 1e-9;

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
	d => 1.86,
    beta => .07,
    logbeta => -2.6,
    cdecision => -1.4,
    griers => -.91,
);

my $v;

foreach (qw/beta logbeta cdecision griers/) {
	$v = $sdt->bias($_);
    ok( about_equal($v, $refvals{$_}), "Bias $_ $v = $refvals{$_}");
}

$v = $sdt->dc2logbeta();
ok( about_equal($v, $refvals{'logbeta'}), "Logbeta $v = $refvals{'logbeta'}");

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;