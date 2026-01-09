package Sim::OPT::Sim;
# This is the module Sim::OPT::Sim of Sim::OPT, distributed under a dual licence, open-source (GPL v3) and proprietary.
# Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


use Exporter;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Math::Trig;
use Math::Round;
use List::Util qw[ min max reduce shuffle];
use List::MoreUtils qw(uniq);
use List::AllUtils qw(sum);
use Sim::OPT::Stats qw(:all);
use Set::Intersection;
use List::Compare;
use File::Copy qw( move copy );
use Data::Dumper;
#$Data::Dumper::Indent = 0;
#$Data::Dumper::Useqq  = 1;
#$Data::Dumper::Terse  = 1;
use Data::Dump qw(dump);
use feature 'say';
use Switch::Back;

use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Report;
use Sim::OPT::Descend;
use Sim::OPT::Takechance;
use Sim::OPT::Interlinear;
use Sim::OPT::Stats;
eval { use Sim::OPTcue; 1 };
eval { use Sim::OPTcue::Patternsearch; 1 };

no strict;
no warnings;
use warnings::unused;
@ISA = qw( Exporter ); # our @adamkISA = qw(Exporter);
#%EXPORT_TAGS = ( DEFAULT => [qw( &opt &prepare )]); # our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#@EXPORT   = qw(); # our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( sim ); # our @EXPORT = qw( );

$VERSION = '0.103'; # our $VERSION = '';
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


