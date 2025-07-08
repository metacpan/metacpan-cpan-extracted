#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;
use Perl::Critic::Policy::References::ProhibitRefChecks;
use PPI;
use Ref::Util;

use Test::More tests=>12;

my $failure=qr/Do not perform manual ref/;

subtest 'decompose'=>sub {
	plan tests=>33;
	my $decompose=sub {
		my ($code)=@_;
		my $doc=PPI::Document->new(\$code);
		my $node=$doc->find_first('PPI::Token::Word');
		return Perl::Critic::Policy::References::ProhibitRefChecks::decompose($node);
	};
	my %tests=(
		'lc ref($x) eq "array"'          => ['eq','array'],
		'ref $$aref[0] !~ /ARRAY/'       => ['!~','/ARRAY/'],
		'ref $$aref[0] && $x=~/\d/'      => [undef],
		'ref $$aref[0] =~ /CODE/'        => ['=~','/CODE/'],
		'ref $$aref[0] eq "CODE" && 1'   => ['eq','code'],
		'ref $$aref[0] eq "CODE"'        => ['eq','code'],
		'ref $$aref[0] eq ref $y'        => ['eq','ref'],
		'ref $$aref[0] ne "CODE"?1:0'    => ['ne','code'],
		'ref $$aref[0]'                  => [undef],
		'ref $href->{k} !~ /ARRAY/'      => ['!~','/ARRAY/'],
		'ref $href->{k} && $x=~/\d/'     => [undef],
		'ref $href->{k} =~ /CODE/'       => ['=~','/CODE/'],
		'ref $href->{k} eq "CODE" && 1'  => ['eq','code'],
		'ref $href->{k} eq "CODE"'       => ['eq','code'],
		'ref $href->{k} eq ref $y'       => ['eq','ref'],
		'ref $href->{k} ne "CODE"?1:0'   => ['ne','code'],
		'ref $href->{k}'                 => [undef],
		'ref($$aref[0]) !~ /ARRAY/'      => ['!~','/ARRAY/'],
		'ref($$aref[0]) && $x=~/\d/'     => [undef],
		'ref($$aref[0]) =~ /CODE/'       => ['=~','/CODE/'],
		'ref($$aref[0]) eq "CODE" && 1'  => ['eq','code'],
		'ref($$aref[0]) eq "CODE"'       => ['eq','code'],
		'ref($$aref[0]) eq ref $y'       => ['eq','ref'],
		'ref($$aref[0]) ne "CODE"?1:0'   => ['ne','code'],
		'ref($$aref[0])'                 => [undef],
		'ref($href->{k}) !~ /ARRAY/'     => ['!~','/ARRAY/'],
		'ref($href->{k}) && $x=~/\d/'    => [undef],
		'ref($href->{k}) =~ /CODE/'      => ['=~','/CODE/'],
		'ref($href->{k}) eq "CODE" && 1' => ['eq','code'],
		'ref($href->{k}) eq "CODE"'      => ['eq','code'],
		'ref($href->{k}) eq ref $y'      => ['eq','ref'],
		'ref($href->{k}) ne "CODE"?1:0'  => ['ne','code'],
		'ref($href->{k})'                => [undef],
	);
	while(my ($code,$expect)=each %tests) { is_deeply([&$decompose($code)],$expect,"decompose:  $code") }
};

subtest 'Valid Ref::Util'=>sub {
	plan tests=>384;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitRefChecks');
	foreach my $whitespace ('',' ') {
	foreach my $parens (0,1) {
	foreach my $var ('$var','$array[0]','$hash{key}','$$sref','$$aref[0]','$$href{key}','$aref->[0]','$href->{key}') {
	foreach my $op (' ','!') {
	foreach my $type (qw/is_arrayref is_hashref is_scalarref is_coderef is_globref is_formatref/) {
		my $code=sprintf('%s%s%s%s%s%s'
			,$op
			,$type
			,$whitespace
			,($parens?'(':($whitespace||' ')) # )
			,$var # ( for next line
			,($parens?')':'')
			);
		my $label=sprintf('%14s %s %12s %s%s'
			,lc($type)
			,$op
			,$var
			,($whitespace?'w':'')
			,($parens?'p':'')
			);
		is_deeply([$critic->critique(\$code)],[],$code);
	} } } } }
};

