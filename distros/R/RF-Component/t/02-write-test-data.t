#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use RF::Component;
use File::Temp qw/tempfile/;

use Test::More tests => 1896;

my @files = grep { !/IDEAL_OPEN|IDEAL_SHORT/ } testfiles(qr/\.s\d+p$/i, 't/test-data/', 't/test-data/muRata');

my $tolerance = 1e-6;

# For each file, permute {MA, RI, DB} <=> {S, Y, A} <=> {khz, MHz, GHz}
# and see if we hit any errors:

foreach my $fn (@files)
{
	my $c = RF::Component->load($fn);

	my ($ext) = ($fn =~ /(\.s\d+p)$/);
	my $t = File::Temp->new(CLEANUP => 1, TEMPLATE => 'rf-component-XXXXX', SUFFIX => $ext);
	my $tfn = $t->filename;
	close $t;

	foreach my $fmt (qw/MA RI DB/)
	{
		# Exclude Z, it is prone to singularities 
		# (and I think that is expected, but patches welcome!)
		foreach my $param (qw/S Y A/)
		{
			next if ($param eq 'A' && $c->num_ports != 2);

			foreach my $hz (qw/khz GHz/) # mixed case
			{
				$c->save($tfn,
					output_fmt => $fmt,
					param_type => $param,
					output_f_unit => $hz);

				my $c2 = RF::Component->load($tfn);

				ok($c->num_ports == $c2->num_ports, "nports");
				ok($c->num_freqs == $c2->num_freqs, "nfreqs");

				verify_sum($c->S, $c2->S, "$fn: $param $fmt $hz: S", $tolerance);
				verify_sum($c->Y, $c2->Y, "$fn: $param $fmt $hz: Y", $tolerance);

				if ($c->num_ports == 2)
				{
					verify_sum($c->ABCD, $c2->ABCD, "$fn: $param $fmt $hz: A", $tolerance);
				}


				# Frequency tolerances aren't quite as tight
				# when scaling between SI units, but this is OK
				# since even 1e-3 Hz (milli-Hz) is negligable.
				verify_max($c->freqs, $c2->freqs, "$fn: $param $fmt $hz: freqs", 1e-3);
			}
		}

	}
}

sub verify_sum
{
	my ($m, $inverse, $msg, $tolerance) = @_;

	my $re_err = sum(($m-$inverse)->re->abs);
	my $im_err = sum(($m-$inverse)->im->abs);

	ok($re_err < $tolerance, "$msg: real error ($re_err) < $tolerance");
	ok($im_err < $tolerance, "$msg: imag error ($im_err) < $tolerance");
}

sub verify_max
{
	my ($m, $inverse, $msg, $tolerance) = @_;

	my $re_err = max(($m-$inverse)->re->abs);
	my $im_err = max(($m-$inverse)->im->abs);

	ok($re_err < $tolerance, "$msg: real error ($re_err) < $tolerance");
	ok($im_err < $tolerance, "$msg: imag error ($im_err) < $tolerance");
}

sub testfiles
{
	my ($regex, @paths) = @_;

	my @files;
	foreach my $datadir (@paths)
	{
		opendir(my $dir, $datadir) or die "$datadir: $!";
		push @files,  map { "$datadir/$_" } grep { /$regex/i } readdir($dir);
		closedir($dir);
	}

	return @files;
}
