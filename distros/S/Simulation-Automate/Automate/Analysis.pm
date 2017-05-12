package Simulation::Automate::Analysis;

use vars qw( $VERSION );
$VERSION = "1.0.1";

#################################################################################
#                                                                              	#
#  Copyright (C) 2000,2002 Wim Vanderbauwhede. All rights reserved.             #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

#=headers

#Package for statistical analysis of SynSim results.
#Based on create_histograms.pl
#This is not finished by far, but already useful.
#This module is used by SynSim.pm and PostProcessors.pm

#$Id$

#=cut

use strict;
use Carp;
use FileHandle;
use Exporter;

@Simulation::Automate::Analysis::ISA = qw(Exporter);
@Simulation::Automate::Analysis::EXPORT = qw(
		     &calc_statistics
		     &build_histograms
                  );

my $v=0;
my %bins=();
my %spec=();
my %trend=();
my @parnames;
my @parunits;
my $info;
my @info;
my $nlots=0;
my @pars=();
my $ncols;
my $data=0;
my $l=0;
my $nsites=0;

my $binfile;
my $title;
my $nbins;
my $min;
my $max;
my $uctitle;
my $lctitle;
my $log='';


################################################################################
##
## PROCESS THE DATAFILE
##
sub process_datafile {
my $binfile=shift;
my %trend=();
push @{$trend{DIFF}},0;

open(IN,"<$binfile")||carp "Can't open $binfile: $!\n";
my $j=0;
$nlots++;
my $in_table=0;
$info=0;
@info=();

#if just 1 column:
my $par=$pars[0];
if($par =~/dif/i){$par='DIFF'};
#else{$par='PAR'}

my $datacol=$pars[1];

while(<IN>) {
/^\s+$/ && next;
/^\s*\#/ && next;
chomp;
s/\s+$//;
s/^\s+//;
my @row=split(/[\s\t]+/,$_);
my $ri=0;

#foreach my $par (@pars) {
#push @{$trend{$par}},$row[$ri];
#$ri++
#}

#if just 1 column:
#print "$row[$datacol-1]\n";
push @{$trend{$par}},$row[$datacol-1];
#print STDERR "$par ($datacol) : ",$row[$datacol-1],"\n";
$nsites++;

}#while

if($v){print "# Done parsing $binfile: $nsites sites\n";}
close IN;


if (exists $trend{DIFF}) {
foreach my $i (0..@{$trend{DIFF}}-2) {
${$trend{DIFF}}[$i]=${$trend{DIFF}}[$i+1]-${$trend{DIFF}}[$i];
}
pop @{$trend{DIFF}};
}

if($log=~/log/i) {
foreach my $logkey (sort keys %trend) {
($logkey !~/log/i) && next;
foreach my $i (0..@{$trend{$logkey}}-1) {
#carp "$i:${$trend{$logkey}}[$i]\n";
if(${$trend{$logkey}}[$i]>0){
${$trend{$logkey}}[$i]=log(${$trend{$logkey}}[$i])/log(10); 
} else {
${$trend{$logkey}}[$i]='';
}
} # each $i
} # each $logkey
} # if LOG
return(\%trend);
} # END of process_datafile


##############################################################################################

sub calc_average {
my $value_array_ref=shift;

my $avg=0;
my $stdev=0;
my $pct_bad=shift||0; # means we throw 50% of the devices away as outliers to calculate the rough mean
my $delta=shift||2e10; # means we take all devices within 20% deviation from actual mean 

my @tmp_values=sort numerical @{$value_array_ref};

my $min=$tmp_values[0];
my $max=$tmp_values[@tmp_values-1];
#print "#all values:".scalar(@tmp_values)."\n";
my $n_samp=scalar @tmp_values;
my $n_iter=int($n_samp*0.5*$pct_bad);

#1. allow $pct_bad bad devices
if($n_iter>0){

foreach my $iter (1..$n_iter) {
pop @tmp_values;
shift @tmp_values;
}
}
#2. calc approx average of these
my $tmpav=0;
foreach my $tmp_val (@tmp_values) {
#print "$tmp_val\n";
$tmpav+=$tmp_val;
}
#print "tmpav*ngood:$tmpav\n";
$tmpav/=@tmp_values;
#print "tmpav:$tmpav\n";
#3. reject based on $tmpav and $delta; calc actual average
my $n_good=0;
my $sumx=0;
my $sumxsq=0;
foreach my $tmp_val (@$value_array_ref) {
#print "$tmp_val ";
  if ($tmpav==0||abs(($tmp_val-$tmpav)/$tmpav)<=$delta) {
$sumx+=$tmp_val;
$sumxsq+=$tmp_val*$tmp_val;
$n_good++;
#print " :pass\n";
} #else {print " :fail\n";}
}
if ($n_good>1) {
$avg=$sumx/$n_good;
# calc stdev: stdev^2=(n*sum(xi^2)-sum(xi)^2)/n/(n-1)
$stdev=sqrt($sumxsq/($n_good-1)-$sumx*$sumx/($n_good*($n_good-1)));
} else {
$avg='';
$stdev='';}
if($v){print "# samples:$n_good\n";}
if($v){print "# AVG:$avg\tSTDEV:$stdev\n";}
return [$avg,$stdev,$min,$max];
}