subtest 'Default eq/ne/regexp/bare'=>sub {
	plan tests=>1409;
	#
	# Verify the fast-failure scenario first.
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitRefChecks');
	like(($critic->critique(\'if(ref $x)'))[0],$failure,'fast failure if(ref $x)');
	#
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitRefChecks',-params=>{eq=>'nothing'});
	#
	# eq/ne
	foreach my $whitespace ('',' ') {
	foreach my $parens (0,1) {
	foreach my $var ('$var','$array[0]','$hash{key}','$$sref','$$aref[0]','$$href{key}','$aref->[0]','$href->{key}') {
	foreach my $op (qw/eq ne/) {
	foreach my $quote ("'",'"') {
	foreach my $type (qw/ARRAY HASH SCALAR CODE GLOB FORMAT/) {
		my $code=sprintf('ref%s%s%s%s %s %s%s%s'
			,$whitespace
			,($parens?'(':($whitespace||' ')) # )
			,$var # ( for next line
			,($parens?')':'')
			,$op
			,$quote
			,$type
			,$quote);
		like(($critic->critique(\$code))[0],$failure,$code);
	} } } } } }
	#
	# regexp
	foreach my $whitespace ('',' ') {
	foreach my $parens (0,1) {
	foreach my $var ('$var','$array[0]','$hash{key}','$$sref','$$aref[0]','$$href{key}','$aref->[0]','$href->{key}') {
	foreach my $op ('=~','!~') {
	foreach my $type (map {"/$_/"} qw/ARRAY HASH SCALAR CODE GLOB FORMAT/) {
		my $code=sprintf('ref%s%s%s%s %s%s%s'
			,$whitespace
			,($parens?'(':($whitespace||' ')) # )
			,$var # ( for next line
			,($parens?')':'')
			,$op
			,$whitespace
			,$type);
		like(($critic->critique(\$code))[0],$failure,$code);
	} } } } }
	#
	# bare ref check
	foreach my $condition (qw/if unless while function/) {
	foreach my $whitespace ('',' ') {
	foreach my $parens (0,1) {
	foreach my $var ('$var','$array[0]','$hash{key}','$$sref','$$aref[0]','$$href{key}','$aref->[0]','$href->{key}') {
	foreach my $op (' ','!') {
		my $code=sprintf('%s(%sref%s%s%s%s)'
			,$condition
			,$op
			,$whitespace
			,($parens?'(':($whitespace||' ')) # )
			,$var # ( for next line
			,($parens?')':'')
			);
		like(($critic->critique(\$code))[0],$failure,$code);
	} } } } }
};

subtest 'eq parameter'=>sub {
	plan tests=>2*2*8*2*2*6*3;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitRefChecks',-params=>{eq=>'code'});
	#
	# eq/ne
	foreach my $whitespace ('',' ') {
	foreach my $parens (0,1) {
	foreach my $var ('$var','$array[0]','$hash{key}','$$sref','$$aref[0]','$$href{key}','$aref->[0]','$href->{key}') {
	foreach my $op (qw/eq ne/) {
	foreach my $quote ("'",'"') {
	foreach my $type (qw/ARRAY HASH SCALAR CODE GLOB FORMAT/) {
	foreach my $suffix ('',' && ref $y eq "CODE"',' ? $x eq "foo" : $y eq "bar"') {
		my $code=sprintf('ref%s%s%s%s %s %s%s%s%s'
			,$whitespace
			,($parens?'(':($whitespace||' ')) # )
			,$var # ( for next line
			,($parens?')':'')
			,$op
			,$quote
			,$type
			,$quote
			,$suffix
			);
		if(($op eq 'eq')&&($type eq 'CODE')) { is_deeply([$critic->critique(\$code)],[],$code) }
		else { like(($critic->critique(\$code))[0],$failure,$code) }
	} } } } } } }
};

subtest 'ne parameter'=>sub {
	plan tests=>2*2*8*2*2*6*3;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitRefChecks',-params=>{ne=>'code'});
	#
	# eq/ne
	foreach my $whitespace ('',' ') {
	foreach my $parens (0,1) {
	foreach my $var ('$var','$array[0]','$hash{key}','$$sref','$$aref[0]','$$href{key}','$aref->[0]','$href->{key}') {
	foreach my $op (qw/eq ne/) {
	foreach my $quote ("'",'"') {
	foreach my $type (qw/ARRAY HASH SCALAR CODE GLOB FORMAT/) {
	foreach my $suffix ('',' && ref $y ne "CODE"',' ? $x eq "foo" : $y eq "bar"') {
		my $code=sprintf('ref%s%s%s%s %s %s%s%s%s'
			,$whitespace
			,($parens?'(':($whitespace||' ')) # )
			,$var # ( for next line
			,($parens?')':'')
			,$op
			,$quote
			,$type
			,$quote
			,$suffix
			);
		if(($op eq 'ne')&&($type eq 'CODE')) { is_deeply([$critic->critique(\$code)],[],$code) }
		else { like(($critic->critique(\$code))[0],$failure,$code) }
	} } } } } } }
};

