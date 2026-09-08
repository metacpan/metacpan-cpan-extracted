#!/usr/bin/perl

use strict;
use warnings;
use Perl::Critic;
use Perl::Critic::Policy::Subroutines::RequireConsistentReturn;
use PPI;

use Test::More tests=>5;

my $failure=qr/implicit return.*explicit returns/;

subtest 'Detecting return statements in the block'=>sub {
	plan tests=>61;
	my $hasReturn=\&Perl::Critic::Policy::Subroutines::RequireConsistentReturn::hasReturn;
	foreach my $code (
		q|return|,
		q|return 5|,
		q|return (5)|,
		q|return {}|,
		q|if(0){return}|,
		q|while(0){return}|,
		q|1 && return|,
		q|$x=sub{return};return 0|,
		q|if(0){while(0){return}}|,
		q|if(0){1}else{return}|,
		q|1;sub aa{return 2};return 3|,
		q|{return}|,
		q|{return 5}|,
		q|{return (5)}|,
		q|{return {}}|,
		q|if(1){return {return=>1}}else{+{return=>0}}|,
		q|if(1){+{return=>1}}else{return {return=>0}}|,
		q|return if 7;3|,
		q|return unless 7;3|,
		q|return while(1);3|,
		q|return foreach(1);3|,
	) {
		ok(&$hasReturn(1,PPI::Document->new(\qq|{$code}|)),"Has return:  $code");
	}
	foreach my $code (
		q|0|,
		q|1|,
		q|(1)|,
		q|{1}|,
		q|+{1,2}|,
		q|undef|,
		q|while(0){1}|,
		q|1 && 2|,
		q|$x=sub{return};0|,
		q|1;sub aa{return 2};3|,
		q|my %x=(return=>1);3|,
	) {
		ok(!&$hasReturn(1,PPI::Document->new(\qq|{$code}|)),"No return:  $code");
	}
	#
	# Bare return cases
	foreach my $code (
		q|return 5|,
		q|return (5)|,
		q|return {}|,
		q|$x=sub{return};return 0|,
		q|1;sub aa{return 2};return 3|,
		q|{return 5}|,
		q|{return (5)}|,
		q|{return {}}|,
	) {
		ok(&$hasReturn(0,PPI::Document->new(\qq|{$code}|)),"Has return:  $code");
	}
	foreach my $code (
		q|return;7|,
		q|if(0){return}|,
		q|while(0){return}|,
		q|1 && return|,
		q|if(0){while(0){return}}|,
		q|if(0){1}else{return}|,
		q|{return}|,
		#
		q|0|,
		q|1|,
		q|(1)|,
		q|{1}|,
		q|+{1,2}|,
		q|undef|,
		q|while(0){1}|,
		q|1 && 2|,
		q|$x=sub{return};0|,
		q|1;sub aa{return 2};3|,
		q|return if 7;3|,
		q|return unless 7;3|,
		q|return while(1);3|,
		q|return foreach(1);3|,
	) {
		ok(!&$hasReturn(0,PPI::Document->new(\qq|{$code}|)),"No return:  $code");
	}
};

subtest 'Finding all the finals in a block'=>sub {
	plan tests=>16;
	my $finals=\&Perl::Critic::Policy::Subroutines::RequireConsistentReturn::finals;
	foreach my $test (
		[1,q|1|],
		[1,q|0 && 8|],
		[1,q|return 1|],
		[2,q|if(1){1}else{2}|],
		[3,q|if(1){1}elsif(1){2}else{3}|],
		[1,q|my $x=do{8}|],
		[0,q|1;while(1){1}|],
		[0,q|1;foreach (1,2,3){4}|],
		[0,q|1;for(1;1;1){4}|],
		[1,q|1;;;|],
		[1,q|if(1){return {return=>3}}|],
		[1,q|if(1){return +{return=>3}}|],
		[1,q|if(1){+{return=>3}}|],
		[2,q|if(1){return {return=>3}}else{return {return=>2}}|],
		[2,q|if(1){return +{return=>3}}else{return +{return=>2}}|],
		[2,q|if(1){+{return=>3}}else{+{return=>2}}|],
	) {
		my @finals=&$finals(PPI::Document->new(\qq|{$$test[1]}|));
		is(scalar(grep {$_->isa('PPI::Node')} @finals),$$test[0],"$$test[0] final:  $$test[1]");
	}
};

