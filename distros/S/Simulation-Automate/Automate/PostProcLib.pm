package Simulation::Automate::PostProcLib;

use vars qw( $VERSION );
$VERSION = "1.0.1";

################################################################################
#                                                                              #
#  Copyright (C) 2000,2002 Wim Vanderbauwhede. All rights reserved.            #
#  This program is free software; you can redistribute it and/or modify it     #
#  under the same terms as Perl itself.                                        #
#                                                                              #
################################################################################

#=headers

#Module to support synsim script for simulation automation.
#This module contains a set of utility functions for use in the
#PostProcessors.pm module.
#This module is generic.

#$Id$

#=cut

use warnings;
use strict;
use Carp;
use Exporter;
use lib '.','..';

use Simulation::Automate::Analysis;
use Simulation::Automate::Dictionary;

@Simulation::Automate::PostProcLib::ISA = qw(Exporter);
@Simulation::Automate::PostProcLib::EXPORT = qw(
						&prepare_plot
						&prepare
						&gnuplot
						&gnuplot_combined
						%simdata
						$last
						$verylast
						$every_sweep_val
						$current_set_str
						$current_set_except_setvar_str
						$results_file_name
						@all_results_file_names
						%current_set_vals
						@results
						&import_symbols
						$verbose
					       );

##################################################################################

sub AUTOLOAD {
my $subref=$Simulation::Automate::PostProcLib::AUTOLOAD;
$subref=~s/.*:://;
print STDERR "
There is no script for this analysis in the PostProcLib.pm module.
This might not be what you intended.
You can add your own subroutine $subref to the PostProcLib.pm module.
";

}

