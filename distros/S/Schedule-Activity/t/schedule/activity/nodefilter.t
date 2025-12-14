#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::NodeFilter;
use Test::More tests=>9;

subtest 'Init'=>sub {
	plan tests=>1;
	eval { Schedule::Activity::NodeFilter->new(f=>'unsupported') };
	like($@,qr/(?i:invalid filter)/,'Invalid filter');
};

subtest 'Values'=>sub {
	plan tests=>12;
	my $filter=Schedule::Activity::NodeFilter->new(f=>'value',attr=>'name',value=>7);
	my %attributes=(name=>{value=>7});
	my $with=sub {
		my (%opt)=@_;
		foreach my $k (keys %opt) { $$filter{$k}=$opt{$k} }
		return $filter->matches(undef,%attributes);
	};
	ok( &$with(op=>'eq'),'eq');
	ok(!&$with(op=>'ne'),'ne');
	ok(!&$with(op=>'lt'),'lt');
	ok( &$with(op=>'le'),'le');
	ok(!&$with(op=>'gt'),'gt');
	ok( &$with(op=>'ge'),'ge');
	#
	$attributes{name}{value}=6;
	ok(!&$with(op=>'eq'),'eq');
	ok( &$with(op=>'ne'),'ne');
	ok( &$with(op=>'lt'),'lt');
	ok( &$with(op=>'le'),'le');
	ok(!&$with(op=>'gt'),'gt');
	ok(!&$with(op=>'ge'),'ge');
};

subtest 'Value modulus'=>sub {
	plan tests=>2;
	my $filter=Schedule::Activity::NodeFilter->new(f=>'value',attr=>'name',op=>'lt',value=>1,mod=>3);
	my %attributes=(name=>{value=>0});
	my @matched;
	foreach my $i (-5..20) {
		$attributes{name}{value}=$i;
		if($filter->matches(undef,%attributes)) { push @matched,$i }
	}
	is_deeply(\@matched,[map {3*$_} (-1..6)],'Every third integer');
	#
	@matched=(); # overload as failures
	for(my $x=0;$x<3;$x+=0.01) {
		foreach my $M (-1..2) {
			$attributes{name}{value}=3*$M+$x;
			my $res=$filter->matches(undef,%attributes);
			if($res&&($x>=1)) { push @matched,"$M,$x,$attributes{name}{value}" }
		}
	}
	is_deeply(\@matched,[],'Floating modulus');
};

package DieFilter;
sub matches { die 'This should not be called' }
package main;

subtest 'Boolean and'=>sub {
	plan tests=>5;
	my $filter=Schedule::Activity::NodeFilter->new(f=>'boolean',boolean=>'and');
	my %attributes=(x=>{value=>7},y=>{value=>8});
	my $with=sub {
		my (%opt)=@_;
		foreach my $k (keys %opt) { $$filter{$k}=$opt{$k} }
		return $filter->matches(undef,%attributes);
	};
	ok( &$with(filters=>[{attr=>'x',op=>'eq',value=>7},{attr=>'y',op=>'eq',value=>8}]),'(x=7)&&(y=8)');
	ok( &$with(filters=>[{attr=>'x',op=>'gt',value=>6},{attr=>'y',op=>'lt',value=>9}]),'(x>6)&&(y<9)');
	ok(!&$with(filters=>[{attr=>'x',op=>'eq',value=>8},bless({},'DieFilter')]),        'Short circuiting');
	ok( &$with(filters=>[
		{attr=>'x',op=>'eq',value=>7},
		{attr=>'y',op=>'eq',value=>8},
		{attr=>'x',op=>'lt',value=>9},
		]),'(x=7)&&(y=8)&&(x<9)');
	ok( &$with(filters=>[
		Schedule::Activity::NodeFilter->new(f=>'value',attr=>'x',op=>'eq',value=>7),
		Schedule::Activity::NodeFilter->new(f=>'value',attr=>'y',op=>'eq',value=>8),
		]),'object (x=7)&&(y=8)');
};

