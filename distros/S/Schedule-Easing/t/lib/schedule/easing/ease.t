#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Easing::Ease;
use Test::More tests=>1;

subtest 'Initialization'=>sub {
	plan tests=>7;
	my $ease;
	eval { $ease=Schedule::Easing::Ease->new(tsA=>'hi') };   like($@,qr/Must be numeric/,'tsA:  string');
	eval { $ease=Schedule::Easing::Ease->new(tsB=>'hi') };   like($@,qr/Must be numeric/,'tsB:  string');
	eval { $ease=Schedule::Easing::Ease->new(begin=>'hi') }; like($@,qr/Must be numeric/,'begin:  string');
	eval { $ease=Schedule::Easing::Ease->new(final=>'hi') }; like($@,qr/Must be numeric/,'final:  string');
	eval { $ease=Schedule::Easing::Ease->new(match=>'hi') }; like($@,qr/Must be Regexp/, 'match:  string');
	#
	$ease=Schedule::Easing::Ease->new(tsB=>10);
	is($ease->new(tsA=>5)->{tsA},5,'Copy:  tsA');
	is($ease->new()->{tsB},     10,'Copy:  tsB');
};

