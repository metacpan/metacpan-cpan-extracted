#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;
use Perl::Critic::Policy::References::ProhibitUnnecessaryRefs;
use PPI;

use Test::More tests=>10;

my $failure=qr/Use Perl basic types/;


if(0) {
subtest 'debugging'=>sub {
	plan tests=>12;
	my $policy=Perl::Critic::Policy::References::ProhibitUnnecessaryRefs->new();
	my $code;
	#
	$code=q|my $x; {my $x;$x=f(%$x); $$x[5]=7}; $x=g(); $$x{k}=7;|;
	$code=q|my $x;     my @A=@$x;|,
	$code=q|my $x;     $$x[5]=7;|,
	$code=q|$z=f();    $$z[5]=7;|;
	#
	my $doc=PPI::Document->new(\$code);
	$policy->initialize_if_enabled();
	$policy->prepare_to_scan_document($doc);
	my %cache=$policy->fetchCache();
	use Data::Dumper; print Dumper({keys=>[keys %cache], %cache{qw/scopes symbol pending var varscope/} }); ...;
}; ...  }


subtest 'Is basic cast'=>sub {
	plan tests=>54;
	my $f=\&Perl::Critic::Policy::References::ProhibitUnnecessaryRefs::isBasicCast;
	foreach my $test (
		[q|$$var|,'$','$var'],
		[q|@$var|,'@','$var'],
		[q|%$var|,'%','$var'],
		[q|&$var|,'&','$var'],
		[q|*$var|,'*','$var'],
		[q|${$var}|,'$','$var'],
		[q|@{$var}|,'@','$var'],
		[q|%{$var}|,'%','$var'],
		[q|&{$var}|,'&','$var'],
		[q|*{$var}|,'*','$var'],
		[q|$$var[0]|,  '@','$var'],
		[q|@$var[0,1]|,'@','$var'],
		[q|$$var{0}|,  '%','$var'],
		[q|@$var{0,1}|,'%','$var'],
		[q|%$var{0,1}|,'%','$var'],
		[q|${$var}[0]|,  '@','$var'],
		[q|@{$var}[0,1]|,'@','$var'],
		[q|${$var}{0}|,  '%','$var'],
		[q|@{$var}{0,1}|,'%','$var'],
		[q|%{$var}{0,1}|,'%','$var'],
		[q|&$var()|,  '&','$var'],
		[q|&{$var}()|,'&','$var'],
		[q|*$globref{ARRAY}|, '*','$globref'],
		[q|*{$globref}{HASH}|,'*','$globref'],
	) {
		my $code=$$test[0];
		my $doc=PPI::Document->new(\$code);
		my $node=$doc->find_first('PPI::Token::Cast');
		my %result=&$f($node);
		is($result{type},  $$test[1],"$code:  sigil");
		is($result{symbol},$$test[2],"$code:  symbol");
	}
	foreach my $code (
		q|$var|,
		q|\$var|,
		q|${1;$var}|,
		q|${if(1){\1}else{\2}}|,
		q|@{[1,2,3]}|,
		q|%{+{one=>3}}|,
	) {
		my $doc=PPI::Document->new(\$code);
		my $node=$doc->find_first('PPI::Token::Cast');
		ok(!&$f($node),"No:  $code");
	}
};

subtest 'Subscripted symbol'=>sub {
	plan tests=>20;
	my $f=\&Perl::Critic::Policy::References::ProhibitUnnecessaryRefs::isSubscriptedSymbol;
	foreach my $test (
		[q|$var->[0]|,'@','$var'],
		[q|$var->{k}|,'%','$var'],
		[q|$var->(1)|,'&','$var'],
		[q|$var->m()|,'B','$var'],
		[q|$v->[0][0]|,'@','$v'],
		[q|$v->[0]{k}|,'@','$v'],
		[q|$v->{k}[0]|,'%','$v'],
		[q|$v->{k}{k}|,'%','$v'],
		[q|$v->m()->[0]|,'B','$v'],
		[q|$v->m()->{k}|,'B','$v'],
	) {
		my $code=$$test[0];
		my $doc=PPI::Document->new(\$code);
		my $node=$doc->find_first('PPI::Token::Symbol');
		my %result=&$f($node);
		is($result{type},  $$test[1],"$code:  type");
		is($result{symbol},$$test[2],"$code:  symbol");
	}
};

