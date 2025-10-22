#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::Message;
use Test::More tests=>5;

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
	my ($msg,$string,$countdown,%seen);
	my $m='Schedule::Activity::Message';
	#
	$msg=$m->new(message=>'abcd');
	($string)=$msg->random();
	is($string,'abcd','Message:  string');
	#
	%seen=();
	$msg=$m->new(message=>[qw/efgh ijkl/]);
	foreach (1..20) { ($string)=$msg->random(); $seen{$string}=1 }
	is_deeply(\%seen,{efgh=>1,ijkl=>1},'Message:  array');
	#
	%seen=();
	$msg=$m->new(message=>{
		alternates=>[
			{message=>'mnop',attributes=>{one=>1}},
			{message=>'qrst',attributes=>{two=>1}},
		],
	});
	foreach my $expect (qw/mnop qrst/) {
		$countdown=30;
		while(($countdown>0)&&!$seen{$expect}) { $countdown--; ($string)=$msg->random(); $seen{$string}=1 }
	}
	is_deeply(\%seen,{'mnop'=>1,'qrst'=>1},'Message:  hash n=2');
};

subtest 'Attributes'=>sub {
	plan tests=>3;
	my ($message,$string,$msg,$countdown,%seen);
	my $m='Schedule::Activity::Message';
	#
	$message=$m->new(message=>'hi',attributes=>{string=>{incr=>1}});
	($string,$msg)=$message->random();
	is_deeply([sort keys %{$$msg{attributes}//{}}],[qw/string/],'String message');
	#
	%seen=();
	$message=$m->new(message=>[qw/one two/],attributes=>{array=>{incr=>1}});
	foreach (1..10) {
		($string,$msg)=$message->random();
		foreach my $k (keys %{$$msg{attributes}//{}}) { $seen{$k}++ }
	}
	is_deeply(\%seen,{array=>10},'Array message');
	#
	%seen=();
	$message=$m->new(message=>
		{alternates=>[{message=>'one',attributes=>{one=>{}}},{message=>'two',attributes=>{two=>{}}}]},
		attributes=>{hash=>{incr=>1}});
	foreach my $expect (qw/one two/) {
		$countdown=30;
		while(($countdown>0)&&!$seen{$expect}) {
			$countdown--;
			($string,$msg)=$message->random();
			foreach my $k (keys %{$$msg{attributes}//{}}) { $seen{$k}++ }
		}
	}
	is_deeply([sort keys %seen],[qw/one two/],'Hash message');
};

subtest 'Named messages'=>sub {
	plan tests=>8;
	my ($msg,$countdown,%results);
	my %names=(
		name1=>{
			message=>'Message 1',
			attributes=>{named=>{incr=>'value not honored in test'}},
		},
		name2=>{
			message=>'Message 2',
			attributes=>{named=>{incr=>'value not honored in test'}},
		},
		name3=>{
			message=>{alternates=>[
				{message=>'three one',attributes=>{one=>{incr=>1}}},
				{message=>'three two',attributes=>{two=>{incr=>1}},names=>{'three two'=>{}}},
			]},
		},
	);
	#
	$msg=Schedule::Activity::Message->new(
		message=>'name1',
		names=>\%names,
	);
	{
		my ($string,$object)=$msg->random();
		$results{string}{$string}++;
		foreach my $k (keys %{$$object{attributes}}) { $results{attr}{$k}++ }
	}
	is_deeply([sort keys(%{$results{string}})],['Message 1'],'String:  All messages');
	is_deeply([sort keys(%{$results{attr}})],  [qw/named/],  'String:  All attributes');
	#
	$msg=Schedule::Activity::Message->new(
		message=>['name1','Plain message','name2','name3'],
		names=>\%names,
	);
	%results=(string=>{});
	foreach my $expect ('Message 1','Message 2','Plain message','three one','three two') {
		$countdown=50;
		while(($countdown>0)&&!$results{string}{$expect}) {
			$countdown--;
			my ($string,$object)=$msg->random();
			$results{string}{$string}++;
			foreach my $k (keys %{$$object{attributes}}) { $results{attr}{$k}++ }
		}
	} # expected string
	is_deeply(
		[sort keys(%{$results{string}})],
		['Message 1','Message 2','Plain message','three one','three two'],
		'Array:  All messages');
	is_deeply([sort keys(%{$results{attr}})],[qw/named one two/],'Array:  All attributes');
	#
	%results=();
	$msg=Schedule::Activity::Message->new(
		message=>{name=>'name1'},
		names=>\%names,
	);
	{
		my ($string,$object)=$msg->random();
		$results{string}{$string}++;
		foreach my $k (keys %{$$object{attributes}}) { $results{attr}{$k}++ }
	}
	is_deeply([sort keys(%{$results{string}})],['Message 1'],'Hash named:  All messages');
	is_deeply([sort keys(%{$results{attr}})],  [qw/named/],  'Hash named:  All attributes');
	#
	$msg=Schedule::Activity::Message->new(
		message=>{alternates=>[
			{message=>'Plain message',attributes=>{unnamed=>{incr=>'value not honored in test'}}},
			{name=>'name1'},
			{name=>'name2'},
		]},
		names=>\%names,
	);
	%results=(string=>{});
	foreach my $expect ('Message 1','Message 2','Plain message') {
		$countdown=40;
		while(($countdown>0)&&!$results{string}{$expect}) {
			$countdown--;
			my ($string,$object)=$msg->random();
			$results{string}{$string}++;
			foreach my $k (keys %{$$object{attributes}}) { $results{attr}{$k}++ }
		}
	} # expect
	is_deeply([sort keys(%{$results{string}})],['Message 1','Message 2','Plain message'],'Hash alternates:  All messages');
	is_deeply([sort keys(%{$results{attr}})],  [qw/named unnamed/],                      'Hash alternates:  All attributes');
	#
};

# attributesFromConf is effectively tested through activity.t at this point,
# but specific tests could be added to ensure that it's prevalidation safe.
