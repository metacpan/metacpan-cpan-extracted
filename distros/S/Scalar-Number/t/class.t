use warnings;
use strict;

use Data::Float 0.008
	qw(have_signed_zero have_nan have_infinite significand_bits);
use Data::Integer 0.001 qw(natint_bits);
use Test::More;

do "t/num_forms.pl" or die $@ || $!;
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
plan tests => 1 + 6 + 2*$nforms;

use_ok "Scalar::Number", qw(sclnum_is_natint sclnum_is_float);

foreach my $func (\&sclnum_is_natint, \&sclnum_is_float) {
	foreach my $ozero (0, +0.0, -0.0) {
		my $nzero = $ozero;
		my $tzero = $ozero;
		$func->($tzero);
		is zpat($tzero), zpat($nzero);
	}
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
