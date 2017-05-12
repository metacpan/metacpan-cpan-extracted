package Sim::OPT::Sim;
# Copyright (C) 2008-2015 by Gian Luca Brunetti and Politecnico di Milano.
# This is the module Sim::OPT::Sim of Sim::OPT, a program for detailed metadesign managing parametric explorations through the ESP-r building performance simulation platform and performing optimization by block coordinate descent.
# This is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.
 
use v5.14;
# use v5.20;
use Exporter;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Math::Trig;
use Math::Round;
use List::Util qw[ min max reduce shuffle];
use List::MoreUtils qw(uniq);
use List::AllUtils qw(sum);
use Statistics::Basic qw(:all);
use Set::Intersection;
use List::Compare;
use IO::Tee;
use File::Copy qw( move copy );
use Data::Dumper;
#$Data::Dumper::Indent = 0;
#$Data::Dumper::Useqq  = 1;
#$Data::Dumper::Terse  = 1;
use Data::Dump qw(dump);
use feature 'say';
#use feature qw(postderef);
#no warnings qw(experimental::postderef);
#use Sub::Signatures;
#no warnings qw(Sub::Signatures); 
#no strict 'refs';
use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Report;
use Sim::OPT::Descend;
use Sim::OPT::Takechance;
use Sim::OPT::Modish;
use Parallel::ForkManager;
no strict; 
no warnings;
use warnings::unused;
@ISA = qw(Exporter); # our @adamkISA = qw(Exporter);
#%EXPORT_TAGS = ( DEFAULT => [qw( &opt &prepare )]); # our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#@EXPORT   = qw(); # our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( sim ); # our @EXPORT = qw( );

$VERSION = '0.53'; # our $VERSION = '';
$ABSTRACT = 'Sim::OPT::Sim is the module used by Sim::OPT to launch simulations once the models have been built.'; 

#########################################################################################
# HERE FOLLOWS THE CONTENT OF "Sim.pm", Sim::OPT::Sim
##############################################################################

# HERE FOLLOWS THE "sim" FUNCTION, CALLED FROM THE MAIN PROGRAM FILE.
# IT LAUCHES SIMULATIONS AND ALSO RETRIEVES RESULTS. 
# THE TWO OPERATIONS ARE CONTROLLED SEPARATELY 
# FROM THE OPT CONFIGURATION FILE.

#____________________________________________________________________________
# Activate or deactivate the following function calls depending from your needs

