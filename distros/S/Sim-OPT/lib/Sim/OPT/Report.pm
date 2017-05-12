package Sim::OPT::Report;
# Copyright (C) 2008-2015 by Gian Luca Brunetti and Politecnico di Milano.
# This is the module Sim::OPT::Retrieve of Sim::OPT, a program for detailed metadesign managing parametric explorations through the ESP-r building performance simulation platform and performing optimization by block coordinate descent.
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
use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Sim;
use Sim::OPT::Descend;
use Sim::OPT::Takechance;
use Sim::OPT::Modish;
#use Parallel::ForkManager;
use Data::Dumper;
#$Data::Dumper::Indent = 0;
#$Data::Dumper::Useqq  = 1;
#$Data::Dumper::Terse  = 1;
use Data::Dump qw(dump);
use feature 'say';
no strict; 
no warnings;
use warnings::unused;
@ISA = qw(Exporter); # our @adamkISA = qw(Exporter);
#%EXPORT_TAGS = ( DEFAULT => [qw( &opt &prepare )]); # our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#@EXPORT   = qw(); # our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( retrieve report get_files );

$VERSION = '0.53.3'; # our $VERSION = '';
$ABSTRACT = 'Sim::OPT::Report is the module used by Sim::OPT to retrieve simulation results.';

#########################################################################################
# HERE FOLLOWS THE CONTENT OF "Retrieve.pm", Sim::OPT::Retrieve
##############################################################################


