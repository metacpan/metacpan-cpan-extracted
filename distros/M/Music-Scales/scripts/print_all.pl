#!/usr/bin/perl

use strict;
use Music::Scales;

foreach my $note qw (C C# Db D D# Eb E F F# Gb G G# Ab A A# Bb B) {
	foreach my $mode (1..30) {
		my @notes = get_scale_notes($note,$mode);
		print join(" ",@notes),"\n";
	}
}



