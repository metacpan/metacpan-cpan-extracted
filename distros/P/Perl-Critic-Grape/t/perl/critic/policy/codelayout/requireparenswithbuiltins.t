#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;

use Test::More tests=>4;

my $failure=qr/Builtin.*without parentheses/;

subtest 'Required cases'=>sub {
	plan tests=>20;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins',-params=>{});
	foreach my $valid (
		['Fallback or',     'my $x=lc("hi"||"bye")'],
		['Undefined or',    'my $x=uc("hi"//"bye")'],
		['lt',              'my $x=lc("hi") lt lc("bye")'],
		['cmp',             'my $x=lc("hi") cmp lc("bye")'],
		['numeric <',       'my $x=int(5) < int(7)'],
		['not mandatory',   'my $x=lc("hi");'],
		['not builtin',     'my $x=function "hi";'],
		['rand',            'my $x=rand(5);'],
		['subroutine',      'sub log {1}'],
		['method bare',     'my $x=$module->log;'],
		['method child',    'my $x=$module->log->thing();'],
		['key',             'my %hash=(one=>1,log=>0,two=>2);'],
	) {
		is_deeply([$critic->critique(\$$valid[1])],[],$$valid[0]);
	}
	foreach my $invalid (
		['Fallback or',     'my $x=lc "hi"||"bye"'],
		['Undefined or',    'my $x=uc "hi"//"bye"'],
		['lt',              'my $x=lc "hi" lt lc "bye"'],
		['cmp',             'my $x=lc "hi" cmp lc "bye"'],
		['numeric <',       'my $x=int 5 < int 7'],
		['not mandatory',   'my $x=lc "hi";'],
		['rand',            'my $x=rand 5;'],
		['lc topic',        'my @A=map {lc} qw/a b c/'],
	) {
		like(($critic->critique(\$$invalid[1]))[0],$failure,$$invalid[0]);
	}
};

subtest 'Allowed cases'=>sub {
	plan tests=>7;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins',-params=>{});
	foreach my $valid (
		['grep/map/rev/sort',  'my @A=reverse sort {$a<=>$b} grep {$_} map {$_} (0,1,2);'],
		['die',                'die "Hello" if 1;'],
		['print',              'print STDERR "Hello\n";'],
		['last',               'foreach (1..5){last}'],
		['my/our',             'my $x=5; my ($y,$z)=(1,2); our $r=5; our ($s,$t)=(6,7);'],
		['keys',               'my @K=keys %hash;'],
		['scalar keys',        'my $n=scalar(keys %hash);'],
	) {
		is_deeply([$critic->critique(\$$valid[1])],[],$$valid[0]);
	}
};

subtest 'Permitted cases'=>sub {
	plan tests=>15;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins',-params=>{});
	foreach my $valid (
		['chomp',              'while(<>) { chomp;   $x+=$_ }'],
		['chomp()',            'while(<>) { chomp(); $x+=$_ }'],
		['defined',            'if(grep {defined} @A){}'],
		['defined(hkey)',      'if(grep {defined($h{$_})} @A){}'],
		['exit',               'exit;'],
		['exit(2)',            'exit(2);'],
		['time',               'my $tm=time;'],
		['time(0)',            'my $tm=time(0);'],
		['time(tm)',           'my $tm=time(12345);'],
	) {
		is_deeply([$critic->critique(\$$valid[1])],[],$$valid[0]);
	}
	foreach my $invalid (
		['chomp',              'chomp $y;'],
		['chomp',              'chomp $h{key};'],
		['defined hkey',       'if(grep {defined $h{$_}} @A){}'],
		['exit 2',             'exit 2;'],
		['time 0',             'my $tm=time 0;'],
		['time tm',            'my $tm=time 12345;'],
	) {
		like(($critic->critique(\$$invalid[1]))[0],$failure,$$invalid[0]);
	}
};

subtest 'Configuration'=>sub {
	plan tests=>7;
	my %params=(
		allow  =>'defined',
		require=>'defined lc',
		permit =>'defined lc die',
	);
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins',-params=>\%params);
	foreach my $valid (
		['defined',            'if(grep {defined} @A){}'],
		['defined(hkey)',      'if(grep {defined($h{$_})} @A){}'],
		['defined hkey',       'if(grep {defined $h{$_}} @A){}'],
		['lc',                 'my $x=lc("Hello");'],
		['die',                'die;'],
	) {
		is_deeply([$critic->critique(\$$valid[1])],[],$$valid[0]);
	}
	foreach my $invalid (
		['lc Hello',           'my $x=lc "Hello";'],
		['die msg',            'die "Goodbye";'],
	) {
		like(($critic->critique(\$$invalid[1]))[0],$failure,$$invalid[0]);
	}
};

