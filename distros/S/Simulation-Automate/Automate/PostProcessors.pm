package Simulation::Automate::PostProcessors;

use vars qw( $VERSION );
$VERSION = "1.0.1";

################################################################################
#                                                                              #
#  Copyright (C) 2000,2002-2003 Wim Vanderbauwhede. All rights reserved.       #
#  This program is free software; you can redistribute it and/or modify it     #
#  under the same terms as Perl itself.                                        #
#                                                                              #
################################################################################

#=headers

#Module to support SynSim simulation automation tool.
#This module contains all subroutines needed for postprocessing of the simulations results. 
#Some routines are quite generic, but most are specific to the type of simulation.

#$Id$

#=cut
##use warnings;
##use strict;

use Carp;
use lib '.','..';

use Simulation::Automate::Analysis;
use Simulation::Automate::PostProcLib;

##################################################################################
# Three generic routines are provided:
# SweepVar: to make a sweep over one variable while using any number of parameters
# ErrorFlags: 
# Histogram: to create simple histograms

#------------------------------------------------------------------------------
# This is a very generic module to generate XY plots from any sweep 
sub XYPlot {
#determine whether the results are single points or a range
  if($xvar && @{$simdata{$xvar}}>1) { # point by point
 my @sweepvarvals=@{$simdata{$sweepvar}};

  # This is to combine the values for different buffers into 1 file
  if ($verylast==0) {
    open(RES,">$results_file_name");
    print RES $resheader;
    # Now add the simulation results. The difference with the raw data
    # is that the value of $sweepvar is added as the first column.
    my $i=0;
    foreach my $sweepvarval ( @sweepvarvals ) {
      print RES "$sweepvarval\t$results[$i]";
      $i++;
    }
    close RES;
  } else {
    # On the very last run, collect the results into one nice plot
    # X values are in the first col, so add 1 to YCOL
    $ycol++;

    &gnuplot_combined();
  }
} else {
  if(not $verylast) {
    open(RES,">$results_file_name");
    print RES $resheader;
    # Now add the simulation results. The difference with the raw data
    # is that the value of $sweepvar is added as the first column.
    foreach my $line ( @results ) {
      print RES $line;
    }
    close RES;
  } else {
    ### On the very last run, collect the results into one nice plot
    &gnuplot_combined();
  }
}
} #END of XYPlot

#------------------------------------------------------------------------------
# This is a very generic module to generate plots from any sweep 

sub PlotXYfromPoints {

  my @sweepvarvals=@{$simdata{$sweepvar}};

  # This is to combine the values for different buffers into 1 file
  if ($verylast==0) {
    open(RES,">$results_file_name");
    print RES $resheader;
    # Now add the simulation results. The difference with the raw data
    # is that the value of $sweepvar is added as the first column.
    my $i=0;
    foreach my $sweepvarval ( @sweepvarvals ) {
      print RES "$sweepvarval\t$results[$i]";
      $i++;
    }
    close RES;
  } else {
    # On the very last run, collect the results into one nice plot
    # X values are in the first col, so add 1 to YCOL
    $ycol++;
    &gnuplot_combined();
  }

} #END of PlotXYfromPoints

#------------------------------------------------------------------------------
sub PlotXYfromRange {

  if($verylast) {
    ### On the very last run, collect the results into one nice plot
    &gnuplot_combined();
  }

} #END of PlotXYfromRange()

#------------------------------------------------------------------------------

