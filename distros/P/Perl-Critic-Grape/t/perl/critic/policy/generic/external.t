#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;
use Perl::Critic::Policy::Generic::External;
use File::Temp qw/tempfile/;

use Test::More tests=>4;

package FakeToken;
sub new {
	my (undef,$ra,$ca,$rb,$cb)=@_;
	return bless({location=>[$ra,$ca],next=>bless({location=>[$rb,$cb]},'FakeToken')},'FakeToken');
}
sub next_token {
	my ($self)=@_;
	return $$self{next};
}
sub location {
	my ($self)=@_;
	return $$self{location};
}
1;

package main;

my $ourpolicy='Perl::Critic::Policy::Generic::External';
sub tmpfile { return tempfile(undef,UNLINK=>1) }

subtest 'Require configuration to activate'=>sub {
	plan tests=>2;
	my $critic;
	my %opts=(
		filetsv=>'',
	);
	#
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>$ourpolicy,-params=>{%opts});
	is(scalar($critic->policies()),0,'Zero options enabled');
	#
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>$ourpolicy,-params=>{%opts,filetsv=>'/dev/null'});
	is(scalar($critic->policies()),1,'filetsv enabled');
	#
};

subtest 'TSV file format'=>sub {
	plan tests=>2;
	my ($critic,$policy,%cache);
	my %common=(
		desc=>{
			'Actual::Policy'=>'The description of actual policy.',
		},
		expl=>{
			'Actual::Policy'=>'The explanation of actual policy.',
		},
		files=>{
			fileA=>1,
			fileB=>1,
		},
	);
	my %expect=(
		fileA=>{
			violations=>[
				[123,456,'Actual','Policy'],
			],
			%common,
		},
		fileB=>{
			violations=>[
				[234,56,'Unknown','Policy'],
			],
			%common,
		},
	);
	my ($tmpfh,$tmpfn)=tmpfile();
	print $tmpfh qq|# Description for Actual::Policy:  The description of actual policy.\n|;
	print $tmpfh qq|# Explanation for Actual::Policy:  The explanation of actual policy.\n|;
	print $tmpfh qq|Ignored line\n|;
	print $tmpfh qq|fileA\t123\t456\tActual\tPolicy\n|;
	print $tmpfh qq|fileB\t234\t56\tUnknown\tPolicy\n|;
	close($tmpfh);
	#
	foreach my $filename (sort keys %expect) {
		$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
		$critic->add_policy(-policy=>$ourpolicy,-params=>{filetsv=>$tmpfn});
		$policy=($critic->policies())[0];
		$policy->retrieveFiles($filename);
		%cache=$policy->cache();
		is_deeply(\%cache,$expect{$filename},$filename);
	}
};

subtest 'Locations within ranges'=>sub {
	plan tests=>10;
	my $f=\&Perl::Critic::Policy::Generic::External::_within;
	ok( &$f(4,1,FakeToken->new(5,6,7,8)),'yes:  4.1 wi [5.6,7.8]');
	ok( &$f(5,1,FakeToken->new(5,6,7,8)),'yes:  5.1 wi [5.6,7.8]');
	ok( &$f(5,7,FakeToken->new(5,6,7,8)),'yes:  5.7 wi [5.6,7.8]');
	ok( &$f(6,0,FakeToken->new(5,6,7,8)),'yes:  6.0 wi [5.6,7.8]');
	ok( &$f(7,0,FakeToken->new(5,6,7,8)),'yes:  7.0 wi [5.6,7.8]');
	ok(!&$f(7,8,FakeToken->new(5,6,7,8)),'no:   7.8 wi [5.6,7.8]');
	ok(!&$f(7,9,FakeToken->new(5,6,7,8)),'no:   7.9 wi [5.6,7.8]');
	#
	ok( &$f(4,0,FakeToken->new(4,1,4,2)),'yes:  4.0 wi [4.1,4.2]');
	ok( &$f(4,1,FakeToken->new(4,1,4,2)),'yes:  4.1 wi [4.1,4.2]');
	ok(!&$f(4,2,FakeToken->new(4,1,4,2)),'no:   4.2 wi [4.1,4.2]');
};

subtest 'End to end'=>sub {
	plan tests=>13;
	my @violations;
	my ($afh,$afn)=tmpfile();
	my ($bfh,$bfn)=tmpfile();
	my ($cfh,$cfn)=tmpfile();
	my ($vfh,$vfn)=tmpfile();
	#
	print $afh qq|my \@A=(1,2,3);\n|; close($afh);
	print $bfh qq|my \@A=(1,2,3);\nexit(0)|; close($bfh);
	print $cfh qq|my \@A=(1,2,3);\nexit(0)|; close($cfh);
	#
	print $vfh qq|# Description for Actual::Policy:  The description of actual policy.\n|;
	print $vfh qq|# Explanation for Actual::Policy:  The explanation of actual policy.\n|;
	print $vfh qq|Ignored line\n|;
	print $vfh qq|$afn\t1\t0\tActual\tPolicy\n|;
	print $vfh qq|$afn\t1\t4\tUnknown\tThingy\n|;
	print $vfh qq|$bfn\t2\t3\tActual\tPolicy\n|;
	close($vfh);
	#
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>$ourpolicy,-params=>{filetsv=>$vfn});
	#
	@violations=$critic->critique($afn);
	is($violations[0]{_policy},     'Perl::Critic::Policy::Actual::Policy', 'fileA.1:  Policy');
	is($violations[0]{_description},'The description of actual policy',     'fileA.1:  Description');
	is($violations[0]{_explanation},'The explanation of actual policy',     'fileA.1:  Explanation');
	is_deeply([@{$violations[0]{_location}}[0,1]],[1,1],                    'fileA.1:  Location');
	is($violations[1]{_policy},     'Perl::Critic::Policy::Unknown::Thingy','fileA.2:  Policy');
	is($violations[1]{_description},'Thingy',                               'fileA.2:  Description');
	is($violations[1]{_explanation},'',                                     'fileA.2:  Explanation');
	is_deeply([@{$violations[1]{_location}}[0,1]],[1,4],                    'fileA.2:  Location');
	#
	@violations=$critic->critique($bfn);
	is($violations[0]{_policy},     'Perl::Critic::Policy::Actual::Policy', 'fileB.1:  Policy');
	is($violations[0]{_description},'The description of actual policy',     'fileB.1:  Description');
	is($violations[0]{_explanation},'The explanation of actual policy',     'fileB.1:  Explanation');
	is_deeply([@{$violations[0]{_location}}[0,1]],[2,1],                    'fileB.1:  Location');
	#
	@violations=$critic->critique($cfn);
	is_deeply(\@violations,[],'fileC:  No violations');
};

