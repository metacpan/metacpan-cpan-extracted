#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone qw/n_ports/;
use RF::Component::Multi;

use File::Temp qw/tempfile/;

use Test::More tests => 4;

my $m = RF::Component::Multi->load('t/test-data/muRata/muRata-GQM-0402.mdf', 
		load_options => { freq_range => 100e6 }
	);

ok(@$m == 53, "load count: ". @$m);
ok(@{$m->cap_pF} == 53, "capacitance count: ". @{$m->cap_pF});
ok(approx($m->cap_pF->[0], 0.10000263), "capacitance[0]  value: " . $m->cap_pF->[0]);
ok(approx($m->cap_pF->[52], 33.117753), "capacitance[52] value: " . $m->cap_pF->[52]);

