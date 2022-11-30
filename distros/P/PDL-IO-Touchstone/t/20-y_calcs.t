#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone qw/rsnp
	s_to_y
	s_port_z
	s_to_abcd
	abcd_to_s
	y_inductance
	y_capacitance
	y_resistance
	y_reactance_l
	y_reactance_c
	y_reactance
	y_qfactor_l
	y_qfactor_c
	y_parallel
	y_srf
	y_srf_ideal
	abcd_series
	/;
use File::Temp qw/tempfile/;

use Test::More tests => 263;

my $tolerance = 1e-3;

my $datadir = 't/test-data/muRata';

# These L/C values have been validated against the muRata SimSurfing site.
# Other measurements have beeen spot-checked and these look right, or at
# least within a reasonable tolerance of "correct":
my %s2p_values = (
	'cap-muRata-GRM1555CYA103GE01_10nF_35v.s2p' =>
		{ cap => 9.86204915004454e-09, ind => -2.5684616424455e-06, esr => 0.00312989514151146,
			Qc => 5156.12195656487, Ql => 0, Xc => 16.138121060893, Xl => -16.1381204538679,
			srf_last => 84500083.4204751 },
	'cap-muRata-GRM155R61C105KA12_1uF_16v.s2p' =>
		{ cap => 5.27691542731619e-07, ind => -4.78624758379708, esr => 162.419882220304,
			Qc => 18.5695255028615, Ql => 0, Xc => 3016.06014506169, Xl => -3007.28804950376,
			srf_last => 11891693.0572848 },
	'ferrite-muRata-BLM15BD182SN1_0402_1800Z_100MHz.s2p' =>
		{ cap => -1.412701071101e-08, ind => 1.7773393864684e-06, esr => 1.04960036949916,
			Qc => 0, Ql => 10.6396234637937, Xc => -11.2660028613029, Xl => 11.1673527189298,
			srf_last => 129524272.673402  },
	'ferrite-muRata-NFZ32BW881HN10_1210_880Z_1MHz.s2p' =>
		{ cap => -1.88228254545831e-10, ind => 0.000134510356259619, esr => 18.1263321333963,
			Qc => 0, Ql => 46.6257314438592, Xc => -845.54225653271, Xl => 845.153494113932,
			srf_last => 11267541.843421 },
	'ind-choke-muRata-LQW15CA22NJ00.s2p' =>
		{ cap => -1.12737540087989e-08, ind => 2.23030799220735e-08, esr => 0.120641109671948,
			Qc => 0, Ql => 11.6158069543859, Xc => -1.41172978377636, Xl => 1.40134384071225,
			srf_last => undef },
	'ind-choke-muRata-LQW15CA2R0K00.s2p' =>
		{ cap => -1.17609717726732e-10, ind => 2.1405746899325e-06, esr => 10.5552789050037,
			Qc => 0, Ql => 12.7420862695809, Xc => -135.324653581513, Xl => 134.496274407044,
			srf_last => 154301731.110681 },
	'ind-choke-muRata-LQW15DN150M00.s2p' =>
		{ cap => 2.27795350681818e-13, ind => -3.54463946754354e-05, esr => 5621.38551154572,
			Qc => 2.4857754896787, Ql => 0, Xc => 13973.5023226353, Xl => -11135.8133108592,
			srf_last => 14602319483.5286 },
	'ind-muRata-LQW15AN3N8C10.s2p' =>
		{ cap => -2.83659488151797e-09, ind => 3.56543038788561e-09, esr => 0.047824416542393,
			Qc => 0, Ql => 23.42136239872, Xc => -1.1221549057208, Xl => 1.12011299134672,
			srf_last => 14385226226.8994 },
	'ind-muRata-LQW15AN9N9G00.s2p' =>
		{ cap => -1.03637818004319e-09, ind => 9.73643877575246e-09, esr => 0.196128109773235,
			Qc => 0, Ql => 15.5958901380311, Xc => -3.07136808081511, Xl => 3.05879245300307,
			srf_last => 7554317730.63135 },

);

opendir(my $dir, $datadir) or die "$datadir: $!";

my @files = map { "$datadir/$_" } sort keys(%s2p_values);
closedir($dir);

