#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Easing;
use Test::More tests=>4;

# TOTEST:  messages that match no {match} entry (should always be included)

my %sample=(
	subsystems=>[qw/alpha beta gamma development production/],
	prefixWarning=>{
		numeric=>qr/^\w+\s+\d+:\s+warning of type (?<value>\d+) in \w+ at \d+$/,
		'md5' =>qr/^(?<digest0>\w+)\s+\d+:\s+(?<digest1>warning of type \d+) in \w+ at \d+$/,
		format=>'prefix %d:  warning of type %d in %s at %d',
		sample=>undef, # defer
	},
);

sub randarr { my ($aref)=@_; return $$aref[int(rand(1+$#$aref))]; }

$sample{prefixWarning}{sample}=sub {
	my ($i)=@_;
	return sprintf($sample{prefixWarning}{format}
		,int(rand(1e6))
		,$i
		,randarr($sample{subsystems})
		,int(rand(1e9)));
};

sub sawstep {
	my ($x,$xa,$xb,$ya,$yb)=@_;
	if($x<$xa) { return $ya }
	if($x>$xb) { return $yb }
	return ($x-$xa)/($xb-$xa)*($yb-$ya)+$ya;
}

sub matchseq {
	my ($easing,$events,$tsA,$tsB,$tsStep,$errf)=@_;
	my @res;
	my $lastN=0;
	for(my $ts=$tsA;$ts<=$tsB;$ts+=$tsStep) {
		my $N=scalar($easing->matches(ts=>$ts,events=>$events));
		push @res,{
			ts=>$ts,
			N=>$N,
			err=>&$errf($ts,$N),
			dN=>$N-$lastN,
		};
		$lastN=$N;
	}
	return @res;
}

sub validateSequence {
	my (%opt)=@_;
	foreach my $k (grep {!$opt{$_}} qw//) { die "Missing option $k" }
	my @events=sort {int(rand(3))-1} map { &{$sample{$opt{samplename}}{sample}}($_) } (1..$opt{eventN});
	my @seq=matchseq($opt{easing},\@events,$opt{tsA},$opt{tsB},$opt{tsStep},sub {
		my ($x,$y)=@_; return abs($y-sawstep($x,$opt{tsA},$opt{tsB},$opt{begin},$opt{final}))/$opt{eventN}*100 });
	my $initial=abs($opt{begin}-scalar($opt{easing}->matches(ts=>$opt{tsA}-1,events=>\@events)))/$opt{eventN}*100;
	my $final=abs($opt{final}-$seq[-1]{N})/$opt{eventN}*100;
	ok($initial<$opt{threshold},                 "$opt{label}:  initial event count");
	ok(!(grep {$$_{dN}<0} @seq),                 "$opt{label}:  non-decreasing");
	ok(!(grep {$$_{err}>=$opt{threshold}} @seq), "$opt{label}:  linearity");
	ok($final<$opt{threshold},                   "$opt{label}:  final event count");
}

subtest 'Initialization'=>sub {
	plan tests=>3;
	#
	eval { Schedule::Easing->new(schedule=>{type=>'md5'}) };
	like($@,qr/must be an array/,'ref(schedule)');
	#
	eval { Schedule::Easing->new(schedule=>[[type=>'md5']]) };
	like($@,qr/must be a hash/,'ref(schedule[i])');
	#
	eval { Schedule::Easing->new(schedule=>[{type=>'numeric',match=>qr/./,ymin=>0,ymax=>1}]) };
	like($@,qr/Match pattern.*value/,'Linear match requires <value>');
	#
};

# Note that MD5 digests won't necessarily maintain linearity.
# Some percent error is expected away from linear, therefore
# we check that results are non-decreasing and that the number
# of matched events is within some percentage of expected.
# We also don't check every timestimp, since "per second"
# variations will be larger.
#
# Because the digest is based on a fixed range of warning "types",
# tests should be stable across systems for the given combination
# of (eventN,tsA,tsB,threshold).
#
subtest 'md5'=>sub {
	plan tests=>8;
	my $label='md5 [0,100]';
	my ($eventN,$tsA,$tsB,$threshold)=(2_000,100,700,2.1);
	my $easing=Schedule::Easing->new(
		warnExpired=>0,
		schedule=>[
			{
				type=>'md5',
				name=>'Fake warnings md5',
				match=>$sample{prefixWarning}{md5},
				begin=>0.00,
				final=>1.00,
				tsA=>$tsA,
				tsB=>$tsB,
				# tsStep=>86400, # not yet supported
			},
		],
	);
	validateSequence(
		eventN=>$eventN,
		samplename=>'prefixWarning',
		easing=>$easing,
		tsA=>$tsA,
		tsB=>$tsB,
		begin=>0,
		final=>$eventN,
		tsStep=>100,
		label=>$label,
		threshold=>$threshold,
	);
	#
	$label='md5 [5,95]';
	$easing=Schedule::Easing->new(
		warnExpired=>0,
		schedule=>[
			{
				type=>'md5',
				name=>'Fake warnings md5',
				match=>$sample{prefixWarning}{md5},
				begin=>0.05,
				final=>0.95,
				tsA=>$tsA,
				tsB=>$tsB,
				# tsStep=>86400, # not yet supported
			},
		],
	);
	validateSequence(
		eventN=>$eventN,
		samplename=>'prefixWarning',
		easing=>$easing,
		tsA=>$tsA,
		tsB=>$tsB,
		begin=>0.05*$eventN,
		final=>0.95*$eventN,
		tsStep=>100,
		label=>$label,
		threshold=>$threshold,
	);
};

subtest 'numeric'=>sub {
	plan tests=>8;
	my $label='numeric [0,100]';
	my ($eventN,$tsA,$tsB,$threshold)=(2_000,100,700,0.05);
	my $easing=Schedule::Easing->new(
		warnExpired=>0,
		schedule=>[
			{
				type=>'numeric',
				name=>'Fake warnings numeric',
				match=>$sample{prefixWarning}{numeric},
				begin=>0.00,
				final=>1.00,
				tsA=>$tsA,
				tsB=>$tsB,
				ymin=>1,
				ymax=>$eventN,
				# tsStep=>86400, # not yet supported
			},
		],
	);
	validateSequence(
		eventN=>$eventN,
		samplename=>'prefixWarning',
		easing=>$easing,
		tsA=>$tsA,
		tsB=>$tsB,
		begin=>0,
		final=>$eventN,
		tsStep=>100,
		label=>$label,
		threshold=>$threshold,
	);
	#
	$label='numeric [5,95]';
	$easing=Schedule::Easing->new(
		warnExpired=>0,
		schedule=>[
			{
				type=>'numeric',
				name=>'Fake warnings numeric',
				match=>$sample{prefixWarning}{numeric},
				begin=>0.05,
				final=>0.95,
				tsA=>$tsA,
				tsB=>$tsB,
				ymin=>1,
				ymax=>$eventN,
				# tsStep=>86400, # not yet supported
			},
		],
	);
	validateSequence(
		eventN=>$eventN,
		samplename=>'prefixWarning',
		easing=>$easing,
		tsA=>$tsA,
		tsB=>$tsB,
		begin=>0.05*$eventN,
		final=>0.95*$eventN,
		tsStep=>100,
		label=>$label,
		threshold=>$threshold,
	);
};


subtest 'Other'=>sub {
	plan tests=>7;
	my $easing=Schedule::Easing->new(
		warnExpired=>0,
		schedule=>[],
	);
	is_deeply([$easing->matches(events=>["hi\n"])],["hi\n"],'Empty schedule');
	#
	$easing=Schedule::Easing->new(
		warnExpired=>0,
		schedule=>[
			{
				type=>'numeric',
				name=>'Quick test',
				match=>qr/(?<value>\d+)/,
				begin=>0,
				final=>1,
				tsA=>0,
				tsB=>10,
				ymin=>1,
				ymax=>10,
			}
		],
	);
	is_deeply([$easing->matches(ts=>0,events=>[{message=>'5',key=>1}])],[],                   'Event hash, ts<p');
	is_deeply([$easing->matches(ts=>5,events=>[{message=>'5',key=>1}])],[{message=>5,key=>1}],'Event hash, ts==p');
	is_deeply([$easing->matches(ts=>0,events=>[['5','key',1]])],[],           'Event array, ts<p');
	is_deeply([$easing->matches(ts=>5,events=>[['5','key',1]])],[[5,'key',1]],'Event array, ts==p');
	#
	$easing=Schedule::Easing->new(
		warnExpired=>0,
		schedule=>[
			{
				type=>'numeric',
				name=>'Quick test',
				match=>qr/(?<value>\d+)/,
				begin=>0,
				final=>1,
				tsA=>0,
				tsB=>10,
				ymin=>1,
				ymax=>10,
				shape=>'power',
				shapeopt=>[2],
			}
		],
	);
	is_deeply([$easing->matches(ts=>5,events=>[5])],[], 'Shape power, ts==5');
	is_deeply([$easing->matches(ts=>8,events=>[5])],[5],'Shape power, ts==8');
};



# html logs
# 'some.domain.com 1.2.3.4 - - [12/Jul/2025:17:14:04 -0700] "GET /a/b/c.html HTTP/1.1" 200 1234',
