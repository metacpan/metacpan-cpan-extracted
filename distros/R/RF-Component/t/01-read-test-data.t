#!/usr/bin/perl

use strict;
use warnings;

use PDL::IO::Touchstone qw/n_ports/;
use RF::Component;
use File::Temp qw/tempfile/;

use Test::More tests => 236;

my $datadir = 't/test-data/muRata';

opendir(my $dir, $datadir) or die "$datadir: $!";

my @files = grep { /\.s\dp$/i } readdir($dir);
closedir($dir);

foreach my $fn (@files)
{
	my %newopts;

	if ($fn =~ /GRM/)
	{
		$newopts{value_code_regex} = qr/GRM.......(...)/; 
		$newopts{value_unit} = 'pF';
		$newopts{model} = $fn;
	}

	my $c = RF::Component->load("$datadir/$fn", undef, %newopts);

	my $n_freqs = $c->{freqs}->nelem;
	my $n_ports = n_ports($c->S); 
	my $c_value = $c->value;
	my $c_unit = $c->value_unit;

	ok($c_value, "$fn: value is set: $c_value $c_unit") if $newopts{model};

	ok($c->num_ports == $n_ports, "$fn: Correct number of ports ($n_ports)");
	ok($c->num_freqs == $n_freqs, "$fn: Correct number of freqs ($n_freqs)");

	my %funcs = (
		port_z           => [1],
		inductance       => [],
		ind_nH           => [],
		resistance       => [],
		esr              => [],
		capacitance      => [],
		cap_pF           => [],
		qfactor_l        => [],
		qfactor_c        => [],
		reactance_l      => [],
		reactance_c      => [],
		reactance        => [],
		#srf              => [],
		#srf_ideal        => [],
		#is_lossless      => [],
		#is_symmetrical   => [],
		#is_reciprocal    => [],
		#is_open_circuit  => [],
		#is_short_circuit => [],
		);

	for my $f (keys %funcs)
	{
		#print "=== $f\n";
		my @args = @{$funcs{$f}};
		my $ret = $c->$f(@args);

		if (defined($ret) && ref($ret) eq 'PDL')
		{
			ok(1, "$fn: $f: is PDL, 1st element=". $ret->slice(0));

			my $n = $c->num_freqs; 
			my $count = $ret->nelem;
			ok($count == $n, "$fn: $f: correct count $count==$n");
		}
	}
}