subtest 'Valid'=>sub {
	plan tests=>40;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Subroutines::RequireConsistentReturn',-params=>{bare=>1});
	#
	foreach my $code (
		q|sub aa{}|,
		q|sub aa{7}|,
		q|sub aa{{7}}|,
		q|sub aa{(7)}|,
		q|sub aa{(7,8,9)}|,
		q|sub aa{7;;;}|,
		q|sub aa{return 7}|,
		q|sub aa{return (7)}|,
		q|sub aa{return (7,8)}|,
		q|sub aa{return {}}|,
		q|sub aa{return {7,8}}|,
		q|sub aa{return 7;;;;}|,
		q|sub aa{return f();;;;}|,
		q|sub aa{if($x){return 7};return 2*$y;}|,
		q|sub aa{if($x){return 7};return f();}|,
		q|sub aa{if($x){7}else{9}}|,
		q|sub aa{if($x){f()}else{g()}}|,
		q|sub aa{if($x){return 7}else{return 9}}|,
		q|sub aa{if($x){return f()}else{return g()}}|,
		q|sub aa{my $x=sub{return 5};9}|,
		q|sub aa{if($x){return 7};die "Unhandled";}|,
		q|sub aa{if($x){return 7};croak "Unhandled";}|,
		q|sub aa{if($x){return 7};confess "Unhandled";}|,
		q|sub aa{if($x){return 7};exit(1);}|,
		q|sub aa{if(1){return 7}}|,
		q|sub aa{if(1){return 7}elsif(1){return 8}else{return 9}}|,
		q|sub aa{if($x){return};return;}|,
		q|sub aa{my $x=sub{return;}|,
		q|sub aa{if($x){return};die "Unhandled";}|,
		q|sub aa{if($x){return};croak "Unhandled";}|,
		q|sub aa{if($x){return};confess "Unhandled";}|,
		q|sub aa{if(1){return}}|,
		q|sub aa{if(1){return}elsif(1){return}else{return}}|,
		q|sub aa{if(1){return};foreach (1){}}|,
		q|sub aa{if(1){return};for(1;1;1){}}|,
		q|sub aa{my %x=(return=>1);3}|,
		q|sub aa{my %x=(return=>1);f()}|,
		q|sub aa{if(1){+{return=>1}}else{+{return=>0}}}|,
		q|sub aa{if(1){return {return=>1}}else{return {return=>0}}}|,
		q|sub aa{if(1){return 7};...;|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
};

subtest 'Invalid'=>sub {
	plan tests=>20;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Subroutines::RequireConsistentReturn',-params=>{bare=>1});
	#
	foreach my $code (
		q|sub aa{return;7}|,
		q|sub aa{return;{7}|,
		q|sub aa{return;{7,8}|,
		q|sub aa{return;{(7,8)}|,
		q|sub aa{return;f()}|,
		q|sub aa{return;7;;;;|,
		q|sub aa{if($x){return 7};2*$y;}|,
		q|sub aa{if($x){return 7};f();}|,
		q|sub aa{if($x){return 7}else{9}}|,
		q|sub aa{if($x){7}else{return 9}}|,
		q|sub aa{if($x){return f()}else{g()}}|,
		q|sub aa{if($x){f()}else{return g()}}|,
		q|sub aa{if($x){return 7}else{9};5}|,
		q|sub aa{if($x){7}else{return 9};5}|,
		q|sub aa{return;(7)|,
		q|sub aa{return;{7}|,
		q|sub aa{return;7&&9}|,
		q|sub aa{if($x){return 7};"Unhandled";}|,
		q|sub aa{if(1){return {return=>1}}else{+{return=>0}}}|,
		q|sub aa{if(1){+{return=>1}}else{return {return=>0}}}|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

subtest 'Bare returns ignored'=>sub {
	plan tests=>54;
	my $critic=Perl::Critic->new(-profile=>'NONE',-only=>1,-severity=>1);
	$critic->add_policy(-policy=>'Perl::Critic::Policy::Subroutines::RequireConsistentReturn',-params=>{bare=>0});
	#
	foreach my $code (
		q|sub aa{7}|,
		q|sub aa{{7}}|,
		q|sub aa{(7)}|,
		q|sub aa{(7,8,9)}|,
		q|sub aa{7;;;}|,
		q|sub aa{return 7}|,
		q|sub aa{return (7)}|,
		q|sub aa{return (7,8)}|,
		q|sub aa{return {}}|,
		q|sub aa{return {7,8}}|,
		q|sub aa{return 7;;;;}|,
		q|sub aa{if($x){return 7};return 2*$y;}|,
		q|sub aa{if($x){7}else{9}}|,
		q|sub aa{if($x){return 7}else{return 9}}|,
		q|sub aa{my $x=sub{return 5};9}|,
		q|sub aa{if($x){return 7};die "Unhandled";}|,
		q|sub aa{if($x){return 7};croak "Unhandled";}|,
		q|sub aa{if(1){return 7}}|,
		q|sub aa{if(1){return 7}elsif(1){return 8}else{return 9}}|,
		q|sub aa{if($x){return};return;}|,
		q|sub aa{my $x=sub{return;}|,
		q|sub aa{if($x){return};die "Unhandled";}|,
		q|sub aa{if($x){return};croak "Unhandled";}|,
		q|sub aa{if($x){return};confess "Unhandled";}|,
		q|sub aa{if(1){return}}|,
		q|sub aa{if(1){return}elsif(1){return}else{return}}|,
		q|sub aa{if(1){return};foreach (1){}}|,
		q|sub aa{if(1){return};for(1;1;1){}}|,
		#
		q|sub aa{return;7}|,
		q|sub aa{return;{7}|,
		q|sub aa{return;{7,8}|,
		q|sub aa{return;{(7,8)}|,
		q|sub aa{return;7;;;;|,
		q|sub aa{return;(7)|,
		q|sub aa{return;{7}|,
		q|sub aa{return;7&&9}|,
		q|sub aa{return if 1;7|,
		q|sub aa{return unless 1;7|,
		q|sub aa{return while(1);7|,
		q|sub aa{return foreach(1);7|,
	) {
		is_deeply([$critic->critique(\$code)],[],$code);
	}
	#
	foreach my $code (
		q|sub aa{return 5;7}|,
		q|sub aa{return 5;{7}|,
		q|sub aa{return 5;{7,8}|,
		q|sub aa{return 5;{(7,8)}|,
		q|sub aa{return 5;7;;;;|,
		q|sub aa{return 5;(7)|,
		q|sub aa{return 5;{7}|,
		q|sub aa{return 5;7&&9}|,
		q|sub aa{if($x){return 7};2*$y;}|,
		q|sub aa{if($x){return 7}else{9}}|,
		q|sub aa{if($x){7}else{return 9}}|,
		q|sub aa{if($x){return 7}else{9};5}|,
		q|sub aa{if($x){7}else{return 9};5}|,
		q|sub aa{if($x){return 7};"Unhandled";}|,
	) {
		like(($critic->critique(\$code))[0],$failure,$code);
	}
};

