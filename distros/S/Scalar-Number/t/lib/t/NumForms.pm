package t::NumForms;

use warnings;
use strict;

use Data::Float 0.008;
use Data::Integer 0.003;

use parent "Exporter";
our @EXPORT_OK = qw(zpat zero_forms natint_forms float_forms);

sub zpat($) {
	my($z) = @_;
	my $p = "";
	foreach(0..5) {
		$p .= sprintf("%+.f", my $zc = $z);
		$z = -$z;
	}
	return $p;
}

my @zero_strings = map { $_, " $_" } map { $_, "+$_", "-$_" } qw(0 0.0 00);
push @zero_strings, "0 but true";

sub zero_forms() {
	my $ival = Data::Integer::hex_natint("0");
	{ no warnings "void"; use integer; $ival + 0; }
	my @forms = ($ival);
	foreach my $hex ("+0", "-0") {
		my $fval = Data::Float::hex_float($hex);
		my $ival = $fval;
		{ no warnings "void"; use integer; $ival + 0; }
		push @forms, $fval, $ival;
	}
	return (@forms, @zero_strings);
}

sub natint_forms($) {
	my($hex) = @_;
	my $ival = Data::Integer::hex_natint($hex);
	{ no warnings "void"; use integer; $ival + 0; }
	my @forms = ($ival);
	if($] >= 5.008 || Data::Integer::natint_bits <= 32) {
		my $sval = "$ival";
		push @forms, $sval;
	}
	if($] >= 5.008) {
		my $fval = $ival;
		{ no warnings "void"; $fval + 0.5; }
		push @forms, $fval;
	}
	if((my $t = $ival) == 0) {
		push @forms, @zero_strings;
		@forms = grep { zpat($_) eq "+0+0+0+0+0+0" } @forms;
	}
	return @forms;
}

sub float_forms($) {
	my($hex) = @_;
	my $fval = Data::Float::hex_float($hex);
	my $class = Data::Float::float_class($fval);
	if($class eq "INFINITE" || $class eq "NAN") {
		$fval = $fval + 0.5;
	} elsif($class ne "ZERO") {
		my(undef, $expt, undef) = Data::Float::float_parts($fval);
		if($expt == Data::Float::max_finite_exp) {
			$fval = ($fval * 0.5) * 2.0;
		} else {
			$fval = ($fval * 2.0) * 0.5;
		}
	}
	my $ival = $fval;
	{ no warnings "void"; use integer; $ival + 0; }
	my @forms = ($fval, $ival);
	if($class eq "ZERO") {
		push @forms, @zero_strings;
		my $flavour = zpat($fval);
		@forms = grep { zpat($_) eq $flavour } @forms;
	}
	return @forms;
}

1;
