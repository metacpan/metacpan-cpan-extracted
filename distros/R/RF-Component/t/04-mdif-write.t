#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone qw/n_ports/;
use RF::Component::Multi;

use File::Temp qw/tempfile/;

use Test::More tests => 266;

my $m = RF::Component::Multi->load('t/test-data/muRata/muRata-GQM-0402.mdf');

my ($fh, $fn) = tempfile();
close($fh);

END { unlink($fn) };

$m->save($fn);
my $m2 = RF::Component::Multi->load($fn);


ok(@$m == @$m2, "load count: ". @$m);

for (my $i = 0; $i < @$m; $i++)
{
	my $S1 = $m->[$i]->S();
	my $S2 = $m2->[$i]->S();

	verify_sum($S1, $S2, "S index $i", 1e-6);

	verify_sum($m->[$i]->freqs, $m2->[$i]->freqs, "F index $i", 1e-6);

	foreach my $var (keys %{ $m->[$i]->{vars} })
	{
		ok(defined($m->[$i]->{vars}->{$var}) &&
			$m->[$i]->{vars}->{$var} eq $m2->[$i]->{vars}->{$var},
				"var: $var=$m->[$i]->{vars}->{$var}");
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