sub XYPlotErrorBars { 

my $sweepvarval=$simdata{$sweepvar}[0];

if($verylast) {#very last run

## With NRUNS, we must wait until the very last run to calc the error flags.
# Get all results files.
my %allresfiles=();
foreach my $resfile (@all_results_file_names) {
$resfile!~/NRUNS/ && next;
my $resfilenorun=$resfile;
$resfilenorun=~s/__NRUNS-\d+/__NRUNS-/;
$allresfiles{$resfilenorun}=1;
}

## Loop over all result files 
foreach my $resfile (keys %allresfiles) {
## For each of these, loop over all runs

  my @allruns=();
  my $allpoints=0;
  foreach my $run (1..$nruns) {
    my $thisrun=$resfile;
    $thisrun=~s/__NRUNS-/__NRUNS-$run/;
    open(RES,"<$thisrun");
    my $i=0;
    while(<RES>) {
      /^#/ && next;
      /^\s*$/ && next;
      $allruns[$run][$i]=$_;
      $i++;
    }
    $allpoints=$i;
    close RES;
    unlink "$thisrun"; # This is quite essential, otherwise it will be included in the plot
  }
  my $sweepvalsnorun=$resfile;
  $sweepvalsnorun=~s/__NRUNS-\d*//;
  $sweepvalsnorun=~s/\-\-/\-/g;
  $sweepvalsnorun=~s/\-$//;


open(STAT,">$sweepvalsnorun");
  if($sweepvar) {
    foreach my $i (0..$allpoints-1) {
      open(TMP,">tmp$i.res");
      foreach my $run (1..$nruns) {
	$allruns[$run][$i]=~s/^\d+\s+//;
	print TMP $simdata{$sweepvar}->[$i],"\t",$allruns[$run][$i];
	print  $simdata{$sweepvar}->[$i],"\t",$allruns[$run][$i];
      }
      close TMP;

      # calc average after every $count
      my $par='PARAM';
      my %stats=%{&calc_statistics("tmp$i.res",[$par, $datacol])};
      unlink "tmp$i.res";
      my $avg=$stats{$par}{AVG}/$normvar;
      my $stdev=$stats{$par}{STDEV}/$norm;
      #Parameter should be NSIGMAS, user can choose. As it is a postprocessing par, the syntax is 'NSIGMAS : 1.96'
      my $nsigmas=$simdata{NSIGMAS}||1.96;
      my $minerr=$avg-$nsigmas*$stdev; # 2 sigma = 95% MAKE THIS A PARAMETER! CONFIDENCE
      my $maxerr=$avg+$nsigmas*$stdev; # 2 sigma = 95%

      print STAT $simdata{$sweepvar}->[$i],"\t$avg\t$minerr\t$maxerr\n";
    }
} else {# no sweepvar, assuming the simulator does the sweep
  my @tmpres=();
  my $i=0;
  foreach my $run (1..$nruns) {
    $i=0;
    foreach (@{$allruns[$run]}) {
      /^\s+$/ && next;
      /^\s*\#/ && next;
      chomp;
      s/\s+$//;
      s/^\s+//;
      my @row=split(/[\s\t]+/,$_);
      push @{$tmpres[$i]},$row[$datacol-1];
      $i++;
    }
  }
  my $itot=$i;
  $i=0;

  while ($i<$itot) {
    open(TMP,">tmp$i.res");
    foreach my $item (@{$tmpres[$i]}) {
      print TMP "$item\n";
    }
    close TMP;
    # calc average after every $count
    my $par='PARAM';
    my %stats=%{&calc_statistics("tmp$i.res",[$par, 1])};
    unlink "tmp$i.res";
    my $avg=$stats{$par}{AVG}/$normvar;
    my $stdev=$stats{$par}{STDEV}/$normvar;
    #Parameter should be NSIGMAS, user can choose. As it is a postprocessing par, the syntax is 'NSIGMAS : 1.96'
    my $nsigmas=$simdata{NSIGMAS}||1.96;
    my $minerr=$avg-$nsigmas*$stdev; # 2 sigma = 95% MAKE THIS A PARAMETER! CONFIDENCE
    my $maxerr=$avg+$nsigmas*$stdev; # 2 sigma = 95%

    print STAT "$i\t$avg\t$minerr\t$maxerr\n";
    $i++;
  }

} # no SWEEPVAR

close STAT;
} # all resfiles

### On the very last run, collect the results into one nice plot

&gnuplot_combined();
}

} #END of XYPlotErrorBars()

#------------------------------------------------------------------------------

sub Histogram {

my $sweepvarval=${$simdata{$sweepvar}}[0]; # used for nbins?!
my $nbins=$simdata{NBINS}||20;
my $binwidth=$simdata{BINWIDTH}||1;
my $min=$simdata{MIN}||'CALC';# was 0
my $max=$simdata{MAX}||'CALC';#was ($min+$nbins*$binwidth);
my $par='DATA';#must be "LOG" for log plot
my $log=''; #must be 'log' for log plot
#carp "LOGSCALE: $logscale\n";
#my @logscale=split("\n",$logscale);
#if($logscale[1]=~/x/i) {
if($logscale!~/nologscale/ and $logscale=~/x/i) {
$xstart=($xstart&&$xstart>0)?log($xstart)/log(10):'';
$xstop=($xstart&&$xstop>0)?log($xstop)/log(10):'';
#  $logscale[1]=~s/x//i;
#  $logscale="$logscale[0]\n$logscale[1]\n";
$logscale=~s/x//i;
  $par='LOG';#'DATA';#must be "LOG" for log plot
  $log='log'
}
#carp "LOGSCALE: $logscale\n";

  if(not $verylast) {
my %hists=%{&build_histograms($results_file_name,[$par,$datacol],$title,$log,$nbins,$min,$max)};

&egrep('#',$results_file_name,'>',"tmp$results_file_name");
rename("tmp$results_file_name",$results_file_name);
open HIST,">$results_file_name";
foreach my $pair (@{$hists{$par}}) {
print HIST $pair->{BIN},"\t",$pair->{COUNT},"\n";
}
close HIST;

} else {
$xcol=1;
$ycol=2;
&gnuplot_combined();

}


} #END of Histogram()

