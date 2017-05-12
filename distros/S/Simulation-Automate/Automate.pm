package Simulation::Automate;

use vars qw( $VERSION );
$VERSION = "1.0.1";

#################################################################################
#                                                                              	#
#  Copyright (C) 2000,2002-2004 Wim Vanderbauwhede. All rights reserved.        #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

#headers
#
#Main module for SynSim simulation automation tool.
#The first part creates the module Loops.pm based on the data file;	
#this module is then called via eval() and used by Simulation::Automate.pm 
#Loops calls &Automate::main() at every pass through the loops.
#
#$Id$
#


use warnings;
use strict;
use Cwd;
use Carp;
use Exporter;
use lib '.';
use Simulation::Automate::Remote;

@Simulation::Automate::ISA = qw(Exporter);
@Simulation::Automate::EXPORT = qw(
		     &synsim
		     &setup
		     &localinstall
                  );

#===============================================================================
sub synsim {
  my $remotehost=&check_for_remote_host();
  if($remotehost){
    &run_on_remote_host($remotehost)
  } else {
    &run_local(); # new name for sub synsim
  }
}
#===============================================================================
sub run_local {
my $datafile=shift||'synsim.data';

################################################################################
#
#                     Create  module Simulation::Automate::Loops.pm
#
################################################################################

my @flags=my ($batch,$interactive,$nosims,$plot,$verbose,$warn)=@{&preprocess_commandline($datafile)};
my $dataset=$datafile;
$dataset=~s/\.data//;
print STDERR "\nCreating Loops.pm...\n" if $verbose;

(my $dataref,my $groupedref)=&allow_multiple_sims($datafile);
my $simref=&generate_loop_module($dataref,$groupedref,$dataset,\@flags);

################################################################################
#
#                     Do the actual simulations
#
################################################################################

&execute_loop($datafile,$dataset,$simref,\@flags) && do {
unlink "Loops_$dataset.pm";
};
if($dataset ne 'synsim'){
print STDERR "\nFinished SynSim run for $dataset.data\n\n";
} else {
print STDERR "\nFinished SynSim run\n\n";
}
return 1;
}
#===============================================================================

################################################################################
##
##                    Subroutines
##
################################################################################

sub preprocess_commandline {
my $datafile=$_[0];
my ($batch,$interactive,$nosims,$plot,$verbose,$warn,$justplot,$list_postprocessors)=(0,0,0,0,0,0,0,0);
my $default=1;
if(@ARGV) {
my $dtf=0;
    foreach(@ARGV) {
      if(/-f/){$dtf=1;next}
      if($dtf==1) {
	$_[0]=$_;$datafile=$_;$default=0;$dtf=0;
      }
      if(/-b/){$batch=1;next} 
      if(/-i/){$interactive=1;$plot=1;$verbose=1;next}
      if(/-N/){$nosims=1;next}
      if(/-p/){$plot=1;next}
      if(/-v/){$verbose=1;next}
      if(/-w/){$warn=1;next;}
      if(/-P/){$justplot=1;next}
      if(/-A/){$list_postprocessors=1;next}
      if(/-D/) {
	(not -d 'TEMPLATES') && mkdir 'TEMPLATES';
	(not -d 'TEMPLATES/SIMTYPES') && mkdir 'TEMPLATES/SIMTYPES';
	(not -d 'TEMPLATES/DEVTYPES') && mkdir 'TEMPLATES/DEVTYPES';
	(not -d 'SOURCES') && mkdir 'SOURCES';
	(not -d 'PLUGINS') && mkdir 'PLUGINS';
	die "An empty directory structure has been created\n";
      }
      if(/-h|-\?/) { 
my $script=$0;
$script=~s/.*\///;

# -f flag now optional
# -f [filename]: 'file input'. Expects a file containing info about simulation and device type.

die <<"HELP";

The script must be executed in a subdirectory of the directory
containing the script.
This directory must contain at least a TEMPLATES/SIMTYPE subdir 
with the simulation templates, and a data file. See documentation for more information.

syntax: ./$script [-h -D -i -p -P -A -v -w -N datafile]

Possible switches:

none: defaults to -f $datafile
 -D : Create an empty SynSim directory structure in the current directory
 -v : 'verbose'. Sends simulator output to STDOUT, otherwise to simlog file
 -p : plot. This creates the plot, but does not display it
 -i : interactive. Creates a plot on the screen after every iteration. Implies -p -v
 -P : Plot. This displays plots created with -p
 -A : Analysis Templates. Displays a list of all available analysis templates and the man page
 -w : 'warnings'. Show warnings for undefined variables.
 -N : 'No simulations'. Does only postprocessing
 -h, -? : this help
HELP
}
    } # foreach @ARGV
if($list_postprocessors) {
#convenience function to list available postprocessors
#so get all subs from PostProcessors

print "\n";
if(-e '../Simulation/Automate.pm') {
#This is good for a local SynSim, not for a global one
system("pod2text ../Simulation/Automate.pm | perl -n -e 'print if /^POST/../^DICT/ and !/DICT/' | less");

} else {
system("man Simulation::Automate");

}
no strict;
require('../Simulation/Automate/PostProcessors.pm');
print "\nAvailable postprocessing routines:\n\n";
foreach my $key (sort keys %Simulation::Automate::PostProcessors::) {

if( $key=~/^[A-Z]+[a-z]+/){
print "$key \n";
}
}
die "\n";
}
#test if the last argument might be the filename (if no -f flag)
if($default){
my $test=$ARGV[@ARGV-1];
if($test!~/^\-/) {
$datafile=$test;
$default=0;
$_[0]=$datafile;
}
}

    if($default) {
print STDERR "Assuming $datafile as input data filename\n" if $verbose;
}
    } else {
print STDERR "No command line arguments given. Assuming $datafile as input data filename\n" if $verbose;
}

if(not(-e "./TEMPLATES" && -d "./TEMPLATES" && -e "./$datafile")) {
die  "
The current directory must contain at least a TEMPLATES/SIMTYPE subdir with the simulation templates, and a data file. See documentation for more information.

If Simulation::Automate is installed locally, the current directory must be in the same directoy as the Simulation directory.

";
}
if($justplot) {
#convenience function to plot results
chomp(my $simtype=`egrep '^SIM(TYPE|NAME|ULATION|TEMPL)|^\ *TEMPLATE' $datafile`);
$simtype=~s/^SIM(TYPE|NAME|ULATION)|^\s*TEMPLATE\s*:\s*//;
$simtype=~s/\s*$//;
$simtype=~s/\..*$//;
chomp(my $anatype=`egrep '^ANA(LYSIS)*_*(TEMPL)*(ATE)*' $datafile`);
$anatype=~s/^ANA(LYSIS)*_*(TEMPL)*(ATE)*\s*:\s*//;
$anatype=~s/\s*$//;
$datafile=~s/\.data//;

chdir "${simtype}-$datafile";
  my $gv='/usr/bin/ggv';
  if((not -e '/usr/bin/ggv') and ( -e '/usr/X11R6/bin/gv')) {
  $gv='/usr/X11R6/bin/gv';
  }
system("$gv ${simtype}-$anatype.ps");
die "Done\n";
}


return [$batch,$interactive,$nosims,$plot,$verbose,$warn];
} #END of preprocess_commandline

#-------------------------------------------------------------------------------
#
# This subroutine takes a reference to %specific as generated by allow_multiple_sims($datafile) and passes it on to fill_data_hash_multi;
# It gets back %data, which contains the list of parameters and their value-list for every simtype
#

