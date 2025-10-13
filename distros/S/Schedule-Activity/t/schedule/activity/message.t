#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::Message;
use Test::More tests=>3;

subtest 'init'=>sub {
	plan tests=>3;
	my $msg;
	my $m='Schedule::Activity::Message';
	#
	$msg=$m->new(message=>'abcd');
	is($$msg{msg}[0],'abcd','Message:  string');
	$msg=$m->new(message=>[qw/efgh ijkl/]);
	is_deeply($$msg{msg},['efgh','ijkl'],'Message:  array');
	$msg=$m->new(message=>{
		alternates=>[
			{message=>'mnop'},
			{message=>'qrst'},
		],
	});
	is_deeply($$msg{msg},[{message=>'mnop'},{message=>'qrst'}],'Message:  hash');
};

subtest 'Primary messages'=>sub {
	plan tests=>4;
	my ($msg,$string,$href);
	my $m='Schedule::Activity::Message';
	#
	$msg=$m->new(message=>'abcd');
	($string)=$msg->primary();
	is($string,'abcd','Message:  string');
	#
	$msg=$m->new(message=>[qw/efgh ijkl/]);
	($string)=$msg->primary();
	is($string,'efgh','Message:  array');
	#
	$msg=$m->new(message=>{
		alternates=>[
			{message=>'mnop',attributes=>{one=>1}},
			{message=>'qrst',attributes=>{two=>1}},
		],
	});
	($string,$href)=$msg->primary();
	is($string,'mnop','Message:  hash');
	is_deeply($$href{attributes},{one=>1},'Message:  hash attributes');
};

subtest 'Random selection'=>sub {
	plan tests=>3;
	my ($msg,$string,%seen);
	my $m='Schedule::Activity::Message';
	#
	$msg=$m->new(message=>'abcd');
	($string)=$msg->random();
	is($string,'abcd','Message:  string');
	#
	%seen=();
	$msg=$m->new(message=>[qw/efgh ijkl/]);
	foreach (1..10) { ($string)=$msg->random(); $seen{$string}=1 }
	is_deeply(\%seen,{efgh=>1,ijkl=>1},'Message:  array');
	#
	%seen=();
	$msg=$m->new(message=>{
		alternates=>[
			{message=>'mnop',attributes=>{one=>1}},
			{message=>'qrst',attributes=>{two=>1}},
		],
	});
	foreach (1..10) { ($string)=$msg->random(); $seen{$string}=1 }
	is_deeply(\%seen,{'mnop'=>1,'qrst'=>1},'Message:  hash n=2');
};

