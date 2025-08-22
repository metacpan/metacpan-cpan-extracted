#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Easing::MD5;
use Test::More tests=>3;

subtest 'Matches'=>sub {
	plan tests=>4;
	my $ease=Schedule::Easing::MD5->new(match=>qr/^hello (?<digest>\w+)/);
	is_deeply({$ease->matches('hello world')},{matched=>1,digest=>'world'},'Returns single value');
	is_deeply({$ease->matches('hello -----')},{},                          'No match');
	#
	$ease=Schedule::Easing::MD5->new(match=>qr/^hello (?<digest0>\w+) (?<digest1>\w+)/);
	is_deeply({$ease->matches('hello foo bar')},{matched=>1,digest0=>'foo',digest1=>'bar'},'Returns double value');
	is_deeply({$ease->matches('hello --- ---')},{},                                        'No match');
};

subtest 'Includes'=>sub {
	plan tests=>9;
	my $tsA=int(1e3+rand(1e9));
	my $ease=Schedule::Easing::MD5->new(
		tsA=>$tsA,
		tsB=>$tsA+1024, # must remain fixed
		begin=>0.1,     # must remain fixed
		final=>0.9,     # must remain fixed
	);
	my $tsC=0.5*($$ease{tsA}+$$ease{tsB});
	my $when=sub { my ($ease,%override)=@_; return $ease->new(%override) };
	#
	is(&$when($ease,begin=>0)->includes($$ease{tsA}-1),                                  0,'ts<tsA, begin=0');
	is(&$when($ease,begin=>0,final=>1,slope=>1/$$ease{tsrange})->includes($$ease{tsB}+1),1,'ts>tsB, [0,1]');
	#
	is($ease->includes($tsC,digest=>'a'), 1,'digest<50%ile');
	is($ease->includes($tsC,digest=>'b'), 0,'digest>50%ile');
	is($ease->includes($tsC,message=>'a'),1,'digest<50%ile, message fallback');
	is($ease->includes($tsC,message=>'b'),0,'digest>50%ile, message fallback');
	is($ease->includes($tsC,digest0=>'a',digest1=>'f'), 1,'dual keys<50%ile');
	is($ease->includes($tsC,digest0=>'b',digest1=>'g'), 0,'dual keys>50%ile');
	is($ease->includes($tsC),                           1,'No digests, no fallback');
};

subtest 'Schedule'=>sub {
	plan tests=>468;
	# It's possible that test messages don't see the never/always cases.
	# A few random passes should provide sufficient coverage.
	my ($alway,$never)=(0,0);
	foreach (1..3) {
		my $tsA=int(1e3+rand(1e9));
		my $ease=Schedule::Easing::MD5->new(
			tsA=>$tsA,
			tsB=>$tsA+int(rand(1e3)),
			begin=>0.1+rand(0.2),
			final=>0.8+rand(0.2),
		);
		foreach my $digest ('aa'..'fz') {
			my $ts=$ease->schedule(digest=>$digest);
			if(!defined($ts)) { $never++; ok(!$ease->includes($$ease{tsB}+1,digest=>$digest),"Message:  $digest (never included)") }
			elsif($ts<=$tsA)  { $alway++; ok($ease->includes($tsA-1,digest=>$digest),"Message:  $digest (always included)") }
			else              { ok($ease->includes($ts-1,digest=>$digest)^$ease->includes($ts+1,digest=>$digest),"Message:  $digest") }
		}
	}
	if($alway==0) { print STDERR "Always not covered\n" }
	if($never==0) { print STDERR "Never not covered\n" }
};
