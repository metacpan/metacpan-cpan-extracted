use strict;
use warnings;
use Test::More tests => 2;
use constant EPS => 1e-9;

use Statistics::SDT;

my $sdt = Statistics::SDT->new(
	correction => 1,
  	precision_s => 2,
);

my %vals = (
    criterion => -.47,
    hr => .99,
    far => .68,
);

my $v;

$sdt->init(
      hits => 50,
  	signal_trials => 50,
	false_alarms => 17,
  	noise_trials => 25,
    );

$v = $sdt->criterion();
ok( about_equal($v, $vals{'criterion'}), "Criterion k $v = $vals{'criterion'}");

$v = $sdt->criterion(far => $vals{'far'});
ok( about_equal($v, $vals{'criterion'}), "Criterion k $v = $vals{'criterion'}");

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;