sub retrieve
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
  
  say $tee "\n#Now in Sim::OPT::Report_retrieve.\n";
  
  %dowhat = %main::dowhat;
  
  #my $evalfiletemp = $dowhat{evalfile};
  #my $evalfile;
  #unless ( ( "$^O" eq "MSWin32" ) or ( "$^O" eq "MSWin64" ) ) 
  #{
  #  $evalfile = $mypath . "/" . $evalfiletemp;
  #}
  #else
  #{
  #  $evalfile = $mypath . "\\" . $evalfiletemp;
  #}
  
  #
  #if ( -e $evalfile )
  #{
  #  say $tee "NOW EVALING $evalfile";
  #  say $tee `cat $evalfile`;
  #  eval { `cat $evalfile` };
  #}
        
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
  my %notecases;
  
  #my $getpars = shift;
  #eval( $getpars );

  #if ( fileno (MORPHLIST)
  
  my $countinstance = 0;
  foreach my $instance (@instances)
  {
    my %d = %{$instance};
    my $countcase = $d{countcase}; say $tee "dump(\$countcase): " . dump($countcase);
    my $countblock = $d{countblock}; say $tee "dump(\@countblock): " . dump(@countblock);
    my %datastruc = %{ $d{datastruc} }; say $tee "dump(\@sweeps): " . dump(@sweeps);######
    my @rescontainer = @{ $d{rescontainer} }; say $tee "dump(\%rescontainer): " . dump(%rescontainer);######
    my @miditers = @{ $d{miditers} }; say $tee "dump(\@miditers): " . dump(@miditers);
    my @winneritems = @{ $d{winneritems} }; say $tee  "dumpIN( \@winneritems) " . dump(@winneritems);
    my $countvar = $d{countvar}; say $tee "dump(\$countvar): " . dump(@countvar );
    my $countstep = $d{countstep}; say $tee "dump(\$countstep): " . dump($countstep);
    my $to = $d{to}; say $tee "dump(\$to): " . dump($to);
    my $origin = $d{origin}; say $tee "dump(\$origin): " . dump($origin);
    my @uplift = @{ $d{uplift} }; say $tee "dump(\@uplift): " . dump(@uplift);
    my @backvalues = @{ $d{backvalues} }; say $tee "IN RETRIEVE \@backvalues " . dump(@backvalues);
    my @sweeps = @{ $d{sweeps} }; say $tee "dump(\@sweeps): " . dump(@sweeps);
    my @sourcesweeps = @{ $d{sourcesweeps} }; say $tee "dump(\@sourcesweeps): " . dump(@sourcesweeps);
    
    #eval($getparshere);
    
    my $skip = $vals{$countvar}{skip}; 
    
    my $rootname = Sim::OPT::getrootname(\@rootnames, $countcase); say $tee "dump(\$rootname): " . dump($rootname);
    my $numberof_simtools = scalar ( keys %{ $dowhat{simtools} } ); say $tee "dump(\$numberof_simtools ): " . dump($numberof_simtools );
    
    my $counttool = 1;
    while ( $counttool <= $numberof_simtools ) 
    {  
      my $skip = $vals{$countvar}{$counttool}{skip}; say $tee "dump(\$skip): " . dump($skip);
      if ( not ( eval ( $skipsim{$counttool} )))
      {
        my $tooltype = $dowhat{simtools}{$counttool}; say $tee "dump(\$tooltype ): " . dump($tooltype );

        sub retrieve_temperatures_results 
        {
          my ( $result, $resfile, $retrdata_ref, $reporttitle, $themereport, $counttheme, $countreport, $retfile ) = @_;
          
          
          
          
          
          
          
          
          
          

          unless ( ( ( not ( $resfile ~~ @simcases ) ) or (-e "$retfile") ) or ( not ( Sim::OPT::checkdone( $to, @rescontainer ) eq "yes" ) ) )
          {
            my $printthis = 
"res -file $resfile -mode script<<YYY

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
a
a
b
a
b
e
b
f
>
a
$retfile
!
-
-
-
-
-
-
-
-
YYY
";
            if ($exeonfiles eq "y")
            {   
              say $tee "#Retrieving temperature results.";
              print `$printthis`;
            }
            print $tee "
      #Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n
      $printthis";

          }
        }

        sub retrieve_comfort_results
        {
          my ( $result, $resfile, $retrdata_ref, $reporttitle, $stripcheck, $themereport, $counttheme, $countreport, $retfile ) = @_;
          
          my @retrdata = @$retrdata_ref;

          unless (-e "$retfile")
          {
            my $printthis =
"res -file $resfile -mode script<<ZZZ

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
c
a

b


a
>
a
$retfile
!
-
-
-
-
-
-
-
-
ZZZ
";
            if ($exeonfiles eq "y") 
            { 
              say $tee "Retrieving comfort results.";
              print `$printthis`;
            }
            print TOFILE "
    #Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n
    $printthis";
          }
        }

        sub retrieve_stats_results
        {  
          my ( $result, $resfile, $retrdata_ref, $reporttitle, $themereport, $counttheme, $countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines ) = @_;
          
          
          my @retrdata = @$retrdata_ref; 
          my $printthis;
          
          if ( $themereport eq "loads" )
          {
            unless (-e "$retfile")
            {
              $printthis =
"res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
d
>
a
$retfile
$retfile
l
a
-
-
-
-
-
TTT
";
            }
          }
          elsif ( $themereport eq "tempsstats" )
          {
            unless (-e "$retfile")
            {
              $printthis =
"res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
d
>
a
$retfile
$retfile
m
-
-
-
-
TTT
";
            }
          }
          if ($exeonfiles eq "y") 
          {
            
            say $tee "#Retrieving $themereport results.";
            print `$printthis`;
          }
          print $tee " 
    #Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n
    $printthis
    ";

        }
        
        sub retrieve_adhoc
        {  
          my ( $result, $resfile, $retrdata_ref, $reporttitle, $themereport, $counttheme, $countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines ) = @_;
          #my ( $result, $resfile, $retrdata_ref, $reporttitle, $themereport, $counttheme, $countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines, $adhoclines ) = @_;
          
          
          my @retrdata = @$retrdata_ref; 
          #my $insert = eval { $adhoclines }; say $tee "\$insert: $insert";
          my $printthis;
          unless (-e "$retfile")
          {
            if ( $themereport eq "radent" )
            {
              $printthis =
"res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
d
a
>
a
$retfile
$retfile

!
-
-
-
-
-
TTT
";
      
              print $tee " 
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n
$printthis
";
          
              if ($exeonfiles eq "y") 
              {
                
                say $tee "#Retrieving $themereport results.";
                print `$printthis`;
              }
            }
            elsif ( $themereport eq "radabs" )
            {
              $printthis =
"res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
d
c
>
a
$retfile
$retfile

!
-
-
-
-
-
TTT
";
      
            print $tee " 
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n
$printthis
";
          
              if ($exeonfiles eq "y") 
              {
                
                say $tee "#Retrieving $themereport results.";
                print `$printthis`;
              }
            }
            elsif ( $themereport eq "airtemp" )
            {
              $printthis =
"res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
b
e
>
a
$retfile
$retfile

!
-
-
-
-
-
TTT
";
      
            print $tee " 
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n
$printthis
";
          
              if ($exeonfiles eq "y") 
              {
                
                say $tee "#Retrieving $themereport results.";
                print `$printthis`;
              }
            }
            elsif ( $themereport eq "radtemp" )
            {
              $printthis =
"res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
b
e
>
a
$retfile
$retfile

!
-
-
-
-
-
TTT
";
      
            print $tee " 
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n
$printthis
";
          
              if ($exeonfiles eq "y") 
              {
                
                say $tee "#Retrieving $themereport results.";
                print `$printthis`;
              }
            }
            elsif ( $themereport eq "restemp" )
            {
              $printthis =
"res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
b
e
>
a
$retfile
$retfile

!
-
-
-
-
-
TTT
";
      
            print $tee " 
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n
$printthis
";
          
              if ($exeonfiles eq "y") 
              {
                
                say $tee "#Retrieving $themereport results.";
                print `$printthis`;
              }
            }
          }
        }
        
        
        my @resfiles = @{ $simstruct[$countcase][$countblock][$countinstance][$counttool] }; 
        
        
        
        
        
        if ( $retrievedata{$counttool} )
        {
          if ( $tooltype eq "esp-r" )
          {
            my $counttheme = 0;
            
            foreach my $retrievedatum ( @{ $retrievedata{$counttool} } )
            {  
              
              my $reportdata_ref_ref = $reportdata{$counttool}->[$counttheme]; 
              my @retrievedatarefs = @{$retrievedatum}; 
              my $simtitle = $simtitles{$counttool}->[ $counttheme ][0]; 
              my @sims = @{ $simtitles{$counttool}->[ $counttheme ] }[1..4]; 
              
              my $resfile = $resfiles[ 0 ]; 
              
              #if ( not ( eval ( $skipreport ) ) )
              if ( -e $resfile ) 
              {
                
                my $countreport = 0;
                foreach my $retrievedataref (@retrievedatarefs)
                {
                  
                  my @retrdata = @$retrievedataref; 
                  my $sim = $sims[$countreport]; 
                  my $targetprov = $sim;
                  $targetprov =~ s/$mypath\///;
                  my $result = "$mypath" . "/$targetprov"; 
                  
                  #if ( fileno (RETLIST) )
                  #if (not (-e $retlist ) )
                  #{
                  #  if ( $countblock == 0 )
                  #  {
                      open( RETLIST, ">>$retlist"); # or die;
                  #  }
                  #  else 
                  #  {
                  #    open( RETLIST, ">>$retlist"); # or die;
                  #  }
                  #}
                  
                  #if ( fileno (RETLIST) ) # SAME LEVEL OF RETLIST. JUST ANOTHER CONTAINER.
                  #if (not (-e $retblock ) )
                  #{
                  #  if ( $countblock == 0 )
                  #  {
                      open( RETBLOCK, ">>$retblock"); # or die;
                  #  }
                  #  else 
                  #  {
                  #    open( RETBLOCK, ">>$retblock"); # or die;
                  #  }
                  #}
                  
                  my $reportdata_ref = $reportdata_ref_ref->[$countreport]; 
                  my @reportdata = @$reportdata_ref;  
                  
                  my $countitem = 0;
                  foreach my $item ( @reportdata )
                  {
                    
                    
                    my %datarep = %$item; 
                    my $reporttitle = $datarep{reporttitle}; 
                    my $themereport = $datarep{themereport}; 
                    my $semaphorego1 = $datarep{semaphorego1}; 
                    my $semaphorego2 = $datarep{semaphorego2}; 
                    my $semaphorestop1 = $datarep{semaphorestop1}; 
                    my $semaphorestop2 = $datarep{semaphorestop2}; 
                    my $textpattern = $datarep{textpattern}; 
                    my $afterlines = $datarep{afterlines}; 
                    #my $adhoclines = $datarep{adhoclines}; say $tee "\$adhoclines " . dump($adhoclines); 
                    my $retfile = "$resfile-$reporttitle-$themereport.grt"; 
                    
                    $retstruct[$countcase][$countblock][ $countinstance ][$counttheme][$countreport][$countitem][$counttool] = $retfile;
                    print RETBLOCK "$retfile\n";
                    
                    if ( not ($retfile ~~ @retcases ) )
                    {
                      push ( @retcases, $retfile );
                      say RETLIST "$retfile";
                    }
                    
                    if ( not ( $retfile ~~ @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } ) )
                    {
                      
                      push ( @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } , 
                                        {
                                          retfile => $retfile,
                                          reporttitle => $reporttitle,
                                          themereport => $themereport,
                                          semaphorego1 => $semaphorego1,
                                          semaphorego2 => $semaphorego2,
                                          semaphorestop1 => $semaphorestop1,
                                          semaphorestop2 => $semaphorestop2,
                                          textpattern => $textpattern,
                                          afterlines => $afterlines,
                                          #adhoclines => $adhoclines,
                                        } );
                    }
                    
                    unless ( ( $dowhat{inactivateres} eq "y" ) or ( -e $retfile ) )
                    {
                      say "#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep for tool $tooltype. Instance $countinstance: going to write $retfile.\ ";
                        
                      if ( $themereport eq "temps" ) 
                      {
                         retrieve_temperatures_results( $result, $resfile, \@retrdata, $reporttitle, $themereport, $counttheme, $countreport, $retfile ); 
                      }
                      elsif ( $themereport eq "comfort"  ) 
                      { 
                        retrieve_comfort_results( $result, $resfile, \@retrdata, $reporttitle, $themereport, $counttheme, $countreport, $retfile ); 
                      }
                      elsif ( ( ( $themereport eq "loads" ) or ( $themereport eq "tempsstats"  ) ) )
                      { 
                        retrieve_stats_results( $result, $resfile, \@retrdata, $reporttitle, $themereport, $counttheme, 
                              $countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines ); 
                      }
                      elsif ( ( $themereport eq "radent" ) or ( $themereport eq "radabs" ) or ( $themereport eq "airtemp" ) or ( $themereport eq "radtemp" ) or ( $themereport eq "restemp" ) )
                      { 
                        
                        retrieve_adhoc( $result, $resfile, \@retrdata, $reporttitle, $themereport, $counttheme, 
                              $countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines ); 
                              #$countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines, $adhoclines ); 
                      }
                    }
                    $countitem++;
                  }
                  $countreport++;
                }
              }
              $counttheme++;
            }
            $counttool++;
          }
          elsif ( ( $tooltype eq "generic" ) or ( $tooltype eq "energyplus" ) )
          {  #use warnings; use strict;
            
            my @retfiles = @{ $simstruct[$countcase][$countblock][$countinstance][$counttool] }; 
            $retstruct[$countcase][$countblock][$countinstance][$counttool]  = $simstruct[$countcase][$countblock][$countinstance][$counttool] ; 
            my $counttheme = 0;
            foreach my $retrievedatum ( @{ $retrievedata{$counttool} } )
            {
              my $reportdata_ref_ref__ = $reportdata{$counttool}; 
              my @retrievedatarefs = @{$retrievedatum}; 
              my $simtitle = $simtitles{$counttool}->[ $counttheme ][0]; 
              my @sims = @{ $simtitles{$counttool}->[ $counttheme ] }[1..4]; 
              
              my $resfile = $resfiles[ $counttheme ]; 
              
              
              my $countpart = 0;
              foreach ( @$reportdata_ref_ref__ )
              {
                $reportdata_ref_ref = $reportdata{$counttool}->[$countpart];
              
              
              
                if ( -e $resfile ) 
                {
                  

                  my @retrdata = @$retrievedataref; 
          
                  open( RETLIST, ">>$retlist"); # or die;
                  open( RETBLOCK, ">>$retblock"); # or die;
                                          
                  my $reportdata_ref = $reportdata_ref_ref->[$countreport]; 
                  my @reportdata = @$reportdata_ref;  
                  @retcases = uniq( @retcases );
                  my $retfile = "$resfile"; 
                  if ( not ($retfile ~~ @retcases ) )
                  {
                    push ( @retcases, $retfile );
                    say RETLIST "$retfile";
                  }
                  my @provbag;
                  
                  push ( @provbag, $retfile );
                    
                  my $countitem = 0;
                  foreach my $item ( @reportdata )
                  {
                    my %datarep = %$item; 
                    my $reporttitle = $datarep{reporttitle}; 
                    my $themereport = $datarep{themereport}; 
                    my $semaphorego1 = $datarep{semaphorego1}; 
                    my $semaphorego2 = $datarep{semaphorego2}; 
                    my $semaphorestop1 = $datarep{semaphorestop1}; 
                    my $semaphorestop2 = $datarep{semaphorestop2}; 
                    my $textpattern = $datarep{textpattern}; 
                    my $afterlines = $datarep{afterlines}; 
                    
                    
                    print RETBLOCK "$retfile\n";
    
                    
                    #if ( not ( $retfile ~~ @provbag ) ) 
                    #{
                      
                      push ( @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } , 
                                        {
                                          retfile => $retfile,
                                          reporttitle => $reporttitle,
                                          themereport => $themereport,
                                          semaphorego1 => $semaphorego1,
                                          semaphorego2 => $semaphorego2,
                                          semaphorestop1 => $semaphorestop1,
                                          semaphorestop2 => $semaphorestop2,
                                          textpattern => $textpattern,
                                          afterlines => $afterlines
                                        } );
                    #}
                    $countitem++;
                  }


                }
                else  
                { 
                  say "A RESULT FILE NAMED $resfile DOES NOT EXIST. EXITING.";
                }
                
              
              
                $countpart++;
              }
              
              
              
              $counttheme++;
            }
            $counttool++;
          }
        }  
      }
    }
    $countinstance++;
  }
  
  print `rm -f $mypath/*.par`;
  print TOFILE "rm -f $mypath/*.par\n";
  close OUTFILE;
  close TOFILE;
  close RETLIST;
  close RETBLOCK;
  
  
  say $tee "\@notecases " . dump( @notecases ); 
  return ( \@retcases, \@retstruct, \@notecases );
}  # END SUB RETRIEVE


