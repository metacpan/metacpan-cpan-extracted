use strict;
use warnings;
use Test::More tests => 10;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::SDT') };

my $sdt = Statistics::SDT->new(
	correction => 1,
  	precision_s => 2,
);
isa_ok($sdt, 'Statistics::SDT');

my $v;

# from Alexander's Table 1: m => p(correct) : d' should = 2
my %ref_d = (
    2 => .921,
    3 => .866,
    4 => .823,
    8 => .711,
    16 => .595,
);
for my $m(keys %ref_d){
    $v = $sdt->sens('f' => {hr => $ref_d{$m}, alternatives => $m, correction => 0, method => 'alexander'});
    ok( about_equal($v, 2), "Sensitivity $m-afc $v = 2 not $ref_d{$m}");
    $sdt->clear();
}

# by initialising counts rather than giving hr:
$sdt->clear();
$sdt->init(
    hits => 866,
  	signal_trials => 1000,
	#false_alarms => 0,
  	#noise_trials => 0,
    );
$v = $sdt->sens('f' => {alternatives => 3, correction => 0, method => 'alexander'});
ok( about_equal($v, 2), "Sensitivity fc $v = 2");

# Smith method:
$sdt->clear();
$v = $sdt->sens('f' => {hr => .866, alternatives => 3, correction => 0, method => 'smith'});
ok( about_equal($v, 2.05), "Sensitivity fc $v = 2.05");

# test n >= 12:
$v = $sdt->sens('f' => {hr => 1/13, alternatives => 13, correction => 0, method => 'smith'});
ok( about_equal($v, 0), "Sensitivity fc $v != 0");

# with corrections:
#$sdt->clear();
#$sdt->init(hr => 1, correction => 2, far => 0);
#diag("d ", $sdt->sens('d'));

#$v = $sdt->sens('pcorrect');
#diag($v);
#$v = $sdt->sens('lpcorrect');
#diag($v);

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}

1;