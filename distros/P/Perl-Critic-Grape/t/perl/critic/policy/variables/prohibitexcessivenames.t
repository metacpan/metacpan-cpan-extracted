#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;
use Perl::Critic::Policy::Variables::ProhibitExcessiveNames;

use Test::More tests=>7;

my $failure=qr/Use concise names/;

subtest 'Splitting'=>sub {
	plan tests=>22;
	my $f=\&Perl::Critic::Policy::Variables::ProhibitExcessiveNames::splitter;
	foreach my $test (
		['some_subroutine_name',        [qw/some subroutine name/]],
		['someSubroutineName',          [qw/some Subroutine Name/]],
		['Package::someSubroutineName', [qw/some Subroutine Name/]],
		#
		['$some_variable_name',         [qw/some variable name/]],
		['$someVariableName',           [qw/some Variable Name/]],
		['$Package::someVariableName',  [qw/some Variable Name/]],
		['@some_variable_name',         [qw/some variable name/]],
		['%some_variable_name',         [qw/some variable name/]],
		#
		['_some_subroutine_name',       [qw/some subroutine name/]],
		['_someSubroutineName',         [qw/some Subroutine Name/]],
		['Package::_someSubroutineName',[qw/some Subroutine Name/]],
		['__some_subroutine_name',      [qw/some subroutine name/]],
		['__someSubroutineName',        [qw/some Subroutine Name/]],
		['___some_subroutine_name',     [qw/some subroutine name/]],
		['___someSubroutineName',       [qw/some Subroutine Name/]],
		#
		['GLOBAL',                      [qw/GLOBAL/]],
		['GLOBAL_CONSTANT',             [qw/GLOBAL CONSTANT/]],
		['Package_Constant',            [qw/Package Constant/]],
		['PackageConstant',             [qw/Package Constant/]],
		#
		['$thing73',                    [qw/thing73/]],
		['$bigThing73',                 [qw/big Thing73/]],
		['$big_thing73',                [qw/big thing73/]],
		#
	) {
		is_deeply([&$f($$test[0])],$$test[1],$$test[0]);
	}
};

subtest 'Happiness'=>sub {
	plan tests=>19;
	my $f=\&Perl::Critic::Policy::Variables::ProhibitExcessiveNames::happy;
	foreach my $test (
		['$word',           3,15,7,4,0],
		['$bigger_words',   3,15,7,4,0],
		['$thing_password', 3,15,7,4,0],
		['$rampingShingle', 3,15,7,4,0],
		#
		['$thing_num',                 3,15,7,4,9],
		['$ramping_shingle',           3,15,7,4,15],
		['$_rampingShingle',           3,15,7,4,15],
		['$translate_thing_from_json', 3,15,7,4,25],
		['$translateThingFromJson',    3,15,7,4,22],
	) {
		ok(&$f(@$test),"@$test");
	}
	#
	foreach my $test (
		['$thing_num',                 3,15,7,4,0],
		['$ramping_shingle',           3,15,7,4,0],
		['$_rampingShingle',           3,15,7,4,0],
		['$translate_thing_from_json', 3,15,7,4,0],
		['$translateThingFromJson',    3,15,7,4,0],
		#
		['$thing_num',                 3,15,7,4,8],
		['$ramping_shingle',           3,15,7,4,14],
		['$_rampingShingle',           3,15,7,4,14],
		['$translate_thing_from_json', 3,15,7,4,24],
		['$translateThingFromJson',    3,15,7,4,21],
	) {
		ok(!&$f(@$test),"@$test");
	}
};