#------------------------------------------------------------------------------

my %condval=();

sub CondXYPlot {


# For every corner in the DOE:

  #The values of the conditional variable
  my @condvarvals=@{$simdata{$condvar}};
#print STDERR "CONDVARVALS: $condvar :",join(',', @condvarvals),"\n";
  # remove the original results file. data are in @results, so no need for it
  # and otherwise the files appear in the final plot
#print STDERR "unlink $results_file_name;\n";
  unlink $results_file_name;

 if(not $verylast) { # The DOE is not finished yet 
    my $condition_met=0;
    my $i=0;
    #This is the core routine to check the condition
    foreach my $condvarval ( @condvarvals ) { # @condvarvals and @results have the same length
      my @line=split(/\s+/,$results[$i]);
      $i++;
      my $value=$line[$datacol-1];
      if( !$condition_met && eval("$value$cond")) {
	$condition_met=1;
#print STDERR "COND is met for $value$cond\n";
	my $setvarval=$current_set_vals{$setvar};
	push @{$condval{$current_set_except_setvar_str}},"$setvarval $condvarval";
      }
    } # all results for current sweep

    if ($last) { # The X-axis sweep for the current set of parameters is finished.
#print STDERR "LAST :";
	foreach my $valstr (keys %condval) {
#print STDERR "VALSTR: $valstr\n";
	  my $new_results_file_name=$results_file_name;
	  $new_results_file_name=~s/$current_set_str/$valstr/;
	  open(RES,">$new_results_file_name");
	  print RES $resheader;
	  foreach my $line (@{$condval{$valstr}}) {
	    print RES "$line\n";
#	    print STDERR "$line\n";
	  }
	  close RES;
      }
    } # if last
  } else { ### On the very last run, collect the results into one nice plot
#    $ycol++;
$ycol=2;
$normvarval=1;
    &gnuplot_combined();
  }

} #END of CondXYPlot()
#------------------------------------------------------------------------------

#==============================================================================
#
# PREPROCESSORS
#
# Routines for pre-processing of results 
# All these routines modify the @results array, which is the raw data from the simulator in a line-by-line array
#
sub show_results {
  print STDERR "RESULTS:\n";
  for my $line (@results){
    print STDERR $line;
  }
  print STDERR "-" x 78;
  print STDERR "\n";
}
#------------------------------------------------------------------------------
sub clean_up {
  for my $line (@results) {
($line=~/^\s*\#/) && next;
    $line=~s/^.*\:\s*//;
  }
}
#------------------------------------------------------------------------------
sub square {
print "Calling square():\n" if $verbose;
  for my $line (@results){
chomp $line;
$line*=$line;
$line.="\n";
}
}
#------------------------------------------------------------------------------
sub get_train_lengths {
my $resultsfile=shift;
my $nports=$simdata{_NPORTS}->[0];

my $prevdest=0;
my @train_length=();

foreach my $dest (0..$nports-1) {
  $train_length[$dest]=0;
}

foreach my $line (@results){
if($line!~/^DEST/){
print TMP $line;
} else {
  chomp(my $dest=$line);
  $dest=~s/^.*\s+//;
  if($dest == $prevdest) {
    $train_length[$dest]++;
  } else {
    chomp $line;
    $line=~s/\d+$//;
    print TMP "$_\t",$train_length[$prevdest],"\n";
    foreach my $dest (0..$nports-1) {
      $train_length[$dest]=0;
    }
    $train_length[$dest]++;
    $prevdest=$dest;
  }
}
}

}
#==============================================================================
sub egrep {
my $pattern=shift;
my $infile=shift;
my $mode=shift;
my $outfile=shift;
open(IN,"<$infile");
open(OUT,"$mode$outfile");
print OUT grep /$pattern/,<IN>;

close IN;
close OUT;
}

#------------------------------------------------------------------------------

sub AUTOLOAD {
my $subref=$Simulation::Automate::PostProcessors::AUTOLOAD;
$subref=~s/.*:://;
print STDERR "
There is no script for the analysis $subref in the PostProcessors.pm module.
This might not be what you intended.
You can add your own subroutine $subref to the PostProcessors.pm module.
";

}
#------------------------------------------------------------------------------
1;
#print STDERR "#" x 80,"\n#\t\t\tSynSim simulation automation tool\n#\n#\t\t\t(C) Wim Vanderbauwhede 2002\n#\n","#" x 80,"\n\n Module PostProcessors loaded\n\n";