sub generate_loop_module {
my $specificref=shift; #this is the reference to %specific, the hash of arrays of data for each sim
my $groupedref=shift;
my %grouped=%$groupedref;

my $dataset=shift;
my $flagsref=shift;
my ($batch,$interactive,$nosims,$plot,$verbose,$warn)=@{$flagsref};
my $dataref=&fill_data_hash_multi($specificref);
my %data=%{$dataref};
open(MOD,">Loops_$dataset.pm");

print MOD &strip(<<"ENDHEAD");
*package Loops_$dataset;
*#
*################################################################################
*# Author:           WV                                                         #
*# Date  : 21/11/2000;01/08/2002                                                #
*#                                                                              #
*# Module to support script for SynSim simulations.                             #
*# The subroutine in this module generates the loop to do multiple simulations. #
*# This module is generated by Simulation::Automate.pm                          #
*#                                                                              #
*################################################################################
*
*use sigtrap qw(die untrapped normal-signals
*               stack-trace any error-signals); 
*use strict;
*
*use FileHandle;
*use Exporter;
*
*\@Loops_${dataset}::ISA = qw(Exporter);
*\@Loops_${dataset}::EXPORT = qw(
ENDHEAD

foreach my $sim (keys %data) {
print MOD &strip(
"*			execute_${sim}_loop\n");
}
print MOD &strip('
*                  );
*
');

my @sims=();
foreach my $sim (keys %data) { 
my $title=$data{$sim}{TITLE};
delete $data{$sim}{TITLE};

my $nruns=(exists $data{$sim}{NRUNS})?$data{$sim}{NRUNS}:1;
if($nruns>1) {
$data{$sim}{__NRUNS}=join(',',(1..$nruns));
}
push @sims,$sim;
print MOD &strip(<<"ENDSUBHEAD");

*use lib '..','../..';
*#use Simulation::Automate::Main;
*use Simulation::Automate;
*#use Simulation::Automate::PostProcessors;
*use Simulation::Automate::PostProcLib;
*
*sub execute_${sim}_loop {
*my \$dataset=shift;
*my \$dirname=\"${sim}-\$dataset\";
*my \$flagsref=shift;
*my \$i=0;
*my \$returnvalue;
*my \$resheader='';
*my \%last=();
*my \%sweepeddata=();
*my \$v=$verbose;
*my \$leaveloop=0;

ENDSUBHEAD

#if($data{$sim}{'PREPROCESSOR'}) {
#print MOD &strip('
#*my $preprocref=\&Simulation::Automate::PostProcessors::'.$data{$sim}{'PREPROCESSOR'}.';
#');
#} else {
#print MOD &strip('
#*my $preprocref;
#');
#}

# TITLE is treated separately
print MOD &strip(
"*my \$TITLE = '$title';\n"
);

 foreach my $par (sort keys %{$data{$sim}}) {
$par!~/^\_/ && next;
  #Here as good as anywhere else
#WV 010604 
# We must deal with CONDVAR
# This is not good: it means some postprocessors require a change to the code!
#Anyway
my $conditional =0;
if (exists $data{$sim}{CONDVAR}) {
#CONDVAR must be the sweepvar
$conditional =1;
}

  if ( ( not $conditional and
 (
(exists $data{$sim}{XVAR} and $par eq $data{$sim}{XVAR})  or (exists $data{$sim}{SWEEPVAR} and $par eq  $data{$sim}{SWEEPVAR})
)
) or ( $conditional and 
( $par eq $data{$sim}{CONDVAR})
) 
) {
    #the sweep variable, make sure it's ; not ,
    $data{$sim}{$par}=~s/,/;/g; # a bit rough, comments at end get it as well
    #make sure grouped variables are treated as well
    if (exists $grouped{$par}) {
      my $leader=$grouped{$par};
      foreach my $gpar (sort keys %grouped) {
	if( $grouped{$gpar} eq $leader) {
	  $data{$sim}{$gpar}=~s/,/;/g;
	  delete  $grouped{$gpar};
   }
   }
 }
}
}
# define vars
 foreach my $par (sort keys %{$data{$sim}}) {
   if ($data{$sim}{$par}!~/,/) { # if just one item
     # support for "for..to..step.."-style lists
     $data{$sim}{$par}=&expand_list($data{$sim}{$par});

     $data{$sim}{$par}=~s/^\'//;
     $data{$sim}{$par}=~s/\'$//;
     print MOD &strip(
		      "*my \$${par} = '$data{$sim}{$par}';\n"
		     );
   } 
  }
# assign common hash items
print MOD &strip(
"*my \%data=();\n"
);
print MOD &strip('
*	print STDERR "# SynSim configuration variables\n" if $v;
*	print STDERR "#","-" x 79,"\n#  TITLE : '.$title.'\n" if $v;
*	$resheader.= "# SynSim configuration variables\n";
*	$resheader.= "#"."-" x 79;
*	$resheader.= "\n#  TITLE : '.$title.'\n";
');
print MOD &strip(
"*\$data{TITLE}=\$TITLE;\n"
);
my $nsims=1;
my $prevkey='';

foreach my $par (sort keys %{$data{$sim}}) {

  if($par=~/^_/ && $prevkey!~/^_/) {
print MOD &strip('
*	print STDERR "#","-" x 79,"\n" if $v;
*	print STDERR "# Static parameters used in the simulation:\n" if $v;
*	print STDERR "#","-" x 79,"\n" if $v;
*	$resheader.= "#"."-" x 79;
*	$resheader.= "\n# Static parameters used in the simulation:\n";
*	$resheader.= "#"."-" x 79;
*	$resheader.= "\n";
');
  }

  if ($data{$sim}{$par}!~/,/) { # if just one item, or it might be a sweep
    if($data{$sim}{$par}=~/(\d+)\s*\.\.\s*(\d+)/) {
      my $b=$1;
      my $e=$2;
      my $patt="$b .. $e";
      $nsims=$e-$b+1;
      print MOD &strip(
"*my \@tmp$par=($patt);
*\$data{$par} = [\@tmp$par];
*print STDERR \"# $par = \$$par\\n\" if \$v;
*\$resheader.=  \"# $par = \$$par\\n\";
");

    } elsif($data{$sim}{$par}=~/;/) {
     
 my $tmp=$data{$sim}{$par};
      my $tmps=($tmp=~s/;/,/g);
      if($tmps>=$nsims){$nsims=$tmps+1}
      print MOD &strip(
"*my \@tmp$par=split(/;/,\$$par);
*\$data{$par} = [\@tmp$par];
*print STDERR \"# $par = \$$par\\n\" if \$v;
*\$resheader.= \"# $par = \$$par\\n\";
");
    } else {
      if($par=~/^_/) {
	print MOD &strip(
"*\$data{$par} = [\$$par];
*print STDERR \"# $par = \$$par\\n\" if \$v;
*\$resheader.= \"# $par = \$$par\\n\";
");
      } else {
	print MOD &strip(
"*\$data{$par} = \$$par; # no reason for array
*print STDERR \"#  $par : \$$par\\n\" if \$v; # no reason to print
*\$resheader.= \"#  $par : \$$par\\n\"; # no reason to print
");
      }
    }
  }
  $prevkey=$par;
}

print MOD &strip(
"*my \$nsims=$nsims;\n"
);


foreach my $par (sort keys %{$data{$sim}}) {

  if ($data{$sim}{$par}=~/,/) { # if more than one item
    # support for "for to step"-style lists
    $data{$sim}{$par}=&expand_list($data{$sim}{$par});
    my $parlist=$data{$sim}{$par};
    $parlist=~s/,/ /g;
    #support for "grouped" parameters
    if(exists $grouped{$par}) {
      if($grouped{$par} eq $par){ # the "leader" of the group
	my $leader=$par;
	foreach my $var (sort keys %grouped) {
	  if($grouped{$var} eq $leader){
	    my $varlist=$data{$sim}{$var};
	    $varlist=~s/,/ /g;
	    print MOD &strip(
			     "*my \@${var}list = qw($varlist);
*\$last{$var}=\$${var}list[\@${var}list-1];
");
	  }
	}
	print MOD &strip("*foreach my \$${par} (\@${par}list) {\n");
	foreach my $var (sort keys %grouped) {
	  ($var eq $par) && next;
	  if($grouped{$var} eq $leader){
	    print MOD &strip("*my \$${var}=shift(\@${var}list);\n");
	  }
	}	
      } 
    } else {
    print MOD &strip(
		     "*my \@${par}list = qw($parlist);
*\$last{$par}=\$${par}list[\@${par}list-1];
*foreach my \$${par} (\@${par}list) {\n"
		    );
  }
  } 
}
print MOD &strip(
		 "*\$i++;
*open(RES,\">\$dirname\/${sim}_C\$i.res\")|| do {print STDERR \"Can\'t open \$dirname\/${sim}_\$i.res\" if \$v;};
");
print MOD &strip('
*	print STDERR "#","-" x 79,"\n" if $v;
*	print STDERR "# Parameters for simulation run $i:\n" if $v;
*	print RES $resheader;
*	print RES "#"."-" x 79,"\n";
*	print RES "# Parameters for simulation run $i:\n";
');

my $simtempl=$data{$sim}{SIMTYPE}||$data{$sim}{SIMNAME}||$data{$sim}{SIMULATION}||$data{$sim}{TEMPLATE}||$data{$sim}{SIMTEMPL};
#$simtempl=~s/\.\w+$//;

my $anatempl=$data{$sim}{ANALYSIS_TEMPLATE}||$data{$sim}{ANALYSIS}||$data{$sim}{ANATEMPL}||$data{$sim}{ANALYSIS_TEMPL}||$data{$sim}{ANA_TEMPLATE}||'None';#'NoAnalysisDefined';
my $subref=$anatempl;

print MOD &strip('
*my $resfilename="'.$sim.'-'.$anatempl.'";
*$data{RESHEADER}=$resheader;
');

foreach my $par (sort keys %{$data{$sim}}) {
  if ($data{$sim}{$par}=~/,/) { # if more than one item
    print MOD &strip(
		     "*\$data{$par} = [\$$par];
*\$sweepeddata{$par} = \$$par;
*\$resfilename.=\"-${par}-\$$par\";
*print STDERR \"# $par = \$$par\\n\" if \$v;
*print RES \"# $par = \$$par\\n\";
");
  }
}

##WV21042003: old, sweep loops internal
#print MOD &strip(
#"* close RES;
#*\$resfilename.='.res';
#*#NEW01072003#rename \"\$dirname\/${sim}_C\$i.res\",\"\$dirname\/\$resfilename\";
#*my \$dataref = [\$nsims,\\\%data];
#*\$returnvalue=&main(\$dataset,\$i,\$dataref,\$resfilename,\$flagsref);
#*
#");

#WV21042003: new, sweep loops external

#The idea is to evaluate a condition inside the loop, after very sim
#If the condition is satisfied, skip the next 

print MOD &strip(
"* close RES;
*my \$dataref = [\$nsims,\\\%data];
*#my \$nsims=&pre_run(\$dataset,\$i,\$dataref,\$flagsref);
*\$nsims=&pre_run(\$dataset,\$i,\$dataref,\$flagsref);
*my \$dataref_postproc = [\$nsims,\\\%data,\\\%sweepeddata,\\\%last];
*foreach my \$simn (1..\$nsims) {
*\$leaveloop && last;
*\$returnvalue=&run(\$nsims,\$simn);
*#print STDERR \"RET:\$returnvalue=\$nsims,\$simn\\n\";
*
*#Call postprocessor inside loop to see if we can leave the loop early
*#chdir \$dirname;
*#print \"SUBREF:$subref\\n\";
*#\$leaveloop=&Simulation::Automate::PostProcessors::$subref(\$dataset,\$i,\$dataref_postproc,\$flagsref,[\$returnvalue],\$preprocref,2);
*#chdir '..';
*#print \"LEAVE: \$leaveloop\\n\";
*}
*\$returnvalue=&post_run();
*
");


print MOD &strip(<<"ENDPP");
*chdir \$dirname;
*my \$dataref1 = [\$nsims,\\\%data,\\\%sweepeddata,\\\%last];
*#&Simulation::Automate::PostProcessors::$subref(\$dataset,\$i,\$dataref1,\$flagsref,\$returnvalue,\$preprocref);
*&prepare(\$dataset,\$i,\$dataref1,\$flagsref,\$returnvalue);
*chdir '..';
ENDPP

foreach my $par (reverse sort keys %{$data{$sim}}) {
  if ($data{$sim}{$par}=~/,/) {
    if( not exists $grouped{$par} or (exists $grouped{$par} and ($grouped{$par} eq $par))) {
    print MOD &strip(
		     "*} #END of $par\n"
		    );
  }
  }
}

print MOD &strip(<<"ENDPP");
*chdir \$dirname;
*my \$dataref2 = [\$nsims,\\\%data,\\\%sweepeddata,\\\%last];
*#&Simulation::Automate::PostProcessors::$subref(\$dataset,\$i,\$dataref2,\$flagsref,1);
*&prepare(\$dataset,\$i,\$dataref2,\$flagsref,1);
*chdir '..';
ENDPP

print MOD &strip(<<"ENDTAIL");
* return \$returnvalue;
*} #END of execute_${sim}_loop
ENDTAIL
$data{$sim}{TITLE}=$title;
} #END of loop over sims

close MOD;
print STDERR "...Done\n\n" if $verbose;

return \%data;
} #END of generate loop module

#-------------------------------------------------------------------------------
sub strip {
my $line=shift;
$line=~s/(^|\n)\*/$1/sg;
return $line;
}
#-------------------------------------------------------------------------------
#
# This subroutine takes a reference to %specific as generated by allow_multiple_sims($datafile)
# So  %multisimdata is actually %specific
# Then, it turns this into a hash of hashes:
# for every $sim, there's a hash with as key the parameter name and as value its value-list
# This is %data, which is returned to $dataref in  generate_loop_module()
# 
sub fill_data_hash_multi {
my $dataref=shift; # reference to %specific
my %data=();
my %multisimdata=%$dataref;
foreach my $sim (keys %multisimdata) {

  foreach (@{$multisimdata{$sim}}){

  if(/^\s*_/) {

my @line=();#split(/\s*=\s*/,$_);
# changed to allow expressions with "=" 
my $line=$_;
($line=~s/^([A-Z0-9_]+)?\s*=\s*//)&&($line[0]=$1);
$line[1]=$line;
$line[1]=~s/\s*\,\s*/,/g;
$line[1]=~s/\s*\;\s*/;/g;
#13082004:What if we just replace ; by , here?
($line[1]!~/[a-zA-Z]/) &&($line[1]=~s/;/,/g); # if there are no expressions

$data{$sim}{$line[0]}=$line[1];
} elsif (/:/) {
my @line=();#split(/\s*:\s*/,$_);
# changed to allow expressions with ":"
my $line=$_;
($line=~s/^([A-Z0-9_]+)?\s*\:\s*//)&&($line[0]=$1);
$line[1]=$line;
#strip trailing spaces
$line[1]=~s/\s+$//;
$data{$sim}{$line[0]}=$line[1];
} #if
  } # foreach
}
return \%data;
} #END of fill_data_hash_multi

#-------------------------------------------------------------------------------
#
# this subroutine splits the datafile into a common part (@common) and a number
# of simtype-specific parts ( %specific{$simtype}); then, it pushes @common onto
# @{$specific{$simtype}} and returns \%specific
# So every key in %specific points to an array with all variables needed for that simtype
#
sub allow_multiple_sims {
my $datafile=shift;
my @sims=();
my $simpart=0;
my $simpatt='NOPATTERN';
my @common=();
my %specific=();
my %grouped=();
my $simtype='NOKEY';
my $skip=0;
open(DATA,"<$datafile")|| die "Can't open $datafile\n";

while(<DATA>) {

/^\s*\#/ && next;
/^\s*$/ && next;
chomp;
# allow include files for configuration variables
/INCL.*\s*:/ && do {
my $incl=$_;
$incl=~s/^.*\:\s*//;
$incl=~s/\s+$//;
my @incl=($incl=~/[,;]/)?split(/\s*[,;]\s*/,$incl):($incl);
foreach my $inclf (@incl) {
open(INCL,"<$inclf")|| die $!;
while(my $incl=<INCL>) {
$incl=~/^\s*\#/ && next;
$incl=~/^\s*$/ && next;
chomp $incl;
# only configuration variables in include files!
($incl=~/:/) && do {push @common,$incl};
}
close INCL;
}
}; # END of allow INCL files
#print STDERR "$_\n";
s/(\#.*)//; # strip comments
s/[;,]\s*$//; # be tolerant: remove separators at end of line
if(/SIM(TYPE|NAME|ULATION|TEMPL)|\bTEMPLATE\s*:/) {
my $sims=$_;
s/TEMPLATE/SIMULATION/;
s/\.\w+$//;
(my $par,$simpatt)=split(/\s*:\s*/,$sims);
$simpatt=~s/\s*\,\s*/|/g;
$simpatt=~s/\s+//g;
@sims=split(/\|/,$simpatt);
my $ext='';
foreach my $sim (@sims){
$sim=~s/(\.\w+)$//;
$ext=$1;
};
if($ext && $ext=~/^\./){
push @common,"TEMPL: $ext\n";
}
$simpatt=join('|',@sims);
$simpatt='('.$simpatt.')';
} elsif(/$simpatt/) {
$skip=0;
$simtype=$1;
#$simtype=~s/\.\w+$//;
$simpart=1
} elsif(/^\s*[a-zA-Z]/&&!/:/) {
$simpart=0;
$skip=1;
print STDERR "$_: Not present in simlist. Skipping data.\n";
}
/^\s*GROUP\s*:\s*([\_A-Z0-9\,\;\s]+)$/ && do {
my $groupline=$1;
#This assumes a single GROUP line with a semicol-separated list of comma-separated values
#Too complex. Just allow multiple GROUP lines, one per group
#my @grouped=split(/\s*\;\s*/,$groupline);
#foreach my $group (@grouped){
#my @groupline=split(/\s*\,\s*/,$group);
#foreach my $item (@groupline){
#$grouped{$item}=$groupline[0];
#}
#}
my @groupline=split(/\s*[\,\;]\s*/,$groupline);
foreach my $item (@groupline){
$grouped{$item}=$groupline[0];
}
next;
};
if($simpart) {
push @{$specific{$simtype}},$_;
} elsif(!$skip) {
push @common,$_;
} else {
print STDERR "Skipped: $_\n" ;
}

} #while
close DATA;

foreach my $sim (@sims) {
push @{$specific{$sim}},@common;
}

return (\%specific,\%grouped);
} #END of allow_multiple_sims
#-------------------------------------------------------------------------------
#
# this subroutine expands for-to-step lists in enumerated lists
#
sub expand_list {
my $list=shift;
$list=~s/\#.*$//;
my $sep=($list=~/;/)?';':','; #

my @list=split(/\s*$sep\s*/,$list);
if(@list==3 && $list!~/[a-zA-Z]/) { #
if(
(
($list[0]<$list[1] && $list[2]>0)||($list[0]>$list[1] && $list[2]<0)
) && (
abs($list[2])<abs($list[1]-$list[0])
)
) {
my $start=$list[0];
my $stop=$list[1];
my $step=$list[2];
$list="$start";
my $i=$start;
while(("$i" ne "$stop")&&((($stop>=0)&&($i<$stop))||(($stop<0)&&($i>$stop)))) { #yes, strange, but Perl says 0.9>0.9 is true!
$i+=$step;
$list.="$sep$i";
}
#print "LIST: $list\n";
#die;
}
}

return $list;
} # END of expand_list
#===============================================================================

sub execute_loop {
my $datafilename=shift;
my $dataset=shift;

require "./Loops_$dataset.pm";
#eval("
#use Loops_$dataset;
#");

my $simref=shift;
my @flags=@{shift(@_)};
my $nosims=$flags[2];
my $verbose=$flags[4];

foreach my $sim (sort keys %{$simref}) {
my $commandline=${$simref}{$sim}->{COMMAND};

$commandline && do {
$commandline=~s/inputfile//i;
$commandline=~s/outputfile//i;
$commandline=~s/\s\-+\w+//g;
$commandline=~s/^\s+//;
$commandline=~s/\s+$//;
};
my @maybe_files=($commandline)?split(/\s+/,$commandline):();

# extension for template files
my $templ=${$simref}{$sim}->{TEMPLEXT}||${$simref}{$sim}->{TEMPL}||'.templ';
my $dev=${$simref}{$sim}->{DEVTYPE}||${$simref}{$sim}->{DEVICE}||'';

my $dirname= "${sim}-$dataset";

  if(-e $dirname && -d $dirname) {
    if ($nosims==0) {
print STDERR "\n# Removing old $dirname dir\n" if $verbose;
if ($verbose) {
print `rm -Rf $dirname`;
} else {
system("rm -Rf $dirname");
}
} else {
print STDERR "\n# Cleaning up $dirname dir\n" if $verbose;
if ($verbose) {
print `rm -f $dirname/$sim-*`;
print `rm -f $dirname/tmp*`;
} else {
system("rm -f $dirname/tmp*");
}
}
}

  if (not -e "TEMPLATES/SIMTYPES/$sim$templ" and not -e "TEMPLATES/$sim$templ" ) {
   
print STDERR "No templates for simulation $sim. Skipped.\n";# if $verbose; #always warn!
next;

} else {
#if the template in under TEMPLATES, make a simlink to TEMPLATES/SIMTYPES
 if (-e "TEMPLATES/$sim$templ" and not -l "TEMPLATES/SIMTYPES/$sim$templ" ) {
      system("cd TEMPLATES/SIMTYPES && ln -s ../$sim$templ .");
    } 
mkdir $dirname, 0755;

if (-e "TEMPLATES/SIMTYPES/$sim$templ") {
system("cp TEMPLATES/SIMTYPES/$sim$templ $dirname");
} else {
die "There's no simulation template for $sim in TEMPLATES/SIMTYPES\n";
}
if($dev){
if (-e "TEMPLATES/DEVTYPES/$dev$templ") {
system("cp TEMPLATES/DEVTYPES/$dev$templ $dirname");
} else {
print STDERR "No device template for $dev in TEMPLATES/DEVTYPES.\n" if $verbose;
}
}
# any file with this pattern is copied to the rundir.
if (-d "SOURCES") {
  if(<SOURCES/$sim*>){
system("cp SOURCES/$sim* $dirname");
}
  foreach my $maybe_file(@maybe_files){
    if(-e "SOURCES/$maybe_file" and not -e "$dirname/$maybe_file"){
      system("cp SOURCES/$maybe_file $dirname/$maybe_file");
    }
  }
} 
}
print STDERR "#" x 80,"\n" if $verbose;
print STDERR "#\n" if $verbose;
print STDERR "# Simulation type: $sim, device dir ".`pwd`."#\n" if $verbose;
print STDERR "#" x 80,"\n" if $verbose;

eval('&Loops_'.$dataset.'::execute_'.$sim.'_loop($dataset,\@flags);');

} #sims
return 1;
} #END of &execute_loop
#==============================================================================
#Routines to support script for simulation automation.
#The function &main() is called from the innermost loop of
#Loops_*.pm
push @Simulation::Automate::EXPORT, qw(
		     main
		     pre_run
		     run
		     post_run					
);

use  Simulation::Automate::Analysis;

##################################################################################
my $simpid=undef; 



#========================================================================================
#  NEW IMPLEMENTATION TO ALLOW POSTPROCESSING AFTER EVERY ELEMENT IN SWEEP
#========================================================================================
my @results=();
my @sweepvarnames=();
my %simdata=();
my $simtype='NO_SIMTYPE';
my $dataset='NO_DATASET';
my $count=0;
my $batch; my $interactive; my $nosims; my $plot; my $verbose; my $warn;
my $output_filter_pattern= '.*';
my $command='perl inputfile outputfile'; 
my $dirname= 'NO_DIRNAME';
my $devtype='NO_DEVTYPE';
my $simtitle='NO_TITLE';
my $title="#$devtype $simtype simulation\n";
my $ext='.templ';
my $extin='.pl';
my $workingdir = 'NO_WORKINGDIR';
#------------------------------------------------------------------------------

sub pre_run {
#called as:&pre_run(\$dataset,\$i,\$dataref,\$flagsref);
$dataset=shift; 
$count=shift;
my $dataref=shift;
my $flagsref=shift;

use Cwd;

#extract flags from flagsref
($batch,$interactive,$nosims,$plot,$verbose,$warn)=@{$flagsref};
#extract number of sims and ref to simdata from dataref
(my $nsims, my $simdataref)=@{$dataref};
#put simdata in a hash
%simdata=%{$simdataref};

print STDERR '#',"-" x 79, "\n" if $verbose;

$command=$simdata{COMMAND}||'perl inputfile outputfile'; 
$output_filter_pattern=$simdata{OUTPUT_FILTER_PATTERN}|| '.*';
$simtype=$simdata{SIMTYPE}||$simdata{SIMNAME}||$simdata{SIMULATION}||$simdata{TEMPLATE}||$simdata{SIMTEMPL}||'';
#$simtype=~s/\.\w+$//;
$dirname= "${simtype}-$dataset";
$devtype=$simdata{DEVTYPE}||$simdata{DEVICE}||$simdata{DEVTEMPL}||'';
$simtitle=$simdata{TITLE};
@sweepvarnames=();
foreach my $key (keys %simdata) {
  ($key!~/^_/) && next;
  ($simtitle=~/$key/) && do {
    $simtitle=~s/$key/$key:$simdata{$key}/;
  };
my $ndata=@{$simdata{$key}};
if($ndata>1) {
push @sweepvarnames,$key;
  }
}
$title="#$simtitle\n"||"#$devtype $simtype simulation\n";
$ext=$simdata{TEMPLEXT}||$simdata{TEMPL}||'.templ';
$extin=$simdata{EXT}||'.pl';
$workingdir =cwd();
chdir "$workingdir/$dirname";
return $nsims;
} #END of pre_run()
#------------------------------------------------------------------------------

sub run {
#called as:&run(\$nsims,\$simn);
my $nsims=shift;
my $simn=shift;

## INPUT FILE CREATION

if($nsims==1){$simn=''} else {
#  print STDERR "# Subrun $simn of $nsims \n" if $verbose;
   if($simn==1){
print STDERR "# Sweep $nsims values for " if $verbose;
    foreach my $sweepvarname(@sweepvarnames){
      print STDERR "$sweepvarname " if $verbose;
    }
  print STDERR ":\n" if $verbose;
    }
    foreach my $sweepvarname(@sweepvarnames){
      print STDERR $simdata{$sweepvarname}->[$simn-1],' ' if $verbose;
#      print STDERR " $sweepvarname = ",$simdata{$sweepvarname}->[$simn-1] if $verbose;
    }
print STDERR " \n" if $verbose;

 # foreach my $sweepvarname(@sweepvarnames){
  #  print STDERR " $sweepvarname = ",$simdata{$sweepvarname}->[$simn-1] if $verbose;
  #}
#  
}
my $inputfile= "${simtype}_${simn}$extin";
my $outputfile= "${simtype}_C${count}_${simn}.out";
my $commandline=$command;
$commandline=~s/inputfile/$inputfile/ig;
$commandline=~s/outputfile/$outputfile/ig;
  
open (NEW, ">$inputfile");

foreach my $type ($devtype,$simtype) {
  if($type) {
    my $nsim=($simn eq '')?0:$simn;
    &gen_sim_script ($nsim-1,"$simtype$ext",\%simdata,\*NEW,$dataset,$warn);
  }
} # device and simulation templates
close (NEW);

if($nosims==0) {
  if($verbose) {
    if (!defined($simpid = fork())) {
      # fork returned undef, so failed
      die "cannot fork: $!";
    } elsif ($simpid == 0) {
      # fork returned 0, so this branch is the child
      exec("$commandline");
      # if the exec fails, fall through to the next statement
      die "can't exec $commandline : $!";
    } else { 
      # fork returned neither 0 nor undef, 
      # so this branch is the parent
      waitpid($simpid, 0);
    } 
  } else { # not verbose
    print STDERR "\n" if $verbose;
    $simpid = open(SIM, "$commandline 2>&1 |") || die "can't fork: $!"; 
    open(LOG,">simlog");
    while (<SIM>) {
      print LOG;
      /$output_filter_pattern/ && do {
	print STDERR;# if $verbose;
      };
    } # while sinulation is running
    close LOG;
    my $ppid=getpgrp($simpid);
    if(not $ppid) {
      close SIM || die "Trouble with $commandline: $! $?";
    }
    print STDERR "\n" if $verbose;
  } #verbose or not

  if($nsims>1) {
    #Postprocessing
    &egrep($output_filter_pattern,"${simtype}_C${count}_${simn}.out",'>>',"${simtype}_C${count}_.out");
  }
} # if simulations not disabled
my $i=($nsims>1)?$simn-1:0;
open(RES,"<${simtype}_C${count}_${simn}.out");
$results[$i]=<RES>;
my $another=<RES>; # This takes the next line, if any,
if($another) { # and if there is one, it assigns the filename to $results[$i]
  $results[$i]="${simtype}_C${count}_${simn}.out";
}
close RES;

#no need to return @results, it's a package global now. Maybe return $results[$i], makes more sense.
my $result= $results[$i];
chomp $result;
return $result; # PostProcessors are only called after &main() exits.
} # END of run()
#------------------------------------------------------------------------------
sub post_run {
#called as:&post_run();
  if($nosims==0){
#Postprocessing after sweep
&egrep($output_filter_pattern, "${simtype}_C${count}_.out", '>>', "${simtype}_C$count.res");
if(  $results[0]=~/${simtype}_C\d+.*\.out/) {
open(RES,"${simtype}_C$count.res");
@results=<RES>;
close RES;
}
}
chdir "$workingdir";

return \@results; # PostProcessors are only called after &main() exits.

} # END of post_run()
#==============================================================================

#print STDERR "\n","#" x 80,"\n#\t\t\tSynSim simulation automation tool\n#\n#  (c) Wim Vanderbauwhede 2000,2002-2003. All rights reserved.\n#  This program is free software; you can redistribute it and/or modify it\n#  under the same terms as Perl itself.\n#\n","#" x 80,"\n";

#-------------------------------------------
# SUBROUTINES used by main, pre_run, run, post_run
#-------------------------------------------

#--------------------------------------
# GENERATION OF THE SIMULATION SCRIPT
#--------------------------------------

#WV What happens: the templates for _SIMTYPE  are read in
#WV and the variables are substituted with the values from the .data file

sub gen_sim_script {

my $nsim=shift;
my $templfilename=shift;
my $simdataref=shift;
my %simdata=%{$simdataref};
my $fh=shift; 
my $dataset=shift;
my $warn=shift;
my %exprdata=();
my %keywords=();
foreach my $key ( sort keys %simdata) {
#make sure substitutions happen in keyword values too
  if ($key!~/^_/ ) {
    if( $simdata{$key}=~/^_/) {
      my $parameter=$simdata{$key};
      ${$keywords{$parameter}}{$key}=1;
    }
    next;
  }

  if(@{$simdata{$key}}==1) {
    $exprdata{$key}=&check_for_expressions(\%simdata,$key,$nsim);
    foreach my $keyword (keys %{$keywords{$key}}) {
      $simdata{$keyword}=$exprdata{$key};
    }
  } # if..else
} # foreach 

# OPEN TEMPLATE
open (TEMPL, "<$templfilename")||die "Can't open $templfilename\n";
while (my $line = <TEMPL>) {
  foreach my $key (keys %simdata) {
    ($key!~/^_/) && next;
    my $ndata=@{$simdata{$key}};
    if($ndata>1) {
      if($line =~ s/$key(?!\w)/$simdata{$key}->[$nsim]/g){
	#print STDERR "# $key = ",$simdata{$key}->[$nsim],"\n" if $warn;
      }
    } else {
      #my $simdata=&check_for_expressions(\%simdata,$key,$nsim);
      #A dangerous addidtion to make SynSim handle words
      $exprdata{$key}||=$simdata{$key}->[0];
      $line =~ s/$key(?!\w)/$exprdata{$key}/g;
      #print STDERR "# $key = ",$simdata{$key}->[0],"\nLINE:$line\n" if $warn;
    } # if..else
  } # foreach 
  
  # check for undefined variables
  while($line=~/\b(_\w+?)\b/&&$line!~/$1\$/) {
    my $nondefvar=$1;
    $line=~s/$nondefvar/0/g; # All undefined vars substituted by 0
    print STDERR "\nWarning: $nondefvar ($templfilename) not defined in $dataset.\n" if $warn; 
  } # if some parameter is still there
  print $fh $line;
} # while
close TEMPL;

} # END OF gen_sim_script 
#------------------------------------------------------------------------------
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
sub check_for_expressions {
my $dataref=shift;
my $key=shift;
my $nsim=shift;
my %simdata=%{$dataref};	
my $expr=$simdata{$key}->[0];
if($expr=~/(_[A-Z_]+)/) { # was "if"
while($expr=~/(_[A-Z_]+)/) { # was "if"
#variable contains other variables
#_A =3*log(_B)+_C*10-_D**2
#_A =3 ;log;_B;;_C;10;_D;;2
my @maybevars=split(/[\ \*\+\-\/\^\(\)\[\]\{\}\?\:\=\>\<]+/,$expr);
my @vars=();
foreach my $maybevar ( @maybevars){
($maybevar=~/_[A-Z]+/)&& push @vars,$maybevar;
}
foreach my $var (@vars) {
my $simn=(@{$simdata{$var}}==1)?0:$nsim;
$expr=~s/$var/$simdata{$var}->[$simn]/g;
}
}
#print STDERR "$key=$expr=>",eval($expr),"\n";
}
return eval($expr);
}

################################################################################
#
# These routines are not used by synsim
# They are used by make install
#
################################################################################

# Create simulation directory etc.
sub setup {

my $HOME=$ENV{HOME};
print "Local SinSym directory? [$HOME/SynSim]:";
my $synsimroot=<STDIN>;
chomp $synsimroot;
if(not $synsimroot){$synsimroot="$HOME/SynSim"}
if($synsimroot!~/^\//) {
print "The directory $synsimroot will be created in $HOME\n";
$synsimroot="$HOME/$synsimroot"
}

  if(not -d "$synsimroot"){
mkdir "$synsimroot", 0755;
  }


print "Simulation project directory? [SynSimProject]:";
my $project=<STDIN>;
chomp $project;
if(not $project){$project='SynSimProject'}


print "Creating $project directory structure in $synsimroot...\n";
mkdir "$synsimroot/$project", 0755;
mkdir "$synsimroot/$project/SOURCES", 0755;
mkdir "$synsimroot/$project/TEMPLATES", 0755;
mkdir "$synsimroot/$project/TEMPLATES/DEVTYPES", 0755;
mkdir "$synsimroot/$project/TEMPLATES/SIMTYPES", 0755;
  if(-d "eg"){
    if(-e "eg/synsim"){
system("cp eg/synsim $synsimroot/$project/synsim");
}
    if(-e "eg/synsim.data"){
system("cp eg/synsim.data $synsimroot/$project/synsim.data");
}

    if(-e "eg/TEMPLATES/test.templ"){
system("cp eg/TEMPLATES/test.templ $synsimroot/$project/TEMPLATES/");
}
  }

&localinstall(0,$synsimroot);

} # END of setup()

#------------------------------------------------------------------------------

# Local Simulation::Automate (SynSim) installation
sub localinstall {
my $full=shift||1;
my $synsimroot=shift||'';

my $HOME=$ENV{HOME};
if(not $synsimroot) {
print "Local SinSym directory? [$HOME/SynSim]:";
$synsimroot=<STDIN>;
chomp $synsimroot;
if(not $synsimroot) {$synsimroot="$HOME/SynSim"}
}
  if(not -d "$synsimroot"){
mkdir "$synsimroot", 0755;
  }
print "Creating local SynSim directory $synsimroot/Simulation/Automate ...\n";
  if(not -d  "$synsimroot/Simulation") {
mkdir "$synsimroot/Simulation", 0755;
}
  if(not -d  "$synsimroot/Simulation") {
mkdir "$synsimroot/Simulation", 0755;
}
  if(not -d  "$synsimroot/Simulation/Automate") {
mkdir "$synsimroot/Simulation/Automate", 0755;
}
  if(-d "Automate") {  
foreach my $module (qw(PostProcessors Dictionary)) {
if( -e "Automate/$module.pm"){
system("cp Automate/$module.pm $synsimroot/Simulation/Automate/$module.pm");
}
}
if($full) {
  foreach my $module (qw(Remote PostProcLib Analysis)){
if( -e "Automate/$module.pm"){
system("cp Automate/$module.pm $synsimroot/Simulation/Automate/$module.pm");
}
}
if( -e "Automate.pm"){
system("cp Automate.pm $synsimroot/Simulation/Automate.pm");
}
} # if full local install
} # if directory Automate exists in current dir. 

} # END of localinstall()

######################## User Documentation ##########################


## To format the following documentation into a more readable format,
## use one of these programs: perldoc; pod2man; pod2html; pod2text.
## For example, to nicely format this documentation for printing, you
## may use pod2man and groff to convert to postscript:
##   pod2man Automate.pod | groff -man -Tps > Automate.ps


=head1 NAME

Simulation::Automate - A Simulation Automation Tool

The set of modules is called B<Simulation::Automate>.

The tool itself is called B<SynSim>, the command C<synsim>.

=head1 REQUIREMENTS

=over 4

=item * a unix-like system

=item * perl 5

=item * gnuplot for postprocessing (optional)

=back

=head1 SYNOPSIS

       use Simulation::Automate;

       &synsim();

=head1 DESCRIPTION

SynSim is a generic template-driven simulation automation tool. It works with any simulator that accepts text input files and generates text output (and even those that don't. See L</"EXAMPLES"> for special cases). It executes thousands of simulations with different input files automatically, and processes the results. Postprocessing facilities include basic statistical analysis and automatic generation of PostScript plots with Gnuplot. SynSim is entirely modular, making it easy to add your own analysis and postprocessing routines.

=head1 INSTALLATION

=head2 1. Download and extract the archive

=over 4

=item 1.
Download the gzipped tar file F<Simulation-Automate-0.9.5.tar.gz>

=item 2.
Extract the archive:

	tar -zxvf Simulation-Automate-0.9.5.tar.gz

=back

=head2 2. Simple local installation

This installation procedure will install the Simulation::Automate modules in a directory of your choice, and create a template directory structure for your SynSim project.

=over 4

=item 1. Run the local install script:

In the main directory of the distribution (i.e. the directory which contains the file C<local_install.pl>), type:

   perl local_install.pl

=item 2. Enter the installation directory

The install script asks for the name of the directory in which it will put SynSim:

   Local SinSym directory? [/local/home/wim/SynSim]:

If you enter just a name, the installer assumes that the directory is in your home directory. If you want to install SynSim outside your home directory, enter a full path.

=item 3. Enter the project directory name

The install script asks for the name of directory where you will run SynSim:

    Simulation project directory? [SynSimProject]:

This directory is a subdirectory of the local SynSim directory.

=back

That's it. Now you can go to your project directory and run the synsim script as a test:

    ./synsim

This will run a simple test. If the installation was succesful, it will display the follwing message:

    SynSim Installation Test
 
    Simulation::Automate version 0.9.6
 
    installed locally in /home/wim/SynSim/Test
 
    Finished SynSim run
 

=head2 3. Perl-style installation

This is the typical Makefile.PL-driven installation procedure. It is only required for system-wide installation, but it works for local installation as well.

=over

=item 1.
Create the Makefile:

	cd Simulation-Automate-0.9.5
	perl Makefile.PL

=item 2.
Make Simulation::Automate:

	make

=item 3.
Test Simulation::Automate:

	make test

=item 4.
Install Simulation::Automate:

This requires you to be root:

	su
	make install

or

	sudo make install


=item 5.
For a local installation 

This does not require you to be root:

	make localinstall

or

	perl -e "use Simulation::Automate;
                 &Simulation::Automate::localinstall();"

=item 6.
Setup your local SynSim project (

SynSim is the name for the tool contained in Simulation::Automate. This step creates the directory structure for your simulations:

	make setup
or

	perl -e "use Simulation::Automate;
                 &Simulation::Automate::setup();"

=back

=head2 4. Archive structure

The archive structure is as follows:

	README    
	Makefile.PL	  
        Automate.pm
        local_install.pl
	Automate/
                Remote.pm
        	PostProcLib.pm
                Analysis.pm
		Dictionary.pm
             	PostProcessors.pm

	eg/
		synsim	
		synsim.data
		ErrorFlags.data
		Histogram.data
		SweepVar.data
		Expressions.data
		gnuplot.data
		SOURCES/
			bufsim3.cc
			MersenneTwister.h
		TEMPLATES/		
			test.templ
			DEVTYPES/
			SIMTYPES/
				bufsim3.templ
		PLUGINS/		


=head1 CONFIGURATION

To configure SynSim for use with your simulator, you must create a set of files in your SynSim project directory structure. This paragraph gives an overview of the different types of files and their place in the SynSim project directory structure.  

=head2 SynSim project directory structure

You can create a SynSim directory structure with C<perl local_install.pl> or C<make setup> (see L</"INSTALLATION"> for details). If you already have an existing project, you can do this:

=over 4

=item *
Create a new project directory:

        mkdir NewProject

=item *
Copy the C<synsim> script from the old project:

        cp oldProject/synsim NewProject

=item *
Go to the C<NewProject> directory and run C<synsim> with the C<-D> option:

        cd NewProject
        ./synsim -D

=back

If you want to create it manually, this is the structure. Directories between square brackets are optional.

	YourProject/
			synsim	
			YourDataFile.data
			[SOURCES/]
			TEMPLATES/		
				 YourSimTempl.templ
				 [DEVTYPES/]
				 [SIMTYPES/]
				 [PLUGINS/]
	[Simulation/SynSim/]
				[Dictionary.pm]
				[PostProcessors.pm]			

The C<synsim> script is the actual script that runs the DOE. It contains the 2 lines from the L</"SYNOPSIS">.  
The local Simulation/Automate modules are only required if you want to customize the postprocessing. 
 
=head2 Source files

The directory F<SOURCES/> is optional. It should contain all files which are required "read-only" by your simulator (e.g. header files, library files, wrappers).

=head2 Template files

Template files are files in which simulation variables will be substituted by their values to create the input file for your simulator. They must be stored in the F<TEMPLATES/> directory, and have by convention the extension C<.templ>.

B<SynSim variable format>

The template file format is free, but the variables to be substituted by SynSim I<must> be in uppercase and start with an underscore:

Examples:

        _VAR1
        _LONG_VARIABLE_NAME

To create a template file, start from an existing input file for your simulator. Replace the values of the variables to be modified by SynSim by a SynSim variable name (e.g. 
var1 = 2.5 => var1 = _VAR1). Put the template files in F<TEMPLATES>.


B<Note:> Relative paths to source files

SynSim creates a run directory ath the same level as the SOURCES and TEMPLATES directories. All commands (compilations etc.) are executed in that directory. As a consequence, paths to source files (e.g. header files) should be "C<../SOURCES/>I<sourcefilename>".

B<Note:> The F<DEVTYPES/> and F<SIMTYPES/> subdirectories 

SynSim can create an input file by combining two different template files, generally called device templates and simulation templates. This is useful in case you want to run different types of simulations on different devices, e.g. DC analysis, transient simulations, small-signal and noise analysis  on 4 different types of operational amplifiers. In total, this requires 16 different input files, but only 8 different template files (4 for the simulation type, 4 for the device types). If you want to use this approach, device templates should go in F<TEMPLATES/DEVTYPES/> and simulation templates in  F<TEMPLATES/SIMTYPES/>. 
SynSim will check both directories for files as defined in the datafile. If a matching file is found in F<DEVTYPES>, it will be prepended to the simulation template from F<SIMTYPES>. 

=head2 Datafile

The datafile is the input file for C<synsim>. It contains the list of simulation variables and their values to be substituted in the template files, as well as a number of configuration variables. See L</"DATAFILE DESCRIPTION"> for more information.

=head2 Postprocessing and Preprocessing (optional)

The F<PostProcessing.pm> module contains routines to perform postprocessing on the simulation results (e.g. plotting, statistical analysis, etc). A number of generic routines are provided, as well as a library of functions to make it easier to develop your own postprocessing routines. See L</"POSTPROCESSING"> for a full description). 

Before the raw data are sent to the postprocessor, it is possible (and very easy) to preprocess the raw data.  See L</"PREROCESSING"> for more details. 

Custom postprocessing and preprocessing routines can either be stored in the F<PLUGINS/> directory (preferred) or directly in the local F<PostProcessing.pm> module (more intended for modified versions of the generic routines).

=head2 Dictionary (optional)

The F<Dictionary.pm> module contains descriptions of the parameters used in the simulation. These descriptions are used by the postprocessing routines to make the simulation results more readable. See L</"DICTIONARY"> for a full description).

=head1 DATAFILE DESCRIPTION

The datafile defines which simulations to run, with which parameter values to use, and how to run the simulation. By convention, it has the extension C<.data>.

=head2 Syntax

The datafile is a case-sensitive text file with following syntax:

=over 4

=item Comments and blanks

Comments are preceded by '#'. 
Comments, blanks and empty lines are ignored

=item Parameters

Parameters (simulation variables) are in UPPERCASE with a leading '_', and must be separated from their values with a '='.

=item Keywords

Keywords (configuration variables) are in UPPERCASE, and must be separated from their values with a ':'.

=item Lists of values

Lists of values have one or more items. The list separator is a comma ','.

Example:

	_PAR1 = 1,1,2,3,5,8,13

If a list has 3 elements START,STOP,STEP, then if possible this list will be expanded as a for-loop from START to STOP with step STEP.

Example:

       _NBUFS = 16,64,8 #  from 16 to 64 in steps if 8: 16,24,32,40,48,56,64

=item Section headers for multiple simulation types (optional)

These must be lines containing only the simulation type 

=back

=head2 Simulation variables 

The main purpose of the datafile is to provide a list of all variables and their values to be substituted in the template files. 

=over 4

=item Default behaviour: combine values

A simulation will be performed for every possible combination of the values for all parameters. 

Example:

	_PAR1 = 1,2
	_PAR2 = 3,4,5

defines 6 simulations: (_PAR1,_PAR2)=(1,3),(1,4),(1,5),(2,3),(2,4),(2,5)

Simulation results for all values in ','-separated list are stored in a separate files.


=item Alternative behaviour: group values

It is possible (See the keyword B<GROUP> under L</"Configuration variables">) to define groups of variables. For every parameter in a group, the value list must have the same number of items. The values of all variables at the same position in the list will be used.

Example:

	GROUP: _PAR1,_PAR2

	_PAR1 = 0;1;2;4
	_PAR2 = 3;4;5;6

defines 4 simulations: (_PAR1,_PAR2)=(0,3);(1,4);(2,5);(4,6)

=back

=head2 Configuration variables

A number of configuration variables ("keywordsw) are provided to configure SynSim's behaviour. There is no mandatory order, but they must appear before the simulation variable. For the default order, see the L</"EXAMPLES">. 
In alphabetical order, they are:

=over 4


=item ANALYSIS

B<Alternative names:> ANALYSIS_TEMPLATE, ANATEMPL

Name of the routine to be used for the result analysis (postprocessing). This routine must be defined in PostProcessors.pm or in a file in the F<PLUGINS/> directory. A number of generic routines are provided, see L</"POSTPROCESSING">.

=item COMMAND

The command line for the program that runs the input file, i.e. the simulator command (default: perl). SynSim looks for the words B<INPUTFILE> and <OUTPUTFILE> and substitutes them with the actual file names.

Examples:

        yoursim1 -i INPUTFILE -o OUTPUTFILE
        yoursim2 INPUTFILE > OUTPUTFILE

=item DEVTYPE (optional)

The name of the device on which to perform the simulation. If defined, SynSim will look in TEMPLATES/DEVTYPES for a file with TEMPL and DEVTYPE, and prepend this file to the simulation template before parsing. This keyword can take a list of values

=item EXT

Extension of input file (default: .pl)

Some simulators expect a particular extension for the input file. This can be specified with the keyword B<EXT>.

=item GROUP (optional)

This keyword can be used to change the default behaviour of creating nested loops for every parameter.
It takes as argument a list of parameters. The behaviour for grouped parameters is to change at the same time. All parameter lists in the group must have the same number of values. More than one group can be created.

Example:

	# First group: 2 parameters, each 4 values
	GROUP: _PAR_A1,_PAR_A2
	# Second group: 3 parameters, each 3 values
	GROUP: _PAR_B1,_PAR_B2,_PAR_B3
	# SynSim will run 4*3 simulations (default without groups would be 16*27)

	_PAR_A1 = 0;1;2;4
	_PAR_A2 = 3;4;5;6

	_PAR_B1 = -1;1;2
	_PAR_B2 = 3;4;7
	_PAR_B3 = 3;6;15

=item INCLUDE (optional)

If the value of INCLUDE is an exisiting filename, this datafile will be included on the spot.

=item NORMVAR (optional)

The name of the variable to normalise the results with. The results will be divided by the corresponding value of the variable.

=item NRUNS (optional)


=item OUTPUT_FILTER_PATTERN (optional)

A Perl regular expression to filter the output of the simulation (default : .*). Tis is very usefull for very verbose simulators. The results file will only contain the filtered output.

=item PREPROCESSOR (optional)

The name of a function which modifies C<@results> before the actual postprocessing. Very usefull to "streamline" the raw results for postprocessing.

=item TEMPLATE

B<Alternative names:> SIMULATION, SIMTEMPL, SIMTYPE

The name of the template file, with or without extension. By convention, this is the same as the type of simulation to be performed. If no extension is given, SynSIm checks for a B<TEMPLEXT> keyword; if this is not defined, the extenstion defaults to C<.templ>. SynSim will look for the template file in F<TEMPLATES/> and F<TEMPLATES/SIMTYPES/>.

B<Note:> Multiple simulation types

The value of SIMULATION can be a ','-separated list. In this case, SynSim will use the datafile for multiple types of simulations. Every item in the list can be used as a section header, demarkating a section with variables particular to that specific simulation. 

=item TEMPLEXT (optional)

Extension of template files (default: C<.templ>)

=item TITLE

The title of the DOE. This title is used on the plots, but typically it is the first line of the datafile and describes the DOE.

=item XVAR (optional)

B<Alternative name:> SWEEPVAR

The name of the variable to be sweeped. Mandatory if the postprocessing routine is XYPlot. 

The number of times the simulation has to be performed. For statistical work.

=item XCOL (optional)

The column in the output file which contains the X-values.

=item YCOL (optional)

B<Alternative name:> DATACOL

The column in the output file which contains the simulation results (default: 2). Mandatory if using any of the generic postprocessing routines. 

=item XLABEL, YLABEL, LOGSCALE, PLOTSTYLE, XTICS, YTICS, XSTART, XSTOP, YSTART, YSTOP (optional)

Variables to allow more flexibility in the customization of the plots. They are identical to the corresponding (lowercase) C<gnuplot> keywords, see the gnuplot documentation for details. The most commonly used, XLABEL and YLABEL are the X and Y axis labels. LOGSCALE is either X, Y or XY, and results in a logarithmic scale for the chosen axis.

=back

=head2 Expressions

The SynSim datafile has support for expressions, i.e. it is possible to express the value list of a variable in terms of the values of other variables.

Example:

    # average packet length for IP dist 
    _MEANPL = ((_AGGREGATE==0)?2784:9120)
    # average gap width 
    _MEANGW= int(_MEANPL*(1/_LOAD-1)) 
    # average load
    _LOAD = 0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.8;0.9
    # aggregate 
    _AGGREGATE =  0,12000

The variables used in the expressions must be defined in the datafile, although not upfront. Using circular references will not work.
The expression syntax is Perl syntax, so any Perl function can be used. Due to the binding rules, it is necessary to enclose expressions using the ternary operator ?: with brackets (see example).

=head1 RUNNING SYNSIM

The SynSim script must be executed in a subdirectory of the SynSim
directory which contains the TEMPLATES subdir and the datafile (like the Example directory in the distribution). 

The command line is as follows:

	./synsim [-h -D -i -p -P -v -N ] [datafile] [remote hostname]

The C<synsim> script supports following command line options:

	none: defaults to -f synsim.data
	 -D : Create an empty SynSim directory structure in the current directory.
	 -v : 'verbose'. Sends simulator output to STDOUT
	 -i : interactive. Calls gv or ggv to display a plot of the results.
              Implies -p -v.  
	 -p : plot. This enables generation of postscript plots via gnuplot. 
              A postprocessing routine is required to generate the plots.
	 -P : Plot. This option can be used to display plots created with -p.
	 -w : 'warnings'. Show warnings about undefined variables.
	 -N : 'No simulations'. Performs only postprocessing.
	 -h, -? : short help message

If [remote hostname] is provided, SynSim will try to run the simulation on the remote host.

The current implementation requires:

-ssh access to remote host

-scp access to remote host

-rsync server on the local host

-or,alternatively, an NFS mounted home directory

-as such, it will (probably) only work on Linux and similar systems


=head1 POSTPROCESSING

Postprocessing of the simulation results is handled by routines in the C<PostProcessors.pm> module. This module uses the C<PostProcLib.pm> and optionally C<Dictionary.pm> and C<Analysis.pm>.

=head2 Generic Postprocessors

SynSim comes with a number of generic postprocessing routines. 

=over 4

=item XYPlot

Required configuration variables: C<XVAR>

Creates a plot using C<XVAR> as X-axis and all other variables as parameters. This routine is completely generic. 

=item CondXYPlot

Required configuration variables: C<XVAR>,C<CONDVAR> and C<CONDITION>. 

Creates a plot using C<SETVAR> as X-axis; C<XVAR> is checked against the condition C<COND> (or C<CONDITION>). The first value of C<CONDVAR> that meets the condition is plotted. All other variables are parameters. This routine is completely generic. 

=item XYPlotErrorBars

Required configuration variables: C<XVAR>, C<NRUNS>

Optional configuration variables: C<NSIGMAS>

Creates a plot using C<XVAR> as X-axis and all other variables as paramters. Calculates average and 95% confidence intervals for C<NRUNS> simulation runs and plots error flags. This routine is fully generic, the confidence interval (95% by default) can be set with NSIGMAS. See eg/ErrorFlags.data for an example datafile. 

=item Histogram

Required configuration variables: C<NBINS>

Optional configuration variables: C<BINWIDTH>, C<MIN>, C<MAX>

Creates a histogram of the simulation results. This requires the simulator to produce raw data for the histograms in a tabular format. When specifying logscale X or XY for the plot, the histogram bins will be logarithmic. See eg/Histogram.data for an example. 
The number of bins in the histogram must be specified via C<NBINS>. The width of the bins can be set with C<BINWIDTH>, in which case  C<MIN> and C<MAX> will be calculated. When  C<MIN> or C<MAX> are set, C<BINWIDTH> is calculated. It is possible to specify either C<MIN> or C<MAX>, the undefine value will be calculated. 

=back

=head2 Preprocessing the raw results

All of the above routines have hooks for simple functions that modify the C<@results> array. To call these functions, include them in the datafile with the C<PREPROCESSOR> variable. e.g:

  PREPROCESSOR : modify_results

  All functions must be put in the PLUGINS folder or in the PostProcessors.pm module, and the template could be like this:

  sub modify_results {
  foreach my $results_line (@results) {
	  #Do whatever is required
  }
  
  } # End of modify_results

=head1 DICTIONARY

The F<Dictionary.pm> module contains descriptions of the parameters used in the simulation. These descriptions are used by the postprocessing routines to make the simulation results more readable. The dictionary is stored in an associative array called C<make_nice>. The description of the variable is stored in a field called 'title'; Descriptions of values are stored in fields indexed by the values.

Following example illustrates the syntax:

	# Translate the parameter names and values into something meaningful
	%Dictionary::make_nice=(
	
	_BUFTYPE => {
	title=>'Buffer type',
		     0=>'Adjustable',
		     1=>'Fixed-length',
		     2=>'Multi-exit',
		    },
	_YOURVAR1 => {
	title=>'Your description for variable 1',
	},
	
	_YOURVAR2 => {
	title=>'Your description for variable 2',
'val1' => 'First value of _YOURVAR2',
'val3' => 'Second value of _YOURVAR2',
	},

	);

=head1 OUTPUT FILES

SynSim creates a run directory C<{SIMTYPE}->I<[datafile without .data]>. It copies all necessary template files and source files to this directory; all output files are generated in this directory.

SynSim generates following files:

=over 4

=item *

Output files for all simulation runs. 

The names of these files are are C<{SIMTYPE}_C>I<[counter]_[simulation number]>C<.out>

I<counter> is increased with every new combination of variables except for C<XVAR>. 

I<simulation number> is the position of the value in the C<XVAR>- list. 

=item *

Combined output file for all values in a ';'-separated list. 

The names of these files are are C<{SIMTYPE}_C>I<[counter]>C<_.out> 

I<counter> is increased with every new combination of variables in ','-separated lists. 

Only the lines matching C</OUTPUT_FILTER_PATTERN/> (treated as a Perl regular expression) are put in this file.

=item *

Combined output file for all values in a ';'-separated list, with a header detailing all values for all variables. 

The names of these files are are C<{SIMTYPE}_C>I<[counter]>C<.res>, 

I<counter> is increased with every new combination of variables in ','-separated lists.  

Only the lines in the C<.out> files matching C</OUTPUT_FILTER_PATTERN/> (treated as a Perl regular expression) are put in this file.


=item *

Separate input files for every item in a ';'-separated list. 

The names of these files are are C<{SIMTYPE}_>I<[simulation number]>C<.{EXT}>

I<simulation number> is the position of the value in the list. 

These files are overwritten for every combination of variables in ','-separated lists.

=back


=head1 WRITING POSTPROCESSING ROUTINES

In a lot of cases you will want to create your own postprocessing routines. First of all, it is important to understand the SynSim output, so make sure you have read L</"OUTPUT FILES">. Apart from that, there is a very simple API. 

=head2 PostProcLib

=over

=item *
All variables from the datafile are exported in a hash called C<%simdata>

The value list for every variable is a Perl list. This means that you can access the values like this:

        my @importantvars = @{$simdata{_VAR1}}

or

        my $importantvar = $simdata{_VAR1}[0]

The same holds for configuration variables, but in general they only have a single value, so:

        my $x_variable = $simdata{XVAR}

=item *
Easy-typing names

Furthermore, every variable can be accessed using a short name. Instead of

        $simdata{_VAR} 

you can use

        $_var

This is especially handy for configuration variables, e.g.

        $plotstyle

instead of

        $simdata{PLOTSTYLE}

=item *
Current set of values for the DOE

The current set of values for the DOE is available in the hash C<%current_set_vals>. The keys are the variable names, the values the current value for the variable. 

Example: A simple DOE with 2 variables.

        _VAR1=1,2,3
        _VAR2=3,4

This DOE has 6 sets. After the fourth run, the values of the set will be: 

        $current_set_vals{_VAR1}==2
        $current_set_vals{_VAR1}==4

The current set is also available in string format through C<$current_set_str>:

        $current_set_str eq '_VAR1-2-_VAR2-4'

This is useful because this string is part of the name of the  results file.

If the configuration variable C<SETVAR> is defined, there is an additional string C<$current_set_except_setvar_str>, which contains the current set except the C<SETVAR>. This is usefull for conditional postprocessing, see e.g. CondXYPlot in PostProcessors.pm.

=item *
Raw results 

The raw results of the last simulation run are available in the array C<@results>. Every element in this array is identical to the corresponding line in the output file for the given simulation run.

It is also possible to access the results files: C<$results_file_name> contains the filename of the current results file, and C<@all_results_file_names> is a list of all results files so far.

=item *
Deciding when to call the postprocessor.

SynSim allows to call your postprocessing routine after every run. However, postprocessing generally only makes sense at certain points in the execution of the DOE. SynSim provide two variables: C<$last>, which indicates the end of a sweep, C<$verylast> which indicates the end of the DOE.

=back 

In summary, following variables are exported:

			   %simdata		# contains all datafile variables 
                                                #and their values/value lists
			   @results		# memory image of the results file
			   %current_set_vals    # values for the current set 
                           $current_set_str     # same in string format 
			   $current_set_except_setvar_str
			   $results_file_name    
			   @all_results_file_names
			   $last		# indicates end of a sweep
			   $verylast		# indicates end of the DOE

An example of how all this is used:

	sub YourRoutine {
	
	## Define your own variables.
	## As every variable can have a list of values, 
	## $simdata{'_YOURVAR1'} is an array reference.
	
	my $yourvar=${$simdata{'_YOURVAR1'}}[0];
	
	my @sweepvarvals=@{$simdata{$sweepvar}};
	
	## $verylast indicates the end of all simulations
	if(not $verylast) {
	
	## what to do for all simulations
	
	## $last indicates the end of a sweep
	if($last) {
        # Do something at the end of every sweep  
	  } # if last
	} else {
	 ## On the very last run, collect the results into one nice plot
	  &gnuplot_combined($firstplotline,$plotlinetempl);
	}
	
	} #END of YourRoutine()


=head2 Statistical analysis

A module for basic statistical analysis is also available (C<Analysis.pm>). Currently, the module provides 2 routines: 

=over 4

=item calc_statistics():

To calculate average, standard deviation, min. and max. of a set of values.

Arguments:

C<$file>: name of the results file. The routine requires the data to be in whitespace-separated columns.  	

C<$par>: Determines if the data will be differentiated before processing ($par='DIFF') or not (any other value for $par). 
              Differentiation is defined as subtracting the previous value in the 
              array form the current value. A '0' is prepended to the array to avoid 
              an undefined first point.

C<$datacol>: column to use for data

C<$title>: optional, a title for the histogram 

C<$log>: optional, log of values before calculating histogram or not ('LOG' or '')


Use:
	my $file="your_results_file.res";
	my $par='YOURPAR';
	my $datacol=2;
	my %stats=%{&calc_statistics($file,[$par, $datacol])};

	my $avg=$stats{$par}{AVG}; # average
	my $stdev=$stats{$par}{STDEV}; # standard deviation
	my $min=$stats{$par}{MIN}; # min. value in set
	my $max=$stats{$par}{MAX}; # max. value in set

=item build_histograms():

To build histograms. There are 3 extra arguments:

	$nbins: number of bins in the histogram
	$min: force the value of the smallest bin (optional)
	$max: force the value of the largest bin (optional)

use:
	my $par='DATA';
	my %hists=%{&build_histograms("your_results_file.res",
                  [$par,$datacol],$title,$log,$nbins,$min,$max)};

NOTE: Because the extra arguments are last, the $title and $log arguments can not be omitted. If not needed, supply ''.

=back

=head1 EXAMPLES

Here are some examples of how to use SynSim for different types of simulators.

=head2 1. Typical SPICE simulator

Normal use: spice -b circuit.sp > circuit.out

With SynSim:

=over 4

=item 1. Create a template file

Copy circuit.sp to TEMPLATES/SIMTYPE/circuit.templ
Replace all variable values with SynSim variable names.

e.g. a MOS device line in SPICE:

  M1 VD VG VS VB nch w=10u l=10u

becomes

  M1 VD VG VS VB _MODEL w=_WIDTH l=_LENGTH

=item 2. Create a data file (e.g. circuit.data)

  TITLE: MOS drain current vs. length
  SIMTYPE : circuit
  COMMAND : spice -b inputfile > outputfile

  # Required for postprocessing 
  OUTPUT_FILTER_PATTERN : Id # keep only the drain current on the output file
  ANALYSIS_TEMPLATE : SweepVar # default template for simple sweep
  SWEEPVAR : _L # we sweep the length, the other variables are parameters
  DATACOL: 2 # first col is the name 

  _L = 1u,2u,5u,10u,20u,50u
  _W = 10u,100u
  _MODEL = nch

There are more possible keywords, cf. L</"DATAFILE DESCRIPTION">.

=item 3. Now run synsim

  ./synsim -p -i -v -f IDvsL.data

  -p to create plots
  -i means interactive, so the plots are displayed during simulation
  -v for verbose output
  -f because the filename is not the default name

SynSim will run 12 SPICE simulations and produce 1 plot with all results.

=item 4. Results

All results are stored in the run directory, in this case:

  circuit-IDvsL

=back

=head2 2. Simulator with command-line input and fixed output file

Normal use: simplesim -a50 -b100 -c0.7

Output is saved in out.txt.

With SynSim:

=over 4

=item 1. Create a template file

As simplesim does not take an input file, we create a wrapper simplesim.templ in TEMPLATES/SIMTYPE.
This file is actually a template for a simple perl script:

 system("simplesim -a_VAR1 -b_VAR2 -c_VAR3");
 system("cp out.txt $ARGV[0]");

=item 2. Create a data file (e.g. test.data)

  TITLE: simplesim test
  SIMTYPE : simplesim
  COMMAND : perl inputfile outputfile

=item 3. Now run synsim

  ./synsim -f test.data

SynSim will run without any messages and produce no plots.

=item 4. Results

All results are stored in the run directory, in this case:

  simplesim-test

=back

=head2 3. Simulator without input file, configured at compile time 

Normal use: Modify values for #if and #ifdef constants in the header file; then compile and run.

e.g.:

  vi bufsim3.h
  g++ -o bufsim3 bufsim3.cc
  ./bufsim3 > outputfile

With SynSim:

=over 4

=item 1. Put the source code (bufsim3.cc) in SOURCES

=item 2. Create a template file

As bufsim3 does not take an input file, we create a wrapper bufsim3.templ in TEMPLATES/SIMTYPE.
This file is actually a template for a perl script that writes the header file, compiles and runs the code:

  open(HEADER,">bufsim3.h");
  print HEADER <<"ENDH";
  #define NBUFS _NBUFS
  #define NPACKETS _NPACK
  #AGGREGATE _AGGREGATE
  ENDH
  close HEADER;

  system("g++ -o bufsim3 bufsim3.cc");
  system("./bufsim3 $ARGV[0]");

=item 3. Create a datafile (e.g. Aggregate.data)

  TITLE: bufsim3 test (_NBUFS, _NPACK) # will be substituted by the values
  SIMTYPE : bufsim3
  COMMAND : perl inputfile outputfile

=item 4. Run synsim

  ./synsim -w -v -f Aggregate.data

SynSim will run verbose and flag all variables not defined in the datafile.

=item 4. Results

All results are stored in the run directory, in this case:

  bufsim3-Aggregate

=back

=head2 4. Circuit simulator which produces binary files.

Normal use: spectre circuit.scs -raw circuit.raw

With SynSim:

=over 4

=item 1. Create a template file

Copy circuit.scs to TEMPLATES/SIMTYPE/circuit.templ
Replace all variable values with SynSim variable names.

=item 2. Create a data file

The .raw file is a binary file, so it should not be touched. SynSim creates output files with extension .out, and combines these with the headers etc. (cf. L</"OUTPUT FILES">). By keeping the extension .raw, the simulator output files will not be touched. 

In the datafile:

  TITLE: Spectre simulation with SPF output
  EXT: .scs
  COMMAND: spectre inputfile -raw outputfile.raw > outputfile

=item 3. Run synsim

SynSim will process C<outputfile>, but not C<outputfile.raw>.

=item 4. Postprocessing

To access the binary files, you will have to write your own postprocessing routines. Most likely they will rely on an external tool to process the binary data. The files will be found in the run directory, and have names as described in L</"OUTPUT FILES">, with the extra extension .raw.

=back

=head1 WRAPPERS

If the simulator command line does not follow the format required by SynSim, a simple shell or perl wrapper is enough to make SynSim understand it.
The wrapper script must be stored under F<SOURCES/>; it should be written such that all relative paths are correct when it is executed under F<SOURCES/>. That is because SynSim runs in a subdirectory fo the project directory. This means that, if the command line contains relative paths to a subdirectory, these paths must be prepended with '../'.

=head2 1. No is wrapper required if the simulator takes input from a file with an arbitrary name and sends output in any way to a file with an arbitrary name: 

        $ simulator INPUTFILE OUTPUTFILE
        $ simulator --o OUTPUTFILE INPUTFILE 
        $ simulator -i INPUTFILE > OUTPUTFILE
        $ simulator < INPUTFILE > OUTPUTFILE

=head2 2. Simulators with fixed input file name:

Example:

        $ simulator sim.conf > sim.out

Wrapper:

        $ simulator_wrapper.sh INPUTFILE > OUTPUTFILE 

The file C<simulator_wrapper.sh> contains 2 lines:
 
        mv $1 sim.conf
        simulator sim.conf

=head2 3. Simulator with a fixed output file name:

Example:

        $ simulator INPUTFILE

The outputfile is called C<output.txt>.

Wrapper: 

        $ simulator_wrapper.sh INPUTFILE OUTPUTFILE 

The file C<simulator_wrapper.sh> contains 2 lines:
 
        simulator $1
        mv output.txt $2

=head2 4. Simulator takes input file from a subdirectory

Example:

        $ simulator ../Config/INPUTFILE > OUTPUTFILE

The F<Config> directory is in this case at the same level of project directory.

Wrapper: 
        
        $ simulator_wrapper.sh INPUTFILE > OUTPUTFILE 

The file C<simulator_wrapper.sh> contains 2 lines. Note the '../' prepended to the paths:
 
        cp $1 ../../Config
        simulator ../../Config/INPUTFILE

=head2 5. Simulator produces output in a subdirectory

Example:

        $ simulator INPUTFILE OUTPUTFILE 

The C<OUTPUTFILE> is generated in the F<Results> subdirectory.

Wrapper: 

        $ simulator_wrapper.sh INPUTFILE OUTPUTFILE 

The file C<simulator_wrapper.sh> contains 2 lines. Note the '../' prepended to the path:
 
        simulator $1 $2
        cp ../Results/$2 .

=head2 6. Simulator with command-line input and fixed output file

        $ simulator -a50 -b100 -c0.7

Output is saved in out.txt.

In this case, there is no actual wrapper script. We will create a simple shell script simulator.templ in TEMPLATES/. This script will act as the input file.

Wrapper: 

        $ bash INPUTFILE OUTPUTFILE 

We need the explicit call to bash because the INPUTFILE does not have the -x flag set.

The file simulator.templ in TEMPLATES/ contains 2 lines:
        
        simulator -a_VAR1 -b_VAR2 -c_VAR3
        cp out.txt $1

SynSim will create simulator.sh from this template file, and then will call bash to execute this shell script.

=head2 7. Simulator requires multiple input files

Example:

        $ simulator config.in topo.in > out.res

Wrapper: 

        $ perl INPUTFILE OUTPUTFILE 

Again, there is no actual wrapper script. The C<INPUTFILE> template is in this case a perl script which contains itself templates for both input files. The script will create both input files, then run the simulator.

A possible implementation of simulator.templ:

        #!/usr/bin/perl
        #Template for simulator with multiple input files
        my $config_templ=<<"ENDCONF";
        /* This is the config.in template */
        int var1 = _VAR1;

        ...

        ENDCONF

        my $topo_templ=<<"ENDTOPO";
        ;;This is the topo.in template
        var2 = _VAR2

        ...

        ENDTOPO

        open CONF,">config.in";
        print CONF $config_templ;
        close CONF;

        open TOPO, ">topo.in";
        print TOPO $topo_templ;
        close TOPO;

        system("simulator config.in topo.in > $ARGV[0]");
 
        #END of simulator.templ

SynSim will create C<simulator.pl> and then will call C<perl> to run the script

=head1 TO DO

This module is still Alpha, a lot of work remains to be done to make it more user-friendly. The main tasks is to add a GUI. A prototype can be found on my web site, it is already useful but too early to include here. The next version will also make it easier to create your own postprocessing routines.

=head1 AUTHOR

Wim Vanderbauwhede <wim\x40motherearth.org>

=head1 COPYRIGHT

Copyright (c) 2000,2002-2003 Wim Vanderbauwhede. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

gnuplot L<http://www.ucc.ie/gnuplot/gnuplot.html>

=cut
