#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;

use Test::More tests=>2;

my $failure=qr/Do not use inline do/;

subtest 'Valid do blocks'=>sub {
	plan tests=>10;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::ControlStructures::ProhibitInlineDo');
	ok(join('',map {$_->get_themes()} $critic->policies()),'themes');
	foreach my $code (
		q|do {$x++} foreach (1..3);|,
		q|my $x; do {$x++} foreach (1..3);|,
		q|my $x=$module->do(5);|,
		q|sub do { return 5 }|,
		q|sub do {}; my $x; $x=7+do(9);|,
		q|sub do{do{$x++} foreach (1..3);$x}|,
		q|unless(@return=do 'filename'){1}|,
		q|{my $x=do} # compile failure|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	#
	require Perl::Critic::Policy::ControlStructures::ProhibitInlineDo;
	ok(!Perl::Critic::Policy::ControlStructures::ProhibitInlineDo::violates(undef,bless({},'PPI::Token')),'Only applies to Token::Word');
};

subtest 'Inline do blocks'=>sub {
	plan tests=>4;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::ControlStructures::ProhibitInlineDo');
	foreach my $code (
		q|my $x=7+do{9};|,
		q|my $x; $x//=do{9};|,
		q|%h=(key=>do{(1,2,3));|,
		q|sub do (&@) {}; my $x; $x=7+do {1} (2..3);|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

