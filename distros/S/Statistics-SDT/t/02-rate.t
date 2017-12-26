use strict;
use warnings;
use Test::More tests => 17;
use constant EPS => 1e-9;

BEGIN { use_ok('Statistics::SDT') };

my $sdt = Statistics::SDT->new(
	correction => 1,
  	precision_s => 2,
);
isa_ok($sdt, 'Statistics::SDT');

my %counts = (  hits => 50,
  	signal_trials => 50,
	false_alarms => 17,
  	noise_trials => 25,);

eval {
    $sdt->init(
    %counts
    );
};
ok(!$@);


my %refvals = (
    hr => .99,
    far => .68,
);

my $v;

# get rates from class object given sufficient counts?:
foreach (qw/hr far/) {
    ok(defined $sdt->{$_} );
    ok(about_equal($sdt->{$_}, $refvals{$_}));
}

# convert given count data to rates via sensitivity and criterion:
$v = $sdt->dc2hr();
ok( about_equal($v, $refvals{'hr'}), "Hr $v = $refvals{'hr'}");

$v = $sdt->dc2far();
ok( about_equal($v, $refvals{'far'}), "FAr $v = $refvals{'far'}");

# set & get rates by rate() method given proportions:
$sdt->clear();

foreach (qw/hr far/) {
    eval { $sdt->rate($_ => $refvals{$_});};
    ok(!$@);
    ok(about_equal($sdt->rate($_), $refvals{$_}));
}

# set & get rates by rate() method given counts:
foreach (qw/hr far/) {
    $sdt->clear();
    eval { $sdt->rate($_ => \%counts);};
    ok(!$@);
    ok(about_equal($sdt->rate($_), $refvals{$_}));
}

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}

1;