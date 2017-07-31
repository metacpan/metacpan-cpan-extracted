use warnings;
use strict;

BEGIN { unshift @INC, "./t/lib"; }
use Data::Float 0.008
	qw(have_signed_zero have_nan have_infinite significand_bits);
use Data::Integer 0.001 qw(natint_bits);
use Test::More;
use t::NumForms qw(zpat zero_forms natint_forms float_forms);

my @all_zeroes = zero_forms();

my @tests;
push @tests, [ 0, 1, [ float_forms("nan") ] ] if have_nan;
open(TEST_VALS, "<", "t/values.data") or die "t/values.data: $!";
while(1) {
	$_ = <TEST_VALS>;
	die "t/values.data: $!" unless defined $_;
	chomp;
	last if $_ eq "_";
	next if $_ eq "";
	if($_ eq "z") {
		if(have_signed_zero) {
			push @tests,
				[ 1, 0, [ natint_forms("0") ] ],
				[ 0, 1, [ float_forms("+0") ] ],
				[ 0, 1, [ float_forms("-0") ] ];
		} else {
			push @tests, [ 1, 1,
				[ natint_forms("0"), float_forms("0") ] ];
		}
		next;
	}
	/\A(?:I+|i([0-9]+)"([^"]+)")=f(\*|[0-9]+)"([^"]+)"\z/
		or die "t/values.data: malformed line [$_]";
	my($isz, $ihex, $fsz, $fhex) = ($1, $2, $3, $4);
	my $igood = defined($isz) && natint_bits >= $isz;
	my $fgood = $fsz eq "*" ? have_infinite : significand_bits >= $fsz;
	my @forms;
	push @forms, natint_forms($ihex) if $igood;
	push @forms, float_forms($fhex) if $fgood;
	push @tests, [ $igood, $fgood, \@forms ] if @forms;
}

my $nforms = 0;
$nforms += @{$_->[2]} foreach @tests;
plan tests => 1 + 3*@all_zeroes + 2*$nforms;

use_ok "Scalar::Number", qw(sclnum_is_natint sclnum_is_float);

foreach my $ozero (@all_zeroes) {
	my $izero = $ozero;
	my $fzero = $ozero;
	my $isi = sclnum_is_natint($izero);
	my $isf = sclnum_is_float($fzero);
	ok $isi || $isf;
	my $nzero = $ozero;
	my $pat = zpat($nzero);
	is zpat($izero), $pat;
	is zpat($fzero), $pat;
}

foreach(@tests) {
	my($igood, $fgood, $forms) = @$_;
	foreach(@$forms) {
		my $desc = eval { sprintf(" of %s (%.1f)",
				my $sval = $_, my $fval = $_) } || "";
		is !!sclnum_is_natint(my $i = $_), !!$igood,
			"integer status$desc";
		is !!sclnum_is_float(my $f = $_), !!$fgood,
			"float status$desc";
	}
}

1;