foreach my $fn (@files, @ARGV)
{
	my ($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_f_unit) = rsnp($fn);

	next unless $param_type eq 'S';

	#print "===== $fn =====\n";

	my $S = $m;

	my $Y = s_to_y($S, $z0);
	my $ABCD = s_to_abcd($S, $z0);

	# basename:
	$fn =~ s!.*/!!;

	# Compare calculated values to reference values:
	my %vals = build_vals($Y, $f);
	my $ref_vals = $s2p_values{$fn};

	foreach my $v (sort keys %$ref_vals)
	{
		my $value = $vals{$v} // '(undef)';
		verify_one($ref_vals->{$v}, $vals{$v}, "$fn: $v=$value");
	}

	# Parallel and series calculations on ferrite beads don't always behave
	# like parallel inductors or caps so skip the parallel/serial tests:
	next if ($fn =~ /ferrite/);

	# Test that parallel and series is working:
	my $pp = y_parallel($Y, $Y);
	my $ss = abcd_series($ABCD, $ABCD);

	my %pp_vals = build_vals($pp, $f);
	my %ss_vals = build_vals($ss, $f);

	if ($vals{cap} > 0)
	{
		verify_one($pp_vals{cap}, $vals{cap}*2, "$fn: cap: parallel");
		verify_one($ss_vals{cap}, $vals{cap}/2, "$fn: cap: series");

		ok($vals{Qc} > 0, "$fn: capacitive reactance");
	}

	if ($vals{ind} > 0)
	{
		verify_one($pp_vals{ind}, $vals{ind}/2, "$fn: ind: parallel");
		verify_one($ss_vals{ind}, $vals{ind}*2, "$fn: ind: series");
		ok($vals{Ql} > 0, "$fn: inductive reactance");
	}

	# This generates the hash above if we need it:
	# These are calculated without any freq_min/max_hz constraints:
=pod
	print "'$fn' => { " .
		"cap => " .(y_capacitance($Y, $f)->slice(0)->sclr). ", " .
		"ind => " .(y_inductance($Y, $f)->slice(0)->sclr). ", " .
		"esr => " .(y_resistance($Y, $f)->slice(0)->sclr). ", " .
		"Qc => " .(y_qfactor_c($Y, $f)->slice(0)->sclr). ", " .
		"Ql => " .(y_qfactor_l($Y, $f)->slice(0)->sclr). ", " .
		"Xc => " .(y_reactance_c($Y, $f)->slice(0)->sclr). ", " .
		"Xl => " .(y_reactance_l($Y, $f)->slice(0)->sclr). " },\n";

	# Debug output:
	print "$fn: f" . $f . "\n";
	print "$fn: Zin" . (s_port_z($S, 50, 1))->dummy(0,1)->glue(0,$f->dummy(0,1)) . "\n";
	print "$fn: Zin" . (s_port_z($S, 50, 1))->dummy(0,1)->glue(0,$f->dummy(0,1)) . "\n";
	print "$fn: ESR: " . (y_resistance($Y, $f))->dummy(0,1)->glue(0,$f->dummy(0,1)) . "\n";
	print "$fn: Xc): " . (y_reactance_c($Y, $f))->dummy(0,1)->glue(0,$f->dummy(0,1)) . "\n";
	print "$fn: Xl): " . (y_reactance_l($Y, $f))->dummy(0,1)->glue(0,$f->dummy(0,1)) . "\n";
	print "$fn: X): " . (y_reactance($Y, $f))->dummy(0,1)->glue(0,$f->dummy(0,1)) . "\n";
	print "$fn: Qc): " . (y_qfactor_c($Y, $f))->dummy(0,1)->glue(0,$f->dummy(0,1)) . "\n";
	print "$fn: Ql): " . (y_qfactor_l($Y, $f))->dummy(0,1)->glue(0,$f->dummy(0,1)) . "\n";
	#print "$fn: L (nH): " . (y_inductance($Y, $f)*1e9)->slice(0) . "\n";
=cut

}

sub verify_one
{
	my ($m, $inverse, $msg) = @_;


	ok((defined($m) && defined($inverse)) || (!defined($m) && !defined($inverse)),
		"$msg: " . (defined($m) ? 'defined' : 'undef'));

	return if (!defined($m) || !defined($inverse));

	my $re_err = sum(($m-$inverse)->re->abs);
	my $im_err = sum(($m-$inverse)->im->abs);

	ok($re_err < $tolerance, "$msg: real error ($re_err) < $tolerance");
	ok($im_err < $tolerance, "$msg: imag error ($im_err) < $tolerance");
}

sub build_vals
{
	my ($Y, $f) = @_;

	my @srf = y_srf($Y, $f);
	return (
		cap => (y_capacitance($Y, $f)->slice(0)),
		ind => (y_inductance($Y, $f)->slice(0)),
		esr => (y_resistance($Y, $f)->slice(0)),
		Qc => (y_qfactor_c($Y, $f)->slice(0)),
		Ql => (y_qfactor_l($Y, $f)->slice(0)),
		Xc => (y_reactance_c($Y, $f)->slice(0)),
		Xl => (y_reactance_l($Y, $f)->slice(0)),
		srf_last => $srf[$#srf]
	);
}