subtest 'Boolean or'=>sub {
	plan tests=>6;
	my $filter=Schedule::Activity::NodeFilter->new(f=>'boolean',boolean=>'or');
	my %attributes=(x=>{value=>7},y=>{value=>8});
	my $with=sub {
		my (%opt)=@_;
		foreach my $k (keys %opt) { $$filter{$k}=$opt{$k} }
		return $filter->matches(undef,%attributes);
	};
	ok( &$with(filters=>[{attr=>'x',op=>'eq',value=>7},{attr=>'y',op=>'eq',value=>8}]),'(x=7)||(y=8)');
	ok( &$with(filters=>[{attr=>'x',op=>'eq',value=>6},{attr=>'y',op=>'lt',value=>9}]),'(x=6)||(y<9)');
	ok( &$with(filters=>[{attr=>'x',op=>'eq',value=>7},bless({},'DieFilter')]),        'Short circuiting');
	ok( &$with(filters=>[
		{attr=>'x',op=>'eq',value=>1},
		{attr=>'y',op=>'eq',value=>1},
		{attr=>'x',op=>'lt',value=>9},
		]),'(x=7)||(y=8)||(x<9)');
	ok(!&$with(filters=>[{attr=>'x',op=>'eq',value=>6},{attr=>'y',op=>'eq',value=>7}]),'(x=6)||(y=7)');
	ok( &$with(filters=>[
		Schedule::Activity::NodeFilter->new(f=>'value',attr=>'x',op=>'eq',value=>7),
		Schedule::Activity::NodeFilter->new(f=>'value',attr=>'y',op=>'eq',value=>8),
		]),'object (x=7)||(y=8)');
};

subtest 'Boolean nand'=>sub {
	plan tests=>6;
	my $filter=Schedule::Activity::NodeFilter->new(f=>'boolean',boolean=>'nand');
	my %attributes=(x=>{value=>7},y=>{value=>8});
	my $with=sub {
		my (%opt)=@_;
		foreach my $k (keys %opt) { $$filter{$k}=$opt{$k} }
		return $filter->matches(undef,%attributes);
	};
	ok(!&$with(filters=>[{attr=>'x',op=>'eq',value=>7},{attr=>'y',op=>'eq',value=>8}]),'(x=7) !&& (y=8)');
	ok( &$with(filters=>[{attr=>'x',op=>'eq',value=>8},bless({},'DieFilter')]),        'Short circuiting');
	ok(!&$with(filters=>[{attr=>'x',op=>'eq',value=>7}]),                              '!(x=7)');
	ok( &$with(filters=>[{attr=>'x',op=>'eq',value=>8}]),                              '!(x=8)');
	ok( &$with(filters=>[
		{attr=>'x',op=>'eq',value=>7},
		{attr=>'y',op=>'eq',value=>8},
		{attr=>'x',op=>'gt',value=>9},
		]),'(x=7)||(y=8)||(x>9)');
	ok(!&$with(filters=>[
		Schedule::Activity::NodeFilter->new(f=>'value',attr=>'x',op=>'eq',value=>7),
		Schedule::Activity::NodeFilter->new(f=>'value',attr=>'y',op=>'eq',value=>8),
		]),'object (x=7) !&& (y=8)');
};

subtest 'Boolean unsupported'=>sub {
	plan tests=>1;
	my $filter=Schedule::Activity::NodeFilter->new(f=>'boolean',boolean=>'unsupported',filters=>[]);
	my %attributes=(x=>{value=>7},y=>{value=>8});
	ok(!$filter->matches(undef,%attributes),'Default does not match');
};

subtest 'Elapsed time'=>sub {
	plan tests=>4;
	my $filter=Schedule::Activity::NodeFilter->new(f=>'elapsed',attr=>'x',value=>7);
	my %attributes=(x=>{value=>0,tmmax=>5});
	my $with=sub {
		my ($tm,%opt)=@_;
		foreach my $k (keys %opt) { $$filter{$k}=$opt{$k} }
		return $filter->matches($tm,%attributes);
	};
	ok( &$with(12,op=>'eq'),'elapsed eq 7');
	ok( &$with(10,op=>'le'),'elapsed le 7');
	ok(!&$with(12,op=>'gt'),'elapsed gt 7');
	ok( &$with(13,op=>'gt'),'elapsed gt 7 b');
};

subtest 'Elapsed modulus'=>sub {
	plan tests=>1;
	my $filter=Schedule::Activity::NodeFilter->new(f=>'elapsed',attr=>'x',op=>'lt',value=>3,mod=>6);
	my %attributes=(x=>{value=>0,tmmax=>3});
	my @matched;
	foreach my $tm (-10..20) { if($filter->matches($tm,%attributes)) { push @matched,$tm } }
	is_deeply(\@matched,[3,4,5,9,10,11,15,16,17],'First half of every 6unit window');
};

