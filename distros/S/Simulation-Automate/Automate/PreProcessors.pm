package Simulation::Automate::PreProcessors;

use vars qw( $VERSION );
$VERSION = "1.0.1";

################################################################################
#                                                                              #
#  Copyright (C) 2003 Wim Vanderbauwhede. All rights reserved.                 #
#  This program is free software; you can redistribute it and/or modify it     #
#  under the same terms as Perl itself.                                        #
#                                                                              #
################################################################################

#=headers

#Module to support SynSim simulation automation tool.
#This module contains all subroutines needed for preprocessing of the raw simulations results before handing them over to the postprocessor.

#$Id$

#=cut

use strict;
use Cwd;
use Carp;
use lib '.','..';

use Simulation::Automate::PostProcLib;

@Simulation::Automate::PreProcessors::ISA = qw(Exporter);
@Simulation::Automate::PreProcessors::EXPORT = qw(
			   &show_results
						 );

##################################################################################

sub None {
}
#==============================================================================
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
my $subref=$Simulation::Automate::PreProcessors::AUTOLOAD;
$subref=~s/.*:://;
print STDERR "
There is no script for the analysis $subref in the PreProcessors.pm module.
This might not be what you intended.
You can add your own subroutine $subref to the PreProcessors.pm module.
";

}
#------------------------------------------------------------------------------
1;
