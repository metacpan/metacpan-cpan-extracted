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

($s, $m, $h, $d, $mm, $y) = localtime; $now = (Nagios::Report::EURO_DATE ? "$d-" . ($mm + 1) : ($mm + 1) . "-$d") . '-' . ($y + 1900) . " $h:$m:$s"; $t=time()
# ($s, $m, $h, $d, $mm, $y) = localtime; ($s, $m, $h) = map length($_) < 2 ? "0$_" : $_, ($s, $m, $h); $now = (Nagios::Report::EURO_DATE ? "$d-" . ($mm + 1) : ($mm + 1) . "-$d") . '-' . ($y + 1900) . " $h:$m:$s"; $t=time()
$si = Nagios::Report::before_start($now, $t - 1);     $si == 0
$si = Nagios::Report::before_start($now, $t + 3_600); $si == 1
$si = Nagios::Report::before_start($now, $t - 3_600); $si == 0


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

