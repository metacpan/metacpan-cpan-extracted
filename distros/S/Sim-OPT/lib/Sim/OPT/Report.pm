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

our @EXPORT = qw( retrieve report newretrieve newreport get_files );

$VERSION = '0.61'; # our $VERSION = '';
$ABSTRACT = 'Sim::OPT::Report is the module used by Sim::OPT to retrieve simulation results.';

#########################################################################################
# HERE FOLLOWS THE CONTENT OF "Retrieve.pm", Sim::OPT::Retrieve
##############################################################################


sub newretrieve
{
  $configfile = $main::configfile;
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
  #open( TOFILE, ">>$tofile" ) or die "Can't open $tofile: $!";

  say $tee "\n#Now in Sim::OPT::Report_newretrieve.\n";

  #my $evalfiletemp = $dowhat{evalfile};
  #my $evalfile;
  # $evalfile = $mypath . "/" . $evalfiletemp;


  #
  #if ( -e $evalfile )
  #{
  #  say $tee "NOW EVALING $evalfile";
  #  say $tee `cat $evalfile`;
  #  eval { `cat $evalfile` };
  #}

  %simtitles = %main::simtitles;
  %retrievedata = %main::retrievedata; #say $tee "dump(\%retrievedata): " . dump(%retrievedata);
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

  my %dt = %{ $_[0] };
  my @instances = @{ $dt{instances} };
  my %dirfiles = %{ $dt{dirfiles} };
  my $countinstance = $dt{countinstance}; #say $tee "# in Retrieve \$countinstance $countinstance ";

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
  my $repfile = $dirfiles{repfile}; #say $tee "IN RETRIEVE \$repfile: " . dump($repfile);

  my %d = %{ $instances[$countinstance] }; #say $tee "# in Retrieve \%d " . dump(%d);;

  my $countcase = $d{countcase}; #say $tee "IN RETRIEVE \$countcase " . dump( $countcase );
  my $countblock = $d{countblock}; #say $tee "IN RETRIEVE \$countblock " . dump( $countblock );
  my %datastruc = %{ $d{datastruc} }; ######
  my @varnumbers = @{ $d{varnumbers} }; #say $tee "IN ENTRY NEWRETRIEVE \@varnumbers : " . dump( @varnumbers );
  @varnumbers = Sim::OPT::washn( @varnumbers ); #say $tee "IN ENTRY NEWRETRIEVE \@varnumbers : " . dump( @varnumbers );
  my @miditers = @{ $d{miditers} }; #say $tee "IN ENTRY NEWRETRIEVE \@miditers : " . dump( @miditers );
  @miditers = Sim::OPT::washn( @miditers ); #say $tee "IN ENTRY NEWRETRIEVE \@miditers : " . dump( @miditers );
  my @sweeps = @{ $d{sweeps} }; #say $tee "IN ENTRY NEWRETRIEVE \@sweeps : " . dump( @sweeps );

  if ( $countcase > $#varnumbers )# NUMBER OF CASES OF THE CURRENT PROBLEM
  {
    exit(say $tee "#END RUN.");
  }

  my %dowhat = %{ $d{dowhat} };

  my $direction = ${$dowhat{direction}}[$countcase][$countblock]; #NEW
  my $precomputed = $dowhat{precomputed}; #NEW
  my @takecolumns = @{ $dowhat{takecolumns} }; #NEW

  my $skipfile = $dowhat{skipfile};
  my $skipsim = $dowhat{skipsim};
  my $skipreport = $dowhat{skipreport};
  my %notecases;

  my @winneritems = @{ $d{winneritems} }; #say $tee  "IN RETRIEVE( \@winneritems) " . dump(@winneritems);
  my $countvar = $d{countvar}; #say $tee "IN RETRIEVE(\$countvar): " . dump($countvar );
  my $countstep = $d{countstep}; #say $tee "IN RETRIEVE(\$countstep): " . dump($countstep);
  my $to = $d{to};
  my $toitem = $d{toitem};
  my $from = $d{from};
  my $c = $d{c}; #say $tee "IN RETRIEVE( \$c ): " . dump( $c );

  #eval($getparshere);

  my $skip = $dowhat{$countvar}{skip};

  my $numberof_simtools = scalar ( keys %{ $dowhat{simtools} } ); #say $tee "dump(\$numberof_simtools ): " . dump($numberof_simtools );

  my $counttool = 1;
  while ( $counttool <= $numberof_simtools )
  {
    my $skip = $dowhat{$countvar}{$counttool}{skip}; #say $tee "INWHILE dump(\$skip): " . dump($skip);
    if ( not ( eval ( $skipsim{$counttool} )))
    {
      my $tooltype = $dowhat{simtools}{$counttool}; #say $tee "INWHILE dump(\$tooltype ): " . dump($tooltype );

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
        if ($exeonfiles eq "y")
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
      #say $tee "IN retrieve_stats_results 1. " ;

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
        say $tee "IN retrieve_stats_results 2. " ;
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
      if ($exeonfiles eq "y")
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

          if ($exeonfiles eq "y")
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

          if ($exeonfiles eq "y")
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

          if ($exeonfiles eq "y")
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

            if ($exeonfiles eq "y")
            {

              say $tee "#Retrieving $themereport results.";
              print `$printthis`;
            }
          }
        }
      }

      #say $tee "\@simstruct : ". dump( @simstruct );
      #say $tee "\@simcases : ". dump( @simcases );
      #say $tee "\$countcase : ". dump( $countcase );
      #say $tee "\$countblock : ". dump( $countblock );
      #say $tee "\$counttool : ". dump( $counttool );
      #say $tee "\$countinstance : ". dump( $countinstance );

      my @resfiles = @{ $simstruct[$countcase][$countblock][$countinstance][$counttool] }; #say $tee "\@resfiles" . "@resfiles";

      if ( $retrievedata{$counttool} )
      {
        #say $tee "\$retrievedata{\$counttool}: yes.";
        if ( $tooltype eq "esp-r" )
        {
          #say $tee "\$tooltype eq esp-r: yes.";









          my $counttheme = 0;
          foreach my $retrievedatum ( @{ $retrievedata{$counttool} } )
          {
            #say $tee " IN FOREACH: \$retrievedatum: " . dump( $retrievedatum ) ;
            my $reportdata_ref_ref = $reportdata{$counttool}->[$counttheme]; #say $tee "\$reportdata_ref_ref : " . dump( $reportdata_ref_ref ) ;
            my @retrievedatarefs = @{$retrievedatum}; #say $tee "\@retrievedatarefs : ". dump( @retrievedatarefs );
            my $simtitle = $simtitles{$counttool}->[ $counttheme ][0]; #say $tee "\$simtitle : $simtitle .";
            my @sims = @{ $simtitles{$counttool}->[ $counttheme ] }[1..4]; #say $tee "\@sims : ". dump( @sims );

            #my $resfile = $resfiles[ $counttheme ]; ################ TURNING THIS OFF IS PROVISIONAL!!!
            #say $tee "\$resfile : $resfile .";

            #if ( not ( eval ( $skipreport ) ) )
            if ( -e $resfile )
            {
              #say $tee "\$resfile EXIXTS, SO GOING ON .";
              my $countreport = 0;
              foreach my $retrievedataref (@retrievedatarefs)
              {
                #say $tee "IN FOREACH 2 \$retrievedataref : $retrievedataref .";
                my @retrdata = @$retrievedataref; #say $tee "\@retrdata : ". dump( @retrdata );
                my $sim = $sims[$countreport]; #say $tee "\$sim : ". dump( $sim );
                my $targetprov = $sim;
                $targetprov =~ s/$mypath\///;
                my $result = "$mypath" . "/$targetprov"; #say $tee "\$result : ". dump( $result );

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
                #}from

                my $reportdata_ref = $reportdata_ref_ref->[$countreport]; #say $tee "\$reportdata_ref : ". dump( $reportdata_ref );
                my @reportdata = @$reportdata_ref;

                my $countitem = 0;
                foreach my $item ( @reportdata )
                {
                  #say $tee "IN FOREACH 3 \$item : ". dump( $item );
                  my %datarep = %$item;  #say $tee "IN FOREACH 3 \%datarep : ". dump( %datarep);
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
                  }  @miditers = Sim::OPT::washn( @miditers ); #say $tee "IN ENTRY NEWRETRIEVE \@miditers : " . dump( @miditers );


                  #say $tee "\$retfile : ". dump( $retfile );
                  if ( not ( $retfile ~~ @{ $notecases[ $countcase ][ $countblock ][ $counttool ][ $countinstance ] } ) )
                  {

                    #say $tee "\$countcase : ". dump( $countcase );
                    #say $tee "\$countblock : ". dump( $countblock );
                    #say $tee "\$counttool : ". dump( $counttool );
                    #say $tee "\$countinstance : ". dump( $countinstance );
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
                           #}
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


  #say $tee "\@notecases " . dump( @notecases );

  if ( $dowhat{neweraseres} eq "y" )
  {
    `rm -f $resfile` ;
  }
  return ( \@retcases, \@retstruct, \@notecases );
}  # END SUB NEWRETRIEVE


sub newreport # This function retrieves the results of interest from the texts files created by the "retrieve" function
{
  $configfile = $main::configfile;
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

  $tee = new IO::Tee(\*STDOUT, ">>$tofile"); # GLOBAL ZZZ

  #open( OUTFILE, ">>$outfile" ) or die "Can't open $outfile: $!";
	#  open( TOFILE, ">>$tofile" ) or die "Can't open $tofile: $!";
  say $tee "\nNow in Sim::OPT::Report::newreport.\n";

  my %dt = %{ $_[0] };
  my @instances = @{ $dt{instances} };
  my %dirfiles = %{ $dt{dirfiles} }; #say $tee "IN REPORT \%dirfiles " . dump( %dirfiles );
  my $countinstance = $dt{countinstance};

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
  my $repfile = $dirfiles{repfile}; #say $tee "IN REPORT REPFILE: $repfile";

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

  my %d = %{ $instances[$countinstance] }; #say $tee "IN REPORT \$instances[\$countinstance]!!! : " . dump( %d );

  my $countcase = $d{countcase}; #say $tee "IN NEWREPORT \$countcase " . dump( $countcase );
  my $countblock = $d{countblock}; #say $tee "IN NEWREPORT \$countblock " . dump( $countblock );
  my %datastruc = %{ $d{datastruc} }; ######

  my @simcases = @{ $d{simcases} }; #####
  my @simstruct = @{ $d{simstruct} }; ######
  my $c = $d{c};

  my @varnumbers = @{ $d{varnumbers} }; #say $tee "IN ENTRY NEWREPORT \@varnumbers : " . dump( @varnumbers );
  @varnumbers = Sim::OPT::washn( @varnumbers ); #say $tee "IN ENTRY NEWREPORT \@varnumbers : " . dump( @varnumbers );
  my @miditers = @{ $d{miditers} }; #say $tee "IN ENTRY NEWREPORT \@miditers : " . dump( @miditers );
  @miditers = Sim::OPT::washn( @miditers ); #say $tee "IN ENTRY NEWREPORT \@miditers : " . dump( @miditers );
  my @sweeps = @{ $d{sweeps} }; #say $tee "IN ENTRY NEWREPORT \@sweeps : " . dump( @sweeps );
  my $toitem = $d{toitem} ;
	my $from = $d{from} ;

  my @winneritems = @{ $d{winneritems} };
  my $countvar = $d{countvar}; #say $tee "IN REPORT \$countvar " . dump( $countvar );
  my $countstep = $d{countstep}; #say $tee "IN REPORT \$countstep " . dump( $countstep );
  my $to = $d{to}; #say $tee "IN REPORT1 \$to " . dump( $to );
  my $c = $d{c}; #say $tee "IN REPORT1 \$c " . dump( $c );

	my @blockelts = @{ $d{blockelts} }; #say $tee "IN REPORT \@blockelts : " . dump( @blockelts );

  my @blocks = @{ $d{blocks} }; #say $tee "IN REPORT \@blocks" . dump( @blocks );
  my %varnums = %{ $d{varnums} }; #say $tee "IN REPORT \%varnums" . dump( %varnums );
  my %mids = %{ $d{mids} };  #say $tee "IN REPORT \%mids" . dump( %mids );

  my $stepsvar = Sim::OPT::getstepsvar( $countvar, $countcase, \@varnumbers );
  my $varnumber = $countvar; ###########################!!!???


  if ( $countcase > $#sweeps )# NUMBER OF CASES OF THE CURRENT PROBLEM
  {
    exit(say $tee "#END RUN.");
  }

  my %dowhat = %{ $d{dowhat} }; #say $tee "DOWHAT IN NEWREPORT " . dump( %dowhat );
  my $resfile = $d{resfile};


  my $direction = ${$dowhat{direction}}[$countcase][$countblock]; #NEW
  my $precomputed = $dowhat{precomputed}; #say $tee "PRECOMPUTED : " . dump( $precomputed );
  my @takecolumns = @{ $dowhat{takecolumns} }; #NEW


  my ( @repfilemem, @linecontent, @convey );
  $" = " ";


  say $tee "#Processing reports for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", instance " . ($countinstance + 1);

  open( REPLIST, ">>$replist" ) or die( "$!" );
  open( REPBLOCK, ">>$repblock" ) or die( "$!" );

  open( REPFILE, ">>$repfile") or die "Can't open $repfile $!"; #say $tee "#OPENED $repfile";
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


  if ( $precomputed eq "" ) #NEW, TAKE CARE.###########################àà
  {
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
              #chomp( $line );
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

              $line =~ s/^\s+// ;
              #$line =~ s/\s+/ /g ;
              #$line =~ s/ /,/ ;
              #chomp( $line );
              #$line = $line . " ";

              if ( ( not ( defined ( $afterlines ) ) ) or ( $afterlines eq "" ) )
              {

                if ( ( $textpattern ne "" ) and ( $line =~ m/^$textpattern/ ) and ( $semaphore1 eq "on" ) and ( $semaphore2 eq "on" ) )
                {
                  #chomp( $line )
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
                      #chomp( $line );
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
     											$line =~ s/^\s+// ;
                          #$line =~ s/\s+/ /g ;
                          #$line =~ s/ /,/ ;
                          #chomp( $line );
                          #$line = $line . " ";
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
                          #chomp( $line );
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
            open ( NOTFOUND, ">./notfound.txt" ) or die $! ;
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
        $thing =~ s/\s+/ /g ;
        $thing =~ s/ ,/,/g ;
        $thing =~ s/, /,/g ;
        $thing =~ s/ /,/g ;
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


  } #END NEW. TAKE CARE.
  elsif (not ( $precomputed eq "" ) ) ############################NEW. END. TAKE CARE.
  {	#say $tee "LOOKING.";

  	my @precomputeds;
	  if (not ( $precomputed eq "" ) ) ############################NEW. END. TAKE CARE.
	  {
	    open ( PRECOMPUTED, "$precomputed" ) or die;
	    @precomputeds = <PRECOMPUTED>;
	    close PRECOMPUTED;
	  }

    my $touse = $to;
    $touse =~ s/$mypath\///; #say $tee "IN REPORT1 \$touse " . dump($touse);
    #say $tee "TOUSE: $touse\n";
    foreach my $line ( @precomputeds )
    {
      if ( $line =~ /$touse/ )
      {
        push ( @{ $mergestruct[$countcase][$countblock][ $countinstance ] }, $line );
        #say $tee "HIT!!! for $repfile\n";
        #say $tee "LINE! $line";
        #say $tee "TOUSE: $touse\n";
        $line =~ s/\s+/ /g ;
        $line =~ s/ ,/,/g ;
        $line =~ s/, /,/g ;
        $line =~ s/ /,/g ;
        say REPFILE "$line";
      }
    }
  }
  close REPFILE;


  #say $tee "HEREIS \@repcases " . dump(@repcases); say $tee "\@repstruct " . dump(@repstruct);

  close TOFILE;
  close OUTFILE;

  if ( $dowhat{neweraseret} eq "y" )
  {
    `rm -f $mypath/*.grt` ;
    print $tee "rm -f $mypath/*.grt";
  }
  if (not( -e $repfile ) ){ die; };
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
