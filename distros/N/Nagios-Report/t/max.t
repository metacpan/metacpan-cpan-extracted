#!/usr/bin/perl -w

#

use Test;

use Nagios::Report ;


# Each element in this array is a single test. Storing them this way makes
# maintenance easy, and should be OK since perl should be pretty functional
# before these tests are run.

$tests = <<'EOTESTS' ;
# Scalar expression 
# 1==1,

$max = &max_l() ;			not defined($max)
$max = &max_l(0) ;			$max == 0 
$max = &max_l(1) and			$max == 1
$max = &max_l(-1, 1)  and		$max == 1
$max = &max_l(0, 0, 0, 0, 0, 1) and	$max == 1
$max = &max_l(0, 0, 0, 0, 0, -1) ;	$max == 0
$max = &max_l(1..20) and		$max == 20

EOTESTS

@t = split /\n/, $tests ;
@tests = grep !( m<\s*#> or m<^\s*$> ), @t ;

plan tests => scalar(@tests) ;
# plan tests => scalar(@tests) + 1 ;


for ( @tests ) {

  $sub = eval "sub { $_ }" ;

  warn "sub { $_ } fails to compile: $@"
    if $@ ;

  ok $sub  ;

  1 ;
}

