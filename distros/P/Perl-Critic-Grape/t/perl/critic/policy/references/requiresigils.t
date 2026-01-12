#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;

use Test::More tests=>3;

my $failure=qr/Only use arrows for methods/;

subtest 'Valid cases'=>sub {
	plan tests=>38;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils');
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
		q|print "a $$x{hi} b";|,
		q|print "a @$x b";|,
		q|print "a @{$x} b";|,     # uhhgly, but not yet rejected
		q|print "a @{[$$x]} b";|,
		q|print "a @{[$$x[0]]} b";|,
		q|print "a @{[$$x{hi}]} b";|,
		q|print "a @{[&$f(1)]} b";|,
		q|print "a X->[0] b";|,
		q|print "a X->{hi} b";|,
		q|print "a \$X->[0] b";|,
		q|print "a \$X->{hi} b";|,
		q|print "a %$x b";|,          # broken code
		q|print "a %{$x} b";|,        # broken code
		q|print "a &$f(1) b";|,       # broken code
		q|print "a $x->method() b";|, # broken code
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

subtest 'Invalid cases'=>sub {
	plan tests=>14;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils');
	#
	foreach my $code (
		q|my $y=$x->[0];|,
		q|my $y=$x->{hi};|,
		q|my $x=$f->(1);|,
		q|my @A=$x->@*;|, # 5.020001
		q|my %H=$x->%*;|, # 5.020001
		q|print 'b',$x->[0];|,
		q|print 'b',$x->{hi};|,
		q|print 'b',$f->(1);|,
		q|print 'b',$x->@*;|, # 5.020001
		q|print 'b',$x->%*;|, # 5.020001
		q|print "a @{[$x->[0]]} b";|,
		q|print "a @{[$x->{hi}]} b";|,
		q|print "a @{[$f->(1)]} b";|,
		# q|print "a $f->(1) b";|, # requires postderef_qq, not supported in PPIx?
		q|print "a $x->@* b";|,  # requires postderef_qq
		# q|print "a $x->%* b";|,  # requires postderef_qq
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

subtest 'Interpolation disabled'=>sub {
	plan tests=>23;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils',-params=>{interpolation=>0});
	#
	foreach my $code (
		q|print "a $$x b";|,
		q|print "a $$x[0] b";|,
		q|print "a $$x{hi} b";|,
		q|print "a @$x b";|,
		q|print "a @{$x} b";|,     # uhhgly, but not yet rejected
		q|print "a @{[$$x]} b";|,
		q|print "a @{[$$x[0]]} b";|,
		q|print "a @{[$$x{hi}]} b";|,
		q|print "a @{[&$f(1)]} b";|,
		q|print "a X->[0] b";|,
		q|print "a X->{hi} b";|,
		q|print "a \$X->[0] b";|,
		q|print "a \$X->{hi} b";|,
		q|print "a %$x b";|,          # broken code
		q|print "a %{$x} b";|,        # broken code
		q|print "a &$f(1) b";|,       # broken code
		q|print "a $x->method() b";|, # broken code
		#
		q|print "a @{[$x->[0]]} b";|,
		q|print "a @{[$x->{hi}]} b";|,
		q|print "a @{[$f->(1)]} b";|,
		q|print "a $f->(1) b";|, # requires postderef_qq
		q|print "a $x->@* b";|,  # requires postderef_qq
		q|print "a $x->%* b";|,  # requires postderef_qq
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

