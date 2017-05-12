#!/usr/bin/perl -w

use strict;

BEGIN { $| = 1; print "1..2\n"; }

END {print "not ok 1\n" unless $::loaded_hyphen;}

eval 'use locale;';

use Benchmark;
use TeX::Hyphen;

$::loaded_hyphen = 1;
print "ok 1\n";

my $hyp = new TeX::Hyphen;

my $t1 = new Benchmark;
my $file = 'lib/TeX/Hyphen.pm';
my $size = -s $file;
print STDERR "\nWill hyphenate file $file (size $size bytes)\n";

open README, $file or die "Error reading $file";
my $line;
while (defined($line = <README>)) {
	last if $line =~ /^__/;
	for (split /\W+/, $line) {
		$hyp->hyphenate($_);
	}
}
close README;
my $t2 = new Benchmark;
my $td = timediff($t2, $t1);
print STDERR "the code took:",timestr($td),"\n";

print "ok 2\n";

