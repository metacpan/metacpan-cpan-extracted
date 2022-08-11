#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone qw/rsnp s_port_z n_ports/;
use File::Temp qw/tempfile/;

use Test::More tests => 4;

my $tolerance = 1e-6;

my $datadir = 't/test-data';

my $S = pdl [
		[
			[0.7163927 + i() * -0.4504119, 0.2836073 + i() *  0.4504119],
			[0.2836073 + i() *  0.4504119, 0.7163927 + i() * -0.4504119]
		],
	];

my $zin  = s_port_z($S, 50, 1);
ok(abs($zin - pdl(50.1070651124653-158.985376613117*i() )) < $tolerance, "(builtin) Port 1");

my $zout = s_port_z($S, 50, 2);
ok(abs($zout - pdl(50.1070651124653-158.985376613117*i() )) < $tolerance, "(builtin) Port 2");

foreach my $fn (qw(t/test-data/IDEAL_SHORT.s2p))
{
	my ($f, $m, $param_type, $z0, $comments, $fmt, $funit, $orig_f_unit) = rsnp($fn);

	next unless $param_type eq 'S';

	for my $p (1..n_ports($m))
	{
		my $z = s_port_z($m, $z0, $p);
		my $err = sum(abs($z - 50));
		ok($err < $tolerance, "$fn port-$p: error: $err");
	}
}

