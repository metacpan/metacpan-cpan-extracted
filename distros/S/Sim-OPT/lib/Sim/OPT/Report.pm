package Sim::OPT::Report;
# This is the module Sim::OPT::Retrieve of Sim::OPT, a program for detailed metadesign managing parametric explorations, distributed under a dual licence, open-source (GPL v3) and proprietary.
# Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


use Exporter;
@ISA = qw(Exporter); # our @adamkISA = qw(Exporter);
our @EXPORT = qw( newretrieve newreport get_files );
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

use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Sim;

use Sim::OPT::Descend;
use Sim::OPT::Takechance;
use Sim::OPT::Interlinear;
use Sim::OPT::Parcoord3d;
use Sim::OPT::Stats;
eval { use Sim::OPTcue::OPTcue; 1 };
eval { use Sim::OPTcue::Metabridge; 1 };
eval { use Sim::OPTcue::Exogen::PatternSearch; 1 };
eval { use Sim::OPTcue::Exogen::NelderMead; 1 };
eval { use Sim::OPTcue::Exogen::Armijo; 1 };
eval { use Sim::OPTcue::Exogen::NSGAII; 1 };
eval { use Sim::OPTcue::Exogen::ParticleSwarm; 1 };
eval { use Sim::OPTcue::Exogen::SimulatedAnnealing; 1 };
eval { use Sim::OPTcue::Exogen::NSGAIII; 1 };
eval { use Sim::OPTcue::Exogen::MOEAD; 1 };
eval { use Sim::OPTcue::Exogen::SPEA2; 1 };
eval { use Sim::OPTcue::Exogen::ParticleSwarm; 1 };
eval { use Sim::OPTcue::Exogen::RadialBasis; 1 };
eval { use Sim::OPTcue::Exogen::Kriging; 1 };
eval { use Sim::OPTcue::Exogen::DecisionTree; 1 };
eval { use Sim::OPTcue::Exogen::KNN; 1 };
eval { use Sim::OPTcue::Exogen::FFNN; 1 };
eval { use Sim::OPTcue::Exogen::GBDT; 1 };
eval { use Sim::OPTcue::Endogen::DWGN2; 1 };
eval { use Sim::OPTcue::Endogen::NeuralBoltzmann; 1 };


use Data::Dumper;
#$Data::Dumper::Indent = 0;
#$Data::Dumper::Useqq  = 1;
#$Data::Dumper::Terse  = 1;
use Data::Dump qw(dump);
use feature 'say';
no strict;
no warnings;
use Switch::Back;

