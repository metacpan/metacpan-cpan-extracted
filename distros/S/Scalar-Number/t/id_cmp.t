use warnings;
use strict;

use Data::Float 0.008 qw(have_signed_zero have_nan have_infinite);
use Test::More;

do "t/num_forms.pl" or die $@ || $!;
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
plan tests => 1 + $nforms*$nforms;

use_ok "Scalar::Number", qw(sclnum_id_cmp);

for(my $ia = @values; $ia--; ) { foreach my $va (@{$values[$ia]}) {
	for(my $ib = @values; $ib--; ) { foreach my $vb (@{$values[$ib]}) {
		my($ta, $tb) = ($va, $vb);
		is sclnum_id_cmp($ta, $tb), ($ia <=> $ib),
			"id[$ia] <=> id[$ib]";
	} }
} }

1;