#------------------------------------------------------------------------------
sub prepare {
#print "Entering prepare()\n";
  use Cwd;

  #*&Simulation::Automate::PostProcessors::$subref(\$dataset,\$i,\$dataref1,\$flagsref,\$returnvalue,\$preprocref);
  #&prepare_plot(@args);
#  print "PREPARE\n";
  my $datafile_name=shift;
  my $count=shift;
  my $dataref=shift;
  my $flagsref=shift;
  my $verylastref=shift;
  my @extra_args=@_;

  my $preprocref=((@extra_args>=1) && $extra_args[0])?$extra_args[0]:0;
  
  my $every_sweep_val=((@extra_args==2) && ($extra_args[1]==2))?1:0;
  my $verylast=1;
  my @results=();

  if($verylastref && $verylastref!=1){
    @results=@{$verylastref};
     $verylast=0;
  } 

  (my $batch, $Simulation::Automate::PostProcLib::interactive,my $nosims,$Simulation::Automate::PostProcLib::plot,$Simulation::Automate::PostProcLib::verbose)=@{$flagsref};
  my $copy_results=1;
  (my $nsims, my $simdataref,my $current_set_valsref,my $lastref)=@{$dataref};
  
  my %synsimdata=%{$simdataref};
  my %current_set_vals=%{$current_set_valsref};
#to be exported: current_set_str
  my $current_set_str='';
  foreach my $key (sort keys %current_set_vals) {
    $current_set_str.="${key}-".$current_set_vals{$key}.'-';
  }
  $current_set_str=~s/-$//;

#The idea is to use XVAR or SWEEPVAR for any X-value sweep. As there is no longer a requirement to have semicol-lists for grouping, if XVAR is not semicol, make it semicol.
#If there was a semicol-list, make it comma. 
#If there were 2 or more semicol lists, add them to %grouped
#CONDVAR must only be defined if a CONDITION is present. In this case, CONDVAR is swept, XVAR is stepped, so XVAR should be a comma-separated list. If not, make it one. Again, if semicol grouping is used, convert to new grouping
#So, internally:
#(COND or CONDITION) {
#XVAR=SETVAR
#SWEEPVAR=CONDVAR
#} else {
#XVAR=SWEEPVAR
#}


  my $setvar=$synsimdata{SETVAR}||'';
  if(exists $synsimdata{COND} or exists $synsimdata{CONDITION}) {
#    my $condvar= $synsimdata{CONDVAR}||$synsimdata{SWEEPVAR}||'none';
#WV 010704: only CONDVAR, not SWEEPVAR
    my $condvar= $synsimdata{CONDVAR}||'none';
#    $synsimdata{CONDVAR}=$synsimdata{SWEEPVAR}=$condvar;
    my $xvar= $synsimdata{XVAR}|| $synsimdata{SETVAR}||$synsimdata{SWEEPVAR}||'';
    $synsimdata{XVAR}=$synsimdata{SETVAR}=$synsimdata{SWEEPVAR}=$xvar;
    $setvar=$xvar;
  } else {
    my $xvar= $synsimdata{XVAR}|| $synsimdata{SWEEPVAR}||'';
    $synsimdata{XVAR}=$synsimdata{SWEEPVAR}=$xvar;
  }

  my $cond=$synsimdata{COND}||$synsimdata{CONDITION}||'<1';
  $synsimdata{COND}=$synsimdata{CONDITION}=$cond;

  my $setvarval=$synsimdata{$setvar}->[0]; # if SETVAR is defined, this would be the first value in the list for SETVAR. This is to used check if the last element in the SETVAR value list has been reached
my $current_set_except_setvar_str=$current_set_str;
my $setvar_str=($setvar ne '')?$setvar.'-'.$setvarval:'';
$current_set_except_setvar_str=~s/$setvar_str\-*//;

  my %last=%{$lastref}; # the last value in the list for every variable

  my $last=($setvar && (exists $last{$setvar}) && ($setvar ne '') && $setvarval && ($setvarval==$last{$setvar})); # SETVAR is defined and the element in the value list has been reached. 

  $synsimdata{OUTPUT_FILTER_PATTERN}||= '.*';

  my $plotext=$synsimdata{PLOTTEMPL}||$synsimdata{PLOTTEMPLATE}||$synsimdata{PLOT_TEMPLATE}||'.gnuplot';
  $synsimdata{PLOTTEMPL}=$synsimdata{PLOTTEMPLATE}=$synsimdata{PLOT_TEMPLATE}=$plotext;

  $synsimdata{PLOTCOMMAND}||='/usr/bin/ggv';
  if((not -e '/usr/bin/ggv') and ( -e '/usr/X11R6/bin/gv')) {
  $synsimdata{PLOTCOMMAND}||='/usr/X11R6/bin/gv';
  }
  my $normvar=$synsimdata{NORMVAR}||1;
  (!$synsimdata{$normvar} || !@{$synsimdata{$normvar}})&&(${$synsimdata{$normvar}}[0]=1);
  my $current_norm_val=(@{$synsimdata{$normvar}}>1)?$current_set_vals{$normvar}:${$synsimdata{$normvar}}[0];
  $synsimdata{NORMVAR}=$normvar;

(exists $synsimdata{XVAR}) && ($synsimdata{XCOL}||=1);
  my $datacol=$synsimdata{DATACOL}||$synsimdata{YCOL}||1;
  $synsimdata{DATACOL}=$synsimdata{YCOL}=$datacol;

  my $simtempl=$synsimdata{SIMULATION}||$synsimdata{SIMNAME}||$synsimdata{SIMTYPE}||$synsimdata{TEMPLATE}||$synsimdata{SIMTEMPL};
  $synsimdata{SIMULATION}=$synsimdata{SIMNAME}=$synsimdata{SIMTYPE}=$synsimdata{TEMPLATE}=$synsimdata{SIMTEMPL}=$simtempl;

  my $anatempl=$synsimdata{ANALYSIS_TEMPLATE}||$synsimdata{ANALYSIS}||$synsimdata{ANATEMPL}||'None';
  $synsimdata{ANALYSIS_TEMPLATE}=$synsimdata{ANALYSIS}=$synsimdata{ANATEMPL}=$anatempl;

  my $results_file_name=$simtempl.'-'.$anatempl.'-'.$current_set_str.'.res';

  #NEW 24/11/2003 Copy "old" results files to new names
  if(not $verylast){
    system("cp ${simtempl}_C${count}.res $results_file_name");
}
  my $devtype=$synsimdata{DEVTYPE}|| $synsimdata{DEVICE}||'';
  $synsimdata{DEVTYPE}=$synsimdata{DEVICE}=$devtype;
  $synsimdata{TITLE}||="$devtype $simtempl simulation";
  my $simtitle = my $title = $synsimdata{TITLE};
  foreach my $key (keys %synsimdata) {
    ($key!~/^_/) && next;
    ($simtitle=~/$key/) && do {
      my $val=$synsimdata{$key};
      my $nicekey=$make_nice{$key}{title}||&make_nice($key);
      my $niceval=$make_nice{$key}{${$val}[0]}||join(',',@{$val});
      $simtitle=~s/$key/$nicekey:\ $niceval/;
    };
    $title=$simtitle;
  }

  # For Gnuplot
  #XSTART, XSTOP, YSTART, YSTOP, XTICS, YTICS, YLABEL, XLABEL, LOGSCALE, STYLE,
  $synsimdata{XSTART}||="";
  $synsimdata{XSTOP}||="";
  $synsimdata{YSTART}||="";
  $synsimdata{YSTOP}||="";
  $synsimdata{XTICS}||="";
  $synsimdata{YTICS}||="";
  $synsimdata{YLABEL}||="$title";
  $synsimdata{XLABEL}||=&make_nice($synsimdata{XVAR});#"$title";
  $synsimdata{LOGSCALE}=($synsimdata{LOGSCALE})?"set nologscale xy\nset logscale ".lc($synsimdata{LOGSCALE}):'set nologscale xy';
  my $plotstyle=$synsimdata{PLOTSTYLE}||$synsimdata{STYLE}||'linespoints';
  $synsimdata{PLOTSTYLE}=$synsimdata{STYLE}=$plotstyle;
  $synsimdata{DATAFILENAME}=$datafile_name;
  (my $legendtitle, my $legend)=@{&create_legend($current_set_str,\%make_nice)};
  my @all_results_file_names=glob($simtempl.'-'.$anatempl.'*.res');

  @Simulation::Automate::PostProcLib::all_results_file_names=@all_results_file_names;
  @Simulation::Automate::PostProcLib::results=@results;
  %Simulation::Automate::PostProcLib::simdata=%synsimdata;
  %Simulation::Automate::PostProcLib::current_set_vals=%current_set_vals;
  $Simulation::Automate::PostProcLib::results_file_name=$results_file_name;
  $Simulation::Automate::PostProcLib::current_set_str=$current_set_str;
  $Simulation::Automate::PostProcLib::current_set_except_setvar_str=$current_set_except_setvar_str;
  $Simulation::Automate::PostProcLib::verylast=$verylast;
  $Simulation::Automate::PostProcLib::last=$last;
  $Simulation::Automate::PostProcLib::simtempl=$simtempl;
  $Simulation::Automate::PostProcLib::anatempl=$anatempl;
  $Simulation::Automate::PostProcLib::plotext=$plotext;
#  if ($preprocref!=0) {
#    eval('use Simulation::Automate::PostProcessors;');
#    &{$preprocref}();
#  }
#%Simulation::Automate::PostProcessors::simdata=%synsimdata;
#@Simulation::Automate::PostProcessors::results=@results;

&import_symbols();
my $postprocpath= $INC{"Simulation/Automate/PostProcLib.pm"};
$postprocpath=~s/Lib/essors/;
($postprocpath=~/^\./)&&($postprocpath='../'.$postprocpath);
require $postprocpath;

my $workingdir=cwd();
if( -d "../PLUGINS") {
  my @preprocs=glob("../PLUGINS/*.pm");
  foreach my $plugin (@preprocs) {
    if($synsimdata{PREPROCESSOR} && ($plugin=~/$synsimdata{PREPROCESSOR}/) or $synsimdata{POSTPROCESSOR} && ($plugin=~/$synsimdata{POSTPROCESSOR}/) or  ($plugin=~/$synsimdata{ANATEMPL}\.pm/)) {
      require $plugin;
    }
  }
}
if(exists $synsimdata{PREPROCESSOR}) {
#print "Calling preprocessor $synsimdata{PREPROCESSOR} from prepare\n";
#@_= @Simulation::Automate::PostProcLib::results;
 eval('&Simulation::Automate::PostProcessors::'.$synsimdata{PREPROCESSOR});#.'(@_)');
# @Simulation::Automate::PostProcLib::results=@_;
}

#print "Calling Simulation::Automate::PostProcessors::$synsimdata{ANATEMPL} from prepare\n";
if( $synsimdata{ANATEMPL} ne 'None' ) {
eval('&Simulation::Automate::PostProcessors::'.$synsimdata{ANATEMPL});
}

#print "Leaving prepare()\n";
  return [@_];
} # END of prepare()

