use warnings;
use strict;

BEGIN { unshift @INC, "./t/lib"; }
use Data::Float 0.008 qw(have_signed_zero have_nan have_infinite);
use Test::More;
use t::NumForms qw(zpat zero_forms natint_forms float_forms);

my @zeroes = zero_forms();
my @values = (
	have_nan ? [ float_forms("nan") ] : [],
	have_infinite ? [ float_forms("-inf") ] : [],
	[ float_forms("-0x1p+130") ],
	[ natint_forms("-0x401"), float_forms("-0x1.004p+10") ],
	[ float_forms("-0x1.edp+6") ],
	[ natint_forms("-0x1"), float_forms("-0x1p+0") ],
	[ float_forms("-0x1.1p-3") ],
	have_signed_zero ? [ float_forms("-0") ] : [],
	have_signed_zero ? [ natint_forms("0") ] : [ natint_forms("0"), float_forms("0") ],
	have_signed_zero ? [ float_forms("+0") ] : [],
	[ float_forms("+0x1.1p-3") ],
	[ natint_forms("+0x1"), float_forms("+0x1p+0") ],
	[ float_forms("+0x1.edp+6") ],
	[ natint_forms("+0x401"), float_forms("+0x1.004p+10") ],
	[ float_forms("+0x1p+130") ],
	have_infinite ? [ float_forms("+inf") ] : [],
);

my $nforms = 0;
$nforms += @$_ foreach @values;
plan tests => 1 + 4*@zeroes*$nforms + $nforms*$nforms;

use_ok "Scalar::Number", qw(sclnum_id_cmp);

foreach my $vz (@zeroes) {
	my $pz = zpat($vz);
	for(my $ib = @values; $ib--; ) { foreach my $vb (@{$values[$ib]}) {
		my($tz, $tb) = ($vz, $vb);
		my $c0 = sclnum_id_cmp($tz, $tb);
		is zpat($tz), $pz;
		($tz, $tb) = ($vz, $vb);
		my $c1 = sclnum_id_cmp($tb, $tz);
		is zpat($tz), $pz;
		is $c0, -$c1;
		if($ib < 7) {
			is $c0, 1;
		} elsif($ib == 7) {
			cmp_ok $c0, ">=", 0;
		} elsif($ib == 8) {
			ok 1;
		} elsif($ib == 9) {
			cmp_ok $c0, "<=", 0;
		} else {
			is $c0, -1;
		}
	} }
}

for(my $ia = @values; $ia--; ) { foreach my $va (@{$values[$ia]}) {
	for(my $ib = @values; $ib--; ) { foreach my $vb (@{$values[$ib]}) {
		my($ta, $tb) = ($va, $vb);
		is sclnum_id_cmp($ta, $tb), ($ia <=> $ib),
			"id[$ia] <=> id[$ib]";
	} }
} }

1;