sub sim
{
  my %vals = %main::vals;
  my $mypath = $main::mypath;
  my $exeonfiles = $main::exeonfiles;
  my $generatechance = $main::generatechance;
  my $file = $main::file;
  my $preventsim = $main::preventsim;
  my $fileconfig = $main::fileconfig;
  my $outfile = $main::outfile;
  my $tofile = $main::tofile;
  my $report = $main::report;
  my $simnetwork = $main::simnetwork;
  my $max_processes = $main::max_processes;

  my %simtitles = %main::simtitles;
  my %retrievedata = %main::retrievedata;
  my @keepcolumns = @main::keepcolumns;
  my @weighttransforms = @main::weighttransforms;
  my @weights = @main::weights;
  my @weightsaim = @main::weightsaim;
  my @varthemes_report = @main::varthemes_report;
  my @varthemes_variations = @vmain::arthemes_variations;
  my @varthemes_steps = @main::varthemes_steps;
  my @rankdata = @main::rankdata; # CUT
  my @rankcolumn = @main::rankcolumn;
  my %reportdata = %main::reportdata;
  my @files_to_filter = @main::files_to_filter;
  my @filter_reports = @main::filter_reports;
  my @base_columns = @main::base_columns;
  my @maketabledata = @main::maketabledata;
  my @filter_columns = @main::filter_columns;

  my %dat = %{ $_[0] };
  my @instances = @{ $dat{instances} };
  my %dirfiles = %{ $dat{dirfiles} };
  my %dowhat = %{ $dat{dowhat} };
  my %vehicles = %{ $dat{vehicles} };
  my $precious = $dat{precious};
  my %inst = %{ $dat{inst} };
  my @precedents = @{ $dat{precedents} };
  my $postproc = $dat{postproc};
  my $pierce = $dat{pierce};
  my $last = $dat{last};
  my @bomb = @{ $dat{bomb} };
  my $postlast = $dat{postlast};
  my $winningvalue;
  my ( @pocket );

  #my $retlist = $dirfiles{retlist};####!!!
  #my $retblock = $dirfiles{retblock};
  #my $simlist = $dirfiles{simlist};
  #my $simblock = $dirfiles{simblock};


	if ( $tofile eq "" )
	{
		$tofile = "./report.txt";
	}

  say  "\nNow in Sim::OPT::Sim.\n";

 #say  "RECEIVED DATA IN SIM: " . dump( @_ );

  
  my %d = %{ $instances[0] };

  my $countcase = $d{countcase};
  my $countblock = $d{countblock};
  my %incumbents = %{ $d{incumbents} }; ######
  my @varnumbers = @{ $d{varnumbers} };
  my @miditers = @{ $d{miditers} };
  my @sweeps = @{ $d{sweeps} };
  my $from = $d{from};
  my @blockelts = @{ $d{blockelts} }; #say  "HERE IN SIM \@blockelts: " . dump( @blockelts );
  my %varnums = %{ $d{varnums} };
  my $repfile;


  #if ( $countcase > $#sweeps )# NUMBER OF CASES OF THE CURRENT PROBLEM
  #{
  #  if ( $dirfiles{checksensitivity} eq "y" )
  #  {
  #    Sim::OPT::sense( $dirfiles{ordtot}, $mypath, $sense{objectivecolumn} );
  #  }
  #  exit(say  "0 #END RUN.");
  #}

  my $skipfile = $vals{skipfile};
	my $skipsim = $vals{skipsim};
	my $skipreport = $vals{skipreport};

  my @pocket;

  my @trieds; #say  "HERE IN SIM \@precedents: " . dump( \@precedents );
  foreach $prec_r ( @precedents )
  {
    my %prec = %{ $prec_r };
    my %to = %{ $prec{to} };
    push ( @trieds, $to{cleanto} );
  } #say  "HERE IN SIM \@trieds: " . dump( \@trieds );

  my @allinstances = @instances ;
  push( @allinstances, @precedents );

  @allinstances = Sim::OPT::cleanbag( @allinstances );

  #my $csim = 0;
  my @container;
  say  "\$pierce $pierce \$postlast $postlast ";
  unless ( ( $pierce eq "y" ) and ( $postlast eq "y" ) )
  {

    foreach my $instance ( @allinstances )
    {
      my %dt = %{$instance}; #say  "HERE IN SIM \%dt: " . dump( \%dt );
      my @winneritems = @{ $dt{winneritems} }; #say  "HERE IN SIM \@winneritems: " . dump( @winneritems );
      my $countvar = $dt{countvar}; #say  "HERE IN SIM \$countvar: " . dump( $countvar );
      my $countstep = $dt{countstep}; #say  "HERE IN SIM \$countstep: " . dump( $countstep );
      my $c = $dt{c}; #say  "HERE IN SIM \$c: " . dump( $c );

  		my %to = %{ $dt{to} }; #say  "HERE IN SIM \%to: " . dump( \%to );
      my $instn = $dt{instn}; #say  "HERE IN SIM \$instn: " . dump( $instn );

      my $origin = $dt{origin};
      
      my $to = $dt{to};
      my $from = $dt{from};
      my $is = $dt{is};
      my $stamp = $dt{stamp};

      my @blockelts = @{ $dt{blockelts} }; #say  "HERE IN SIM \@blockelts: " . dump( @blockelts );
      my @blocks = @{ $dt{blocks} }; #say  "HERE IN SIM \@blocks: " . dump( @blocks );
      my %varnums = %{ $dt{varnums} }; #say  "HERE IN SIM \%varnums: " . dump( \%varnums );
      my %mids = %{ $dt{mids} }; #say  "HERE IN SIM \%mids: " . dump( \%mids );
      my $countinstance = $instn; #say  "HERE IN SIM \$countinstance: " . dump( $countinstance );

      my $fire = $dt{fire};
      my $gaproc = $dt{gaproc};

      if ( !$dirfiles{repfile} )
      {
        $dirfiles{repfile} = "$mypath/$file-report-$countcase-$countblock.csv";
      }
      $repfile = $dirfiles{repfile}; say  "IN SIM FROM DIRFILES, \$countblock $countblock, \$repfile $repfile";

      if ( ( $fire eq "y" ) and ( $precious ne "" ) )
      {
        $repfile = $repfile . "-fire-$is.csv";###DDD!!!
      }

      my $skip = $dowhat{$countvar}{skip}; #########################################
      my ( $resfile, $flfile );

      my $varnumber = $countvar;
      my $stepsvar = $varnums{$countvar};

      my @ress;
      my @flfs;
      my $countdir = 0;

      my $numberof_simtools = scalar ( keys %{ $dowhat{simtools} } );
      my $simelt = $to{crypto}; #say  "SIMELT: $simelt";
      my $shortsimelt = $simelt;
      $shortsimelt =~ s/$mypath\///;
      my ( $shortresfile, $shortflfile );

      #if ( ( $dowhat{simulate} eq "y")
      #  and ( ( ( not ( $to{cleanto} ~~ ( @trieds ) ) ) or ( not ( $precious eq "" ) ) )
      #    or ( ( $gaproc eq "y" ) and ( $fire eq "y" ) ) ) )

      {
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
              if ( ( -e "../tmp/*.res" ) or ( -e "../tmp/*.fl" ) or ( -e "../tmp/*.mfr" ) )
              {
                $launchline = "rm ../tmp/*.res \n rm ../tmp/*.fl \n rm ../tmp/*.mfr \n cd $simelt/tmp/ \n bps -file $fileconfig -mode script";
              }
              else
              {
                $launchline = "cd $simelt/cfg/ \n bps -file $fileconfig -mode script";
              }

              my $countsim = 0;
              foreach my $simtitle_ref ( @{ $simtitles{$counttool} } )
              {
                my $date_to_sim = $simtitle_ref->[0];
                my $begin = $simtitle_ref->[1];
                my $end = $simtitle_ref->[2];
                my $before = $simtitle_ref->[3];
                my $step = $simtitle_ref->[4];

                if ( ( $simelt ne "") and ( $date_to_sim ne "" ) )
                {
                  my $fileconfigroot = $fileconfig;
                  $fileconfigroot =~ s/\.cfg//;
                  $resfile = "$simelt/tmp/$fileconfigroot.res";
                  $flfile = "$simelt/tmp/$fileconfigroot.fl";
                  $shortresfile = "$fileconfigroot.res";
                  $shortflfile = "$fileconfigroot.fl";
                }

                #open( SIMLIST, ">$simlist") or die( "$!" );

                #if (not (-e $simblock ) )
                #{
                #  if ( $countblock == 0 )
                #  {
                #    open( SIMBLOCK, ">$simblock"); # or die;
                #  }
                #  else
                #  {
                #    open( SIMBLOCK, ">$simblock"); # or die;
                #  }
                #}

                if ( !@{ $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool} } )
                {
                  @{ $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool} } = ();
                }
                push ( @{ $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool} }, $resfile );
                print SIMBLOCK "$resfile\n";

                if ( ( not ( $resfile ~~ @{ $dirfiles{simcases} } ) ) and ( not ( -e $resfile ) ) and ( $dowhat{simulate} eq "y")
                  and ( not ( $to{cleanto} ~~ ( @trieds ) ) ) )
                {
                  push ( @{ $dirfiles{simcases} } , $resfile );
                  #print SIMLIST "$resfile\n";

                  unless ( ( $preventsim eq "y" ) or ( $dowhat{inactivatesim} eq "y" ) or ( $dowhat{simulate} eq "n" ) or ( $postproc eq "y") )
                  {

                    say  "IN SIM, FOR INSOLATION \$countvar $countvar \$blockelts->[-1] $blockelts->[-1] \$blockelts[-1] $blockelts[-1] \@blockelts " . dump ( @blockelts );
                    say  "IN SIM, FOR INSOLATION  \$countstep $countstep \$varnums{\$countvar} $varnums{$countvar} "; 
                    say  "IN SIM, FOR INSOLATION  \$countop $countop \$#applytype $#applytype \@applytype ";
                    say  "IN SIM, FOR INSOLATION  \$dowhat{shadeupdate} $dowhat{shadeupdate}";
                    if ( $dowhat{shadeupdate} eq "y" )
                    {
                      my $done = Sim::OPT::Morph::recalculateish( $is, $stepsvar, $countop, 
                          $countstep, \@applytype, $recalculateish, $countvar, $fileconfig, $mypath, $file, $countmorphing, $newlaunchline, 
                          \@menus, $countinstance, \%dowhat );
                    }

                    if ( $simnetwork eq "y" )
                    {
                      say  "#Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep for tool $tooltype. Instance $countinstance: writing $resfile and $flfile." ;
                      say  "#Simulating \$simelt $simelt";
                      my $printthis;
                      if ( $step > 1 )
                      {                    
                        $printthis =
"$launchline<<XXX

c
$shortresfile
$shortflfile
$begin
$end
$before
$step
y
s
$simnetwork
Res! $simelt
y
y
-
-
-
-
-
XXX
  ";
                        }
                        else
                        {
  $printthis =
"$launchline<<XXX

c
$shortresfile
$shortflfile
$begin
$end
$before
$step
s
y
Res! $simelt
y
y
-
-
-
-
-
XXX
  ";                        
                        }

                      say  "#Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep. Instance $countinstance.\ $printthis";
                      say  "#Simulating \$simelt $simelt";
                      if ($exeonfiles eq "y")
                      {
                        say  `$printthis`;
                        #say  "$printthis";
                      }
                      print OUTFILE "TWO, $resfile\n";
                    }
                    else #  if ( $simnetwork eq "n" )
                    {
                      say  "#Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep for tool $tooltype. Instance $countinstance: writing $resfile. " ;
                      say  "#Simulating \$simelt $simelt";
                      my $printthis =
"$launchline<<XXX

c
$shortresfile
$begin
$end
$before
$step
y
s
$simnetwork
Res! $simelt
y
y
-
-
-
-
-
XXX
";

                      ####print  "$printthis";
                      if ($exeonfiles eq "y")
                      {
                        say  `$printthis`;
                        #say  "$printthis";
                      }
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

                my $epw = $simtitle_ref->[5];
                my $epwfile = $mypath . "/" . $epw;
                my $epdir = $simtitle_ref->[6];
                my $epoldfile = $simtitle_ref->[7];
                my $epnewfragment = $simtitle_ref->[8];
                my $outputdir = $simtitle_ref->[9];
                my $modfiletype = $simtitle_ref->[10];
                my $resfiletype = $simtitle_ref->[11];
                my $to = $to{crypto}; ### TAKE CARE!!!
                my $epoldpath = $to . $epdir . "/" . $epoldfile;
                my $tempname = $to;
                $tempname =~ s/$mypath\///;
                my $epnewfile = $tempname . $epnewfragment . "$epnewfile";
                my $epresroot = $tempname . $epnewfragment ;

                my $epnewpath;
                $resfile;

                $epnewpath = $to . $epdir . "/" . $epnewfile;

                my @simdos = @{ $simtitle_ref };
                my @changes = @simdos[ 12..$#simdos ];
                if ( $tooltype eq "energyplus" ) # RESTORES DEFAULTS FOR ENERGYPLUS
                {
                  $outputdir = "/Output";
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


                $resfile = "$simelt/$epresroot$resfiletype";


                #unless ( $dowhat{inactivatesim} eq "y" )
                #{

                  #if (not ( -e $simblock ) )
                  #{
                    #if ( $countblock == 0 )
                    #{
                     # open( SIMBLOCK, ">$simblock"); # or die;
                    #}
                    #else
                    #{
                    #  open( SIMBLOCK, ">$simblock"); # or die;
                    #}
                  #}

                  #if (not (-e $retblock ) )
                  #{
                   # if ( $countblock == 0 )
                  #  {
                   #   open( RETBLOCK, ">$retblock"); # or die;
                   # }
                   # else
                  #  {
                  #    open( RETBLOCK, ">$retblock"); # or die;
                  #  }
                 # }
                #}
                
                if ( !@{ $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool} } )
                {
                  @{ $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool} } = ();
                }
                push ( @{ $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool} }, $resfile );

                #unless ( $dowhat{inactivatesim} eq "y" )
                #{
                #  print SIMBLOCK "$resfile\n";
                #}

                if ( ( not ( $resfile ~~ @{ $dirfiles{retcases} } ) ) and ( not ( -e $resfile ) ) )
                {
                  push ( @{ $dirfiles{simcases} } , $resfile );

                  unless ( $dowhat{inactivatesim} eq "y" )
                  {
                    #print SIMLIST "$resfile\n";
                    #print RETLIST "$resfile\n";
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
                        $tempf =~ s/$to$epdir\///;
                        $templaunch = $mypath . "/" . $tempf;
                        `cp -f $epnewpath $templaunch`;
                        `runenergyplus $templaunch $epwfile`;
                        #`rm -f $templaunch`;
                      }

                      ####print  "cp -f $epnewpath $templaunch\n";
                      ####print  "runenergyplus $templaunch $epwfile\n";

                      say  "#Simulating case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep for tool $tooltype. Instance $countinstance: using $epnewpath (actually $templaunch) to obtain $resfile. " ;
                    }
                  }
                }


                $countsim++;
              }
            }
          }
          $counttool++;
        }
      }

      if ( $dowhat{newretrieve} eq "y" )
      {
        unless ( ( $postproc eq "y") )
        {
          my ( $dirfiles_r ) = Sim::OPT::Report::newretrieve(
          {
            instance => $instance, dirfiles => \%dirfiles,
            resfile => $resfile, flfile => $flfile,
            vehicles => \%vehicles, precious => $precious, inst => \%inst,
            dowhat => \%dowhat
          } );
          %dirfiles = %$dirfiles_r;
        }
      }
      
      my $dirfiles_r;
      if ( $dowhat{newreport} eq "y" )
      {
        ( $dirfiles_r, $instant ) = Sim::OPT::Report::newreport(
        {
          instance => $instance, dirfiles => \%dirfiles,
          resfile => $resfile, flfile => $flfile,
          vehicles => \%vehicles, precious => $precious, inst => \%inst,
          dowhat => \%dowhat,  csim => $csim,
          stamp => $stamp
        } );
        
        %dirfiles = %$dirfiles_r;
        push( @pocket, $instant );
      }

      #if ( $dowhat{newreport} eq "y" )
      #{ say  "DOING 3";
      #  $winningvalue = Sim::OPT::Report::newreport(
      #  {
      #    instance => $instance, dirfiles => \%dirfiles,
      #    resfile => $resfile, flfile => $flfile,
      #    vehicles => \%vehicles, precious => $precious, inst => \%inst,
      #    csim => $csim, dowhat => \%dowhat,
      #    stamp => $stamp,
      #  } );
      #}

      $csim++;
    }
    #close SIMLIST;
    #close SIMBLOCK;
  }
  else 
  {
    if ( !$dirfiles{repfile} )
    {
      $dirfiles{repfile} = "$mypath/$file-report-$countcase-$countblock.csv";
    }
    $repfile = $dirfiles{repfile}; say  "IN SIM FROM DIRFILES, \$countblock $countblock, \$repfile $repfile";
  }


  ########################################################################################################################

  my @newbowl; 
  my $expected_r;

  if ( not ( $pierce eq "y" ) )
  {
    $expected_r = Sim::OPT::enumerate( \%varnums, \@blockelts, $from ); say  "IN POSTSIM \@blockelts " . dump( @blockelts ) . " \$expected_r " . dump( $expected_r );
    #say  "IN POSTSIM  \$from $from  \$expected_r  " . dump( $expected_r ) . " \%varnums " . dump( \%varnums ) . "\@blockelts " . dump( @blockelts );


### @pocket = uniiq( @pocket );
    @{ $dirfiles{repsblocks}{$countcase}{$countblock} } = uniq( @{ $dirfiles{repsblocks}{$countcase}{$countblock} } );
    #say  "IN DESCEND \@{ \$dirfiles{repsblocks}{\$countcase}{\$countblock} }: " . dump( @{ $dirfiles{repsblocks}{$countcase}{$countblock} } );
  
### foreach my $ln ( @pocket )
    foreach my $ln ( @{ $dirfiles{repsblocks}{$countcase}{$countblock} } )
    {
      chomp $ln;
      next if $ln =~ /^\s*$/;

      my $rid = Sim::OPT::instid( $ln, $file ); #say  "IN POSTSIM \$file $file \$ln $ln \$countblock $countblock \$rid " . dump( $rid );# NOT $repfile
      if ( defined($rid) and $rid ne "" )
      {
        push( @newbowl , $ln );
        #$dirfiles{reps}{$rid} = $ln; say  "IN POSTSIM WRITING \$dirfiles{reps}{\$rid} \$dirfiles{reps}{$rid} " . dump( $dirfiles{reps}{$rid} );# NOT $repfile
        $present{$rid} = 1; #say  "IN POSTSIM \$countblock $countblock \$present{\$rid} \$present{$rid} " . dump( $present{$rid} );# NOT $repfile
        #say  "IN POSTSIM CHECKING: \$rid $rid \$dirfiles{reps}{\$rid}: " . dump( $dirfiles{reps}{$rid} );
      }
    }
    

    my %present;
    foreach my $rid ( @{ $expected_r } )
    {
      next if $present{$rid};

      if ( exists $dirfiles{reps}{$rid} )
      {
        push( @newbowl, $dirfiles{reps}{$rid} );
        say  "IN POSTSIM EXISTS \$countblock $countblock \$dirfiles{reps}{\$rid} \$dirfiles{reps}{$rid} " . dump( $dirfiles{reps}{$rid} );# NOT $repfile
      }
    }
  }
  
  
  if ( ( $pierce eq "y" ) and ( not ( $postlast eq "y" ) ) )
  {
    push ( @newbowl, $instant );
  }


  my @newgo;

  if ( ( not ( $pierce eq "y" ) ) or ( ( $pierce eq "y" ) and ( $postlast ne "y" ) ) )
  {
    @newgo = @newbowl; say  "IN POSTSIM \@newgo " . dump( @newgo );
  }
  elsif ( ( $pierce eq "y" ) and ( $postlast eq "y" ) )
  {
    @newgo = @bomb; say  "IN POSTSIM \@newgo " . dump( @newgo );
  }


  if ( ( not ( $pierce eq "y" ) ) or ( ( $pierce eq "y" ) and ( $postlast eq "y" ) ) )
  {
    @newgo = uniq( @newgo );
    if ( $dowhat{dumpfiles} eq "y" )
    {
      my $repline = $repfile;
      $repline =~ s/\.csv?/-incharge\.csv/;
      open( REPFILE, ">$repline" ) or die;
      foreach my $line ( @newgo )
      {
        say REPFILE $line;
      }
      close REPFILE;
    }
  }



  my @selectbag;

  if ( $dowhat{precomputed} eq "" )
  { 
    foreach my $line ( @newgo )
    {
      my $lin;
      if ( ( $line ne "" ) and ( $line ne " " ) and ( $line ne "\n" ) )
      {
        chomp $line;
        $line =~ s/\n/°/g;
        $line =~ s/°/\n/g;
        $line =~ s/[()%]//g;
        $line =~ s/,?//;
        $line =~ s/,?//;
        $line =~ s/,?//;
        $line =~ s/ ?//;
        $line =~ s/ ?//;

        my @elts = split(/,/, $line); 
        my $touse = $elts[0];

        $touse = Sim::OPT::clean( $touse, $mypath, $file );

        if ( ( ( $dowhat{names} eq "short" ) or ( $dowhat{names} eq "medium" ) ) and ( $touse =~ /^\d+$/ ) )
        {
          my $clear = $inst_r->{$touse};

          if ( ( !defined($clear) ) or ( $clear eq "" ) )
          {
            my $k = "$mypath/$file" . "_" . $touse;
            $clear = $inst_r->{$k};
          }


          if ( ( !defined($clear) ) or ( $clear eq "" ) )
          {
            die "Cannot map crypto id '$touse' to clear instance (names=short)";
          }
          $touse = $clear;
        }

        my ( @elements, @names, @obtaineds, @newnames ); #say  "\@keepcolumns: " . dump( @keepcolumns );
        foreach my $elm_ref (@keepcolumns)
        {
          my @cols = @{ $elm_ref };
          my $name = $cols[0];
          my $number = $cols[1];
          push ( @elements, $elts[$number] ); #say  "\PUSH \$elts[\$number]: " . dump( $elts[$number] );
          #say  "\$elts: $elts, \$number: $number";
          push ( @names, $name );
        } #say  "ELEMENTS: ". dump( @elements ); say  "NAMES: ". dump( @names );

        if ( not ( scalar( @weighttransforms ) == 0 ) )
        {
          my $coun = 0;
          foreach my $elt_ref ( @weighttransforms )
          {
            my @els = @{ $elt_ref };
            my $newname = $els[0];
            my $transform = $els[1];
            my $obtained = eval ( $transform ); #say  "HERE \$transform: $transform, \$obtained: $obtained";
            push ( @obtaineds, $obtained );
            push ( @newnames, $newname );
            $coun++;
          }
        }
        else
        {
          @obtaineds = @elements;
          @newnames = @names;
        }
        #say  "ELEMENTS: ". dump( @elements ); #say  "\@obtaineds: ". dump( @obtaineds );
        #say  "NAMES: ". dump( @names ); #say  "NEWNAMES: ". dump( @newnames );

        if ( !defined( $dirfiles{countnettotrowlength}  ) ) #THIS SWITCHES OFF AFTER THE FIRST PASS
        {
          $dirfiles{totrowlength} = ( scalar( @obtaineds ) * 2 );
          $dirfiles{countnettotrowlength}++; #THIS CALCULATES THE LENGTH OF THE ROW AND STORES IT
        }
        
        say  "IN SIM \$dowhat{discard} $dowhat{discard}";
        unless ( $obtaineds[-1] eq $dowhat{discard} )
        {
          $lin =  "$touse,";

          my $coun = 0; #say  "PRINTNG OBTAINEDS: " . dump ( @obtaineds ) ;
          foreach my $elt ( @obtaineds )
          {
            $lin = $lin . "$newnames[$coun],";
            unless ( $coun == $#obtaineds )
            {
              $lin = $lin . "$elt,";
            }
            else 
            {
              $lin = $lin . "$elt";
            }
            $coun++;
          }
          push( @selectbag, $lin );
        }
      }
    }
  }
  say  "IN POSTSIM \@selectbag " . dump( @selectbag );
  

  my @weightbag;

  my ( $max, $min );

  if ( $dowhat{precomputed} eq "" )
  {
    my $counterline = 0;
    my ( @containerone, @containernames, @containertitles, @containertwo, @containerthree, @maxes, @mins, @absmaxes );
    foreach my $line ( @selectbag) 
    {
      chomp $line;
      my @elts = split( ",", $line );
      my $touse = shift( @elts ); # IT CHOPS AWAY THE FIRST ELEMENT DESTRUCTIVELY
      my $countel = 0;
      my $countcol = 0;
      my $countcn = 0;
      foreach my $elt ( @elts )
      {
        if ( Sim::OPT::Descend::odd( $countel ) )
        {
          push ( @{ $containerone[ $countcol ] }, $elt );
          $countcol++;
        }
        else
        {
          push ( @{ $containernames[$countcn] }, $elt );
          $countcn++;
        }
        $countel++;
      }
      push ( @containertitles, $touse );
    }


    my $countcolm = 0;
    foreach my $colref ( @containerone )
    {
      my @column = @{ $colref }; # DEREFERENCE
    
      if ( max( @column ) != 0) # FILLS THE UNTRACTABLE VALUES
      {
        push ( @maxes, max( @column ) );
      }
      else
      {
        push ( @maxes, "" );
      }
    
      push ( @mins, min( @column ) );
    
      foreach my $el ( @column )
      {
        if ( abs( $maxes[ $countcolm ] ) >= abs( $mins[$countcolm] ) )
        {
          $absmaxes[ $countcolm ] = abs( $maxes[ $countcolm ] );
        }
        else 
        {
          $absmaxes[ $countcolm ] = abs( $mins[ $countcolm ] );
        }

        my $eltrans;
        if ( $absmaxes[ $countcolm ] != 0 )
        {
          $eltrans = ( $el / $absmaxes[$countcolm] ) ;
        }
        else
        {
          $eltrans = "" ;
        }
        push ( @{ $containertwo[$countcolm] }, $eltrans) ; #print  "ELTRANS: $eltrans\n";
      }
      $countcolm++;
    }

   


    $dirfiles{absmaxes} ||= ();
    $dirfiles{absmins}  ||= ();

    my $c = 0;
    foreach my $max ( @maxes ) 
    {

      if ( !defined( $max ) or ( $max eq "NOTHING1") ) {  # keep index alignment
        $c++;
        next;
      }

      if ( !defined($dirfiles{absmaxes}[$c]) or ( $max > $dirfiles{absmaxes}[$c] ) ) 
      {
        $dirfiles{absmaxes}[$c] = $max;
      } else {
        $max = $dirfiles{absmaxes}[$c];
      }
      $c++;
    }

    $c = 0;
    foreach my $min ( @mins ) 
    {
      if ( !defined( $min ) ) 
      { 
        $c++; 
        next; 
      }

      if ( !defined($dirfiles{absmins}[$c]) or ( $min < $dirfiles{absmins}[$c] ) ) 
      {
        $dirfiles{absmins}[$c] = $min;
      } 
      else 
      {
        $min = $dirfiles{absmins}[$c];   
      }
      $c++;
    }


  
    
    my $countrow = 0;
    foreach ( @selectbag )
    {
      my $growlin;
      my ( @c1row, @c2row, @cnamesrow );

      foreach my $c1_ref ( @containerone )
      {
        my @c1col = @{ $c1_ref };
        push( @c1row, $c1col[ $countrow ] );
      }

      foreach my $cnames_ref ( @containernames )
      {
        my @cnamescol = @{ $cnames_ref };
        push( @cnamesrow, $cnamescol[$countrow] );
      }

      foreach my $c2_ref ( @containertwo )
      {
        my @c2col = @{ $c2_ref };
        push( @c2row, $c2col[$countrow] );
      }


      my ( $numberels, $scalar_keepcolumns );
      if ( not ( scalar( @weighttransforms ) == 0 ) )
      {
        $numberels = scalar( @weighttransforms );
        $scalar_keepcolumns = scalar( @weighttransforms );
      }
      else
      {
        $numberels = scalar( @keepcolumns );
        $scalar_keepcolumns = scalar( @keepcolumns );
      }


      my $wsum = 0; # WEIGHTED SUM
      my $counterin = 0;
      foreach my $elt ( @c2row )
      {
        my $newelt = ( $elt * abs( $weights[$counterin] ) );
        $wsum = ( $wsum + $newelt ) ;
        $counterin++;
      }

      $growlin = $growlin . "$containertitles[ $countrow ],";

      $countel = 0;
      foreach my $el ( @c1row )
      {
        $growlin = $growlin . "$cnamesrow[$countel],";
        $growlin = $growlin . "$el,";

        $countel++;
      }

      foreach my $el ( @c2row )
      {
        $growlin = $growlin . "$el,";
      }

      $growlin = $growlin . "$wsum";
      push( @weightbag, $growlin );
      $countrow++;
    }
  }  say  "IN POSTSIM \@weightbag " . dump( @weightbag );
    
  @weightbag = uniq( @weightbag ); 


  if ( ( not ( $pierce eq "y" ) ) or ( ( $pierce eq "y" ) and ( $postlast ne "y") ) )
  {
    foreach my $line ( @weightbag )
    {
      my $rid = Sim::OPT::instid( $line, $file ); ## !!!! THIS IS THE INSTANCE ID
      if ( defined($rid) and $rid ne "" )
      {
        $dirfiles{realreps}{$rid} = $line;
      }
    }
  }

  if ( not ( $pierce eq "y" ) )
  {
    return( \@weightbag, \%dirfiles, $csim );
  }
  elsif ( ( $pierce eq "y" ) and ( $postlast ne "y") )
  {
    return( \@weightbag, \%dirfiles, $csim, $instant, \@bomb );
  }
  elsif ( ( $pierce eq "y" ) and ( $postlast eq "y") )
  {
    return( \@weightbag, \%dirfiles, $csim );
  }

  close TOFILE;
  close OUTFILE;

}    # END SUB sim;

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

Sim::OPT::Sim is the module used by Sim::OPT to launch the simulations once the models have been built. Sim::OPT::Sim's presently existing functionalities can be used to launch simulations in ESP-r and EnergyPlus. The possibility to call simulation programs other than the cited two may be pursued through modifications of the code dedicated to EnergyPlus (which is actually meant as an example of a generic case). This code portion may be actually constituted by the single line launching the simulation program through the shell.
This module is dual-licensed, open-source and proprietary. The open-source distribution is available on CPAN (https://metacpan.org/dist/Sim-OPT ). A proprietary distribution, including additional modules (OPTcue), is available from the author’s website (https://sites.google.com/view/bioclimatic-design/home/software ).

=head2 EXPORT

"sim".

=head1 SEE ALSO

Annotated examples can be found packed in the "optw.tar.gz" file in "examples" directory in this distribution.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.

=cut
