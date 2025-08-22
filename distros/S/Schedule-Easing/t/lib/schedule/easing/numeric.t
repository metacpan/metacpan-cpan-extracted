#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Easing::Numeric;
use Test::More tests=>5;

subtest 'Initialization'=>sub {
	my $ease;
	eval { $ease=Schedule::Easing::Numeric->new(ymin=>'hi') };   like($@,qr/Must be numeric/,'ymin:  string');
	eval { $ease=Schedule::Easing::Numeric->new(ymax=>'hi') };   like($@,qr/Must be numeric/,'ymax:  string');
	eval { $ease=Schedule::Easing::Numeric->new(match=>'hi') };  like($@,qr/Must be Regexp/, 'match:  string');
	#
	eval { $ease=Schedule::Easing::Numeric->new(match=>qr/./) }; like($@,qr/Match pattern.*value/, 'match contains value:  .');
	eval { $ease=Schedule::Easing::Numeric->new(match=>qr/(?<value>)/) }; is($@,'', 'match contains value:  empty pattern');
};

subtest 'Matches'=>sub {
	plan tests=>2;
	my $ease=Schedule::Easing::Numeric->new(match=>qr/hello (?<value>\w+)/);
	is_deeply({$ease->matches('hello world')},{matched=>1,value=>'world'},'Returns matched value');
	is_deeply({$ease->matches('hello -----')},{},                         'No match');
};

subtest 'Includes'=>sub {
	plan tests=>4;
	my $tsA=int(1e3+rand(1e9));
	my $ymin=int(rand(1e3));
	my $ease=Schedule::Easing::Numeric->new(
		tsA=>$tsA,
		tsB=>$tsA+int(rand(1e9)),
		tsrange=>undef,
		begin=>rand(0.2),
		final=>0.8+rand(0.2),
		slope=>undef,
		ymin=>$ymin,
		ymax=>$ymin+int(rand(1e3)),
	);
	my $tsC=0.5*($$ease{tsA}+$$ease{tsB});
	my $when=sub { my ($ease,%override)=@_; return $ease->new(%override) };
	#
	is(&$when($ease,begin=>0)->includes($$ease{tsA}-1,value=>0),         0,'ts<tsA, begin=0');
	is(&$when($ease,begin=>0,final=>1)->includes($$ease{tsB}+1,value=>0),1,'ts>tsB, final=1');
	#
	is($ease->includes($tsC,value=>$$ease{ymin}),1,'ymin<50%ile');
	is($ease->includes($tsC,value=>$$ease{ymax}),0,'ymax>50%ile');
};

subtest 'Includes edge cases'=>sub {
	my $ease=Schedule::Easing::Numeric->new();
	is($ease->includes(),             1,'ts undefined');
	is($ease->includes(1),            1,'value undefined');
	is($ease->includes(1,value=>'hi'),1,'value non-numeric');
	#
	is($ease->includes(0.4,value=>0.5),0,'0.4<0.5 not included');
	is($ease->includes(0.6,value=>0.5),1,'0.6>0.5 is included');
	is($ease->includes(0.5,value=>0.5),1,'Equality is included');
};

subtest 'Schedule'=>sub {
	my ($alway,$never)=(0,0);
	my $tsA=int(1e3+rand(1e9));
	my $ymin=int(rand(1e3));
	my $ease=Schedule::Easing::Numeric->new(
		tsA=>$tsA,
		tsB=>$tsA+2*int(rand(1e8)),
		tsrange=>undef,
		begin=>0.1+rand(0.2),
		final=>0.8+rand(0.2),
		slope=>undef,
		ymin=>$ymin,
		ymax=>$ymin+int(rand(1e3)),
	);
	plan tests=>1+($$ease{ymax}-$$ease{ymin}+11);
	foreach my $y ($$ease{ymin}-5..$$ease{ymax}+5) {
		my $ts=$ease->schedule(value=>$y);
		if(!defined($ts)) { $never++; ok(!$ease->includes($$ease{tsB}+1,value=>$y),"Value:  $y (never included)") }
		elsif($ts<=$tsA)  { $alway++; ok($ease->includes($tsA-1,value=>$y),"Value:  $y (always included)") }
		else              { ok($ease->includes($ts-1,value=>$y)^$ease->includes($ts+1,value=>$y),"Value:  $y") }
	}
	ok($alway*$never>0,'Always/Never covered');
};