##############################################################################################

sub numerical { $a<=>$b }

##############################################################################################

sub min {
my $a=shift;
my $b=shift;
my $min=abs(($a+$b)-abs($a-$b))/2;
return $min;
}


################################################################################
# Build Histogram

sub build_histogram {
# reference to array with values
my $value_array_ref=shift;

# number of bins, number of sigmas for with ofinterval
my $nbins=shift; 
my $nsigma=shift;
my $min=shift||'CALC';
my $max=shift||'CALC';

# calculate mean & sigma and min/max/binwidth
my ($avg,$stdev)=@{&calc_average($value_array_ref)};
if(not $nsigma){$nsigma=6}
#if((not $min) && ($min!=0)){
if($min=~/C/) { 
$min=$avg-$nsigma*$stdev;
if($stdev>$avg) {
# in this case take min and max value of set
$min=${$value_array_ref}[0];
  foreach my $val (@{$value_array_ref}) {
    if($val<$min){$min=$val}
  }
}
}
if($v){print "# MIN:$min\n";}
if( $max=~/C/) { 
$max=$avg+$nsigma*$stdev;

if(1||$stdev>$avg) {
# in this case take min and max value of set
$max=${$value_array_ref}[0];
  foreach my $val (@{$value_array_ref}) {
    if($val>$max){$max=$val}
  }
}
}
if($v){print "# MAX:$max\n";}

#For traffic studies, all values are always positive.
if($min<0){$min=0;}
my $binwidth=($max-$min)/$nbins;

## first sort

my @tmp_values=sort numerical @$value_array_ref;
my $i=0;

my $n_samp=scalar @tmp_values;
my @counts;
for my $i (0..$nbins+1) {
$counts[$i]=0;
}
my $bin=1;
my $binh;
my $binl;

foreach my $val (@tmp_values) {

$binh=$bin*$binwidth+$min; 
$binl=($bin-1)*$binwidth+$min;

  if($val>=$binl&&$val<$binh) { # if inside bin
$counts[$bin]++;

}
elsif($val<$min) { # if lower than min
#print "lower:$counts[0]\n";
$counts[0]++;
}
elsif($val>=$binh) { # if higher than bin, next bin
  while($val >=$binh && $bin<$nbins) {
#print STDERR "$bin\n";
if($bin<$nbins) {
$bin++; #max. 25
$counts[$bin]=0;
}else{$bin=$nbins} 
#so $bin <=25
$binl=($bin-1)*$binwidth+$min; #WV15072002
$binh=$bin*$binwidth+$min;
}

if($val<$binh){$counts[$bin]++} # if lower than bin+1
elsif($val>=$max) {
#print "higher:$counts[$nbins]\n";
$counts[$nbins+1]++
} elsif(not defined $counts[$bin] ) {$counts[$bin]=0} 
} else {print STDERR "#$binl#$val#$binh#\n";}
}

return [\@counts,$min,$binwidth,$avg,$stdev];
}

#------------------------------------------------------------------------------
sub get_common_args {
if(not @_){die 'arguments: $datafilename,\@parameters,$title,$log'."\n"}

 $binfile=shift;
 @pars= @{shift(@_)}; # deref an array ref
 $title=shift||'';
 $log=shift||'';
#carp "LOG:$log\n";
$uctitle=uc($title);
$lctitle=lc($title);
$lctitle=~s/\s+/_/g;
if($v){print "# $uctitle DATA ANALYSIS\n\n";}
return [@_];
}
#------------------------------------------------------------------------------
sub calc_statistics {
my @specific=@{&get_common_args(@_)};
my $reject=shift  @specific;
my $delta=shift  @specific;
my %trend=%{&process_datafile($binfile)};
my %stats=();

#foreach my $par (@pars) {
#just 1 par
my $par=$pars[0];
#($par=~/none/i) && next;
if($v){print "# Processing $par\n";}
($stats{$par}{AVG},$stats{$par}{STDEV},$stats{$par}{MIN},$stats{$par}{MAX})=@{&calc_average(\@{$trend{$par}})};
#} # foreach par

return( \%stats );

} # END of calc_statistics

#------------------------------------------------------------------------------
sub build_histograms {

my @specific=@{&get_common_args(@_)};
$nbins=shift  @specific;
$min =shift  @specific;
$max =shift  @specific;

my %trend=%{&process_datafile($binfile)};

my %hists=();


my $par=$pars[0];

print "# Processing $par\n" if $v;

my @tmpa=@{&build_histogram(\@{$trend{$par}},$nbins,3,$min,$max)};
my $tmp=$tmpa[0];
my $minbin=$tmpa[1];
my $binwidth=$tmpa[2];
my $avg=$tmpa[@tmpa-2];
my $stdev=$tmpa[@tmpa-1];
my $bi=0;

foreach my $bin (@{$tmp}) {
  if($bi>0){
if($v){print $minbin+($bi-1)*$binwidth,"\t$bin\n";}
push @{$hists{$par}},{BIN=>$minbin+($bi-1)*$binwidth,COUNT=>$bin};
}
$bi++;
}



return( \%hists );

} # END of build_histograms
#------------------------------------------------------------------------------
1;
