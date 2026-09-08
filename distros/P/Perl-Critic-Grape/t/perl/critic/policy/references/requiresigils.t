#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;

use Test::More tests=>4;

my $failure=qr/Only use arrows for methods/;

# Because directcast was not available, historically these tests all have directcast==0

subtest 'Valid cases'=>sub {
	plan tests=>38;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils',-params=>{directcast=>0});
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
		q|my $y=${$x};|,           # uhhgly, accepted when directcast=0
		q|my $y=${$x}[0];|,        # uhhgly, accepted when directcast=0
		q|my $y=${$x}{hi};|,       # uhhgly, accepted when directcast=0
		q|my @A=@{$x};|,           # uhhgly, accepted when directcast=0
		q|my %H=%{$x};|,           # uhhgly, accepted when directcast=0
		q|print "a $$x b";|,
		q|print "a $$x[0] b";|,
		q|print "a $$x{hi} b";|,
		q|print "a @$x b";|,
		q|print "a @{$x} b";|,     # uhhgly, accepted when directcast=0
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
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils',-params=>{directcast=>0});
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
		q|print "a @{$x} b";|,     # uhhgly, but skipped when interpolation==0
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

subtest 'Direct casting rejections'=>sub {
	plan tests=>54;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::RequireSigils',-params=>{directcast=>1});
	#
	foreach my $code (
		q|my $y=$$x;|,
		q|my $y=$$x[0];|,
		q|my $y=$$x{hi};|,
		q|my $x=&$f(1);|,
		q|my @A=@$x;|,
		q|my @A=@{$x{$y}};|,
		q|my @A=@{f()};|,
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
		q|print "a $$x b";|,
		q|print "a $$x[0] b";|,
		q|print "a $$x{hi} b";|,
		q|print "a @$x b";|,
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
	#
	foreach my $code (
		q|my $y=$x->[0];|,
		q|my $y=$x->{hi};|,
		q|my $x=$f->(1);|,
		q|my @A=$x->@*;|, # 5.020001
		q|my %H=$x->%*;|, # 5.020001
		q|my $y=${$x};|,
		q|my $y=${$x}[0];|,
		q|my $y=${$x}{hi};|,
		q|my @A=@{$x};|,
		q|my %H=%{$x};|,
		q|print 'b',$x->[0];|,
		q|print 'b',$x->{hi};|,
		q|print 'b',$f->(1);|,
		q|print 'b',$x->@*;|, # 5.020001
		q|print 'b',$x->%*;|, # 5.020001
		q|print "a @{$x} b";|,
		q|print "a @{[$x->[0]]} b";|,
		q|print "a @{[$x->{hi}]} b";|,
		q|print "a @{[$f->(1)]} b";|,
		# q|print "a $f->(1) b";|, # requires postderef_qq, not supported in PPIx?
		q|print "a $x->@* b";|,  # requires postderef_qq
		# q|print "a $x->%* b";|,  # requires postderef_qq
	) {
		like(($critic->critique(\$code))[0],qr/(?:$failure|not block cast single symbols)/,$code);
	}
};