sub sim    # This function launch the simulations in ESP-r
{
  my $swap = shift; 
  my %dat = %$swap;
  my @instances = @{ $dat{instances} }; 
  my $countcase = $dat{countcase}; 
  my $countblock = $dat{countblock}; 
  my %datastruc = %{ $dat{datastruc} }; ######
    my @rescontainer = @{ $dat{rescontainer} }; ######
  my %dirfiles = %{ $dat{dirfiles} }; 
    
  $configfile = $main::configfile; 
  @varinumbers = @main::varinumbers; 
  @mediumiters = @main::mediumiters;
  @rootnames = @main::rootnames; 
  %vals = %main::vals; 
  
  $mypath = $main::mypath;  
  $exeonfiles = $main::exeonfiles; 
  $generatechance = $main::generatechance; 
  $file = $main::file;
  $preventsim = $main::preventsim;
  $fileconfig = $main::fileconfig; 
  $outfile = $main::outfile;
  $tofile = $main::tofile;
  $report = $main::report;
  $simnetwork = $main::simnetwork;
  $max_processes = $main::max_processes;
  
  $tee = new IO::Tee(\*STDOUT, ">>$tofile"); # GLOBAL ZZZ
  
  #open( OUTFILE, ">>$outfile" ) or die "Can't open $outfile: $!"; 
  open( TOFILE, ">>$tofile" ) or die "Can't open $tofile: $!"; 
  say $tee "\nNow in Sim::OPT::Sim.\n";
  
  %dowhat = %main::dowhat;

  %simtitles = %main::simtitles; 
  %retrievedata = %main::retrievedata;
  @keepcolumns = @main::keepcolumns;
  @weights = @main::weights;
  @weightsaim = @main::weightsaim;
  @varthemes_report = @main::varthemes_report;
  @varthemes_variations = @vmain::arthemes_variations;
  @varthemes_steps = @main::varthemes_steps;
  @rankdata = @main::rankdata; # CUT ZZZ
  @rankcolumn = @main::rankcolumn;
  %reportdata = %main::reportdata;
  @files_to_filter = @main::files_to_filter;
  @filter_reports = @main::filter_reports;
  @base_columns = @main::base_columns;
  @maketabledata = @main::maketabledata;
  @filter_columns = @main::filter_columns;
  %vals = %main::vals;
  
  my @simcases = @{ $dirfiles{simcases} }; 
  my @simstruct = @{ $dirfiles{simstruct} }; 
  my @morphcases = @{ $dirfiles{morphcases} };
  my @morphstruct = @{ $dirfiles{morphstruct} };
  my @retcases = @{ $dirfiles{retcases} };
  my @retstruct = @{ $dirfiles{retstruct} };
  my @repcases = @{ $dirfiles{repcases} };
  my @repstruct = @{ $dirfiles{repstruct} };
  my @mergecases = @{ $dirfiles{mergecases} };
  my @mergestruct = @{ $dirfiles{mergestruct} };
  my @descendcases = @{ $dirfiles{descendcases} };
  my @descendstruct = @{ $dirfiles{descendstruct} };
  
  my $morphlist = $dirfiles{morphlist}; 
  my $morphblock = $dirfiles{morphblock};
  my %datastruc = %{ $d{datastruc} }; ######
    my @rescontainer = @{ $d{rescontainer} }; ######
  my $simlist = $dirfiles{simlist}; 
  my $simblock = $dirfiles{simblock};
  my $retlist = $dirfiles{retlist};
  my $retblock = $dirfiles{retblock};
  my $replist = $dirfiles{replist};
  my $repblock = $dirfiles{repblock};
  my $descendlist = $dirfiles{descendlist};
  my $descendblock = $dirfiles{descendblock};
  
  my $skipfile = $vals{skipfile}; 
  my $skipsim = $vals{skipsim}; 
  my $skipreport = $vals{skipreport}; 
  
  #my $getpars = shift;
  #eval( $getpars );

  #if ( fileno (MORPHLIST) 

  my @container;
  
  my $countinstance = 0;
  #my $pm = new Parallel::ForkManager( $max_processes ); #Sets up the possibility of opening child processes
  foreach my $instance (@instances)
  {
    #my $pid = $pm->start and next; # Begins the child process
    my %d = %{$instance};
    my $countcase = $d{countcase}; 
    my $countblock = $d{countblock}; 
    my @miditers = @{ $d{miditers} }; 
    my @winneritems = @{ $d{winneritems} }; 
    my $countvar = $d{countvar}; 
    my $countstep = $d{countstep}; 
    my $to = $d{to}; 
    my $origin = $d{origin}; 
    my @uplift = @{ $d{uplift} }; 
    my @backvalues = @{ $d{backvalues} }; 
    my @sweeps = @{ $d{sweeps} }; 
    my @sourcesweeps = @{ $d{sourcesweeps} }; 
    #eval($getparshere);
    
    my $rootname = Sim::OPT::getrootname(\@rootnames, $countcase); 
    my @blockelts = Sim::OPT::getblockelts(\@sweeps, $countcase, $countblock); 
    my @blocks = Sim::OPT::getblocks(\@sweeps, $countcase);  
    my $toitem = Sim::OPT::getitem(\@winneritems, $countcase, $countblock); 
    my $from = Sim::OPT::getline($toitem); 
    my %varnums = Sim::OPT::getcase(\@varinumbers, $countcase); 
    my %mids = Sim::OPT::getcase(\@miditers, $countcase); 
    #eval($getfly);
    
    my $stepsvar = Sim::OPT::getstepsvar($countvar, $countcase, \@varinumbers); 
    my $varnumber = $countvar; 
    
    my @ress;
    my @flfs;
    my $countdir = 0;
    
    #my $prov = $to;
    #my $prov =~ s/$mypath\/$file//;
    #my $prov =~ s/_$//;
    #my $prov =~ s/_-*$//;
    #if ( not ( $to ~~ @{ $simcases[$countcase] } ) )
    #{
    #  push ( @simcases, $to ); say TOFILE "simcases: " . dump(@simcases);
    #  print SIMLIST "$to\n";
    #}
    
    my $numberof_simtools = scalar ( keys %{ $dowhat{simtools} } ); 
    my $simelt = $to;
    
    my $counttool = 1;
    while ( $counttool <= $numberof_simtools )
    {  
      my $skip = $vals{$countvar}{$counttool}{skip}; 
      if ( not ( eval ( $skipsim{$counttool} )))
      {
        my $tooltype = $dowhat{simtools}{$counttool}; 
        
        if ( $tooltype eq "esp-r" )
        {  
          my $launchline;
          unless ( ( "$^O" eq "MSWin32" ) or ( "$^O" eq "MSWin64" ) ) 
          {
            $launchline = "-file $simelt/cfg/$fileconfig -mode script";
          }
          else
          {
            $launchline = "-file $simelt\\cfg\\$fileconfig -mode script";
          }
          
          
          
          
          my $countsim = 0;    
          foreach my $simtitle_ref ( @{ $simtitles{$counttool} } )
          {
            my $date_to_sim = $simtitle_ref->[0]; 
            my $begin = $simtitle_ref->[1]; 
            my $end = $simtitle_ref->[2]; 
            my $before = $simtitle_ref->[3]; 
            my $step = $simtitle_ref->[4]; 
            
            my $resfile = "$simelt-$date_to_sim-$tooltype.res"; 
            my $flfile = "$simelt-$date_to_sim-$tooltype.fl"; 

            #if ( fileno (SIMLIST) )
            #if (not (-e $simlist ) )
            #{
            #  if ( $countblock == 0 )
            #  {
                open( SIMLIST, ">>$simlist") or die( "$!" );
            #  }
            #  else 
            #  {
            #    open( SIMLIST, ">>$simlist") or die;
            #  }
            #}
            
            #if ( fileno (SIMBLOCK) )
            if (not (-e $simblock ) )
            {
              if ( $countblock == 0 )
              {
                open( SIMBLOCK, ">>$simblock"); # or die;
              }
              else 
              {
                open( SIMBLOCK, ">>$simblock"); # or die;
              }
            }
            
            
            
            
            
            
            
            if ( not ( Sim::OPT::checkdone( $to, @rescontainer ) eq "yes" ) )
      {
        push( @rescontainer, $line );
      }
            
            
            
            push ( @{ $simstruct[ $countcase ][ $countblock ][ $countinstance ][$counttool] }, $resfile );
            print SIMBLOCK "$resfile\n";
            
            if  ( ( ( not ( $resfile ~~ @simcases ) ) and ( not ( -e $resfile ) ) ) or ( not ( Sim::OPT::checkdone( $to, @rescontainer ) eq "yes" ) ) )
            {
              push ( @simcases, $resfile );
              print SIMLIST "$resfile\n";
                
              unless ( ( $preventsim eq "y" ) or ( $dowhat{inactivatesim} eq "y" ) )
              {
                if ( $simnetwork eq "y" )
                {
                  say "#Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep for tool $tooltype. Instance $countinstance: writing $resfile and $flfile." ;
                  my $printthis =  
"bps $launchline<<XXX

c
$resfile
$flfile
$begin
$end
$before
$step
s
$simnetwork
Results for $simelt-$dates_to_sim
y
y
-
-
-
-
-
-
-
XXX
  ";
                  if ($exeonfiles eq "y") 
                  {
                    print `$printthis`;
                  }
                  print TOFILE "   
      #Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep. Instance $countinstance.\
      $printthis
      \n";
                  print OUTFILE "TWO, $resfile\n";
                }  
                else #  if ( $simnetwork eq "n" )
                {
                  say "#Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep for tool $tooltype. Instance $countinstance: writing $resfile. " ;
                  my $printthis =
"bps $launchline<<XXX

c
$resfile
$begin
$end
$before
$step
s
$simnetwork
Results for $simelt-$date_to_sim
y
y
-
-
-
-
-
-
-
XXX
";
                  if ($exeonfiles eq "y") 
                  {
                    print `$printthis`;
                  }
                  print TOFILE "  
$printthis
";
                }          
              }    
            }              
            $countsim++;
          }
        }
        elsif ( ( $tooltype eq ( "generic" ) ) or ( $tooltype eq ( "energyplus" ) ) )
        {  # TO DO: POSSIBILITY TO SPECIFY LINE AND ELEMENT OF TEXT SUBSTITUTIONS.
          # THIS PART OF PROCEDURE HAS BEEN THOUGHT FOR ENERGYPLUS, THEN GENERALIZED.
          my $countsim = 0;      
          foreach my $simtitle_ref ( @{ $simtitles{$counttool} } )
          {
            my $date_to_sim = $simtitle_ref->[0]; 
            my $begin = $simtitle_ref->[1]; 
            my $end = $simtitle_ref->[2]; 
            my $before = $simtitle_ref->[3]; 
            my $step = $simtitle_ref->[4]; 
             
            my $epw = $simtitle_ref->[5]; say "\$epw $epw ";
            my $epwfile = $mypath . "/" . $epw; say "\$epwfile $epwfile ";
            my $epdir = $simtitle_ref->[6]; say "\$epdir $epdir ";
            my $epoldfile = $simtitle_ref->[7]; say "\$epoldfile $epoldfile ";
            my $epnewfragment = $simtitle_ref->[8]; say "\$epnewfragment $epnewfragment ";
            my $outputdir = $simtitle_ref->[9]; say "\$outputdir $outputdir ";
            my $modfiletype = $simtitle_ref->[10]; say "\$modfiletype $modfiletype ";
            my $resfiletype = $simtitle_ref->[11]; say "\$resfiletype $resfiletype ";
            my $epoldpath = $to . $epdir . "/" . $epoldfile; say "\$epoldpath $epoldpath ";
            my $tempname = $to;say "\$tempname $tempname "; 
            $tempname =~ s/$mypath\/// ; say "\$epw $epw "; say "\$tempname $tempname ";
            my $epnewfile = $tempname . $epnewfragment . "$epnewfile"; say "\$epw $epnewfile ";
            my $epresroot = $tempname . $epnewfragment ; say "\$epw $epresroot ";
            
            my $epnewpath;
            unless ( ( "$^O" eq "MSWin32" ) or ( "$^O" eq "MSWin64" ) ) 
            { 
              $epnewpath = $to . $epdir . "/" . $epnewfile; 
            }
            else
            { 
              $epnewpath = $to . $epdir . "\\" . $epnewfile; 
            }
            
            my @simdos = @{ $simtitle_ref };
            my @changes = @simdos[ 12..$#simdos ]; 
            if ( $tooltype eq "energyplus" ) # RESTORES DEFAULTS FOR ENERGYPLUS
            {
              unless ( ( "$^O" eq "MSWin32" ) or ( "$^O" eq "MSWin64" ) ) 
              {
                $outputdir = "/Output";
              }
              else
              {
                $outputdir = "\\Output";
              }
              $modfiletype = ".idf";
              unless ( defined( $resfilename ) )
              {
                $resfilename = ".eso";
              }
            }
            
            open ( EPOLDPATH, "$epoldpath" ) or die( "$!" );
            my @sourcecontents = <EPOLDPATH>;
            close EPOLDPATH; 
            
            unless ( -e $epnewpath )
            {
              open ( EPNEWPATH, ">$epnewpath" ) or die( "$!" );
              foreach my $row ( @sourcecontents )
              {
                foreach my $change ( @changes )
                {
                  my $source = $change->[0]; 
                  my $target = $change->[1]; 
                  $row =~ s/$source/$target/ ; 
                }
                print EPNEWPATH $row;

              }  
              close EPNEWPATH;
            }
            
            my $file_eplus = "$to/$file_eplus";  
            
            my $simelt = $mypath . "$outputdir"; 
            
            my $resfile;
            unless ( ( "$^O" eq "MSWin32" ) or ( "$^O" eq "MSWin64" ) ) 
            {
              $resfile = "$simelt/$epresroot$resfiletype"; 
            }
            else
            {
              $resfile = "$simelt\\$epresroot$resfiletype"; 
            }
            
            
            unless ( $dowhat{inactivatesim} eq "y" )
            {
              
              if (not ( -e $simblock ) )
              {
                if ( $countblock == 0 )
                {
                  open( SIMBLOCK, ">>$simblock"); # or die;
                }
                else 
                {
                  open( SIMBLOCK, ">>$simblock"); # or die;
                }
              }
              
              if (not (-e $retblock ) )
              {
                if ( $countblock == 0 )
                {
                  open( RETBLOCK, ">>$retblock"); # or die;
                }
                else 
                {
                  open( RETBLOCK, ">>$retblock"); # or die;
                }
              }
            }
            
            push ( @{ $simstruct[ $countcase ][ $countblock ][ $countinstance ][ $counttool ] }, $resfile );
            push ( @{ $retstruct[ $countcase ][ $countblock ][ $countinstance ][ $counttool ] }, $resfile );
            
            unless ( $dowhat{inactivatesim} eq "y" )
            {
              print SIMBLOCK "$resfile\n";
            }
            
            if ( ( not ( $resfile ~~ @retcases ) ) and ( not ( -e $resfile ) ) )
            {
              push ( @simcases, $resfile );
              push ( @retcases, $resfile );
              
              unless ( $dowhat{inactivatesim} eq "y" )
              {
                print SIMLIST "$resfile\n";
                print RETLIST "$resfile\n";
              }
              
              unless ( ( $preventsim eq "y" ) or ( $dowhat{inactivatesim} eq "y" ) )
              {  
                open ( OLDFILEEPLUS, $epoldpath ) or die( "$!" );
                my @oldlines = <OLDFILEEPLUS>;
                close OLDFILEEPLUS;
                unless ( -e $epnewpath )
                {
                  open ( NEWFILEEPLUS, ">$epnewpath" ) or die( "$!" );
                  foreach my $line ( @oldlines )
                  {
                    foreach my $elt ( @changes )
                    {
                      my $old = $elt->[0];
                      my $new = $elt->[1];
                      $line =~ s/$old/$new/;
                    }
                    print NEWFILEEPLUS $line;
                  }
                  close NEWFILEEPLUS;
                }
                
                my $templaunch;
                unless ( -e $resfile )
                {
                  unless ( $exeonfiles eq "n" )
                    {
                    
                    my $tempf = $epnewpath; 
                    unless ( ( "$^O" eq "MSWin32" ) or ( "$^O" eq "MSWin64" ) ) 
                    {
                      $tempf =~ s/$to$epdir\///;  
                      $templaunch = $mypath . "/" . $tempf; 
                      `cp -f $epnewpath $templaunch`;
                    }
                    else
                    {
                      $tempf =~ s/$to$epdir\\//;  
                      $templaunch = $mypath . "\\" . $tempf; 
                      `xcopy  /e /c /r /y $epnewpath $templaunch`;
                    }
                    `runenergyplus $templaunch $epwfile`;
                    #`rm -f $templaunch`;
                  }
                  unless ( ( "$^O" eq "MSWin32" ) or ( "$^O" eq "MSWin64" ) ) 
                  {
                    print TOFILE "cp -f $epnewpath $templaunch\n";
                  }
                  else
                  {
                    print TOFILE "xcopy  /e /c /r /y $epnewpath $templaunch\n";
                  }
                  print TOFILE "runenergyplus $templaunch $epwfile\n";
                  
                  say "#Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep for tool $tooltype. Instance $countinstance: using $epnewpath (actually $templaunch) to obtain $resfile. " ;                    
                }
              }  
            }
            $countsim++;
          }
        }
      }
      $counttool++;
    }  
    #$pm->finish; # Terminates the child process
    $countinstance++;
  }
  close SIMLIST;
  close SIMBLOCK;
  
  
  return ( \@simcases, \@simstruct );
  close TOFILE;
  close OUTFILE;
}    # END SUB sim;      

# END OF THE CONTENT OF Sim::OPT::Sim
##############################################################################
##############################################################################
      
1;      


__END__

=head1 NAME

Sim::OPT::Sim.

=head1 SYNOPSIS

  use Sim::OPT;
  opt;

=head1 DESCRIPTION

Sim::OPT::Sim is the module used by Sim::OPT to launch the simulations once the models have been built. Sim::OPT::Sim's presently existing functionalities can be used to launch simulations in ESP-r and EnergyPlus. The possibility to call simulation programs other than the cited two may be pursued through modifications of the code dedicated to EnergyPlus (which is actually meant as an example of a generic case). This portion of code may be actually constituted by the single line launching the simulation program through the shell.

=head2 EXPORT

"sim".

=head1 SEE ALSO

Annotated examples can be found packed in the "optw.tar.gz" file in "examples" directory in this distribution. They constitute the available documentation. Additionally, reference to the source code may be made.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2015 by Gian Luca Brunetti and Politecnico di Milano. This is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
