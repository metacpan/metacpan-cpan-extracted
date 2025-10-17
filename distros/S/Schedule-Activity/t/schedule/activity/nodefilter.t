#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::NodeFilter;
use Test::More tests=>5;

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

package DieFilter;
sub matches { die 'This should not be called' }
package main;

subtest 'Boolean and'=>sub {
	plan tests=>4;
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
};

subtest 'Boolean or'=>sub {
	plan tests=>4;
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
};

subtest 'Boolean nand'=>sub {
	plan tests=>5;
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