subtest 'Invalid cases (short=0)'=>sub {
	plan tests=>18;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{short=>0});
	foreach my $code (
		q|my $ventrocystorrhaphy;|, # length
		q|my $AbCdEfGh;|,           # words (but also small multiword)
		q|my $abcSomething;|,       # smallest
		q|my $unarguMentative|,     # lpw
		#
		q|my ($xOne,$y,$z)=@_;|,
		q|my ($x,$yOne,$z)=@_;|,
		q|my ($x,$y,$zOne)=@_;|,
		q|my (@xOne,@y,@z)=@_;|,
		q|my (@x,@yOne,@z)=@_;|,
		q|my (@x,@y,@zOne)=@_;|,
		q|my (%xOne,%y,%z)=%_;|,
		q|my (%x,%yOne,%z)=%_;|,
		q|my (%x,%y,%zOne)=%_;|,
		#
		q|sub ventrocystorrhaphy {}|, # length
		q|sub AbCdEfGh {}|,           # words (but also small multiword)
		q|sub abcSomething {}|,       # smallest
		q|sub unarguMentative {}|,    # lpw
		#
		q|my $precheckCookies=8;|,    # lpw violation
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

subtest 'Valid cases'=>sub {
	plan tests=>18;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{});
	foreach my $code (
		q|my $ventrocystorrha;|, # length
		q|my $AbcdEfghIjkl;|,    # words
		q|my $abcdSomething;|,   # smallest
		q|my $remuNeratively|,   # lpw
		#
		q|my ($x,$y,$z)=@_;|,
		q|my ($xa,$ya,$za)=@_;|,
		q|my (@x,@y,@z)=@_;|,
		q|my (@xa,@ya,@za)=@_;|,
		q|my (%x,%y,%z)=@_;|,
		q|my (%xa,%ya,%za)=@_;|,
		q|my ($firstPotato,$secondPotato,$thirdPotato)=@_;|,
		q|my (@firstPotato,@secondPotato,@thirdPotato)=@_;|,
		q|my (%firstPotato,%secondPotato,%thirdPotato)=@_;|,
		#
		q|sub ventrocystorrha {}|, # length
		q|sub AbcdEfghIjkl {}|,    # words
		q|sub abcdSomething {}|,   # smallest
		q|sub remuNeratively {}|,  # lpw
		#
		q|our $VERSION=7;|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

subtest 'Option:  subs'=>sub {
	plan tests=>8;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{subs=>0});
	foreach my $code (
		q|my $ventrocystorrhaphy;|, # length
		q|my $AbCdEfGh;|,           # words (but also small multiword)
		q|my $abcSomething;|,       # smallest
		q|my $unarguMentative|,     # lpw
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
	foreach my $code (
		q|sub ventrocystorrhaphy {}|, # length
		q|sub AbCdEfGh {}|,           # words (but also small multiword)
		q|sub abcSomething {}|,       # smallest
		q|sub unarguMentative {}|,    # lpw
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

subtest 'Option:  vars'=>sub {
	plan tests=>8;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{vars=>0});
	foreach my $code (
		q|my $ventrocystorrhaphy;|, # length
		q|my $AbCdEfGh;|,           # words (but also small multiword)
		q|my $abcSomething;|,       # smallest
		q|my $unarguMentative|,     # lpw
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	foreach my $code (
		q|sub ventrocystorrhaphy {}|, # length
		q|sub AbCdEfGh {}|,           # words (but also small multiword)
		q|sub abcSomething {}|,       # smallest
		q|sub unarguMentative {}|,    # lpw
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

subtest 'Options:  lwsl'=>sub {
	plan tests=>48;
	my $critic;
	#
	# length
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{
		length  =>20,
		words   =>8,
		smallest=>1,
		lpw     =>20,
		short   =>0,
	});
	foreach my $code (
		q|my $anthracitePerchromic|,
		q|sub anthracitePerchromic {}|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	foreach my $code (
		q|my $anthracite_perchromic|,
		q|sub anthracite_perchromic {}|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
	#
	# words
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{
		length  =>40,
		words   =>4,
		smallest=>1,
		lpw     =>20,
		short   =>0,
	});
	foreach my $code (
		q|my $oneTwoThreeFour|,
		q|my $one_two_three_four|,
		q|sub oneTwoThreeFour {}|,
		q|sub one_two_three_four {}|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	foreach my $code (
		q|my $oneTwoThreeFourFive|,
		q|my $one_two_three_four_five|,
		q|sub oneTwoThreeFourFive {}|,
		q|sub one_two_three_four_five {}|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
	#
	# smallest
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{
		length  =>40,
		words   =>4,
		smallest=>3,
		lpw     =>20,
		short   =>0,
	});
	foreach my $code (
		q|my $aaaBbbCcc|,
		q|my $aaa_bbb_ccc|,
		q|sub aaaBbbCcc {}|,
		q|sub aaa_bbb_ccc {}|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	foreach my $code (
		q|my $aaBbbCcc|,
		q|my $aaaBbCcc|,
		q|my $aaaBbbCc|,
		q|my $aa_bbb_ccc|,
		q|my $aaa_bb_ccc|,
		q|my $aaa_bbb_cc|,
		q|sub aaBbbCcc {}|,
		q|sub aaaBbCcc {}|,
		q|sub aaaBbbCc {}|,
		q|sub aa_bbb_ccc {}|,
		q|sub aaa_bb_ccc {}|,
		q|sub aaa_bbb_cc {}|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
	#
	# lpw
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{
		length  =>40,
		words   =>3,
		smallest=>1,
		lpw     =>5,
		short   =>0,
	});
	foreach my $code (
		q|my $cliffRotor|,
		q|my $cliffRotorThumb|,
		q|sub cliffRotor {}|,
		q|sub cliffRotorThumb {}|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	foreach my $code (
		q|my $cliff_rotor|,
		q|my $cliffRotorThumby|,
		q|sub cliff_rotor {}|,
		q|sub cliffRotorThumby {}|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
	#
	# short
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{
		length  =>40,
		words   =>3,
		smallest=>3,
		lpw     =>7,
		short   =>6,
	});
	foreach my $code (
		q|my $aBbCcD|,
		q|my $aaBbCc|,
		q|my $pAB|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	foreach my $code (
		q|my $aaBbCcc|,
		q|my $aaBbCcDd|,
		q|my $p_Ab__C|,
		q|my $p_A_B_C|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
	#
	# edge cases, length=0
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{
		length  =>0,
		words   =>3,
		smallest=>3,
		lpw     =>7,
		short   =>0,
	});
	foreach my $code (
		q|my $thymolsulphonephthaleinabc123def456ghi|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	#
	# edge cases, words=0
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{
		length  =>15,
		words   =>0,
		smallest=>1,
		lpw     =>7,
		short   =>0,
	});
	foreach my $code (
		q|my $a_b_c_d_e_f_g_h|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	#
	# edge cases, smallest=0
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{
		length  =>15,
		words   =>3,
		smallest=>0,
		lpw     =>7,
		short   =>0,
	});
	foreach my $code (
		q|my $aaaBbC|,
		q|my $_a_b_c|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	#
	# edge cases, lpw=0
	$critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Variables::ProhibitExcessiveNames',-params=>{
		length  =>40,
		words   =>3,
		smallest=>3,
		lpw     =>0,
		short   =>0,
	});
	foreach my $code (
		q|my $thymolsulpho_nephthaleinabc_123def456ghi|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

# Issues to consider, build, and test:

# test for different variable sigils:  %hash, @array
# CONSTANTS
# CapitalConstants
# ___multipleInitial
# ___multiple_initial
# 
# abbreviations like loadFromPNG

# Honestly, I say release as-as and worry about todo/improvements later.

# edge cases for configurations:
# negative values?
# real values?


