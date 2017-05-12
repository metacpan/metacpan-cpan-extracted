#!/usr/bin/perl -w

use strict;
use Test::More tests => 3+16*2+13*2;

BEGIN { use_ok('SCUBA::Table::NoDeco') };

my %MAX_TIMES = (
	SSI => {
		3.0  => 300,
		4.5  => 350,
		6.0  => 325,
		7.5  => 245,
		9.0  => 205,
		10.5 => 160,
		12.0 => 130,
		15.0 =>  70,
		18.0 =>  50,
		21.0 =>  40,
		24.0 =>  30,
		27.0 =>  25,
		30.0 =>  20,
		33.0 =>  15,
		36.0 =>  10,
		39.0 =>   5,
	},
	PADI => {
		10.5 => 205,
		12.0 => 140,
		15.0 =>  80,
		18.0 =>  55,
		21.0 =>  40,
		24.0 =>  30,
		27.0 =>  25,
		30.0 =>  20,
		33.0 =>  16,
		36.0 =>  13,
		39.0 =>  10,
		42.0 =>   8,
	}
);

my %MAX_TIMES_FT = (
	SSI => {
		10  => 300,
		15  => 350,
		20  => 325,
		25  => 245,
		30  => 205,
		35  => 160,
		40  => 130,
		50  =>  70,
		60  =>  50,
		70  =>  40,
		80  =>  30,
		90  =>  25,
		100 =>  20,
		110 =>  15,
		120 =>  10,
		130 =>   5,
	},
	PADI => {
		 35 => 205,
		 40 => 140,
		 50 =>  80,
		 60 =>  55,
		 70 =>  40,
		 80 =>  30,
		 90 =>  25,
		100 =>  20,
		110 =>  16,
		120 =>  13,
		130 =>  10,
		140 =>   8,
	}
);

my %sdt = (
	SSI  => SCUBA::Table::NoDeco->new(table => 'SSI'),
	PADI => SCUBA::Table::NoDeco->new(table => 'PADI'),
);

# Test SSI dive.

$sdt{SSI}->dive(metres => 18, minutes => 30);

is($sdt{SSI}->group,"F","Dive for 18 metres for 30 minutes is group F");

$sdt{SSI}->clear;
is($sdt{SSI}->group,"","Group cleared");

# Test PADI dive.

$sdt{PADI}->dive(metres => 18, minutes => 30);
is($sdt{PADI}->group,"L","PADI dive for 18 minutes and 30 minutes is group L");

$sdt{PADI}->clear;
is($sdt{PADI}->group,"","PADI Group cleared");

foreach my $table (keys %MAX_TIMES) {

	foreach my $depth (keys %{$MAX_TIMES{$table}}) {
		is($sdt{$table}->max_time(metres => $depth),
		   $MAX_TIMES{$table}{$depth},
		   "Max time at $depth metres on $table is $MAX_TIMES{$table}{$depth}");
	}

	foreach my $depth (keys %{$MAX_TIMES_FT{$table}}) {
		is($sdt{$table}->max_time(feet => $depth),
		   $MAX_TIMES_FT{$table}{$depth},
		   "Max time at $depth feet on $table is $MAX_TIMES_FT{$table}{$depth}");
	}

}