subtest 'regexp parameter'=>sub {
	plan tests=>384;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitRefChecks',-params=>{regexp=>1});
	#
	# regexp
	foreach my $whitespace ('',' ') {
	foreach my $parens (0,1) {
	foreach my $var ('$var','$array[0]','$hash{key}','$$sref','$$aref[0]','$$href{key}','$aref->[0]','$href->{key}') {
	foreach my $op ('=~','!~') {
	foreach my $type (map {"/$_/"} qw/ARRAY HASH SCALAR CODE GLOB FORMAT/) {
		my $code=sprintf('ref%s%s%s%s %s%s%s'
			,$whitespace
			,($parens?'(':($whitespace||' ')) # )
			,$var # ( for next line
			,($parens?')':'')
			,$op
			,$whitespace
			,$type);
		is_deeply([$critic->critique(\$code)],[],$code);
	} } } } }
};

subtest 'bareref parameter'=>sub {
	plan tests=>768;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitRefChecks',-params=>{bareref=>1});
	#
	# bare ref check
	foreach my $condition (qw/if unless while function/) {
	foreach my $whitespace ('',' ') {
	foreach my $parens (0,1) {
	foreach my $var ('$var','$array[0]','$hash{key}','$$sref','$$aref[0]','$$href{key}','$aref->[0]','$href->{key}') {
	foreach my $op (' ','!') {
	foreach my $suffix ('',' && $x=~/\d/',' || $x eq "A"') {
		my $code=sprintf('%s(%sref%s%s%s%s%s)'
			,$condition
			,$op
			,$whitespace
			,($parens?'(':($whitespace||' ')) # )
			,$var # ( for next line
			,($parens?')':'')
			,$suffix
			);
		is_deeply([$critic->critique(\$code)],[],$code);
	} } } } } }
};

subtest 'ref eq ref'=>sub {
	plan tests=>128;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitRefChecks',-params=>{eq=>'ref'});
	#
	# eq/ne
	foreach my $whitespace ('',' ') {
	foreach my $parens (0,1) {
	foreach my $var ('$var','$array[0]','$hash{key}','$$sref','$$aref[0]','$$href{key}','$aref->[0]','$href->{key}') {
	foreach my $op (qw/eq ne/) {
	foreach my $rhs ('ref($x)','ref $x') {
		my $code=sprintf('ref%s%s%s%s %s %s'
			,$whitespace
			,($parens?'(':($whitespace||' ')) # )
			,$var # ( for next line
			,($parens?')':'')
			,$op
			,$rhs);
		if($op eq 'eq') { is_deeply([$critic->critique(\$code)],[],$code) }
		else { like(($critic->critique(\$code))[0],$failure,$code) }
	} } } } }
};

subtest 'ref ne ref'=>sub {
	plan tests=>128;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitRefChecks',-params=>{ne=>'ref'});
	#
	# eq/ne
	foreach my $whitespace ('',' ') {
	foreach my $parens (0,1) {
	foreach my $var ('$var','$array[0]','$hash{key}','$$sref','$$aref[0]','$$href{key}','$aref->[0]','$href->{key}') {
	foreach my $op (qw/eq ne/) {
	foreach my $rhs ('ref($x)','ref $x') {
		my $code=sprintf('ref%s%s%s%s %s %s'
			,$whitespace
			,($parens?'(':($whitespace||' ')) # )
			,$var # ( for next line
			,($parens?')':'')
			,$op
			,$rhs);
		if($op eq 'ne') { is_deeply([$critic->critique(\$code)],[],$code) }
		else { like(($critic->critique(\$code))[0],$failure,$code) }
	} } } } }
};

subtest 'Valid various'=>sub {
	plan tests=>4;
	my $code;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitRefChecks');
	ok(join('',map {$_->get_themes()} $critic->policies()),'themes');
	#
	$code='$x=Module->ref($x)'; is_deeply([$critic->critique(\$code)],[],$code);
	$code='sub ref { return }'; is_deeply([$critic->critique(\$code)],[],$code);
	$code='if("ARRAY" eq ref($x))'; is_deeply([$critic->critique(\$code)],[],$code);
};

subtest 'Invalid various'=>sub {
	plan tests=>6;
	my $code;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::References::ProhibitRefChecks',-params=>{eq=>'nothing'});
	#
	$code='if(ref($x) eq $string)';     like(($critic->critique(\$code))[0],$failure,$code);
	$code='if(lc(ref($x)) eq "array")'; like(($critic->critique(\$code))[0],$failure,$code);
	$code='if(lc ref($x)  eq "array")'; like(($critic->critique(\$code))[0],$failure,$code);
	$code='if(ref($x) cmp "ARRAY")';    like(($critic->critique(\$code))[0],$failure,$code);
	$code='if("ARRAY" cmp ref($x))';    like(($critic->critique(\$code))[0],$failure,$code);
	$code='$s=ref($x).ref($y)';         like(($critic->critique(\$code))[0],$failure,$code);
};

subtest 'Other'=>sub {
	plan tests=>1;
	require Perl::Critic::Policy::References::ProhibitRefChecks;
	ok(!Perl::Critic::Policy::References::ProhibitRefChecks::violates(undef,bless({},'PPI::Token')),'Only applies to Token::Word');
};