sub report # This function retrieves the results of interest from the texts files created by the "retrieve" function
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
  
  $tee = new IO::Tee(\*STDOUT, ">>$tofile"); # GLOBAL ZZZ
  
  #open( OUTFILE, ">>$outfile" ) or die "Can't open $outfile: $!"; 
  open( TOFILE, ">>$tofile" ) or die "Can't open $tofile: $!";  
  say $tee "\nNow in Sim::OPT::Report::report.\n";
  
  
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
  %notecases = %main::notecases;
  
  my @simcases = @{ $dirfiles{simcases} }; 
  my @simstruct = @{ $dirfiles{simstruct} }; 
  my @INREPORT = @{ $dirfiles{morphcases} };
  my @morphstruct = @{ $dirfiles{morphstruct} };
  my @retcases = @{ $dirfiles{retcases} }; 
  my @retstruct = @{ $dirfiles{retstruct} }; 
  my @repcases = @{ $dirfiles{repcases} };
  my @repstruct = @{ $dirfiles{repstruct} };
  my @mergecases = @{ $dirfiles{mergecases} };
  my @mergestruct = @{ $dirfiles{mergestruct} };
  my @descendcases = @{ $dirfiles{descendcases} };
  my @descendstruct = @{ $dirfiles{descendstruct} };
  my @notecases = @{ $dirfiles{notecases} }; 
  
  my $morphlist = $dirfiles{morphlist}; 
  my $morphblock = $dirfiles{morphblock};
  my $simlist = $dirfiles{simlist}; 
  my $simblock = $dirfiles{simblock};
  my $retlist = $dirfiles{retlist}; 
  my $retblock = $dirfiles{retblock};
  my $replist = $dirfiles{replist};
  my $repblock = $dirfiles{repblock};
  my $descendlist = $dirfiles{descendlist};
  my $descendblock = $dirfiles{descendblock};
  
  my @repfilemem;
  my @linecontent;
  $" = " ";
  my $repfile;
  #my @convey;
  my $countinstance = 0;
  foreach my $instance ( @instances )
  {
    
    my %d = %{$instance};
    my $countcase = $d{countcase}; 
    my $countblock = $d{countblock}; 
    my %datastruc = %{ $d{datastruc} }; ######
       my @rescontainer = @{ $d{rescontainer} }; ######
    my @miditers = @{ $d{miditers} }; 
    my @winneritems = @{ $d{winneritems} }; 
    my $countvar = $d{countvar}; 
    my $countstep = $d{countstep}; 
    my $to = $d{to}; 
    my $origin = $d{origin}; 
    my @uplift = @{ $d{uplift} }; 
    my $rootname = Sim::OPT::getrootname(\@rootnames, $countcase); 
    my @blockelts = Sim::OPT::getblockelts(\@sweeps, $countcase, $countblock); 
    my @blocks = Sim::OPT::getblocks(\@sweeps, $countcase);  
    my $toitem = Sim::OPT::getitem(\@winneritems, $countcase, $countblock); 
    my $from = Sim::OPT::getline($toitem); 
    my %varnums = Sim::OPT::getcase(\@varinumbers, $countcase); 
    my %mids = Sim::OPT::getcase(\@miditers, $countcase); 
    my @backvalues = @{ $d{backvalues} }; say $tee "IN REPORT \@backvalues " . dump(@backvalues);
    my @sweeps = @{ $d{sweeps} }; say $tee "dump(\@sweeps): " . dump(@sweeps);
    my @sourcesweeps = @{ $d{sourcesweeps} }; say $tee "dump(\@sourcesweeps): " . dump(@sourcesweeps);
    
    my $stepsvar = Sim::OPT::getstepsvar($countvar, $countcase, \@varinumbers); 
    my $varnumber = $countvar; 

    say $tee "#Processing reports for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", instance " . ($countinstance + 1);
    
    open( REPLIST, ">>$replist" ) or die( "$!" ); 
    open( REPBLOCK, ">>$repblock" ) or die( "$!" ); 
    
    unless ( ( "$^O" eq "MSWin32" ) or ( "$^O" eq "MSWin64" ) ) 
    {
      $repfile = "$mypath/$file-report-$countcase-$countblock.txt";  
    }
    else
    {
      $repfile = "$mypath\\$file-report-$countcase-$countblock.txt";  
    }
    
    open( REPFILE, ">>$repfile") or die "Can't open $repfile $!";
    @repcases = uniq( @repcases );
    
    say REPBLOCK "$repfile";
    if ( not ( $repfile ~~ @repcases ) )
    {
      push ( @repcases, $repfile );
      say REPLIST "$repfile";
    }
    
    if ( not ( $repfile ~~ @{ $repstruct[$countcase][$countblock] } ) )
    {
      push ( @{ $repstruct[$countcase][$countblock] }, $repfile );
    }
    my $signalnewinstance = 1;
    
    #open( REPFILE, ">>$repfile") or die "Can't open $repfile $!";
    
    
    
    my $numberof_simtools = scalar ( keys %{ $dowhat{simtools} } ); 
    #my @mergestruct;
    my $counttool = 1;
    while ( $counttool <= $numberof_simtools )
    {  
      #uniq( @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } );
      my $skip = $vals{$countvar}{$counttool}{skip}; 
      if ( not ( eval ( $skipsim{$counttool} )))
      {
        my $tooltype = $dowhat{simtools}{$counttool}; 
        #@{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } = uniq( @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] }  );
        
        
        #foreach $ret_ref ( sort { $a->{retfile} <=> $b->{retfile} } ( @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } ) )
        foreach $ret_ref ( ( @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } ) )
        {
          
          
          %retitem = %$ret_ref; 
          my $retfile = $retitem{retfile}; 
          my $reporttitle = $retitem{reporttitle}; 
          my $themereport = $retitem{themereport}; 
          my $semaphorego1 = $retitem{semaphorego1}; 
          my $semaphorego2 = $retitem{semaphorego2}; 
          my $semaphorestop1 = $retitem{semaphorestop1}; 
          my $semaphorestop2 = $retitem{semaphorestop2}; 
          my $textpattern = $retitem{textpattern}; 
          my $afterlines = $retitem{afterlines}; 
          #my $adhoclines = $retitem{adhoclines}; 
          
          if ( $signalnewinstance == 1 )
          {
            push ( @{ $mergestruct[$countcase][$countblock][$countinstance] }, "$retfile " );
            $signalnewinstance--;
          }
          
          my ( $semaphore1, $semaphore2 );
          
          if ( -e $retfile ) #if ( not ( eval ( $skipreport ) ) )
          {  say $tee "#Inspecting results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", instance " . ($countinstance + 1) . ", file $retfile, to report $themereport." ;
            open( RETFILE, "$retfile" ) or die( "$!" );
            my @lines = <RETFILE>;
            close RETFILE;
            
            my $countline = 0;
            my $signalhit = 0;
            my $foundhit = 0;
            my $countlin = 0;
            my $countli = 0;
            foreach my $line ( @lines )
            {
              $line =~ s/^\s+//;
              chomp( $line ); 
              #$line = $line . " ";
              
              
              if ( ( not ( defined( $semaphorego1 ) ) ) or ( $semaphorego1 eq "" ) or ( $line =~ m/$semaphorego1/ ) )
              {
                $semaphore1 = "on";  
              }
              
              if ( $semaphore1 eq "on" )
              {
                if ( ( not ( defined( $semaphorego2 ) ) ) or ( $semaphorego2 eq "" ) or ( $line =~ m/$semaphorego2/ ) )
                {
                  $semaphore2 = "on"; 
                }
              }
                            
              if ( ( $line =~ m/$semaphorestop1/ ) and ( defined( $semaphorestop1 ) ) and ( $semaphorestop1 ne "" ) )
              {
                $semaphore1 = "off"; 
              }
              
              if ( ( $line =~ m/$semaphorestop2/ ) and ( defined( $semaphorestop2 ) ) and ( $semaphorestop2 ne "" ) )
              {
                $semaphore2 = "off"; 
              }
              
              $line =~ s/  / / ;
		  	      $line =~ s/  / / ;
		  	      $line =~ s/  / / ;
		  	      $line =~ s/  / / ;
		  	      $line =~ s/  / / ;
  			      $line =~ s/ /,/ ;
              chomp( $line ); chomp( $line ); 
              #$line = $line . " ";
              
              if ( ( not ( defined ( $afterlines ) ) ) or ( $afterlines eq "" ) )
              {
                
                if ( ( $textpattern ne "" ) and ( $line =~ m/^$textpattern/ ) and ( $semaphore1 eq "on" ) and ( $semaphore2 eq "on" ) )
                {  
                  chomp( $line ); chomp( $line ); 
                  if ( $foundhit == 0 )
                  {  
                    push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, "$themereport,$line" );
                  }
                  else
                  {
                    push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, $line );
                  }
                  $foundhit++;
                }
              }
              else
              {
                
                if ( ( $textpattern ne "" ) and ( $line =~ m/^$textpattern/ ) and ( $semaphore1 eq "on" ) and ( $semaphore2 eq "on" ) )
                {  
                  $signalhit++;
                }
                
                if ( ( $semaphore1 eq "on" ) and ( $semaphore2 eq "on" ) and ( $signalhit > 0 ) )
                {
                  
                  if ( not ( ref( $afterlines ) ) )
                  {  
                    if ( ( $afterlines ne "" ) and ( $countline == ( $afterlines - 1) ) )
                    {  
                      chomp( $line );
                      push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, "$themereport,$line" );
                      $countli++;
                    }
                  }
                  else
                  {  
                    my @afterlins = @$afterlines;  
                    my @bringer;
                    foreach my $afterlin ( @afterlins )
                    {  
                      if ( not ( $afterlin =~ /-/ ) )
                      {
                         $afterlin =~ s/  / / ;
                         $afterlin =~ s/  / / ;
                         $afterlin =~ s/  / / ;
                         $afterlin =~ s/  / / ;
                         $afterlin =~ s/  / / ;
                         $afterlin =~ s/ /,/ ;
                        push ( @bringer, $afterlin );
                      }
                      else
                      {
                        
                        my ( $count, $endel ) = split( /-/, $afterlin );
                        while ( $count <= $endel )
                        {
                          push ( @bringer, $count );
                          $count++;
                        }
                      }
                      
                      my $countlocal = 0;
                      foreach my $afterl ( @bringer )
                      {
                        
                        if ( $countline == ( $afterl - 1 ) )
                        {
                          chomp( $line );
                          if ( $countlocal == 0 )
                          {
                            push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, "$themereport,$line" );
                          }
                          else
                          {
                            push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, $line );
                          }
                        }
                        $counlin++;
                        $countlocal++;
                      }
                    }
                  }
                }
              }
              $countline++; 
            }
          }
          else 
          { 
            open ( NOTFOUND, ">>./notfound.txt" ) or die $! ;
            say NOTFOUND $retfile;
            
          }
        }
      }
      $counttool++;
    }
    
    
    
    unless ( $dowhat{inactivateret} eq "y" )
    {
      
      foreach my $thing ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] } )
      {
        $thing =~ s/\n/ /g ; $thing =~ s/\n/ /g ; $thing =~ s/\r/ /g ; $thing =~ s/\r/ /g ;
        $thing =~ s/\r\n/ /g; $thing =~ s/\r\n/ /g;
        $thing =~ s/  / / ;
        $thing =~ s/  / / ;
        $thing =~ s/  / / ;
        $thing =~ s/  / / ;
        $thing =~ s/  / / ;
        $thing =~ s/  / / ;
        $thing =~ s/ ,/,/ ;
        $thing =~ s/, /,/ ;
        $thing =~ s/ /,/ ;
        print REPFILE $thing;
        print REPFILE ",";
      }
      print REPFILE "\n";
    
    #my $lin;
    #foreach my $thing ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] } )
    #{
    #  $thing =~ s/\n/ /g ; 
    #  $lin = $lin . $thing . " ";
    #}
    #push ( @{ $convey[ $countcase ][ $counblock ] }, $lin );
      say "#Reporting results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep. Instance $countinstance: writing $repfile. ";
    }
    $countinstance++;
  }
  
  #if ( @repfilemem ~~ @mergecases ) 
  #{ 
  #  push ( @mergecases,  @repfilemem );
  #}
  
  
  #foreach ( sort ( @{ $convey[ $countcase ][ $counblock ] } ) )
  #{
    

    print REPFILE "$_\n"; 
  #}
  close REPFILE;

  my $repstore = $repfile . ".csv";
  
  open ( REPFILE, "$repfile" ) or die "$!";
  my @lins = <REPFILE>;
  close  REPFILE;

  open( REPSTORE, ">$repstore" ) or die "$!";
  foreach my $lin ( @lins )
  {
  	$lin =~ s/  / / ;
    $lin =~ s/  / / ;
    $lin =~ s/  / / ;
    $lin =~ s/  / / ;
    $lin =~ s/  / / ;
    $lin =~ s/  / / ;
    $lin =~ s/ ,/,/ ;
    $lin =~ s/, /,/ ;
    $lin =~ s/ /,/ ;
    print REPSTORE "$lin";
  }

  close REPSTORE;

  say $tee "HEREIS \@repcases " . dump(@repcases); say $tee "\@repstruct " . dump(@repstruct); 
  
  close TOFILE;
  close OUTFILE;
  return ( \@repcases, \@repstruct, \@mergestruct, \@mergecases, $repfile ); 
} # END SUB report;

