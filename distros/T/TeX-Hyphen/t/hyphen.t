#!/usr/bin/perl -w

use strict;

BEGIN { $| = 1; print "1..21\n"; }

END {print "not ok 1\n" unless $::loaded_hyphen;}

use TeX::Hyphen;
$::loaded_hyphen = 1;
print "ok 1\n";

### $TeX::Hyphen::DEBUG = 4;

my $hyp = new TeX::Hyphen;

if (not defined $hyp) {
	print STDERR "Loading the patterm file failed with: $TeX::Hyphen::errstr\n";
}

my ($word, $result, $expected);

sub test_hyp ($$$$)
	{
	my ($num, $hyp, $word, $expected) = @_;
	my $result = $hyp->visualize($word);
	if ($result ne $expected)
		{ print "Hyphenation($word), expected $expected, got $result\nnot "; }
	print "ok $num\n";
	}

test_hyp 2, $hyp, 'representation', 'rep-re-sen-ta-tion';
test_hyp 3, $hyp, 'presents', 'presents';
test_hyp 4, $hyp, 'declination', 'dec-li-na-tion';
test_hyp 5, $hyp, 'peter', 'pe-ter';
test_hyp 6, $hyp, 'going', 'go-ing';
test_hyp 7, $hyp, 'leaving', 'leav-ing';
test_hyp 8, $hyp, 'multiple', 'mul-ti-ple';
test_hyp 9, $hyp, 'playback', 'play-back';
test_hyp 10, $hyp, 'additional', 'ad-di-tion-al';
test_hyp 11, $hyp, 'maximizes', 'max-i-mizes';
test_hyp 12, $hyp, 'programmable', 'pro-grammable';

open OUT, "> testhyp.hyp";
print OUT <<'EOF';
\patterns{.ach4
.ad4der
.af1t
.al3t
.am5at
.an5c
}
EOF
close OUT;

my $hyp1 = new TeX::Hyphen 'testhyp.hyp';
if (not defined $hyp1) {
	print "$TeX::Hyphen::errstr\nnot ";
}

print "ok 13\n";

my $hyp2 = new TeX::Hyphen name => 'testhyp.hyp';
if (not defined $hyp2) {
	print "$TeX::Hyphen::errstr\nnot ";
}

print "ok 14\n";

my $hypdup = new TeX::Hyphen;
if (not defined $hypdup) {
	print "$TeX::Hyphen::errstr\nnot ";
}

print "ok 15\n";

test_hyp 16, $hypdup, 'declination', 'dec-li-na-tion';

my $hyp3 = new TeX::Hyphen rightmin => 4;
test_hyp 17, $hyp3, 'twilynx', 'twilynx';

my $hyp4 = new TeX::Hyphen "t/utf8.tex";
test_hyp 18, $hyp4, 'žížala', 'ž-í-ža-la';
use utf8;
test_hyp 19, $hyp4, 'žížala', 'žíža-la';

my $hyp5 = new TeX::Hyphen "t/utf8.tex", style => "utf8";
no utf8;
test_hyp 20, $hyp5, 'žížala', 'žíža-la';
use utf8;
test_hyp 21, $hyp5, 'žížala', 'ží-ža-la';