$VERSION = '0.125';
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

	if ( $tofile eq "" )
	{
		$tofile = "./report.txt";
	}



  say  "\n#Now in Sim::OPT::Report::newretrieve.\n";

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

  my %dt = %{ $_[0] };

  my %dirfiles = %{ $dt{dirfiles} };
  my $resfile = $dt{resfile};
  my $flfile = $dt{flfile};
  my %vehicles = %{ $dt{vehicles} };
  my $precious = $dt{precious};
  my %inst = %{ $dt{inst} };
  my %dowhat = %{ $dt{dowhat} };

  my $repfile = $dirfiles{repfile}; say  "IN RETRIEVE FROM DIRFILES \$repfile $repfile";

  #my $csim = $dt{csim};

  @{ $dirfiles{dones} } = uniq( @{ $dirfiles{dones} } );
  #%inst = %{ Sim::OPT::>washhash( \%inst ) }; say  "3 HERE IN OPT SUB CALLBLOCK \%onst: " . dump( \%onst );
  $inst_ref = Sim::OPT::filterinsts_wnames( \@{ $dirfiles{dones} } , \%inst );
  %inst = %{ $inst_ref }; # REASSIGNMENT!!!!!!


  my %d = %{ $dt{instance} };

  my $countinstance = $d{instn}; #say  "HERE IN NEWRETRIEVE \$countinstance: " . dump( $countinstance );
  my $instn = $d{instn};
  my $countcase = $d{countcase}; #say  "HERE IN NEWRETRIEVE \$countcase: " . dump( $countcase );
  my $countblock = $d{countblock}; #say  "HERE IN NEWRETRIEVE \$countblock: " . dump( $countblock );
  my %incumbents = %{ $d{incumbents} }; #say  "HERE IN NEWRETRIEVE \%incumbents: " . dump( \%incumbents );
  my @varnumbers = @{ $d{varnumbers} };
  @varnumbers = Sim::OPT::washn( @varnumbers ); #say  "HERE IN NEWRETRIEVE \@varnumbers: " . dump( @varnumbers );
  my @miditers = @{ $d{miditers} };
  @miditers = Sim::OPT::washn( @miditers ); #say  "HERE IN NEWRETRIEVE \@miditers: " . dump( @miditers );
  my @sweeps = @{ $d{sweeps} }; #say  "HERE IN NEWRETRIEVE \@sweeps: " . dump( @sweeps );

  my $direction = ${$dowhat{direction}}[$countcase][$countblock]; #say  "HERE IN NEWRETRIEVE \$direction: " . dump( $direction );
  my $precomputed = $dowhat{precomputed}; #say  "HERE IN NEWRETRIEVE \$precomputed: " . dump( $precomputed );
  my @takecolumns = @{ $dowhat{takecolumns} }; #say  "HERE IN NEWRETRIEVE \@takecolumns: " . dump( @takecolumns );

  my $skipfile = $vals{skipfile};
	my $skipsim = $vals{skipsim};
	my $skipreport = $vals{skipreport};

  my @winneritems = @{ $d{winneritems} }; #say  "HERE IN NEWRETRIEVE \@winneritems: " . dump( @winneritems );
  my $countvar = $d{countvar}; #say  "HERE IN NEWRETRIEVE \$countvar: " . dump( $countvar );
  my $countstep = $d{countstep}; #say  "HERE IN NEWRETRIEVE \$countstep: " . dump( $countstep );

  #my $retlist = $dirfiles{retlist};####!!!
  #my $retblock = $dirfiles{retblock};
  #my $replist = $dirfiles{replist};
  #my $repblock = $dirfiles{repblock};

  my %to = %{ $d{to} }; #say  "HERE IN NEWRETRIEVE \%to: " . dump( %to );
  #####my $thisto = $to{to}; #say  "\$thisto: $thisto";!!!!!


  my $thisto;
  if ( ( $dowhat{names} eq "short" ) or ( $dowhat{names} eq "medium" ) )
  {
    $thisto= $to{crypto}; #say  "\$thisto: $thisto";
  }
  else
  {
    $thisto= $to{to}; #say  "\$thisto: $thisto";
  }

  my $cleanto = $inst{$thisto}; #say  "\$cleanto: $cleanto";

  my $origin = $d{origin};
  my $from = $origin; #say  "HERE IN NEWRETRIEVE \$from: " . dump( $from );
  my $is = $d{is};

  my $fire = $d{fire};

  my $c = $d{c};

  my $skip = $dowhat{$countvar}{skip};

  my ( @repdata, @retrdata );

  my $numberof_simtools = scalar ( keys %{ $dowhat{simtools} } );

  my $shortresfile = $resfile;
  $shortresfile =~ s/$thisto// ;
  $shortresfile =~ s/\/cfg\///;
  #say  "IN RETRIEVE: \$shortresfile: $shortresfile, \$resfile: $resfile, \$to: $to, \$thisto: $thisto, \$cleanto: $cleanto";

  my $shortflfile = $flfile;
  $shortflfile =~ s/$thisto\/cfg\///; #say  "IN RETRIEVE: \$shortflfile: $shortflfile, \$flfile: $flfile";

  #say  "RELAUNCHED IN RETRIEVE WITH INST " . dump( %inst );

  my $counttool = 1;
  while ( $counttool <= $numberof_simtools )
  {
    my $skip = $dowhat{$countvar}{$counttool}{skip};
    if ( not ( eval ( $skipsim{$counttool} )))
    {
      my $tooltype = $dowhat{simtools}{$counttool};

      sub retrieve_temperatures_results
      {
        my ( $result, $resfile, $shortresfile, $thisto, $retrdata_ref, $reporttitle, $themereport, $counttheme, $countreport, $retfile ) = @_;

my $printthis =
"cd $thisto/cfg
res -file $resfile -mode script<<YYY

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
b
e
-
>
$retfile
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
          say  "#Retrieving temperature results.";
          print `$printthis`;
          say  "$printthis";
        }

        my $olddest =  "$retfile" . ".old";
        `mv -f $retfile $olddest`;

        open (OLDDEST, "$olddest" ) or die;
        my @oldlines = <OLDDEST>;
        close OLDDEST;

        open(NEWDEST, ">$retfile") or die;

        foreach my $line ( @oldlines )
        {
          chomp $line;
          print NEWDEST "$line,";
        }
        close NEWDEST;

        #print  "
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n $printthis";

      }

      sub retrieve_comfort_results
      {
        my ( $result, $resfile, $shortresfile, $thisto, $retrdata_ref, $reporttitle, $stripcheck, $themereport, $counttheme, $countreport, $retfile ) = @_;

        my @retrdata = @$retrdata_ref;

        if ( -e "$retfile" )
        {
          say  `rm -f $retfile`;
        }

        {
          my $printthis =
"cd $thisto/cfg
res -file $resfile -mode script<<ZZZ

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
            say  "Retrieving comfort results.";
            print `$printthis`;
            say  "$printthis";
         }
         print TOFILE "
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n $printthis";
      }
    }

    sub retrieve_stats_results
    {
      my ( $result, $resfile, $shortresfile, $thisto, $retrdata_ref, $reporttitle, $themereport, $counttheme, $countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines, $howmuch, $where, $what ) = @_;

      my @retrdata = @$retrdata_ref;
      my $printthis;

      if ( $themereport eq "loads" )
      {
        if ( -e $retfile )
          {
            say  `rm -f $retfile` ;
          }

        {
          $printthis =
"cd $thisto/cfg
res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
d
>
$retfile
$retfile
l
a
-
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
        if ( -e $retfile )
        {
          say  `rm -f $retfile` ;
        }
        
        {
        $printthis =
"cd $thisto/cfg
res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
d
>
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
      elsif ( $themereport eq "dhs" ) # dhs = degree hours
      {
        
        if ( -e $retfile )
        {
          say  `rm -f $retfile` ;
        }

        {
          $printthis =
"cd $thisto/cfg
res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
d
>
$retfile
$retfile
$where
b
$what
-
$howmuch
m
-
-
-
-
TTT
";
        }
      }
      elsif ( $themereport eq "surfflow" ) # flow through surface
      {
        if ( -e $retfile )
        {
          say  `rm -f $retfile` ;
        }

        {
          $printthis =
"cd $thisto/cfg
res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
d
>
$retfile
$retfile
i
b
b
$what
-
-
-
-
TTT
";
        }
      }
      elsif ( $themereport eq "surftemps" ) # temps at inside face of surface
      {
        if ( -e $retfile )
        {
          say  `rm -f $retfile` ;
        }

        {
          $printthis =
"cd $thisto/cfg
res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
d
>
$retfile
$retfile
b
b
i
-
$what
y
-
-
-
-
TTT
";
        }
      }

      if ( ($exeonfiles eq "y") or ( $dowhat{newretrieve} eq "y" ) )
      {

        say  "#Retrieving $themereport results.";
        print `$printthis`;
        say  "$printthis";
      }
      #print  "
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n $printthis";

    }

    sub retrieve_adhoc
    {
      my ( $result, $resfile, $shortresfile, $thisto, $retrdata_ref, $reporttitle, $themereport, $counttheme, $countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines ) = @_;

      my @retrdata = @$retrdata_ref;
      #my $insert = eval { $adhoclines }; say  "\$insert: $insert";
      my $printthis;
      if ( -e $retfile )
      {
        say  `rm -f $retfile` ;
      }

      {
        if ( $themereport eq "radent" )
        {
          $printthis =
"cd $thisto/cfg
res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
d
a
>
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

          #print  "
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n $printthis";

          if ( ($exeonfiles eq "y") or ( $dowhat{newretrieve} eq "y" ) )
          {

            say  "#Retrieving $themereport results.";
            print `$printthis`;
            say  "$printthis";
          }
        }
        elsif ( $themereport eq "radabs" )
        {
"cd $thisto/cfg
res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
d
c
>
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

        #print  "
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n $printthis";

          if ( ($exeonfiles eq "y") or ( $dowhat{newretrieve} eq "y" ) )
          {

            say  "#Retrieving $themereport results.";
            print `$printthis`;
            say  "$printthis";
          }
        }
        elsif ( $themereport eq "airtemp" )
        {
          $printthis =
"cd $thisto/cfg
res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
b
e
>
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

        #print  "
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n $printthis";

          if ( ( $exeonfiles eq "y" ) or ( $dowhat{newretrieve} eq "y" ) )
          {

            say  "#Retrieving $themereport results.";
            print `$printthis`;
            say  "$printthis";
          }
        }
        elsif ( $themereport eq "radtemp" )
        {
          $printthis =
"cd $thisto/cfg
res -file $resfile -mode script<<TTT

3
$retrdata[0]
$retrdata[1]
$retrdata[2]
c
g
b
e
>
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

        #print  "
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n$printthis";

          if ( ( $exeonfiles eq "y" ) or ( $dowhat{newretrieve} eq "y" ) )
          {

            say  "#Retrieving $themereport results.";
            print `$printthis`;
            say  "$printthis";
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

        #print  "
#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", simulation period $counttheme, retrieve period $countreport\n $printthis";

            if ( ( $exeonfiles eq "y" ) or ( $dowhat{newretrieve} eq "y" ) )
            {

              say  "#Retrieving $themereport results.";
              print `$printthis`;
            }
          }
        }
      }
      
      say  "IN RETRIEVE \$countinstance $countinstance";

     if ( !@{ $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool} } )
      {
        @{ $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool} } = ();
      }
      @{ $dirfiles{resfiles} } = @{ $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool} };
      
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
          my $howmuch = $datarep{howmuch};
          my $where = $datarep{where};
          my $what = $datarep{what};

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

                #open( RETLIST, ">>$retlist"); # or die;

                #open( RETBLOCK, ">>$retblock"); # or die;

                my $reportdata_ref = $reportdata_ref_ref->[$countreport];
                @repdata = @$reportdata_ref; #say  "HERE REPDATA: " . dump( @repdata );

                
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
                  my $howmuch = $datarep{howmuch};
                  my $where = $datarep{where};
                  my $what = $datarep{what};
                  
                  say  "IN RETRIEVE2 \$countinstance $countinstance";

                  $dirfiles{retstruct}{$countcase}{$countblock}{$countinstance}{$counttheme}{$countreport}{$countitem}{$counttool} = $retfile;
                  #print RETBLOCK "$retfile\n";

                  if ( not ( $retfile ~~ @{ $dirfiles{retcases} } ) )
                  {
                    push ( @{ $dirfiles{retcases} }, $retfile );
                    #say RETLIST "$retfile";
                  }  @miditers = Sim::OPT::washn( @miditers );
                  
                  
                  say  "IN RETRIEVE3 \$countinstance $countinstance";

                  if ( not ( $retfile ~~ @{ $dirfiles{notecases}{$countcase}{$countblock}{$counttool}{$countinstance} } ) )
                  {
                    if ( !@{ $dirfiles{notecases}{$countcase}{$countblock}{$counttool}{$countinstance} } )
                    {
                      @{ $dirfiles{notecases}{$countcase}{$countblock}{$counttool}{$countinstance} } = ();
                    }
                    push ( @{ $dirfiles{notecases}{$countcase}{$countblock}{$counttool}{$countinstance} } ,
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
                        howmuch => $howmuch,
                        where => $where,
                        what => $what
                        #adhoclines => $adhoclines,
                      } );
                  }

                  unless ( $dowhat{inactivateres} eq "y" )
                  {
                    say  "#Retrieving results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep for tool $tooltype. Instance $countinstance: going to write $retfile.\ ";

                    if ( ( $themereport eq "temps" ) or ( $themereport eq "surftemps" ) )
                    {
                       retrieve_temperatures_results( $result, $resfile, $shortresfile, $thisto, \@retrdata, $reporttitle, $themereport, $counttheme, $countreport, $retfile );
                    }
                    elsif ( $themereport eq "comfort"  )
                           #}
           					{
                      retrieve_comfort_results( $result, $resfile, $shortresfile, $thisto, \@retrdata, $reporttitle, $themereport, $counttheme, $countreport, $retfile );
                    }
                    elsif ( ( ( $themereport eq "loads" ) or ( $themereport eq "tempsstats"  ) or  ( $themereport eq "dhs"  ) or ( $themereport eq "surfflow"  )) )
                    {
                      #say  "IN NEWRETRIEVE \$result $result, \$resfile $resfile, $shortresfile. \@retrdata @retrdata, \$reporttitle $reporttitle, \$themereport $themereport, \$counttheme $counttheme, \$countrep$shortresfile, ort $countreport, \$retfile $retfile, \$semaphorego1 $semaphorego1, \$semaphorego2 $semaphorego2, \$semaphorestop1 $semaphorestop1, \$semaphorestop2 $semaphorestop2, \$textpattern $textpattern, \$afterlines $afterlines, \$howmuch $howmuch, \$where $where, \$what $what";
                      retrieve_stats_results( $result, $resfile, $shortresfile, $thisto, \@retrdata, $reporttitle, $themereport, $counttheme,
                            $countreport, $retfile, $semaphorego1, $semaphorego2, $semaphorestop1, $semaphorestop2, $textpattern, $afterlines, $howmuch, $where, $what );
                    }
                    elsif ( ( $themereport eq "radent" ) or ( $themereport eq "radabs" ) or ( $themereport eq "airtemp" ) or ( $themereport eq "radtemp" ) or ( $themereport eq "restemp" ) )
                    {

                      retrieve_adhoc( $result, $resfile, $shortresfile, $thisto, \@retrdata, $reporttitle, $themereport, $counttheme,
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

          @{ $dirfiles{retfiles} } = @{ $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool} };
          $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool}  = $dirfiles{simstruct}{$countcase}{$countblock}{$countinstance}{$counttool} ;
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

                #open( RETLIST, ">>$retlist"); # or die;
                #open( RETBLOCK, ">>$retblock"); # or die;

                my $reportdata_ref = $reportdata_ref_ref->[$countreport];
                @repdata = @$reportdata_ref;
                @{ $dirfiles{retcases} } = uniq( @{ $dirfiles{retcases} } );
                my $retfile = $resfile;
                if ( not ($retfile ~~ @{ $dirfiles{retcases} } ) )
                {
                  push ( @{ $dirfiles{retcases} }, $retfile );
                  #say RETLIST "$retfile";
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

                  #print RETBLOCK "$retfile\n";

                  if ( !@{ $dirfiles{notecases}{$countcase}{$countblock}{$counttool}{$countinstance} } )
                  {
                    @{ $dirfiles{notecases}{$countcase}{$countblock}{$counttool}{$countinstance} } = ();
                  }
                  push ( @{ $dirfiles{notecases}{$countcase}{$countblock}{$counttool}{$countinstance} } ,
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
                  say  "IN RETRIEVE WORKING FOR \$resfile $resfile at iteration $countinstance";
                  $countitem++;
                }
              }
              else
              {
                say  "A RESULT FILE NAMED $resfile DOES NOT EXIST. EXITING.";
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
  #print  "rm -f $mypath/*.par\n";
  close OUTFILE;
  close TOFILE;
  #close RETLIST;
  #close RETBLOCK;
  

  if ( $dowhat{neweraseres} eq "y" )
  {
    my $flfile = $resfile;
    $flfile =~ s/\.res/\.fl/ ;
    if ( -e $resfile )
    {
      say  `rm -f $resfile` ;
    }

    if ( -e $flfile )
    {
      say  `rm -f $flfile` ;
    }
  }

  return ( \%dirfiles );
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
  my $winline;
  my @winbag;
  my $instant;

	if ( $tofile eq "" )
	{
		$tofile = "./report.txt";
	}


  say  "\nNow in Sim::OPT::Report::newreport\n";

  my %dt = %{ $_[0] };
  

  my %dirfiles = %{ $dt{dirfiles} };
  my $resfile = $dt{resfile}; #say  "BEGINNING REPORT: RESFILE $resfile";
  my $flfile = $dt{flfile};
  my %vehicles = %{ $dt{vehicles} };
  my $precious = $dt{precious};
  my %inst = %{ $dt{inst} };



  my %dowhat = %{ $dt{dowhat} };
  my $postproc = $dt{postproc};
  #my $csim = $dt{csim};

  
  my %d = %{ $dt{instance} };

  my $countcase = $d{countcase};
  my $countblock = $d{countblock};
  my %incumbents = %{ $d{incumbents} }; ######
  my $countinstance = $d{instn};

  my $c = $d{c};
  my $fire = $d{fire};
  my $stamp = $d{stamp};

  my @varnumbers = @{ $d{varnumbers} };
  @varnumbers = Sim::OPT::washn( @varnumbers );
  my @miditers = @{ $d{miditers} };
  @miditers = Sim::OPT::washn( @miditers );
  my @sweeps = @{ $d{sweeps} };

  my @winneritems = @{ $d{winneritems} };
  my $countvar = $d{countvar};
  my $countstep = $d{countstep};

  my %to = %{ $d{to} };
  my $thisto = $to{to};

  my $cleanto = $inst{$thisto};
  my $is = $d{is};
  my $double;

  if ( !$dirfiles{repfile} )
  {
    $dirfiles{repfile} = "$mypath/$file-report-$countcase-$countblock.csv";
  }
  my $repfile = $dirfiles{repfile}; say  "IN REPORT FROM DIRFILES \$repfile $repfile";


  if ( $fire eq "y" )
  {
    $double = $repfile;
    $repfile = $repfile . "-fire-$stamp.csv";
  }

  my $origin = $d{origin};
  my $from = $origin;

  my $c = $d{c};

	my @blockelts = @{ $d{blockelts} };

  my @blocks = @{ $d{blocks} };
  my %varnums = %{ $d{varnums} };
  my %mids = %{ $d{mids} };

  my $varnumber = $countvar; ###########################!!!
  my $stepsvar = $varnums{$countvar}; ;


  my $direction = ${$dowhat{direction}}[$countcase][$countblock]; #NEW
  my $precomputed = $dowhat{precomputed};
  my @takecolumns = @{ $dowhat{takecolumns} }; #NEW
  #say  "HERE IN NEWREPORT \@_: " . dump( @_ );

  my ( @repfilemem, @linecontent, @convey );
  $" = " ";

  my $bring;

  say  "#Processing reports for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", instance " . ($countinstance + 1);

  #open( REPLIST, ">>$replist" ) or die( "$!" );
  #open( REPBLOCK, ">>$repblock" ) or die( "$!" );

  my $divert;
  if ( $dirfiles{launching} eq "y" )
  {
    say  "YES.";
    $divert = $repfile . ".revealnum.csv";
    open( DIVERT, ">>$divert") or die "Can't open $repfile $!";
  }
  
  if ( $dowhat{dumpfiles} eq "y" )
  {
    open( REPFILE, ">>$repfile") or die "Can't open $repfile $!";
  }
  
  @{ $dirfiles{repcases} } = uniq( @{ $dirfiles{repcases} } );

  #say REPBLOCK "$repfile";
  if ( not ( $repfile ~~ @{ $dirfiles{repcases} } ) )
  {
    push ( @{ $dirfiles{repcases} }, $repfile );
    #say REPLIST "$repfile";
  }
  
  if ( not ( $repfile ~~ @{ $dirfiles{repstruct}{$countcase}{$countblock} } ) )
  {
    if ( !@{ $dirfiles{repstruct}{$countcase}{$countblock} } )
    {
      @{ $dirfiles{repstruct}{$countcase}{$countblock} } = ();
    }
    push ( @{ $dirfiles{repstruct}{$countcase}{$countblock} }, $repfile );
  }
  my $signalnewinstance = 1;

  #say  "RELAUNCHED IN NEWREPORT WITH INST " . dump( %inst );
  #say  "PROBING THE EXISTANCE OF $repfile";

  #say  "FIRE: $file";



  if ( ( ( $fire eq "y" ) or ( $dowhat{reportbasics} eq "y" ) ) and ( $precomputed eq "" ) )
  {
    my @hfiles = @{ $dowhat{helperfiles} };
    my @hpatterns = @{ $dowhat{helperpatterns} };
    my $c = 0;
    my $result = "$file" . "_" . "$is,";
    foreach my $hfile ( @hfiles )
    {
      my $hpattern = $hpatterns[$c];
      $hfile = "$resfile" . "-$hfile";
      #say  "CHECKING \$hfile $hfile";

      open( HFILE, "$hfile" ) or die;
      my @lines = <HFILE>;
      close HFILE;
      #say  "CHECKING HPATTERN $hpattern";
      foreach my $line ( @lines )
      {
        chomp $line;
        $line =~ s/^(\s+)//;
        $line =~ s/^ +//;

        ###if ( $line =~ /$hpattern/ ) ###CHANGED
        if ( $line =~ /$hpattern/ )
        { #say  "CHECK LINE-$line";
          chomp $line;

          $line =~ s/:\s/:/g;
          $line =~ s/(\s+)/ /g;
          $line =~ s/ /,/g; #say  "CHECK TREATEDLINE-$line";
          $result = $result . "$line,"; #say  "CHECK \$result-$result";
        }
      }
      $c++;
    }

    $result =~ s/,$// ;

    if ( $fire eq "y" )
    {
      if ( $dowhat{dumpfiles} eq "y" )
      {
        open( REPFILE, ">$repfile" );
      }
    }
    elsif ( $dowhat{reportbasics} eq "y" )
    {
      if ( $dowhat{dumpfiles} eq "y" )
      {
          open( REPFILE, ">>$repfile" );
      }
    }

    print REPFILE "$result\n";
    close REPFILE;

    open ( REPFILE, ">>$double" );
    print REPFILE "$result\n";
    close REPFILE;
  }
  elsif ( ( ( $fire eq "" ) or ( $dowhat{reportbasics} eq "" ) ) and ( $precomputed eq "" ) ) #NEW, TAKE CARE.###########################
  {
    my $numberof_simtools = scalar( keys %{ $dowhat{simtools} } );
    my $counttool = 1;
    while ( $counttool <= $numberof_simtools )
    {
      my $skip = $vals{$countvar}{$counttool}{skip};
      if ( not ( eval ( $skipsim{$counttool} )))
      {
        say  "IN REPORT \$countinstance $countinstance";
        my $tooltype = $dowhat{simtools}{$counttool};
        
        foreach $ret_ref ( @{ $dirfiles{notecases}{$countcase}{$countblock}{$counttool}{$countinstance} } )
        {
          %retitem = %$ret_ref;
          my $retfile = $retitem{retfile}; say  "IN NEWREPORT 1 \$retfile $retfile";
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
            say  "IN REPORT2 \$countinstance $countinstance";

            if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
            {
              @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
            }
            push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, "$retfile " );
            $signalnewinstance--;
          }

          my ( $semaphore1, $semaphore2 );

          if ( -e $retfile )
          { say  "#Inspecting results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", instance " . ($countinstance + 1) . ", file $retfile, to report $themereport." ;
            say  "IN NEWREPORT 2 \$retfile $retfile";
            open( RETFILE, "$retfile" ) or die( "$!" );
            my @lines = <RETFILE>;
            close RETFILE;

            my $countline = 0;
            my $signalhit = 0;
            my $foundhit = 0;
            my $countlin = 0;
            my $countli = 0;

	          if ( $dowhat{simplifiedreport} eq "y" )
            {
	            say  "EXECUTING ON simplifiedreport. Now looking for _ $textpattern _ in $retfile.";
	          }

            foreach my $line ( @lines )
            {
              chomp $line;

              if ( $dowhat{simplifiedreport} eq "y" )
              {
                my $thisline = $line;
                $thisline =~ s/^(\s+)//;
                $thisline =~ s/(^ +)//;

                if ( $thisline =~ /^$textpattern/ )
                {
	                chomp $thisline;

                  $thisline =~ s/:\s/:/g;
                  $thisline =~ s/(\s+)/ /g;
                  $thisline =~ s/ /,/g;
		              print REPFILE "$thisto,$thisline,";
		              print  "SIMPLIFIEDREPORT: $thisto,$thisline,";
		            }
              }

	            $line =~ s/^(\s+)//;
              $line =~ s/:\s/:/g;
              $line =~ s/(\s+)/ /g;
              my @elts = split( " ", $line );
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
                  chomp( $line );
                  if ( $foundhit == 0 )
                  {
                    say  "IN REPORT3 \$countinstance $countinstance";
                    unless ( $reportstrategy eq "new" )
                    {
                      if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
                      {
                        @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
                      }
                      push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, "$line" );
                    }
                    else
                    { say  "NEWSTRATEGY";
                      if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
                      {
                        @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
                      }
                      push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, "$elt" );
                    }
                  }
                  else
                  {
                    say  "IN REPORT4 \$countinstance $countinstance";
                    unless ( $reportstrategy eq "new" )
                    {
                      if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
                      {
                        @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
                      }
                      push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, $line );
                    }
                    else
                    { say  "NEWSTRATEGY";
                      push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, $elt );
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
                        if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
                        {
                          @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
                        }
                        push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, "$line" );
                      }
                      else
                      {
                        if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
                        {
                          @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
                        }
                        push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, "$elt" );
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
                              if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
                              {
                                @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
                              }
                              push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, "$line" );
                            }
                            else
                            {
                              if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
                              {
                                @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
                              }
                              push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, "$elt" );
                            }
                          }
                          else
                          {
                            unless ( $reportstrategy eq "new" )
                            {
                              if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
                              {
                                @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
                              }
                              push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, $line );
                            }
                            else
                            {
                              if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
                              {
                                @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
                              }
                              push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, $elt );
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
            say  "THERE IS NO RESULT FILE $retfile. Quitting.";
          }
        }
      }
      $counttool++;
    }

    unless ( $dowhat{inactivateret} eq "y" )
    {
      my $string;
      my $count = 0;
      say  "IN REPORT5 \$countinstance $countinstance";
      foreach my $thing ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
      { 
        chomp $thing; 
        $thing =~ s/\s+/,/g ; #say  "IN REPORT \$thing $thing ";
        if ( $count == 0 )
        { 
          $thing =~ s/$mypath\/// ; #say  "IN REPORT MODthing $thing "; say  "IN REPORT \$mypath $mypath "; 
          my ( $head ) = $thing =~ /^\Q$file\E_([^\/]+)(?:\/|$)/; #say  "IN REPORT \$head $head ";
          my $newhead = $inst{$head}; #say  "IN REPORT \$newhead $newhead ";
          if ( $newhead ne "" )
          {
            $newhead = $newhead . "__"; #say  "IN REPORT \$newhead $newhead ";
            my $filend = $file . "_" . $head ;
            $thing =~ s/^$filend/$newhead/ ; #say  "IN REPORT NEWthing $thing ";
          }
        }
        push ( @winbag, $thing );

        $string = $string . $thing;
        print REPFILE $thing;
        
        unless ( $count == $#{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
        {
          $string = $string . ",";
          print REPFILE ",";
        }

        if ( $dirfiles{launching} eq "y" )
        {
          print DIVERT $thing;
          unless ( $count == $#{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
          {
            print DIVERT ",";
          }
        }
        $count++;
      }
      
      print REPFILE "\n";
      if ( $dirfiles{launching} eq "y" )
      {
        print DIVERT "\n";
      }
      say  "#Reporting results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep. Instance $countinstance: writing $repfile. ";
    }
  } #END NEW. TAKE CARE.
  elsif ( $precomputed ne "" ) ############################NEW. END. TAKE CARE.
  {
    my @precomputeds;
    open ( PRECOMPUTED, "$precomputed" ) or die;
    @precomputeds = <PRECOMPUTED>;
    close PRECOMPUTED;

    my $touse = $is; ### TAKE CARE!

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

        if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
        {
          @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
        }
        push ( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} }, $line );
        push( @box, $line );
        $winline = $line;

        last;
      }
    }
    @box = uniq( sort( @box ) );
    foreach my $el ( @box )
    {
      say REPFILE $el;
      if ( $dirfiles{launching} eq "y" )
      {
        say DIVERT $el;
      }
    }
    say  "#Reporting results for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ", parameter $countvar at iteration $countstep. Instance $countinstance: writing $repfile. ";
  }
  close REPFILE;

  if ( $dirfiles{launching} eq "y" )
  {
    close DIVERT;
  }
  close TOFILE;
  close OUTFILE;

  if ( $dowhat{neweraseret} eq "y" )
  {
    `rm -f $mypath/*.grt` ;
    #print  "rm -f $mypath/*.grt";
  }

  if ( ( $dowhat{dumpfiles} eq "y" ) and (not( -e $repfile ) ) )
  {
    die;
  }
  

  if ( $dirfiles{launching} eq "y" )
  {
    say  "JUMPING";
    next;
  }


  say  "IN REPORT \@{ \$dirfiles{mergestruct}{\$countcase}{\$countblock}{\$countinstance} } " . dump( @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } );
  
  if ( !@{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } )
  {
    @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} } = ();
  }
  my @elts = @{ $dirfiles{mergestruct}{$countcase}{$countblock}{$countinstance} };
  my @bag;
  foreach my $elt ( @elts )
  {
    $elt =~ s/,?//;
    $elt =~ s/,?//;
    push( @bag, $elt );
  }
  my $newln = join( ",", @bag );
  
  my $rid = Sim::OPT::instid( $newln, $file ); say  "IN REPORT \$countblock $countblock \$rid " . dump( $rid );# NOT $repfile
  if ( defined($rid) and $rid ne "" )
  {
    $dirfiles{reps}{$rid} = $newln; say  "IN REPORT  \$dirfiles{reps}{\$rid} \$dirfiles{reps}{$rid} " . dump( $dirfiles{reps2}{$rid} );# NOT $repfile
    
    if ( !@{ $dirfiles{repsblocks}{$countcase}{$countblock} } )
    {
      @{ $dirfiles{repsblocks}{$countcase}{$countblock} } = ();
    }
    push ( @{ $dirfiles{repsblocks}{$countcase}{$countblock} }, $newln ); #!!!!!

    $dirfiles{repsingles}{$countcase}{$countblock}{$countinstance} = $newln; #!!!!!
    
    $instant = $newln; #!!!!!
    $dirfiles{instant} = $newln; #!!!!!
  }


  if ( $precious eq "" )
  {
    return ( \%dirfiles, $instant );
  }
  else
  {
    if ( $precomputed eq "" )
    {
      #say  "RETURNING $newln";
      #$dirfiles{instant} = $newln;
      say  "RETURNING $winbag[-1]";
      $dirfiles{instant} = $winbag[-1];
      return ( \%dirfiles, $instant );
    }
    else
    {
      chomp $winline;
      $winline =~ s/(\s+)$// ;
      $winline =~ s/(,+)$// ;
      my @elts = split( ",", $winline );
      say  "RETURNING $elts[-1]";
      $dirfiles{instant} = $elts[-1];
      return ( \%dirfiles, $instant );
    }
  }
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

This module is dual-licensed, open-source and proprietary. The open-source distribution is available on CPAN (https://metacpan.org/dist/Sim-OPT ). A proprietary distribution, including additional modules (OPTcue), is available from the author’s website (https://sites.google.com/view/bioclimatic-design/home/software ).

=head2 EXPORT

"retrieve" "report".

=head1 SEE ALSO

Annotated examples can be found packed in the "optw.tar.gz" file in "examples" directory in this distribution.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
