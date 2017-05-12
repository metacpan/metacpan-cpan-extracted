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

$n = Nagios::Report->new(q<dev_debug from_data_handle>, [q<Test>]) ;
ref($n)							=~ /Nagios::Report/


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

{ 
  my $data ; 

  sub from_data_handle {

    my $rep_period = shift @_ ;

    my @avail_rep = () ;

    local $/ = undef ;
    $data = <DATA> 
      unless $data ;

    my ($r) = $data =~ /^# $rep_period\n(.*?)^END_OF_FILE_MARKER/sm ;
  
    @avail_rep = split /\n/, $r ;

    @avail_rep ;

  }
}

__DATA__
# Test
HOST_NAME, TIME_UP_SCHEDULED, PERCENT_TIME_UP_SCHEDULED, PERCENT_KNOWN_TIME_UP_SCHEDULED, TIME_UP_UNSCHEDULED, PERCENT_TIME_UP_UNSCHEDULED, PERCENT_KNOWN_TIME_UP_UNSCHEDULED, TOTAL_TIME_UP, PERCENT_TOTAL_TIME_UP, PERCENT_KNOWN_TIME_UP, TIME_DOWN_SCHEDULED, PERCENT_TIME_DOWN_SCHEDULED, PERCENT_KNOWN_TIME_DOWN_SCHEDULED, TIME_DOWN_UNSCHEDULED, PERCENT_TIME_DOWN_UNSCHEDULED, PERCENT_KNOWN_TIME_DOWN_UNSCHEDULED, TOTAL_TIME_DOWN, PERCENT_TOTAL_TIME_DOWN, PERCENT_KNOWN_TIME_DOWN, TIME_UNREACHABLE_SCHEDULED, PERCENT_TIME_UNREACHABLE_SCHEDULED, PERCENT_KNOWN_TIME_UNREACHABLE_SCHEDULED, TIME_UNREACHABLE_UNSCHEDULED, PERCENT_TIME_UNREACHABLE_UNSCHEDULED, PERCENT_KNOWN_TIME_UNREACHABLE_UNSCHEDULED, TOTAL_TIME_UNREACHABLE, PERCENT_TOTAL_TIME_UNREACHABLE, PERCENT_KNOWN_TIME_UNREACHABLE, TIME_UNDETERMINED_NOT_RUNNING, PERCENT_TIME_UNDETERMINED_NOT_RUNNING, TIME_UNDETERMINED_NO_DATA, PERCENT_TIME_UNDETERMINED_NO_DATA, TOTAL_TIME_UNDETERMINED, PERCENT_TOTAL_TIME_UNDETERMINED
"16_Mort_St_Optus_router_PE_interface", 0, 0.000%, 0.000%, 2045127, 100.000%, 100.000%, 2045127, 100.000%, 100.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0, 0.000%, 0, 0.000%
"Adelaide_State_Office_DEST_router", 0, 0.000%, 0.000%, 2045127, 100.000%, 100.000%, 2045127, 100.000%, 100.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0, 0.000%, 0, 0.000%
"Adelaide_State_Office_Optus_router_PE_interface", 0, 0.000%, 0.000%, 2045127, 100.000%, 100.000%, 2045127, 100.000%, 100.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0.000%, 0, 0.000%, 0, 0.000%, 0, 0.000%
"Albany_DEST_router", 0, 0.000%, 0.000%, 2039937, 99.746%, 99.746%, 2039937, 99.746%, 99.746%, 0, 0.000%, 0.000%, 290, 0.014%, 0.014%, 290, 0.014%, 0.014%, 0, 0.000%, 0.000%, 4900, 0.240%, 0.240%, 4900, 0.240%, 0.240%, 0, 0.000%, 0, 0.000%, 0, 0.000%
END_OF_FILE_MARKER


