use warnings;
use strict;

use Data::Float 0.008;
use Data::Integer 0.003;

sub zpat($) { my($z) = @_; my $nz = -$z; sprintf("%+.f%+.f%+.f",$z,$nz,-$nz) }

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
		push @forms, "0", "0.0", "+0", "+0.0", "-0", "-0.0";
		@forms = grep { zpat($_) eq "+0+0+0" } @forms;
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
		push @forms, "0", "0.0", "+0", "+0.0", "-0", "-0.0";
		my $flavour = zpat($fval);
		@forms = grep { zpat($_) eq $flavour } @forms;
	}
	return @forms;
}

1;
