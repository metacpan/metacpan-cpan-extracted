#!/usr/bin/perl -w

# $Id: comp.t,v 1.1 2005-12-18 17:00:43+11 sh1517 Exp sh1517 $

# $Log: comp.t,v $
# Revision 1.1  2005-12-18 17:00:43+11  sh1517
# Initial revision
#

use Test;

use Nagios::Report ;


# Each element in this array is a single test. Storing them this way makes
# maintenance easy, and should be OK since perl should be pretty functional
# before these tests are run.

use vars qw($hn1 $hn2 $dt1 $dt2) ;

$hn1 = `perl -Mblib examples/ex5_comp_by_hostname_up`; 

=begin comment

16_Mort_St_Optus_router_P 100.000%         0                                 0

Adelaide_State_Office_DES 100.000%         0                                 0

Adelaide_State_Office_Opt 100.000%         0                                 0

Albany_DEST_router        99.746%          290              5m               4900             1h 20m

Albany_Optus_router_PE_in 99.761%          4890             1h 20m           0

Albury_DEST_router        100.000%         0                                 0

Albury_Optus_router_PE_in 100.000%         0                                 0

Armidale_DEST_router      99.882%          290              5m               2120             35m

Armidale_Optus_router_PE_ 99.897%          2110             35m              0

=end comment

=cut


$hn2 = `perl -Mblib examples/ex5_comp_by_hostname_down`; 

=begin comment

Albany_Optus_router_PE_in 99.761%          4890             1h 20m           0

Albany_DEST_router        99.746%          290              5m               4900             1h 20m

Adelaide_State_Office_Opt 100.000%         0                                 0

Adelaide_State_Office_DES 100.000%         0                                 0

16_Mort_St_Optus_router_P 100.000%         0                                 0

=end comment

=cut

$dt1 = `perl -Mblib examples/ex5_comp_by_max_downtime_up` ;

=begin comment

Wyong_Optus_router_PE_int 99.887%          2320             40m              0

Broken_Hill_DEST_router   99.801%          280              5m               3788             1h 5m

Broken_Hill_Optus_router_ 99.810%          3888             1h 5m            0

Albany_Optus_router_PE_in 99.761%          4890             1h 20m           0

Albany_DEST_router        99.746%          290              5m               4900             1h 20m

Thursday_Island_DEST_rout 98.989%          20678            5h 45m           0

Dubbo_DEST_router         92.011%          163377           1d 21h 25m       0

DUBSW200                  92.011%          163387           1d 21h 25m       0

Kempsey_DEST_router       83.884%          0                                 329598           3d 19h 35m

Kempsey_Optus_router_PE_i 83.883%          329609           3d 19h 35m       0

Bendigo_DEST_router       46.706%          1089920          1w 5d 14h 45m    0


=end comment

=cut


$dt2 = `perl -Mblib examples/ex5_comp_by_max_downtime_down` ;

=begin comment

Bendigo_DEST_router       46.706%          1089920          1w 5d 14h 45m    0

Kempsey_Optus_router_PE_i 83.883%          329609           3d 19h 35m       0

Kempsey_DEST_router       83.884%          0                                 329598           3d 19h 35m

DUBSW200                  92.011%          163387           1d 21h 25m       0

Dubbo_DEST_router         92.011%          163377           1d 21h 25m       0

Thursday_Island_DEST_rout 98.989%          20678            5h 45m           0

Albany_DEST_router        99.746%          290              5m               4900             1h 20m

Albany_Optus_router_PE_in 99.761%          4890             1h 20m           0

Broken_Hill_Optus_router_ 99.810%          3888             1h 5m            0

Broken_Hill_DEST_router   99.801%          280              5m               3788             1h 5m

Wyong_DEST_router         99.880%          125                               2320             40m

Wyong_Optus_router_PE_int 99.887%          2320             40m              0

Armidale_DEST_router      99.882%          290              5m               2120             35m

Armidale_Optus_router_PE_ 99.897%          2110             35m              0

Taree_DEST_router         99.901%          0                                 2022             35m

Taree_Optus_router_PE_int 99.901%          2022             35m              0

Walgett_DEST_router       99.905%          1936             30m              0

Lismore_DEST_router       99.911%          0                                 1810             30m

=end comment

=cut



$tests = <<'EOTESTS' ;
# Scalar expression 
# 1==1,

$hn1
$hn2
$dt1
$dt2

$hn1 =~ /^16_Mort_St.+?^Adelaide.+?^Adelaide.+?^Albany.+?^Albany/ms
$hn2 =~ /^Albany.+?^Albany.+?^Adelaide.+?^Adelaide.+?^16_Mort_St/ms
$dt1 =~ /^Wyong.+?^Broken_Hill_DEST.+?^Broken.+?^Albany.+?^Albany.+?^Thursday.+?^Dubbo.+?^DUBSW200.+?^Kempsey.+?^Kempsey.+?^Bendigo/ms
$dt2 =~ /^Bendigo.+?^Kempsey_Optus.+?^Kempsey.+?^DUB.+?^Dubbo.+?^Thursday.+?^Albany_DEST.+?^Albany.+?^Broken.+?^Broken.+?^Wyong.+?^Wyong.+?^Armidale.+?^Armidale.+?^Taree_DEST/ms



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

sub aeq {

  my ($ar1, $ar2) = @_ ;

  # compare two arrays passed by ref

  return 0
    unless scalar(@$ar1) == scalar(@$ar2) ;

  foreach my $i (0..$#$ar1) {

    return 0
      unless $ar1->[$i] eq $ar2->[$i] ;
  }

  return 1 ;

}