sub get_files # UNUSED. LEGACY. CUT.
{
  say $tee "Extracting statistics for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", instance: " . ( $countinstance + 1);
  my ( $themereport, $countcase, $countblock, $counttheme, $countreport, $retfile, $repfile, 
    $simtitle, $reporttitle, $simdatum, $retrievsref, $countinstance, $swap, $loadsortemps ) = @_;
    
    
  my @repfilemem = @$swap; 
  my @retrievs = @$retrievsref;
  
  my @measurements_to_report = $retrievs[0]; 
  my $dates_to_report = $simtitle; 
  
  
  open( RETFILE,  "$retfile" ) or die "Can't open $retfile $!";
  my @lines_to_inspect = <RETFILE>; 

  my @countcolumns;
  my $countzones = 0;
  my $countlines = 0;
  foreach my $line_to_inspect (@lines_to_inspect) 
  {
    if ( $line_to_inspect )
    {
      
      $line_to_inspect =~ s/^\s+//g;### DO THIS? ZZZ
      $line_to_inspect =~ s/\s*$//;      #remove trailing whitespace
      #$line_to_inspect =~ s/\ {2,}/ /g;  #remove multiple literal spaces
      $line_to_inspect =~ s/\t{2,}/\t/g; 
      
      if ( $themereport eq "temps" ) # NEVER CHECKED IF IT STILL WORKS AFTER SOME USES
      {
        my @roww = split( /\s+/, $line_to_inspect );
        if ( $countlines == 1 )
        {
          $file_and_period = $roww[5];
        } 
        elsif ( $countlines == 3 )
        {
          my $countcolumn = 0;
          foreach $elt_of_row (@roww)
          {    #
            foreach $column (@columns_to_report)
            {
              if ( $elt_of_row eq $column )
              {
                push @countcolumns, $countcolumn;
                if ( $elt_of_row eq $columns_to_report[0] )
                {
                  $title_of_column = "$elt_of_row";
                } else
                {
                  $title_of_column =  "$elt_of_row-" . "$file_and_period";
                }
                push ( @{ $repfilemem[$countinstance] }, "$title_of_column\t" );
              }
            }
            $countcolumn = $countcolumn + 1;
          }
          #push ( @{ $repfilemem[$countlines] }, "\n" );
        } 
        elsif ( $countlines > 3 )
        {
          foreach $columnumber (@countcolumns)
          {
            if ( $columnumber =~ /\d/ )
            {
              push ( @{ $repfilemem[$countinstance] }, "$roww[$columnumber]\t" );
            }
          }
          #push ( @{ $repfilemem[$countlines] }, "\n" );
        }
        $countlines++;
      }
      
      if ( $themereport eq "comfort" ) # NEVER CHECKED IF IT STILL WORKS AFTER SOME USES
      {        
        my @roww = split( /\s+/, $line_to_inspect );

        if ( $countlines == 1 )
        {
          $file_and_period = $roww[5];
        } 
        elsif ( $countlines == 3 )
        {
          my $countcolumn = 0;
          foreach $elt_of_row (@roww)
          {    #
            foreach $column (@columns_to_report)
            {
              if ( $elt_of_row eq $column )
              {
                push @countcolumns, $countcolumn;
                if ( $elt_of_row eq $columns_to_report[0] )
                {
                  $title_of_column = "$elt_of_row";
                } 
                else
                {
                  $title_of_column =
                    "$elt_of_row-" . "$file_and_period";
                }
                push ( @{ $repfilemem[$countinstance] }, "$title_of_column\t" );
              }
            }
            $countcolumn = $countcolumn + 1;
          }
          #push ( @{ $repfilemem[$countlines] }, "\n" );
        } 
        elsif ( $countlines > 3 )
        {
          foreach $columnumber (@countcolumns)
          {
            if ( $columnumber =~ /\d/ )
            {
              push ( @{ $repfilemem[$countinstance] }, "$roww[$columnumber]\t" );
            }
          }
          #push ( @{ $repfilemem[$countlines] }, "\n" );
        }
        $countlines++;
      }
      
      my $line_to_report;
      
      if ( ( $themereport eq "loads" ) or ( $themereport eq "tempsstats" ) ) 
      {  
        if ( $line_to_inspect =~ /^$loadsortemps/ )
        {
          $line_to_report = "$retfile " . " $themereport $reporttitle " . $line_to_inspect . " " ;
          $line_to_report =~ s/--//g;
          $line_to_report =~ s/\s+/ /g;  #remove multiple literal spaces
          $line_to_report =~ s/ /,/g;  #remove multiple literal spaces
          push ( @{ $repfilemem[$countinstance] }, $line_to_report );
        }
        $countlines++;
      }
    }
  }
  
  return (@repfilemem); 
} # END SUB get_files

1;

__END__

=head1 NAME

Sim::OPT::Report.

=head1 SYNOPSIS

  use Sim::OPT;
  opt;

=head1 DESCRIPTION

Sim::OPT::Report is the module used by Sim::OPT to retrieve simulation results. Sim::OPT::Report performs two kinds of action. The first, which is required only by certain simulation programs, is that of making the simulation program write the results in a user-specified text format. This functionality is platform-specific and is presently implemented only for ESP-r (EnergyPlus does not require that). The second functionality is that of gathering the results in a user-specified manner. That functionality is based on pattern-matching and is not simulation-program-specific.

=head2 EXPORT

"retrieve" "report".

=head1 SEE ALSO

Annotated examples can be found packed in the "optw.tar.gz" file in "examples" directory in this distribution. They constitute the available documentation. Additionally, reference to the source code may be made.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2015 by Gian Luca Brunetti and Politecnico di Milano. This is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