#------------------------------------------------------------------------------
sub gnuplot {
my $commands=shift;
my $persist=shift||'';
if($Simulation::Automate::PostProcLib::plot) {
open GNUPLOT,"| gnuplot $persist";
print GNUPLOT $commands;
close GNUPLOT;
}
} # END of gnuplot()
#------------------------------------------------------------------------------
sub gnuplot_combined {
#my $firstplotline=shift||'';
#my $plotlinetempl=shift||'';
#my $col=$Simulation::Automate::PostProcLib::datacol;
#my $ycol=$Simulation::Automate::PostProcLib::ycol;
#if($firstplotline=~/^\d+$/) {
#$ycol=$firstplotline;
#$firstplotline='';
#}
my $firstplotline='';
my $plotlinetempl='';
#my $synsimdataref=shift;
#my %synsimdata=%Simulation::Automate::PostProcLib::synsimdata;
my %synsimdata=%Simulation::Automate::PostProcLib::simdata;
$synsimdata{YCOL}= $Simulation::Automate::PostProcLib::ycol;

### On the very last run, collect the results 
#1. get a list of all plot files
my @plotfiles=glob("${Simulation::Automate::PostProcLib::simtempl}-${Simulation::Automate::PostProcLib::anatempl}-*.res");

#2. create a gnuplot script 
#this should be a full script, but with room for additional feature
my @lines=();
my $legendtitle='';
my $lt=0;
my $range='';
foreach my $filename (@plotfiles) {
$lt++;
my $title=$filename;

$title=~s/${Simulation::Automate::PostProcLib::simtempl}-${Simulation::Automate::PostProcLib::anatempl}-//;
$title=~s/\.res//;
$title=~s/\-\-/\-\_MINUS_/g;
#(my $legendkey,my $legendvalue)=split('-',$title);
my %legend=split('-',$title);
my @legendkeys=();
my @legendvalues=();
foreach  my $varname (sort keys %legend){
push @legendkeys,$varname;
push @legendvalues,$legend{$varname};
}
my $legendkey='';
$legendkey.=join(', ',@legendkeys);
my $legendvalue='';
$legendvalue.=join(', ', @legendvalues);

#$legendkey||=' ';
($legendkey eq '') && ( $legendkey=' ');
($legendvalue eq '') && ($legendvalue=' ');
#($legendvalue=~/^\d+$/)&&($legendvalue!=0) && ($legendvalue||=' ');
($legendkey=~/_MINUS_/)&&($legendkey=~s/_MINUS_/\-/g);
($legendvalue=~/_MINUS_/)&&($legendvalue=~s/_MINUS_/\-/g);

my %title= ($legendkey=>$legendvalue);

my $legend='';
$legendtitle='';
foreach my $key (sort keys %title) {
$legendtitle.=',';
$legendtitle.=$make_nice{$key}{title}||&make_nice($key);
$legend.=$make_nice{$key}{$title{$key}}||&make_nice($title{$key});
$legend.=',';
}
$legend=~s/,$//;
$legendtitle=~s/^,//;
$synsimdata{LEGEND}=$legend;
$synsimdata{LEGENDTITLE}=$legendtitle;

if(($firstplotline eq '') and ($plotlinetempl eq '')){
($firstplotline, $plotlinetempl,$range)=@{&parse_gnuplot_templ(\%synsimdata)};
}

my $plotline;
#print "PLOTLINE:", '$plotline='.$plotlinetempl;
eval('$plotline='.$plotlinetempl);
#carp "PLOTLINE:$plotline";
push @lines, $plotline
}
$firstplotline=~s/set\s+key\s+title.*/set key title "$legendtitle"/;
my $plot="\nplot $range ";
if($firstplotline=~/$plot/ms){$plot=''};
my $line=$firstplotline.$plot.join(",\\\n",@lines);

if($Simulation::Automate::PostProcLib::plot) {
open GNUPLOT,"| gnuplot";
print GNUPLOT $line;
close GNUPLOT;
}
open GNUPLOT,">${Simulation::Automate::PostProcLib::simtempl}-${Simulation::Automate::PostProcLib::anatempl}.gnuplot";
print GNUPLOT $line;
close GNUPLOT;

if($Simulation::Automate::PostProcLib::interactive) {
system("${Simulation::Automate::PostProcLib::plotcommand} ${Simulation::Automate::PostProcLib::simtempl}-${Simulation::Automate::PostProcLib::anatempl}.ps &");
}
} # END of gnuplot_combined()
#------------------------------------------------------------------------------
sub parse_gnuplot_templ {
my $synsimdataref=shift;
my %synsimdata=%{$synsimdataref};

  no strict;

  foreach my $key (keys %synsimdata){
    ($key=~/^\d*$/)&&next;
    my $lcname=lc($key);
    if($key=~/^_/) {
      @{$lcname}=@{$synsimdata{$key}};
    } else {
      $$lcname=$synsimdata{$key};
    }
  }
my $normvarval=$synsimdata{$normvar}[0];

#plot templates can be either 
#SIMPTYPE.PLOTTEMPL, stored under TEMPLATES or TEMPLATES/SYMTYPE
#$dataset.PLOTTEMPL, stored next to $dataset.data
my $plot_templ_file="../$datafilename$plottempl"; 
#print "../$datafilename$plottempl\n"; 
if( not -e $plot_templ_file) {
  $plot_templ_file="../TEMPLATES/$simtempl$plottempl";
  if( not -e $plot_templ_file) {
    $plot_templ_file='';
  }
}
#print " plot_templ_file $plot_templ_file\n";

my $xcolentry='(\$_XCOL*1):';

if(not exists $synsimdata{XCOL} and not exists $synsimdata{XVAR} and not exists $synsimdata{SWEEPVAR} and ($xcol && ($xcol!~/\d/))){
$xcolentry='';
}
my $firstplotline=<<"ENDH";
set terminal postscript landscape enhanced  color solid "Helvetica" 14
set output "${simtempl}-${anatempl}.ps"

$logscale

#set xtics $xtics
#set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title" "Helvetica,18"
set xlabel "$xlabel" "Helvetica,16"
set ylabel "$ylabel" "Helvetica,16"

ENDH

my $plotlinetempl=q["\'$filename\' using _XCOLENTRY(\$_YCOL/_NORMVAR) title \"$legend\" with _PLOTSTYLE"];
$plotlinetempl=~s/_XCOLENTRY/$xcolentry/;
$plotlinetempl=~s/_NORMVAR/$normvarval/;
$plotlinetempl=~s/_YCOL/$ycol/;
$plotlinetempl=~s/_XCOL/$xcol/;
$plotlinetempl=~s/_PLOTSTYLE/$plotstyle/;
my $range='';
  if($plot_templ_file) {
    $firstplotline='';
    open(PLOTTEMPL,"<$plot_templ_file");

    while (<PLOTTEMPL>) {
      /FILENAME/ && ($plotlinetempl=$_) && last;
      s/OUTPUT/${simtempl}-${anatempl}/;
      s/PLOTTITLE/$title/;
      s/LEGENDTITLE/$legendtitle/;
      s/XLABEL/$xlabel/;
      s/YLABEL/$ylabel/;
      s/XTICS/$xtics/;
      s/YTICS/$ytics/;
      s/LOGSCALE/$logscale/;
      $firstplotline.=$_;
    }
    chomp($plotlinetempl);
    $plotlinetempl=~s/\$/\\\$/g;
    $plotlinetempl=~s/RESULTSFILENAME/\$filename/g;
    $plotlinetempl=~s/FILENAME/\$filename/g;
    $plotlinetempl=~s/XCOL/$xcol/;
    $plotlinetempl=~s/YCOL/$ycol/;
    $plotlinetempl=~s/NORMVAR/$normvarval/;
    $plotlinetempl=~s/LEGENDENTRY/\$legend/;
    $plotlinetempl=~s/LEGEND/\$legend/;
    $plotlinetempl=~s/PLOTSTYLE/$plotstyle/;
    $plotlinetempl=~s/^plot\s+//;
    $plotlinetempl=~s/\'/\\\'/g;
    $plotlinetempl=~s/\"/\\\"/g;
    $plotlinetempl=~s/XSTART/$xstart/;
    $plotlinetempl=~s/XSTOP/$xstop/;
    $plotlinetempl=~s/YSTART/$ystart/;
    $plotlinetempl=~s/YSTOP/$ystop/;


( $plotlinetempl=~s/(\[[\d\.eE\-\+]*\:[\d\.eE\-\+]*\]\s+)//) && do {
$range=$1;
};
    $plotlinetempl='"'.$plotlinetempl.'"';
  }
$range||='';

  return [$firstplotline,$plotlinetempl,$range];

} # END of parse_gnuplot_templ()
#------------------------------------------------------------------------------
sub copy_results {
use Cwd;
my $workingdir=cwd();
  if(not(-e "$workingdir/../../Results")) {
mkdir  "$workingdir/../../Results";
}
  if(not(-e "$workingdir/../../Results/$Simulation::Automate::PostProcLib::simtempl")) {
mkdir  "$workingdir/../../Results/$Simulation::Automate::PostProcLib::simtempl";
}

  if(not(-e "$workingdir/../../Results/$Simulation::Automate::PostProcLib::simtempl/$Simulation::Automate::PostProcLib::anatempl")) {
mkdir  "$workingdir/../../Results/$Simulation::Automate::PostProcLib::simtempl/$Simulation::Automate::PostProcLib::dataset";
}
system("cp ${Simulation::Automate::PostProcLib::simtempl}-${Simulation::Automate::PostProcLib::anatempl}.* $workingdir/../../Results/$Simulation::Automate::PostProcLib::simtempl/$Simulation::Automate::PostProcLib::dataset");

} #END of copy_results()
#------------------------------------------------------------------------------
sub create_legend {
my $title=shift;

my %make_nice=%{shift(@_)};

$title=~s/\-\-/\-\_MINUS_/g;
(my $legendkey,my $legendvalue)=split('-',$title);
$legendkey||=' ';
$legendvalue||=' ';
($legendkey=~/_MINUS_/)&&($legendkey=~s/_MINUS_/\-/g);
($legendvalue=~/_MINUS_/)&&($legendvalue=~s/_MINUS_/\-/g);

my %title= ($legendkey=>$legendvalue);

my $legend='';
my $legendtitle='';
foreach my $key (sort keys %title) {
my $titlepart=$make_nice{$key}{title}||&make_nice($key);
$legendtitle.=','.$titlepart;
my $legendpart=$make_nice{$key}{$title{$key}}||$title{$key};
$legend.=','.$legendpart;
}
$legend=~s/^,//;
$legendtitle=~s/^,//;

return [$legendtitle,$legend];
}
#------------------------------------------------------------------------------
sub import_symbols { 
  no strict;
  foreach my $name (sort keys %Simulation::Automate::PostProcLib::simdata) {
    ($name=~/^\d*$/) && next;
    my $lcname=lc($name);
    if($name=~/^_/) {
      @{"Simulation::Automate::PostProcLib::$lcname"}=@{$Simulation::Automate::PostProcLib::simdata{$name}};
      @{"Simulation::Automate::PostProcessors::$lcname"}=@{$Simulation::Automate::PostProcLib::simdata{$name}};
      push @Simulation::Automate::PostProcLib::EXPORT,'@'.$lcname;
    } else {
      ${"Simulation::Automate::PostProcLib::$lcname"}=$Simulation::Automate::PostProcLib::simdata{$name};
      ${"Simulation::Automate::PostProcessors::$lcname"}=$Simulation::Automate::PostProcLib::simdata{$name};
      push @Simulation::Automate::PostProcLib::EXPORT,'$'.$lcname;
    }
  }
}
#------------------------------------------------------------------------------
sub make_nice {
my $varname=shift;
if($varname=~/,/){
  my @varnames=split(', ',$varname);
  foreach my $varname (@varnames) {
    $varname=~s/^_//;
    $varname=~s/_/ /g;
    $varname=lc($varname);
    $varname=~s/^([a-z])/uc($1)/e;
  }
  $varname=join(', ',@varnames);
} else {
$varname=~s/^_//;
$varname=~s/_/ /g;
$varname=lc($varname);
$varname=~s/^([a-z])/uc($1)/e;
}
return $varname;
}
#------------------------------------------------------------------------------
1;
#print STDERR "#" x 80,"\n#\t\t\tSynSim simulation automation tool\n#\n#\t\t\t(C) Wim Vanderbauwhede 2002\n#\n","#" x 80,"\n\n Module SynSim::PostProcLib loaded\n\n";