subtest 'Analyze:  Scope'=>sub {
	plan tests=>12;
	my $policy=Perl::Critic::Policy::References::ProhibitUnnecessaryRefs->new();
	#
	# When this test was written, only casting was supported.  Change these to my-vars etc later.
	my $code=q|
		our ($d);
		while(my $e=f()) {
			if(@$e) {
				@$g;
				$d=d();
			}
			@$f;
		}
		@$c;
	|;
	my $doc=PPI::Document->new(\$code);
	$policy->initialize_if_enabled();
	$policy->prepare_to_scan_document($doc);
	my %cache=$policy->fetchCache();
	is(scalar(keys %{$cache{scopes}}),1,'Active scope count');
	my ($lastline,%seen)=(1);
	my %expect=(
		count=>{c=>1,d=>1},
	);
	foreach my $var ('c'..'g') {
		my @sarray=@{$cache{symbol}{'$'.$var}//[]};
		is(1+$#sarray,$expect{count}{$var}//0,"$var:  scopes count");
		my $line=$expect{count}{$var}?($sarray[0]{scope}=~s/ .*//r):$lastline;
		ok($line>=$lastline,"$var:  scope location");
		$lastline=$line;
		$seen{$sarray[0]{scope}//'undefined'}++;
	}
	is(scalar(keys %seen)-1,1,'Distinct variable scopes');
};

subtest 'Analyze:  Assignment'=>sub {
	plan tests=>7;
	my $policy=Perl::Critic::Policy::References::ProhibitUnnecessaryRefs->new();
	my $code=q|
		my ($x,$y,$z);
		$y=f(@$x);
		$z=f(%$y);
		{
			my ($x,$y)=([@$y],{%$x});
			$z=[@$x,%$y];
		}
	|;
	my $doc=PPI::Document->new(\$code);
	$policy->initialize_if_enabled();
	$policy->prepare_to_scan_document($doc);
	my %cache=$policy->fetchCache();
	my %symbols;
	foreach my $k (sort keys %{$cache{var}}) { push @{$symbols{$k=~s/.* //r}},$k }
	#
	is_deeply($cache{var}{ $symbols{'$x'}[0] }{usage},{'%'=>1,'@'=>1},'x1:  dual use');
	is_deeply($cache{var}{ $symbols{'$x'}[1] }{usage},{'@'=>1},       'x2:  single use');
	is_deeply($cache{var}{ $symbols{'$y'}[0] }{usage},{'%'=>1,'@'=>1},'y1:  dual use');
	is_deeply($cache{var}{ $symbols{'$y'}[1] }{usage},{'%'=>1},       'y2:  single use');
	is($#{$symbols{'$x'}},1,'x:   two uses');
	is($#{$symbols{'$y'}},1,'y:   two uses');
	ok(!defined($symbols{'$z'}),'z:   zero use');
};

subtest 'Analyze:  Usage'=>sub {
	plan tests=>8;
	my $policy=Perl::Critic::Policy::References::ProhibitUnnecessaryRefs->new();
	my $code=q|
		my ($sref,$aref,$href,$cref,$obja);
		my ($srefb,$arefb,$hrefb,$crefb);
		if(&$cref(1) && $obja->happy()) {
			$$sref;  # $srefb->$*;
			$$aref[0]; $arefb->[0];
			$crefb->(1);
		}
		$$href{key}; $hrefb->{key};
	|;
	my $doc=PPI::Document->new(\$code);
	$policy->initialize_if_enabled();
	$policy->prepare_to_scan_document($doc);
	my %cache=$policy->fetchCache();
	is_deeply($cache{var}{$cache{symbol}{'$sref'}[0]{key}},{usage=>{'$'=>1}},'sref');
	is_deeply($cache{var}{$cache{symbol}{'$aref'}[0]{key}},{usage=>{'@'=>1}},'aref');
	is_deeply($cache{var}{$cache{symbol}{'$href'}[0]{key}},{usage=>{'%'=>1}},'href');
	is_deeply($cache{var}{$cache{symbol}{'$cref'}[0]{key}},{usage=>{'&'=>1}},'cref');
	is_deeply($cache{var}{$cache{symbol}{'$obja'}[0]{key}},{usage=>{'B'=>1}},'obja');
	# is_deeply($cache{var}{$cache{symbol}{'$srefb'}[0]{key}},{usage=>{'$'=>1}},'sref arrow'); # not yet supported
	is_deeply($cache{var}{$cache{symbol}{'$arefb'}[0]{key}},{usage=>{'@'=>1}},'aref arrow');
	is_deeply($cache{var}{$cache{symbol}{'$hrefb'}[0]{key}},{usage=>{'%'=>1}},'href arrow');
	is_deeply($cache{var}{$cache{symbol}{'$crefb'}[0]{key}},{usage=>{'&'=>1}},'cref arrow');
};

subtest 'Invalid cases'=>sub {
	plan tests=>43;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitUnnecessaryRefs',-params=>{});
	foreach my $code (
		#
		q|my $x;     $$x[5]=7;|,
		q|my $y=f(); $$y[5]=7;|,
		q|my (undef,$z,undef)=f(); $$z[5]=7;|,
		q|my $x;     $$x{k}=7;|,
		q|my $y=f(); $$y{k}=7;|,
		q|my (undef,$z,undef)=f(); $$z{k}=7;|,
		#
		q|my $x;     $x->[5]=7;|,
		q|my $y=f(); $y->[5]=7;|,
		q|my (undef,$z,undef)=f(); $z->[5]=7;|,
		q|my $x;     $x->{k}=7;|,
		q|my $y=f(); $y->{k}=7;|,
		q|my (undef,$z,undef)=f(); $z->{k}=7;|,
		#
		q|my $x;     my @A=@$x;|,
		q|my $y=f(); my @A=@$y;|,
		q|my (undef,$z,undef)=f(); my @A=@$z;|,
		q|my $x;     my %H=%$x;|,
		q|my $y=f(); my %H=%$y;|,
		q|my (undef,$z,undef)=f(); my %H=%$z;|,
		#
		q|my $x;     my $y=f($$x[5]);|,
		q|my $x;     my $y=f($x->[5]);|,
		q|my $x;     my $y=f(@$x);|,
		q|my $x;     my $y=f($$x{k});|,
		q|my $x;     my $y=f($x->{k});|,
		q|my $x;     my $y=f(%$x);|,
		#
		# chaining
		q|my $c=my $d=my $e=f(); @$d;|,
		q|my $c=my $d=my $e=f(); %$e;|,
		q|my ($x,$y,$z); @$x; %$x; (undef,$x)=(undef,$y)=(undef,$z)=f(); @$x;|,
		q|my ($x,$y,$z); @$y; %$y; (undef,$x)=(undef,$y)=(undef,$z)=f(); @$y;|,
		q|my ($x,$y,$z); @$z; %$z; (undef,$x)=(undef,$y)=(undef,$z)=f(); @$z;|,
		q|my ($r,$s); my ($x,$y)=(@$r,$s);|,
		#
		# no Statement::Variable declaration
		q|$w=f(); @$w;|,
		#
		# post-conditionals
		q|my ($x,$y)=f(); $y=1 if(@$x);|,
		q|my ($x,$y)=f(); $y=1 if(is_arrayref($x) && @$x);|,
		q|my ($x,$y)=f(); $y=1 foreach @$x;|,
		q|my ($x,$y)=f(); $x=g(@$x) if $x;|,
		q|my ($x,$y)=f(); $x=g() if $x; %$x;|,
		q|my ($x,$y)=f(); $x=g() if @$x; %$x;|,
		#
		# Statement::Compound
		q|if(my $x=f()) { @$x }|,
		q|my $x=g(); if(my $x=f()) { $x }; %$x|,
		q|my $x=g(); if(my $x=f()) { @$x }; %$x|,
		q|my $x=g(); if(my $x=f()) { @$x }; $x|,
		#
		q|my $thing=f(); if(is_arrayref($thing)) { g(@$thing) }|,
		q|my $thing=f(); if(is_hashref ($thing)) { g(%$thing) }|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

subtest 'Valid cases'=>sub {
	plan tests=>7;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitUnnecessaryRefs',-params=>{});
	foreach my $code (
		q|
			my $x; $x=7;
			my @y; $y[0]=8;
			my %z; $z{k}=9;
			my $r; *$r{HASH}{two}=3;
		|,
		q|
			my $x=f();
			my @y=($x,$x,$x.$x,$x+$x);
		|,
		q|
			my ($y)=f();
			my $z=$y;
		|,
		q|
			my @x=g();
			my ($y,$z)=@x[0,2];
			$z=$x[0];
		|,
		q|
			my $x=f();
			my $y=&$x();
		|,
		q|my $thing=f(); if($thing{type} eq 'array') { g(@{$thing{list}}) }|,
		q|my $thing=f(); if($thing{type} eq 'hash')  { g(%{$thing{set}}) }|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

subtest 'Invalid case uniqueness'=>sub {
	plan tests=>3;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitUnnecessaryRefs',-params=>{});
	foreach my $code (
		#
		q|my $x;     $$x[5]=7;|,
		q|my $y=f(); $$y[5]=7;|,
		q|$z=f();    $$z[5]=7;|,
		#
	) {
		is($#{[$critic->critique(\$code)]},0,$code);
	}
};

# These should be failures but aren't handled at this time.
subtest 'Broken cases'=>sub {
	plan tests=>1;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitUnnecessaryRefs',-params=>{});
	foreach my $code (
		q|
			my $c=my $d=my $e=f();
			$d->@*; # warning, postfix deref
			$e->%*; # warning, postfix deref
		|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

subtest 'Option self'=>sub {
	plan tests=>6;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitUnnecessaryRefs',-params=>{self=>0});
	foreach my $code (
		q|
			sub thing {
				my ($self)=@_;
				if($$self{thing}) { return }
				return;
			}
		|,
		q|
			sub thing {
				my $self=shift;
				if($$self{thing}) { return }
				return;
			}
		|,
		q|
			sub thing {
				my $self={};
				$$self{thing}=5;
				return bless($self,'C');
			}
		|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	#
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitUnnecessaryRefs',-params=>{self=>1});
	foreach my $code (
		q|
			sub thing {
				my ($self)=@_;
				if($$self{thing}) { return }
				return;
			}
		|,
		q|
			sub thing {
				my $self=shift;
				if($$self{thing}) { return }
				return;
			}
		|,
		q|
			sub thing {
				my $self={};
				$$self{thing}=5;
				return bless($self,'C');
			}
		|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

