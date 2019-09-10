package Sim::OPT::Report;
# Copyright (C) 2008-2019 by Gian Luca Brunetti and Politecnico di Milano.
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

our @EXPORT = qw( retrieve report newretrieve newreport get_files );

$VERSION = '0.077';
$ABSTRACT = 'Sim::OPT::Report is the module used by Sim::OPT to retrieve simulation results.';

#########################################################################################
# HERE FOLLOWS THE CONTENT OF "Retrieve.pm", Sim::OPT::Retrieve
##############################################################################


sub newretrieve
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

  $tee = new IO::Tee(\*STDOUT, ">>$tofile"); # GLOBAL


  say $tee "\n#Now in Sim::OPT::Report_newretrieve.\n";

  my %simtitles = %main::simtitles;
  my %retrievedata = %main::retrievedata;
  my @keepcolumns = @main::keepcolumns;
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

  my %dt = %{ $_[0] };
  my %d = %{ $dt{instance} };
  my %dirfiles = %{ $dt{dirfiles} };
  my $resfile = $dt{resfile};
  my $flfile = $dt{flfile};
  my %vehicles = %{ $dt{vehicles} };

  my @simcases = @{ $dirfiles{simcases} }; ######
  my @simstruct = @{ $dirfiles{simstruct} }; ######
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

  my $countinstance = $d{instn};

  my $countcase = $d{countcase};
  my $countblock = $d{countblock};
  my %datastruc = %{ $d{datastruc} }; ######
  my @varnumbers = @{ $d{varnumbers} };
  @varnumbers = Sim::OPT::washn( @varnumbers );
  my @miditers = @{ $d{miditers} };
  @miditers = Sim::OPT::washn( @miditers );
  my @sweeps = @{ $d{sweeps} };

  my %dowhat = %{ $d{dowhat} };

  my $direction = ${$dowhat{direction}}[$countcase][$countblock]; #NEW
  my $precomputed = $dowhat{precomputed}; #NEW
  my @takecolumns = @{ $dowhat{takecolumns} }; #NEW

  my $skipfile = $vals{skipfile};
	my $skipsim = $vals{skipsim};
	my $skipreport = $vals{skipreport};
  my %notecases;

  my @winneritems = @{ $d{winneritems} };
  my $countvar = $d{countvar};
  my $countstep = $d{countstep};

  my %to = %{ $d{to} };
  my $thisto = $to{to};
  my %inst = %{ $d{inst} };
  my $cleanto = $inst{$thisto};


  my $from = $d{from};
  my $toitem = $d{toitem};

  my $c = $d{c};

  my $skip = $dowhat{$countvar}{skip};

  my ( @repdata, @retrdata );

  my $numberof_simtools = scalar ( keys %{ $dowhat{simtools} } );

  my $counttool = 1;
  while ( $counttool <= $numberof_simtools )
  {
    my $skip = $dowhat{$countvar}{$counttool}{skip};
    if ( not ( eval ( $skipsim{$counttool} )))
    {
      my $tooltype = $dowhat{simtools}{$counttool};

      sub retrieve_temperatures_results
      {
        my ( $result, $resfile, $retrdata_ref, $reporttitle, $themereport, $counttheme, $countreport, $retfile ) = @_;

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
        if ( ( $exeonfiles eq "y" ) or ( $dowhat{newretrieve} eq "y" ) )
        {
          say $tee "#Retrieving temperature results.";
          print `$printthis`;
          say $tee "$printthis";
        }
        print $tee "
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n
$printthis";

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
         if ($exeonfilvalses eq "y")
         {
            say $tee "Retrieving comfort results.";
            print `$printthis`;
            say $tee "$printthis";
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
        else
        {
          say $tee "THERE ALREADY IS A RETFILE!";
        }
      }
      if ( ($exeonfiles eq "y") or ( $dowhat{newretrieve} eq "y" ) )
      {

        say $tee "#Retrieving $themereport results.";
        print `$printthis`;
        say $tee "$printthis";
      }
      print $tee "
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n
$printthis
";

    }

    sub retrieve_adhoc
    {
      my ( $result, $resfile, $retrdata_ref, $reporttitle, $themereport, $counttheme, $countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines ) = @_;

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

          if ( ($exeonfiles eq "y") or ( $dowhat{newretrieve} eq "y" ) )
          {

            say $tee "#Retrieving $themereport results.";
            print `$printthis`;
            say $tee "$printthis";
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

          if ( ($exeonfiles eq "y") or ( $dowhat{newretrieve} eq "y" ) )
          {

            say $tee "#Retrieving $themereport results.";
            print `$printthis`;
            say $tee "$printthis";
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

          if ( ( $exeonfiles eq "y" ) or ( $dowhat{newretrieve} eq "y" ) )
          {

            say $tee "#Retrieving $themereport results.";
            print `$printthis`;
            say $tee "$printthis";
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

          if ( ( $exeonfiles eq "y" ) or ( $dowhat{newretrieve} eq "y" ) )
          {

            say $tee "#Retrieving $themereport results.";
            print `$printthis`;
            say $tee "$printthis";
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

            if ( ( $exeonfiles eq "y" ) or ( $dowhat{newretrieve} eq "y" ) )
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

          my $retfile = $datarep{retfile};
          my $reporttitle = $datarep{reporttitle};
          my $themereport = $datarep{themereport};
          my $semaphorego = $datarep{semaphorego};
          my $semaphorego1 = $datarep{semaphorego1};
          my $semaphorego2 = $datarep{semaphorego2};
          my $semaphorestop = $datarep{semaphorestop};
          my $semaphorestop1 = $datarep{semaphorestop1};
          my $semaphorestop2 = $datarep{semaphorestop2};
          my $textpattern = $datarep{textpattern};
          my $afterlines = $datarep{afterlines};
          my $column = $datarep{column};
          my $reportstrategy = $datarep{reportstrategy};

          my $counttheme = 0;
          foreach my $retrievedatum ( @{ $retrievedata{$counttool} } )
          {
            my $reportdata_ref_ref = $reportdata{$counttool}->[$counttheme];
            my @retrievedatarefs = @{$retrievedatum};
            my $simtitle = $simtitles{$counttool}->[ $counttheme ][0];
            my @sims = @{ $simtitles{$counttool}->[ $counttheme ] }[1..4];

            #if ( not ( eval ( $skipreport ) ) )
            if ( -e $resfile )
            {
              my $countreport = 0;
              foreach my $retrievedataref (@retrievedatarefs)
              {
                @retrdata = @$retrievedataref;
                my $sim = $sims[$countreport];
                my $targetprov = $sim;
                $targetprov =~ s/$mypath\///;
                my $result = "$mypath/" . "$targetprov";

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

                open( RETBLOCK, ">>$retblock"); # or die;

                my $reportdata_ref = $reportdata_ref_ref->[$countreport];
                @repdata = @$reportdata_ref;



                my $countitem = 0;
                foreach my $item ( @repdata )
                {
                  my %datarep = %$item;
                  my $reporttitle = $datarep{reporttitle};
                  my $themereport = $datarep{themereport};
                  my $semaphorego = $datarep{semaphorego};
                  my $semaphorego1 = $datarep{semaphorego1};
                  my $semaphorego2 = $datarep{semaphorego2};
                  my $semaphorestop = $datarep{semaphorestop};
                  my $semaphorestop1 = $datarep{semaphorestop1};
                  my $semaphorestop2 = $datarep{semaphorestop2};
                  my $textpattern = $datarep{textpattern};
                  my $afterlines = $datarep{afterlines};
                  my $reportstrategy = $datarep{reportstrategy};
                  my $retfile = "$resfile-$reporttitle-$themereport.grt";
                  my $column = $datarep{column};

                  $retstruct[$countcase][$countblock][ $countinstance ][$counttheme][$countreport][$countitem][$counttool] = $retfile;
                  print RETBLOCK "$retfile\n";

                  if ( not ($retfile ~~ @retcases ) )
                  {
                    push ( @retcases, $retfile );
                    say RETLIST "$retfile";
                  }  @miditers = Sim::OPT::washn( @miditers );

                  if ( not ( $retfile ~~ @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } ) )
                  {
                    push ( @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } ,
                      {
                        retfile => $retfile,
                        reporttitle => $reporttitle,
                        themereport => $themereport,
                        semaphorego => $semaphorego,
                        semaphorego1 => $semaphorego1,
                        semaphorego2 => $semaphorego2,
                        semaphorestop => $semaphorestop,
                        semaphorestop1 => $semaphorestop1,
                        semaphorestop2 => $semaphorestop2,
                        textpattern => $textpattern,
                        afterlines => $afterlines,
                        column => $column,
                        reportstrategy => $reportstrategy,
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
                           #}
           					{
                      retrieve_comfort_results( $result, $resfile, \@retrdata, $reporttitle, $themereport, $counttheme, $countreport, $retfile );
                    }
                    elsif ( ( ( $themereport eq "loads" ) or ( $themereport eq "tempsstats"  ) ) )
                    {
                      say $tee "IN NEWRETRIEVE \$result $result, \$resfile $resfile, \@retrdata @retrdata, \$reporttitle $reporttitle,
                      \$themereport $themereport, \$counttheme $counttheme,
                            \$countreport $countreport, \$retfile $retfile, \$semaphorego1 $semaphorego1, \$semaphorego2 $semaphorego2,
                            \$semaphorestop1 $semaphorestop1, \$semaphorestop2 $semaphorestop2, \$textpattern $textpattern, \$afterlines $afterlines";
                      retrieve_stats_results( $result, $resfile, \@retrdata, $reporttitle, $themereport, $counttheme,
                            $countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines );
                    }
                    elsif ( ( $themereport eq "radent" ) or ( $themereport eq "radabs" ) or ( $themereport eq "airtemp" ) or ( $themereport eq "radtemp" ) or ( $themereport eq "restemp" ) )
                    {

                      retrieve_adhoc( $result, $resfile, \@retrdata, $reporttitle, $themereport, $counttheme,
                            $countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines );
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
                @retrdata = @$retrievedataref;

                open( RETLIST, ">>$retlist"); # or die;
                open( RETBLOCK, ">>$retblock"); # or die;

                my $reportdata_ref = $reportdata_ref_ref->[$countreport];
                @repdata = @$reportdata_ref;
                @retcases = uniq( @retcases );
                my $retfile = $resfile;
                if ( not ($retfile ~~ @retcases ) )
                {
                  push ( @retcases, $retfile );
                  say RETLIST "$retfile";
                }
                my @provbag;

                push ( @provbag, $retfile );

                my $countitem = 0;
                foreach my $item ( @repdata )
                {
                  my %datarep = %$item;
                  my $reporttitle = $datarep{reporttitle};
                  my $themereport = $datarep{themereport};
                  my $semaphorego = $datarep{semaphorego};
                  my $semaphorego1 = $datarep{semaphorego1};
                  my $semaphorego2 = $datarep{semaphorego2};
                  my $semaphorestop = $datarep{semaphorestop};
                  my $semaphorestop1 = $datarep{semaphorestop1};
                  my $semaphorestop2 = $datarep{semaphorestop2};
                  my $textpattern = $datarep{textpattern};
                  my $afterlines = $datarep{afterlines};
                  my $column = $datarep{column};
                  my $reportstrategy = $datarep{reportstrategy};

                  print RETBLOCK "$retfile\n";

                  push ( @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } ,
                                    {
                                      retfile => $retfile,
                                      reporttitle => $reporttitle,
                                      themereport => $themereport,
                                      semaphorego => $semaphorego,
                                      semaphorego1 => $semaphorego1,
                                      semaphorego2 => $semaphorego2,
                                      semaphorestop => $semaphorestop,
                                      semaphorestop1 => $semaphorestop1,
                                      semaphorestop2 => $semaphorestop2,
                                      textpattern => $textpattern,
                                      afterlines => $afterlines,
                                      column => $column,
                                      reportstrategy => $reportstrategy,
                                    } );

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

  `rm -f $mypath/*.par`;
  print $tee "rm -f $mypath/*.par\n";
  close OUTFILE;
  close TOFILE;
  close RETLIST;
  close RETBLOCK;

  if ( $dowhat{neweraseres} eq "y" )
  {
    `rm -f $resfile` ;
    if ( -e $flfile )
    {
      `rm -f $flfile` ;
    }
  }
  return ( \@retcases, \@retstruct, \@notecases );
}  # END SUB NEWRETRIEVE


sub newreport # This function retrieves the results of interest from the texts files created by the "retrieve" function
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

  my %simtitles = %main::simtitles;
  my %retrievedata = %main::retrievedata;
  my @keepcolumns = @main::keepcolumns;
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
  my %notecases = %main::notecases;

  $tee = new IO::Tee(\*STDOUT, ">>$tofile"); # GLOBAL

  say $tee "\nNow in Sim::OPT::Report::newreport.\n";

  my %dt = %{ $_[0] };
  my %d = %{ $dt{instance} };
  my %dirfiles = %{ $dt{dirfiles} };
  my $resfile = %{ $dt{resfile} };
  my $flfile = %{ $dt{flfile} };
  my %vehicles = %{ $dt{vehicles} };

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
  my $repfile = $dirfiles{repfile};

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

  my $countcase = $d{countcase};
  my $countblock = $d{countblock};
  my %datastruc = %{ $d{datastruc} }; ######
  my $countinstance = $d{instn};

  my @simcases = @{ $d{simcases} }; #####
  my @simstruct = @{ $d{simstruct} }; ######
  my $c = $d{c};

  my @varnumbers = @{ $d{varnumbers} };
  @varnumbers = Sim::OPT::washn( @varnumbers );
  my @miditers = @{ $d{miditers} };
  @miditers = Sim::OPT::washn( @miditers );
  my @sweeps = @{ $d{sweeps} };
  #my $toitem = $d{toitem} ;
	#my $from = $d{from} ;

  my @winneritems = @{ $d{winneritems} };
  my $countvar = $d{countvar};
  my $countstep = $d{countstep};

  my %to = %{ $d{to} };
  my $thisto = $to{to};
  my %inst = %{ $d{inst} };
  my $cleanto = $inst{$thisto};

  my $from = $d{from};
  my $toitem = $d{toitem};

  my $c = $d{c};

	my @blockelts = @{ $d{blockelts} };

  my @blocks = @{ $d{blocks} };
  my %varnums = %{ $d{varnums} };
  my %mids = %{ $d{mids} };

  my $varnumber = $countvar; ###########################!!!
  my $stepsvar = $varnums{$countvar}; ;

  my %dowhat = %{ $d{dowhat} };
  my $resfile = $d{resfile};


  my $direction = ${$dowhat{direction}}[$countcase][$countblock]; #NEW
  my $precomputed = $dowhat{precomputed};
  my @takecolumns = @{ $dowhat{takecolumns} }; #NEW


  my ( @repfilemem, @linecontent, @convey );
  $" = " ";


  say $tee "#Processing reports for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", instance " . ($countinstance + 1);


  open( REPLIST, ">>$replist" ) or die( "$!" );
  open( REPBLOCK, ">>$repblock" ) or die( "$!" );

  my $divert;
  if ( $dirfiles{launching} eq "yes" )
  {
    say "YES.";
    $divert = $repfile . ".revealnum.csv";
    open( DIVERT, ">>$divert") or die "Can't open $repfile $!";
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


  if ( $precomputed eq "" ) #NEW, TAKE CARE.###########################
  {
    my $numberof_simtools = scalar( keys %{ $dowhat{simtools} } );
    #my @mergestruct;
    my $counttool = 1;
    while ( $counttool <= $numberof_simtools )
    {
      my $skip = $vals{$countvar}{$counttool}{skip};
      if ( not ( eval ( $skipsim{$counttool} )))
      {
        my $tooltype = $dowhat{simtools}{$counttool};
        foreach $ret_ref ( ( @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } ) )
        {
          %retitem = %$ret_ref;
          my $retfile = $retitem{retfile};
          my $reporttitle = $retitem{reporttitle};
          my $themereport = $retitem{themereport};
          my $semaphorego = $retitem{semaphorego};
          my $semaphorego1 = $retitem{semaphorego1};
          my $semaphorego2 = $retitem{semaphorego2};
          my $semaphorestop = $retitem{semaphorestop};
          my $semaphorestop1 = $retitem{semaphorestop1};
          my $semaphorestop2 = $retitem{semaphorestop2};
          my $textpattern = $retitem{textpattern};
          my $afterlines = $retitem{afterlines};
          my $column = $retitem{column};
          my $reportstrategy = $retitem{reportstrategy};

          if ( $signalnewinstance == 1 )
          {
            push ( @{ $mergestruct[$countcase][$countblock][$countinstance] }, "$retfile " );
            $signalnewinstance--;
          }

          my ( $semaphore1, $semaphore2 );

          if ( -e $retfile )
          { say $tee "#Inspecting results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", instance " . ($countinstance + 1) . ", file $retfile, to report $themereport." ;

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
              $line =~ s/^\s//;
              $line =~ s/^\s//;
              $line =~ s/^\s//;
              $line =~ s/://;
              #$line =~ s/(\s+)/\s/;
              $line =~ s/(\s+)/,/;
              my @elts = split( ",", $line );
              my $elt = $elts[$column];

              if ( ( not ( defined( $semaphorego ) ) ) or ( $semaphorego eq "" ) or ( $line =~ m/$semaphorego/ ) )
              {
                $semaphore = "on";
              }


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

              if ( ( $line =~ m/$semaphorestop/ ) and ( defined( $semaphorestop ) ) and ( $semaphorestop ne "" ) )
              {
                $semaphore = "off";
              }

              if ( ( $line =~ m/$semaphorestop1/ ) and ( defined( $semaphorestop1 ) ) and ( $semaphorestop1 ne "" ) )
              {
                $semaphore1 = "off";
              }

              if ( ( $line =~ m/$semaphorestop2/ ) and ( defined( $semaphorestop2 ) ) and ( $semaphorestop2 ne "" ) )
              {
                $semaphore2 = "off";
              }

              if ( ( not ( defined ( $afterlines ) ) ) or ( $afterlines eq "" ) )
              {
                if ( ( $textpattern ne "" ) and ( $line =~ m/$textpattern/ ) and ( $semaphore1 eq "on" ) and ( $semaphore2 eq "on" ) )
                {
                  #chomp( $line )
                  if ( $foundhit == 0 )
                  {
                    unless ( $reportstrategy eq "new" )
                    {
                      push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, "$themereport,$reporttitle,$line" );
                    }
                    else
                    { #say $tee "NEWSTRATEGY";
                      push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, "$themereport,$reporttitle,$elt" );
                    }
                  }
                  else
                  {
                    unless ( $reportstrategy eq "new" )
                    {
                      push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, $line );
                    }
                    else
                    { #say $tee "NEWSTRATEGY";
                      push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, $elt );
                    }
                  }
                  $foundhit++;
                }
              }
              else
              {
                if ( ( $textpattern ne "" ) and ( $line =~ m/$textpattern/ ) and ( $semaphore1 eq "on" ) and ( $semaphore2 eq "on" ) )
                {
                  $signalhit++;
                }

                if ( ( $semaphore1 eq "on" ) and ( $semaphore2 eq "on" ) and ( $signalhit > 0 ) )
                {

                  if ( not ( ref( $afterlines ) ) )
                  {
                    if ( ( $afterlines ne "" ) and ( $countline == ( $afterlines - 1 ) ) )
                    {
                      unless ( $reportstrategy eq "new" )
                      {
                        push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, "$themereport,$reporttitle,$line" );
                      }
                      else
                      {
                        push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, "$themereport,$reporttitle,$elt" );
                      }
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
                          if ( $countlocal == 0 )
                          {
                            unless ( $reportstrategy eq "new" )
                            {
                              push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, "$themereport,$reporttitle,$line" );
                            }
                            else
                            {
                              push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, "$themereport,$reporttitle,$elt" );
                            }
                          }
                          else
                          {
                            unless ( $reportstrategy eq "new" )
                            {
                              push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, $line );
                            }
                            else
                            {
                              push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, $elt );
                            }
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
            open ( NOTFOUND, ">./notfound.txt" ) or die $! ;
            say NOTFOUND $retfile;

          }
        }
      }
      $counttool++;
    }

    unless ( $dowhat{inactivateret} eq "y" )
    {
      my $count = 0;
      foreach my $thing ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] } )
      {
        chomp $thing;
        $thing =~ s/\s+/,/g ;
        if ( $count == 0 )
        {
          $thing =~ s/$mypath\/// ;
          $thing =~ /^(\w+__)/ ;
          my $head = $1;
          my $oldhead = $head;
          $head = "$mypath/" . $head;
          my $newhead = $inst{$head};
          if ( $newhead ne "" )
          {
            $newhead = $newhead . "__";
            $thing =~ s/^$oldhead/$newhead/ ;
          }
        }
        print REPFILE $thing;
        print REPFILE ",";
        if ( $dirfiles{launching} eq "yes" )
        {
          print DIVERT $thing;
          print DIVERT ",";
        }
        $count++;
      }
      print REPFILE "\n";
      if ( $dirfiles{launching} eq "yes" )
      {
        print DIVERT "\n";
      }
      say "#Reporting results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep. Instance $countinstance: writing $repfile. ";
    }
  } #END NEW. TAKE CARE.
  elsif ( $precomputed ne "" ) ############################NEW. END. TAKE CARE.
  {

  	my @precomputeds;
	  if (not ( $precomputed eq "" ) ) ############################NEW. END. TAKE CARE.
	  {
	    open ( PRECOMPUTED, "$precomputed" ) or die;
	    @precomputeds = <PRECOMPUTED>;
	    close PRECOMPUTED;
	  }

    my $touse = $cleanto; ### TAKE CARE!

    my @box;
    foreach my $line ( @precomputeds )
    {
      $line =~ s/\s+/ / ;
      if ( $line =~ /$touse/ )
      {
        my @row = split( ",", $line);
        shift( @row );
        unshift( @row, $cleanto );
        $line = join( ",", @row );
        push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, $line );
        push( @box, $line );
      }
    }
    @box = uniq( sort( @box ) );
    foreach my $el ( @box )
    {
      say REPFILE $el;
      if ( $dirfiles{launching} eq "yes" )
      {
        say DIVERT $el;
      }
    }
    say "#Reporting results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep. Instance $countinstance: writing $repfile. ";
  }
  close REPFILE;
  if ( $dirfiles{launching} eq "yes" )
  {
    close DIVERT;
  }
  close TOFILE;
  close OUTFILE;

  if ( $dowhat{neweraseret} eq "y" )
  {
    `rm -f $mypath/*.grt` ;
    print $tee "rm -f $mypath/*.grt";
  }
  if (not( -e $repfile ) ){ die; };

  if ( $dirfiles{launching} eq "yes" )
  {
    say "JUMPING";
    next;
  }
  return ( \@repcases, \@repstruct, $repfile, \@mergestruct, \@mergecases );
} # END SUB NEWREPORT;


1;

__END__

=head1 NAME

Sim::OPT::Report.

=head1 SYNOPSIS

  use Sim::OPT;
  opt;

=head1 DESCRIPTION

Sim::OPT::Report is the module used by Sim::OPT to retrieve simulation results. Sim::OPT::Report performs two kinds of action. The first, which is required only by certain simulation programs, is that of making the simulation program write the results in a user-specified text format. This functionality is platform-specific and is presently implemented only for ESP-r (EnergyPlus does not require that). The second functionality is that of collecting the results in a user-specified manner. That functionality is based on pattern-matching and is not simulation-program-specific.

=head2 EXPORT

"retrieve" "report".

=head1 SEE ALSO

Annotated examples can be found packed in the "optw.tar.gz" file in "examples" directory in this distribution.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2018 by Gian Luca Brunetti and Politecnico di Milano. This is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
