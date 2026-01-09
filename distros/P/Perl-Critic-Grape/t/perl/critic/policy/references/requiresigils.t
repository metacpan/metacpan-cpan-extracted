#!/usr/bin/perl

use 5.020001; # postfix dereferencing operators here
use strict;
use warnings;
use Perl::Critic;

use Test::More tests=>3;

my $failure=qr/Only use arrows for methods/;

# todo Default is now interpolation=1; merge those tests into the default in/valid cases, and create separate tests for interpolation=0

subtest 'Valid cases'=>sub {
	plan tests=>27;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils',-params=>{interpolation=>0});
	#
	foreach my $code (
		q|my $y=$$x;|,
		q|my $y=$$x[0];|,
		q|my $y=$$x{hi};|,
		q|my $x=&$f(1);|,
		q|my @A=@$x;|,
		q|my %H=%$x;|,
		q|my $y=$x->method;|,
		q|my $y=$x->method();|,
		q|print 'a',$$x;|,
		q|print 'a',$$x[0];|,
		q|print 'a',$$x{hi};|,
		q|print 'a',&$f(1);|,
		q|print 'a',@$x;|,
		q|print 'a',%$x;|,
		q|print 'a',$x->method;|,
		q|print 'a',$x->method();|,
		q|my $y=${$x};|,           # uhhgly, but not yet rejected
		q|my $y=${$x}[0];|,        # uhhgly, but not yet rejected
		q|my $y=${$x}{hi};|,       # uhhgly, but not yet rejected
		q|my @A=@{$x};|,           # uhhgly, but not yet rejected
		q|my %H=%{$x};|,           # uhhgly, but not yet rejected
		q|print "a $$x b";|,
		q|print "a $$x[0] b";|,
		q|print "a X->[0] b";|,
		q|print "a X->{hi} b";|,
		q|print "a \$X->[0] b";|,
		q|print "a \$X->{hi} b";|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

subtest 'Invalid cases'=>sub {
	plan tests=>10;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils',-params=>{interpolation=>0});
	#
	foreach my $code (
		q|my $y=$x->[0];|,
		q|my $y=$x->{hi};|,
		q|my $x=$f->(1);|,
		q|my @A=$x->@*;|,
		q|my %H=$x->%*;|,
		q|print 'b',$x->[0];|,
		q|print 'b',$x->{hi};|,
		q|print 'b',$f->(1);|,
		q|print 'b',$x->@*;|,
		q|print 'b',$x->%*;|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

subtest 'String interpolation'=>sub {
	plan tests=>22;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils',-params=>{interpolation=>1});
	#
	foreach my $code (
		q|print "a $$x b";|,
		q|print "a $$x[0] b";|,
		q|print "a $$x{hi} b";|,
		q|print "a @$x b";|,
		q|print "a @{$x} b";|,
		q|print "a @{[$$x]} b";|,
		q|print "a @{[$$x[0]]} b";|,
		q|print "a @{[$$x{hi}]} b";|,
		q|print "a @{[&$f(1)]} b";|,
		q|print "a X->[0] b";|,
		q|print "a X->{hi} b";|,
		q|print "a \$X->[0] b";|,
		q|print "a \$X->{hi} b";|,
		q|print "a %$x b";|,          # invalid code
		q|print "a %{$x} b";|,        # invalid code
		q|print "a &$f(1) b";|,       # invalid code
		q|print "a $x->method() b";|, # invalid code
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	foreach my $code (
		q|print "a $x->[0] b";|,
		q|print "a $x->{hi} b";|,
		# q|print "a $f->(1) b";|, # requires postderef_qq
		# q|print "a $x->@* b";|,  # requires postderef_qq
		# q|print "a $x->%* b";|,  # requires postderef_qq
		q|print "a @{[$x->[0]]} b";|,
		q|print "a @{[$x->{hi}]} b";|,
		q|print "a @{[$f->(1)]} b";|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

