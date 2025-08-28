#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Easing::Ease;
use Test::Warn;

use Test::More tests=>3;

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

subtest 'Error states'=>sub {
	plan tests=>9;
	my $ease;
	eval {$ease=Schedule::Easing::Ease->new(begin=>'hi')}; like($@, qr/Must be numeric/,'begin invalid type');
	eval {$ease=Schedule::Easing::Ease->new(final=>'hi')}; like($@, qr/Must be numeric/,'final invalid type');
	eval {$ease=Schedule::Easing::Ease->new(tsA=>'hi')};   like($@, qr/Must be numeric/,'tsA invalid type');
	eval {$ease=Schedule::Easing::Ease->new(tsB=>'hi')};   like($@, qr/Must be numeric/,'tsB invalid type');
	eval {$ease=Schedule::Easing::Ease->new(match=>1)};    like($@, qr/Must be Regexp/, 'match invalid type');
	#
	warning_like(sub{$ease=Schedule::Easing::Ease->new(begin=>-1)},    qr/begin<0/, 'begin<0');
	warning_like(sub{$ease=Schedule::Easing::Ease->new(final=> 2)},    qr/final>1/, 'final>1');
	warning_like(sub{$ease=Schedule::Easing::Ease->new(tsA=>1,tsB=>0)},qr/tsA>=tsB/,'tsA>tsB');
	#
	ok($$ease{_err},'Error flag set');
};

subtest 'Expiration'=>sub {
	plan tests=>3;
	my $ease;
	my $ts=time()-1e3;
	warning_like(sub{$ease=Schedule::Easing::Ease->new(_warnExpired=>1,tsA=>$ts-1,tsB=>$ts,final=>1,name=>'Name')},qr/Event has expired:  Name/,      'Final=1, ts>tsB, named');
	warning_like(sub{$ease=Schedule::Easing::Ease->new(_warnExpired=>1,tsA=>$ts-1,tsB=>$ts,final=>0,name=>undef)}, qr/Event with tsB=\d+ has expired/,'Final=0, ts>tsB');
	warnings_are(sub{$ease=Schedule::Easing::Ease->new(_warnExpired=>1,tsA=>$ts-1,tsB=>$ts,final=>0.5)},[],                                           'Final=0.5, no warnings');
};

