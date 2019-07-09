package Sim::OPT::Descend;
# Copyright (C) 2008-2017 by Gian Luca Brunetti and Politecnico di Milano.
# This is the module Sim::OPT::Descend of Sim::OPT, a program for detailed metadesign managing parametric explorations through the ESP-r building performance simulation platform and performing optimization by block coordinate descent.
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
use Storable qw(lock_store lock_nstore lock_retrieve dclone);
use Data::Dump qw(dump);
use Data::Dumper;
use feature 'say';
use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Sim;
use Sim::OPT::Report;
use Sim::OPT::Takechance;
use Sim::OPT::Interlinear;


$Data::Dumper::Indent = 0;
$Data::Dumper::Useqq  = 1;
$Data::Dumper::Terse  = 1;

no strict;
no warnings;

@ISA = qw(Exporter); # our @adamkISA = qw(Exporter);
#%EXPORT_TAGS = ( DEFAULT => [qw( &opt &prepare )]); # our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#@EXPORT   = qw(); # our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( descend prepareblank ); # our @EXPORT = qw( );

$VERSION = '0.137'; # our $VERSION = '';
$ABSTRACT = 'Sim::OPT::Descent is an module collaborating with the Sim::OPT module for performing block coordinate descent.';

#########################################################################################
# HERE FOLLOWS THE CONTENT OF "Descend.pm" - Sim::OPT::Descend
##############################################################################

sub descend
{
  $configfile = $main::configfile;
  %vals = %main::vals;
  #@pinmiditers = @main::pinmiditers;

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

  #open( OUTFILE, ">>$outfile" ) or die "Can't open $outfile: $!";
  #open( TOFILE, ">>$tofile" ) or die "Can't open $tofile: $!";
  $tee = new IO::Tee(\*STDOUT, ">>$tofile"); # GLOBAL ZZZ
  say $tee "\n#Now in Sim::OPT::Descend.\n";
  #say $tee "IN ENTRY DESCEND4 \$file : " . dump( $file );

  %simtitles = %main::simtitles;
  %retrievedata = %main::retrievedata;
  @keepcolumns = @main::keepcolumns;
  @weights = @main::weights;
  @weightsaim = @main::weightsaim;
  @varthemes_report = @main::varthemes_report;
  @varthemes_variations = @vmain::arthemes_variations;
  @varthemes_steps = @main::varthemes_steps;
  @rankdata = @main::rankdata; # CUT ZZZSim::OPT::
  @rankcolumn = @main::rankcolumn;
  %reportdata = %main::reportdata;
  @report_loadsortemps = @main::report_loadsortemps;
  @files_to_filter = @main::files_to_filter;
  @filter_reports = @main::filter_reports;
  @base_columns = @main::base_columns;
  @maketabledata = @main::maketabledata;
  @filter_columns = @main::filter_columns;
  %vals = %main::vals;

  my %dt = %{ $_[0] };
  my @instances = @{ $dt{instances} }; #say $tee "IN ENTRY DESCEND \@instances : " . dump( @instances );
  my %dirfiles = %{ $dt{dirfiles} };

  my @simcases = @{ $dirfiles{simcases} }; #say $tee "\@simcases: " . dump( @simcases );
  my @simstruct = @{ $dirfiles{simstruct} }; #say $tee "\@simstruct: " . dump( @simstruct );
  my @morphcases = @{ $dirfiles{morphcases} };
  my @morphstruct = @{ $dirfiles{morphstruct} };
  my @retcases = @{ $dirfiles{retcases} };
  my @retstruct = @{ $dirfiles{retstruct} };
  my @repcases = @{ $dirfiles{repcases} };
  my @repstruct = @{ $dirfiles{repstruct} }; #say $tee "IN DESCEND \@repstruct: " . dump(@repstruct);
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

  my $exitname = $dirfiles{exitname};

  say $tee "IN ENTRY DESCEND3  \$dirfiles{starsign} " . dump( $dirfiles{starsign} );

  my %d = %{ $instances[0] }; #say $tee "IN ENTRY DESCEND3 \%d : " . dump( \%d );
  my $countcase = $d{countcase}; #say $tee "IN ENTRY DESCEND \$countcase : " . dump( $countcase );
  my $countblock = $d{countblock}; #say $tee "IN ENTRY DESCEND \$countblock : " . dump( $countblock );
  my %datastruc = %{ $d{datastruc} }; ######
  my @varnumbers = @{ $d{varnumbers} }; #say $tee "IN ENTRY DESCEND \@varnumbers : " . dump( @varnumbers );
  @varnumbers = Sim::OPT::washn( @varnumbers ); #say $tee "IN ENTRY DESCEND WASHED \@varnumbers : " . dump( @varnumbers );
  my @miditers = @{ $d{miditers} }; #say $tee "IN ENTRY DESCEND \@miditers : " . dump( @miditers );
  @miditers = Sim::OPT::washn( @miditers ); #say $tee "IN ENTRY DESCEND WASHED \@miditers : " . dump( @miditers );
  my @sweeps = @{ $d{sweeps} }; #say $tee "IN ENTRY DESCEND \@sweeps : " . dump( @sweeps );
  my @sourcesweeps = @{ $d{sourcesweeps} }; #say $tee "IN ENTRY DESCEND \@sourcesweeps : " . dump( @sourcesweeps );
  my @rootnames = @{ $d{rootnames} }; ######
  my @winneritems = @{ $d{winneritems} }; #say $tee "IN ENTRY DESCEND \@winneritems : " . dump( @winneritems );
  my $instn = $d{instn}; #say $tee "IN ENTRY DESCEND \$instn : " . dump( $instn );
  my %inst = %{ $d{inst} }; #say $tee "IN ENTRY DESCEND \%inst : " . dump( \%inst );
  my %dowhat = %{ $d{dowhat} }; ######

  my $skipfile = $vals{skipfile};
	my $skipsim = $vals{skipsim};
	my $skipreport = $vals{skipreport};

  if ( $countcase > $#sweeps )# NUMBER OF CASES OF THE CURRENT PROBLEM
  {
    if ( $dirfiles{checksensitivity} eq "yes" )
    {
      Sim::OPT::sense( $dirfiles{ordtot}, $mypath, $dowhat{objectivecolumn} );
    }
    exit(say $tee "3 #END RUN.");
  }

	my @blockelts = @{ $d{blockelts} }; #say $tee "IN ENTRY DESCEND \@blockelts : " . dump( @blockelts );

	my @blocks = @{ $d{blocks} }; #say $tee "IN ENTRY DESCEND \@blocks : " . dump( @blocks );
	my $toitem = Sim::OPT::getitem( \@winneritems, $countcase, $countblock ); #say $tee "IN12 ENTRY DESCEND \$toitem : " . dump( $toitem );
  $toitem = Sim::OPT::clean( $toitem, $mypath, $file ); #say $tee "IN12 ENTRY DESCEND \$toitem : " . dump( $toitem );
  my $from = Sim::OPT::getline( $toitem ); #say $tee "IN ENTRY DESCEND \$from : " . dump( $from );
	#say $tee "IN ENTRY DESCEND \$varnumbers[\$countcase]" . dump( $varnumbers[$countcase] );
  $from = Sim::OPT::clean( $from, $mypath, $file ); #say $tee "IN12 ENTRY DESCEND \$from : " . dump( $from );
  my $rootname = Sim::OPT::getrootname(\@rootnames, $countcase);
  $rootname = Sim::OPT::clean( $rootname, $mypath, $file ); #say $tee "IN12 ENTRY DESCEND \$rootname : " . dump( $rootname );
  my %varnums = %{ $d{varnums} }; #say $tee "IN ENTRY DESCEN \%varnums" . dump( %varnums );
  my %mids = %{ $d{mids} }; #say $tee "IN ENTRY DESCEND \%mids" . dump( \%mids );
  my %carrier = %{ $d{carrier} }; #say $tee "IN ENTRY DESCEND \%carrier" . dump( \%carrier );
  my $outstarmode = $dowhat{outstarmode};

  my ( $direction, $starorder );
  if ( $outstarmode eq "yes" )
  {
    $direction = ${$dowhat{direction}}[$countcase][$countblock];
    $starorder = ${$dowhat{starorder}}[$countcase][$countblock];
    if ( $direction eq "" )
    {
      $direction = ${$dowhat{direction}}[0][0];
    }
    if ( $starorder eq "" )
    {
      $starorder = ${$dowhat{starorder}}[0][0];
    }
  }
  else
	{
		$direction = $dirfiles{direction};
		$starorder = $dirfiles{starorder}; #say $tee "IN ENTRY DESCEND \$starorder " . dump( $starorder ); #NEW
		if ( $direction eq "" ){ $direction = ${$dowhat{direction}}[$countcase][$countblock]; }
		if ( $starorder eq "" ){ $starorder = ${$dowhat{starorder}}[$countcase][$countblock]; }
    if ( $direction eq "" )
    {
      $direction = ${$dowhat{direction}}[0][0];
    }
    if ( $starorder eq "" )
    {
      $starorder = ${$dowhat{starorder}}[0][0];
    }
	}
  #say $tee "IN ENTRY DESCEND \$direction : " . dump( $direction ); #NEW
  #say $tee "IN ENTRY DESCEND \$starorder : " . dump( $starorder ); #NEW

  my $precomputed = $dowhat{precomputed}; #say $tee "IN DESCEND \$precomputed: " . dump($precomputed); #NEW
  my @takecolumns = @{ $dowhat{takecolumns} }; #NEW


  my @starpositions;
  if ( $outstarmode eq "yes" )
  {
    @starpositions = @{ $dowhat{starpositions} };
  }
  else
  {
    @starpositions = @{ $dirfiles{starpositions} };
  }
  #say $tee "IN ENTRY DESCEND \@starpositions : " . dump( @starpositions );

  my $starnumber = scalar( @starpositions ); #say $tee "IN ENTRY DESCEND \$starnumber : " . dump( $starnumber );
  my $starobjective = $dowhat{starobjective}; #say $tee "IN ENTRY DESCEND \$starobjective : " . dump( $starobjective );
  my $objectivecolumn = $dowhat{objectivecolumn}; #say $tee "IN ENTRY DESCEND \$objectivecolumn : " . dump( $objectivecolumn );
  my $searchname = $dowhat{searchname}; #say $tee "IN ENTRY DESCEND \$searchname: " . dump( $searchname );

  my $countstring = $dirfiles{countstring}; #say $tee "IN ENTRY DESCEND \$countstring: " . dump( $countstring );
  my $starstring = $dirfiles{starstring}; #say $tee "IN ENTRY DESCEND \$starstring: " . dump( $starstring );
  my $starsign = $dirfiles{starsign}; #say $tee "IN ENTRY DESCEND \$starsign: " . dump( $starsign );
  my $totres = $dirfiles{totres}; #say $tee "IN ENTRY DESCEND \$totres: " . dump( $totres );
  my $ordres = $dirfiles{ordres}; #say $tee "IN ENTRY DESCEND \$ordres: " . dump( $ordres );
  my $tottot = $dirfiles{tottot}; #say $tee "IN ENTRY DESCEND \$tottot: " . dump( $tottot );
  my $ordtot = $dirfiles{ordtot}; #say $tee "IN ENTRY DESCEND \$ordtot: " . dump( $ordtot );

  my $confinterlinear = "$mypath/" . $dowhat{confinterlinear} ; say $tee "IN DESCEND5 \$confinterlinear: " . dump( $confinterlinear );

  my $repfile = $dirfiles{repfile}; #say $tee "IN DESCEND \$repfile: " . dump( $repfile );
  if ( not( $repfile ) ){ die; }
  my $sortmixed = $dirfiles{sortmixed}; #say $tee "IN DESCEND \$sortmixed: " . dump( $sortmixed );
  if ( not( $sortmixed ) ){ die; }

  my ( $entryfile, $exitfile, $orderedfile );
  my $entryname = $dirfiles{entryname}; #say $tee "IN DESCEND \$entryname: " .exit dump( $entryname );
  if ( $entryname ne "" )
  {
    $entryfile = "$mypath/" . "$file" . "_tmp_" . "$entryname" . ".csv";
  }
  else
  {
    $entryfile = "";
  } #say $tee "IN DESCEND \$entryfile: " . dump( $entryfile );

  my $exitname = $dirfiles{exitname}; #say $tee "IN DESCEND \$exitname: " . dump( $exitname );
  if ( $exitname ne "" )
  {
    $exitfile = "$mypath/" . "$file" . "_tmp_" . "$exitname" . ".csv";
  }
  else
  {
    $exitfile = "";
  } #say $tee "IN DESCEND \$exitfile: " . dump( $exitfile );

  my $orderedname = "$exitname" . "-ord";
  if ( $orderedname ne "" )
  {
    $orderedfile = "$mypath/" . "$file" . "_tmp_" . "$orderedname" . ".csv";
  }
  else
  {
    $orderedfile = "";
  } #say $tee "IN DESCEND \$orderedfile: " . dump( $orderedfile );


  #my $getpars = shift;
  #eval( $getpars );

  #if ( fileno (MORPHLIST)

  #my $getpars = shift;
  #eval( $getpars );


  sub plus1
  {
    my ( $val ) = @_;
    my $val = ( $val + 1 );
    return ( $val );
  }


  if ( $countcase > $#sweeps )# NUMBER OF CASES OF THE CURRENT PROBLEM
  {
    {
      Sim::OPT::sense( $dirfiles{ordtot}, $mypath, $dowhat{objectivecolumn} );
    }
    exit(say $tee "4 #END RUN.");
  }

  say $tee " \$repfile " . dump($repfile);
  if ( not( -e $repfile ) ){ die "There isn't \$repfile: $repfile"; };


  my $instance = $instances[0]; # THIS WOULD HAVE TO BE A LOOP HERE TO MIX ALL THE MERGECASES!!! ### ZZZ

  my %dat = %{$instance};
  my @winneritems = @{ $dat{winneritems} }; #say $tee "IN DESCEND \@winneritems " . dump(@winneritems);
  my $countvar = $dat{countvar}; #say $tee "IN DESCEND \$countvar " . dump( $countvar );
  my $countstep = $dat{countstep}; #say $tee "IN DESCEND \$countstep " . dump( $countstep );


  my $counthold = 0;

  my $skip = $dowhat{$countvar}{skip};

  my $word = join( ", ", @blockelts ); ###NEW

  my $varnumber = $countvar;
  my $stepsvar = $varnums{$countvar};

  say $tee "Descending into case " . ( plus1($countcase) ) . ", block " . ( plus1($countblock) ) . ".";

  my @columns_to_report = @{ $reporttempsdata[1] };
  my $number_of_columns_to_report = scalar(@columns_to_report);
  my $number_of_dates_to_mix = scalar(@simtitles);
  my @dates                    = @simtitles;

  my $cleanmixed = "$repfile-clean.csv";
  my $throwclean = $cleanmixed;
  $throwclean =~ s/\.csv//;
  my $selectmixed = "$throwclean-select.csv";

  my $remember;

  sub cleanselect
  {   # IT CLEANS THE MIXED FILE AND SELECTS SOME COLUMNS, THEN COPIES THEM IN ANOTHER FILE
    my ( $repfile, $cleanmixed, $selectmixed ) = @_;
    say $tee "Cleaning results for case " . ( plus1( $countcase ) ) . ", block " . ( plus1( $countblock ) ) . ".";
    open( MIXFILE, $repfile ) or die( "$!" ); #say $tee "dump(\$repfile IN SUB cleanselect): " . dump($repfile);
    my @lines = <MIXFILE>;
    close MIXFILE;

    open( CLEANMIXED, ">$cleanmixed" ) or die( "$!" );

    foreach my $line ( @lines )
    {
      #chomp $line;
      $line =~ s/\n/°/g;
      $line =~ s/\s+/,/g;
      $line =~ s/°/\n/g;
      if ( ( $line ne "" ) and ( $line ne " " ) and ( $line ne "\n" ) )
      {
        print CLEANMIXED "$line";
      }
    }
    close CLEANMIXED;

    # IT SELECTS SOME COLUMNS AND COPIES THEM IN ANOTHER FILE
    open( CLEANMIXED, $cleanmixed ) or die( "$!" );
    my @lines = <CLEANMIXED>;
    close CLEANMIXED;

    open( SELECTEDMIXED, ">$selectmixed" ) or die( "$!" );
    foreach my $line (@lines)
    {
      if ( ( $line ne "" ) and ( $line ne " " ) and ( $line ne "\n" ) )
      {
        #chomp $line;
        my @elts = split(/\s+|,/, $line);
        $elts[0] =~ /^(.*)_-(.*)/;
        my $touse = $1;
        $touse =~ s/$mypath\///;
        print SELECTEDMIXED "$touse,";
        my $countout = 0;
        foreach my $elmref (@keepcolumns)
        {
          my @cols = @$elmref;
          my $countin = 0;
          foreach my $elm (@cols)
          {
            if ( Sim::OPT::odd($countin) )
            {
              print SELECTEDMIXED "$elts[$elm]";
            }
            else
            {
              print SELECTEDMIXED "$elm";
            }

            if ( ( $countout < $#keepcolumns  ) or ( $countin < $#cols) )
            {
              print  SELECTEDMIXED ",";
            }
            else
            {
              print  SELECTEDMIXED "\n";
            }
            $countin++;
          }
          $countout++;
        }
      }
    }
    close SELECTEDMIXED;
  }

  if ( $precomputed eq "" )
  {
    cleanselect( $repfile, $cleanmixed, $selectmixed );
  }


  my $throw = $selectmixed;
  $throw =~ s/\.csv//;
  my $weight = "$throw-weight.csv";
  sub weight
  {
    my ( $selectmixed, $weight ) = @_;
    say $tee "Scaling results for case " . ( plus1( $countcase ) ). ", block " . ( plus1( $countblock ) ) . ".";
    open( SELECTEDMIXED, $selectmixed ) or die( "$!" );
    my @lines = <SELECTEDMIXED>;
    close SELECTEDMIXED;
    my $counterline = 0;
    open( WEIGHT, ">$weight" ) or die( "$!" );

    my @containerone;
    my @containernames;
    foreach my $line (@lines)
    {
      #chomp $line;
      $line =~ s/^[\n]//;
      my @elts = split( /\s+|,/, $line );
      my $touse = shift(@elts);
      my $countcol = 0;
      my $countel = 0;
      foreach my $elt (@elts)
      {
        if ( Sim::OPT::odd($countel) )
        {
          push ( @{$containerone[$countcol]}, $elt);
          $countcol++;
        }
        push (@containernames, $touse);
        $countel++;
      }
    }


    my @containertwo;
    my @containerthree;
    $countcolm = 0;
    my @optimals;
    foreach my $colref ( @containerone )
    {
      my @column = @{ $colref }; # DEREFERENCE

      if ( $weights[$countcolm] < 0 ) # TURNS EVERYTHING POSITIVE
      {
        foreach my $el (@column)
        {
          $el = ($el * -1);
        }
      }

      if ( max(@column) != 0) # FILLS THE UNTRACTABLE VALUES
      {
        push (@maxes, max(@column));
      }
      else
      {
        push (@maxes, "NOTHING1");
      }

      #print TOFILE "MAXES: " . Dumper(@maxes) . "\n";
      #print TOFILE "DUMPCOLUMN: " . Dumper(@column) . "\n";

      foreach my $el (@column)
      {
        my $eltrans;
        if ( $maxes[$countcolm] != 0 )
        {
          print TOFILE "\$weights[\$countcolm]: $weights[$countcolm]\n";
          $eltrans = ( $el / $maxes[$countcolm] ) ;
        }
        else
        {
          $eltrans = "NOTHING2" ;
        }
        push ( @{$containertwo[$countcolm]}, $eltrans) ; print TOFILE "ELTRANS: $eltrans\n";
      }
      $countcolm++;
    }
    #print TOFILE "CONTAINERTWO " . Dumper(@containertwo) . "\n";

    my $countline = 0;
    foreach my $line (@lines)
    {
      #chomp $line;
      $line =~ s/^[\n]//;
      my @elts = split(/\s+|,/, $line);
      my $countcolm = 0;
      foreach $eltref (@containertwo)
      {
        my @col =  @{$eltref};
        my $max = max(@col); #print TOFILE "MAX IN SUB weight: $max\n";
        my $min = min(@col); #print TOFILE "MIN IN SUB weight: $min\n";
        my $floordistance = ($max - $min);
        my $el = $col[$countline];
        my $rescaledel;
        if ( $floordistance != 0 )
        {
          $rescaledel = ( ( $el - $min ) / $floordistance ) ;
        }
        else
        {
          $rescaledel = 1;
        }
        if ( $weightsaim[$countcolm] < 0)
        {
          $rescaledel = ( 1 - $rescaledel);
        }
        push (@elts, $rescaledel);
        $countcolm++;
      }

      $countline++;

      my $counter = 0;
      foreach my $el (@elts)
      {
        print WEIGHT "$el";
        if ($counter < $#elts)
        {
          print WEIGHT ",";
        }
        else
        {
          print WEIGHT "\n";
        }
        $containerthree[$counterline][$counter] = $el;
        $counter++;
      }
      $counterline++;
    }
    close WEIGHT;
  }

  if ( $precomputed eq "" )
  {
    weight( $selectmixed, $weight ); #
  }

  my $weighttwo = "$throw-weighttwo.csv"; # THIS WILL HOST PARTIALLY SCALED VALUES, MADE POSITIVE AND WITH A CELING OF 1
  # say $tee "WEIGHTTWO: " . dump( $weighttwo );


  sub weighttwo
  {
    my ( $weight, $weighttwo ) = @_;
    say $tee "Weighting results for case " . ( plus1( $countcase ) ) . ", block " . ( plus1( $countblock ) ) .".";
    open( WEIGHT, $weight );
    my @lines = <WEIGHT>;
    close WEIGHT;
    open( WEIGHTTWO, ">$weighttwo" );
    if ( not( -e $weighttwo) ){ die; };
    my $counterline;
    foreach my $line (@lines)
    {
      #chomp $line;
      $line =~ s/^[\n]//;
      my @elts = split(/\s+|,/, $line);
      my $counterelt = 0;
      my $counterin = 0;
      my $sum = 0;
      my $avg;
      my $numberels = scalar(@keepcolumns);
      foreach my $elt (@elts)
      {
        my $newelt;
        if ($counterelt > ( $#elts - $numberels ))
        {
          #print TOFILE "ELT: $elt\n";
          $newelt = ( $elt * abs($weights[$counterin]) );
          #print TOFILE "ABS " . abs($weights[$counterin]) . "\n";
          $sum = ( $sum + $newelt ) ;
          $counterin++;
        }
        $counterelt++;
      }
      $avg = ($sum / scalar(@keepcolumns) );
      push ( @elts, $avg);

      my $counter = 0;
      foreach my $elt (@elts)
      {
        print WEIGHTTWO "$elt";
        if ($counter < $#elts)
        {
          print WEIGHTTWO ",";
        }
        else
        {
          print WEIGHTTWO "\n";
        }
        $counter++;
      }
      $counterline++;
    }
  }


  if ( $precomputed eq "" )
  {
    weighttwo( $weight, $weighttwo );
  }
  else #NEW. TAKE CARE!
  {
    $weighttwo = $repfile;############### TAKE CARE!
  }

  if ( not( -e $weighttwo) ){ die; };


  if ( not( ( $repfile ) and ( -e $repfile ) ) )
  {
    die( "$!" );
  }



  sub sortmixed
  {
    my ( $weighttwo, $sortmixed, $searchname, $entryfile, $exitfile, $orderedfile, $outstarmode, $instn, $inst_r ) = @_;
    say $tee "Processing results for case " . ( plus1( $countcase ) ) . ", block " . ( plus1( $countblock ) ) . ".";
    my %inst = %{ $inst_r }; #say $tee "IN SORTMIXED \%inst" . dump( \%inst );
    if ( $searchname eq "no" )###################################
    {
      open( WEIGHTTWO, $weighttwo ) or die( "$!" ); #say $tee "IN SORTMIXED \$weighttwo" . dump( $weighttwo );
      my @lines = <WEIGHTTWO>;
      close WEIGHTTWO;
      #say $tee "IN SORTMIXED \$direction" . dump( $direction );
      #say $tee "IN SORTMIXED \$starorder" . dump( $starorder );
      #say $tee "IN SORTMIXED \$objectivecolumn " . dump( $objectivecolumn );

      #if ( not( scalar( @{ $dowhat{starpositions} } ) == 0 ) )##############CHECK HERE. IT ONCE WAS.
      #{
      #  open( SORTMIXED, ">>$sortmixed" ) or die( "$!" );
      #}
      #else
      #{
      #  open( SORTMIXED, ">$sortmixed" ) or die( "$!" );
      #}
      #my ( @crypteds, @cleans );
      #foreach my $el ( %inst )
      #{
      #  push( @cleans, $el{cleanto} );
      #  push( @crypteds, $el{crypto} );
      #}
      #
      #foreach my $line ( @lines )
      #{
      #  #chomp $line;
      #  $line =~ s/\,+$//;
      #  $line =~ s/"//g;
      #
      #  my $counter = 0;
      #  foreach my $clean ( @cleans )
      #  {
      #    my $crypted = $crypteds{$counter};
      #    $line =~ s/$crypted/$clean/ ;
      #  }
      #}

      @lines = uniq( @lines );

      #say TOFILE "TAKEOPTIMA--dump(\@lines): " . dump(@lines);
      # NOTE: bugs to fix in "star" behav@winneritemsiour: 1) uniq reduces too much; 2) subsequent prepareblanks are longer and longer.

      my @sorted;
      if ( $direction ne "star" )
      {
        if ( $direction eq "<" )
        {
          @sorted = sort { (split( ',', $a ))[ $objectivecolumn ] <=> ( split( ',', $b ))[ $objectivecolumn ] } @lines;
        }
        elsif ( $direction eq ">" )
        {
          @sorted = sort { (split( ',', $b ))[ $objectivecolumn ] <=> ( split( ',', $a ))[ $objectivecolumn ] } @lines;
        }
      }
      elsif ( ( $direction eq "star" ) and ( $outstarmode eq "yes" ) )
      {
        if ( $starorder eq "<" )
        {
          @sorted = sort { (split( ',', $a))[ 0 ] <=> ( split( ',', $b))[ 0 ] } @lines;
        }
        elsif ( $starorder eq ">" )
        {
          @sorted = sort { (split( ',', $b))[ 0 ] <=> ( split( ',', $a))[ 0 ] } @lines;
        }
      }
      elsif ( ( $direction eq "star" ) and ( $outstarmode ne "yes" ) )
      {
        if ( $starorder eq "<" )
        {
          @sorted = sort { (split( ',', $a))[ $objectivecolumn ] <=> ( split( ',', $b))[ $objectivecolumn ] } @lines;
        }
        elsif ( $starorder eq ">" )
        {
          @sorted = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lines;
        }
      }

      open( SORTMIXED, ">$sortmixed" ) or die( "$!" ); #say $tee "OPENING SORTMIXED: " . dump( $sortmixed );
      if ( not( -e $sortmixed ) ){ die; };

      open( TOTRES, ">>$totres" ) or die;

      foreach my $line ( @sorted )
      {
        print SORTMIXED $line;
        print TOTRES $line;
        push ( @totalcases, $line );
      }
      close TOTRES;
      close SORTMIXED;

      #if ($numberelts > 0) { print SORTMIXED `sort -t, -k$numberelts -n $weighttwo`; }
      #my @sorted = sort { $b->[1] <=> $a->[1] } @lines;
      #sort { $a->[$#eltstemp] <=> $b->[$#eltstemp] }
      #map { [ [ @lines ] , /,/ ] }
      #foreach my $elt (@sorted)
      #{
      #  print $SORTMIXED "$elt";
      #}
      #if ($numberelts > 0) { print SORTMIXED `sort -n -k$numberelts,$numberelts -t , $weighttwo`; } ### ZZZ
      #########################################à
    }
    elsif ( $searchname eq "yes" )###################################à
    {
      my @theselines;
      if ( ( $weighttwo ne "" ) and ( -e $weighttwo ) )
      {
        open( WEIGHTTWO, $weighttwo ) or die( "$!" ); #say $tee "\$weighttwo" . dump( $weighttwo );
        @theselines = <WEIGHTTWO>;
        close WEIGHTTWO;
      }

      if ( $exitfile ne "" )
      {
        open( EXITFILE, ">>$exitfile" ) or die; #say $tee "IN DESCENT OPENING IN WRITING \$exitfile" . dump( $exitfile );
        foreach my $line ( @theselines )
        {
          print EXITFILE $line;
        }
        close EXITFILE;
      }

      my $thoselines;
      if ( ( $entryfile ne "" ) and ( -e $entryfile ) )
      {
        open( ENTRYFILE, "$entryfile" ) or die; say $tee "IN DESCENT OPENING \$entryfile" . dump( $entryfile );
        $thoselines = <ENTRYFILE>;
        close ENTRYFILE;
      }

      my @lines;
      push( @lines, @theselines, $thoselines );

      if ( ( $exitfile ne "" ) and ( -e $exitfile ) )
      {
        open( EXITFILE, "$exitfile" ) or die; #say $tee "IN DESCENT OPENING IN READING \$exitfile" . dump( $exitfile );
        @lines = <EXITFILE>;
        close EXITFILE;
      }

      foreach my $line ( @lines )
      {
        $line =~ s/\,+$//;
        $line =~ s/"//g;
      }

      my @sorted;
      if ( $direction ne "star" )
      {
        if ( $direction eq "<" )
        {
          @sorted = sort { (split( ',', $a))[ $objectivecolumn ] <=> ( split( ',', $b))[ $objectivecolumn ] } @lines;
        }
        elsif ( $direction eq ">" )
        {
          @sorted = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lines;
        }
      }
      elsif ( $direction eq "star" )
      {
        if ( $starorder eq "<" )
        {
          @sorted = sort { (split( ',', $a))[ 0 ] <=> ( split( ',', $b))[ 0 ] } @lines;
        }
        elsif ( $starorder eq ">" )
        {
          @sorted = sort { (split( ',', $b))[ 0 ] <=> ( split( ',', $a))[ 0 ] } @lines;
        }
      }

      open ( ORDEREDFILE, ">>$orderedfile" ) or die;
      open( TOTRES, ">>$totres" ) or die;

      foreach my $line ( @sorted )
      {
        print ORDEREDFILE $line;
        print TOTRES $line;
        push ( @totalcases, $line );
      }
      close TOTRES;
      close ORDEREDFILE;
    }#######################################################
    close SORTMIXED;
  } ### END SUB sortmixed

  if ( not( -e $weighttwo) ){ die; };
  if ( not( $sortmixed) ){ die; };
  sortmixed( $weighttwo, $sortmixed, $searchname, $entryfile, $exitfile, $orderedfile, $outstarmode, $instn, \%inst );




  sub metamodel
	{
    my ( $dowhat_r, $sortmixed, $file, $dirfiles_r, $blockelts_r, $carrier_r, $metafile,
      $direction, $starorder, $ordmeta, $varnums_r, $countblock ) = @_;
    my %dowhat = %{ $dowhat_r };

    if ( $dowhat{preprep} ne "" )
    {
      $sortmixed = $dowhat{preprep};
      unless ( -e $sortmixed )
      {
        die;
      }
    }

    if ( $dowhat{preprep} ne "" )
    {
      $sortmixed = $dowhat{preprep};
      unless ( -e $sortmixed )
      {
        die;
      }
    }

    my %dirfiles = %{ $dirfiles_r };
    my @blockelts = @{ $blockelts_r }; #say $tee " IN metamodel \@blockelts : " . dump( @blockelts );
    my %carrier = %{ $carrier_r };
    my %varnums = %{ $varnums_r };
    #say $tee " IN metamodel \$countblock : " . dump( $countblock );
    close SORTMIXED;

	  #my ( $dowhat_r, $sortmixed, $file, $dirfiles_r, $blockelts_r, $mids_r, $metafile, $direction, $starorder, $ordmeta ) = @_;
		#say $tee " IN metamodel \$dowhat{metamodel} : " . dump( $dowhat{metamodel} );
		if ( $dowhat{metamodel} eq "yes" ) # PART ON METAMODELS
		{
		  sub cleanres
		  {
		    my ( $sortmixed ) = @_;
		    open( ORDRES, "$sortmixed") or die;
		    my $cleanordres = $sortmixed . "_tmp_cleaned.csv";
		    my @lines = <ORDRES>;
	      close ORDRES;

	      open( CLEANORDRES, ">>$cleanordres" ) or die;
	      foreach my $line ( @lines )
	      {
	        $line =~ s/^$mypath\/$file// ;
	        $line =~ s/^_// ;
	        print CLEANORDRES $line;
	      }
	      close CLEANORDRES;
	      return( $cleanordres );
	    }


      sub prepareblank
	    {
	      my ( $varnums_r, $blankfile, $blockelts_r, $bag_r, $file, $carrier_r ) = @_;
	      my %varnums = %{ $varnums_r }; #say "IN prepareblank \%varnums : " . dump( \%varnums );
	      my @blockelts = ( sort { $a <=> $b } @{ $blockelts_r } ); #say "IN prepareblank1 \@blockelts : " . dump( @blockelts );
        my @bag = @{ $bag_r }; #say "IN prepareblank1 \@bag : " . dump( \@bag );
        my %carrier = %{ $carrier_r }; #say "IN prepareblank1 \%carrier : " . dump( \%carrier );
        open( BLANKFILE, ">$blankfile" ) or die;

        my @box = @{ Sim::OPT::toil( \@blockelts, \%varnums, $bag_r ) };
	      @box = @{ $box[-1] }; #say "IN prepareblank \@box : " . dump( @box );
	      my $integrated_r = Sim::OPT::integratebox( \@box, \%carrier, $file, \@blockelts ); #say "IN prepareblank \$integrated_r : " . dump( $integrated_r );

	      my @finalbox = @{ $integrated_r }; #say "IN PREPAREBLANK \@finalbox : " . dump( @finalbox );

        foreach my $el ( @finalbox )
	      {
	        say BLANKFILE $el->[0];
	      }
	      close BLANKFILE;
        return( \@finalbox )
	    }


      sub prepvarnums
      {
        my ( $varns_ref, $blockelts_r ) = @_;
        my %varns = %{ $varns_ref };
        my @blockelts = @{ $blockelts_r };
        foreach my $key ( sort ( keys %varns ) )
        {
          if ( not( $key ~~ @blockelts ) )
          {
            $varns{$key} = 1;
          }
        }
        return( %varns );
      }

      #say $tee " IN PREPAREBLANK FROM PREPVARNUMS \$dirfiles{varnumbershold}->[0] : " . dump( $dirfiles{varnumbershold}->[0] );
      my %varns;
      if ( $dirfiles{starsign} eq "yes ")
      {
        %varns = prepvarnums( $dirfiles{varnumbershold}->[0], \@blockelts ); #say $tee " IN PREPAREBLANK FROM PREPVARNUMS \%varns : " . dump( \%varns );
      #say $tee "TO PREPAREBLANK \%carrier : " . dump( \%carrier); say $tee "\@blockelts : " . dump( @blockelts );
      }
      else
      {
        %varns = prepvarnums( \%varnums, \@blockelts ); #say $tee " IN PREPAREBLANK FROM PREPVARNUMS \%varns : " . dump( \%varns );
      }

      my $cleanordres = cleanres( $sortmixed ); #say $tee "IN TAKEOPTIMA1 \$cleanordres : " . dump( $cleanordres );
	    my $blankfile = "$sortmixed" . "_tmp_blank.csv";
	    my $bit = $file . "_";
	    my @bag =( $bit );
	    prepareblank( \%varns, $blankfile, \@blockelts, \@bag, $file, \%carrier ) ;


      sub prepfile
      {
        my ( $blankfile, $prepblank, $cleanordres, $prepsort, $blockelts_r, $varnums_r, $carrier_r, $metafile ) = @_;
        my @blockelts = @{ $blockelts_r };
        my %varnums = %{ $varnums_r }; #say $tee "IN PREPFILE \%varnums " . dump( \%varnums );
        my %carrier = %{ $carrier_r }; #say $tee "IN PREPFILE \%carrier " . dump( \%carrier );

        my %modhs;
        my %torecovers;
        foreach my $el ( @blockelts )
        {
          foreach my $key ( sort ( keys( %varnums ) ) )
          {
            if ( not( $key ~~ @blockelts ) )
            {
              $modhs{$key} = $varnums{$key};
              $torecovers{$key} = $carrier{$key};
            }
          }
        }
        #say $tee "IN PREPFILE \%modhs " . dump( \%modhs );

        open( BLANKFILE, "$blankfile" ) or die;
        my @lines = <BLANKFILE>;
        close BLANKFILE;

        open( PREPBLANK, ">$prepblank" ) or die;
        foreach my $line ( @lines )
        {
          #say $tee "IN PREPFILE LINE BEFORE \$line $line";
          foreach my $key ( keys %modhs )
          {
            $line =~ s/$key-\d+/$key-$modhs{$key}/ ;
          }
          #say $tee "IN PREPFILE LINE AFTER \$line $line";
          print PREPBLANK $line;
        }
        close PREPBLANK;

        open( CLEANORDRES, "$cleanordres" ) or die;
        my @lines = <CLEANORDRES>;
        close CLEANORDRES;

        open( PREPSORT, ">$prepsort" ) or die;
        foreach my $line ( @lines )
        {
          #say $tee "IN PREPSORT LINE BEFORE \$line $line";
          foreach my $key ( keys %modhs )
          {
            $line =~ s/$key-\d+/$key-$modhs{$key}/ ;
          }
          #say $tee "IN PREPSORT LINE AFTER \$line $line";
          print PREPSORT $line;
        }
        close PREPSORT;

        return( %torecovers );
      }

      my $prepblank = $sortmixed . "_tmp_prepblank.csv";
      my $prepsort = $sortmixed . "_tmp_prepsort.csv";
      #say $tee "BEFORE PREPFILE \%carrier " . dump( \%carrier );
      #say $tee "BEFORE PREPFILE \%varnums " . dump( \%varnums );
      my %torecovers = prepfile( $blankfile, $prepblank, $cleanordres, $prepsort, \@blockelts, \%varnums, \%carrier, $metafile );
      #say $tee "FROM PREPFILE \%torecovers " . dump( \%torecovers );


      #say $tee "BEFORE jointwo \%varnums " . dump( \%varnums );
	    sub jointwo
	    {
	      my ( $prepsort, $prepblank, $prepfile ) = @_;
	      open( PREPBLANK, $prepblank ) or die;
	      my @blanklines = <PREPBLANK>;
        @blanklines = uniq( @blanklines );
	      close PREPBLANK;

	      open( PREPSORT, $prepsort ) or die;
	      my @ordlines = <PREPSORT>;
        @ordlines = uniq( @ordlines );
	      close PREPSORT;

	      open( PREPFILE, ">$prepfile" ) or die;

	      my @newarr;
	      foreach my $blankline ( @blanklines )
	      {
	        chomp $blankline;
	        my $signal = "no";
	        foreach my $ordline ( @ordlines )
	        {
	          chomp $ordline;
	          my @row = split( "," , $ordline );
	          if ( ( $row[0] =~ /$blankline/ ) or ( /$blankline/ =~ $row[0] ) )
	          {
	            say PREPFILE "$blankline" . "," . "$row[1]" ;
	            $signal = "yes";
	          }
	        }
	        if ( $signal eq "no" )
	        {
	          say PREPFILE $blankline ;
	        }
	      }
	      close PREPFILE;
	    }

      my $prepfile = $sortmixed . "_tmp_prepfile.csv";
	    jointwo( $prepsort, $prepblank, $prepfile ) ;

      my $rawmetafile = $metafile . "_tmp_raw.csv";
	    say $tee "ABOUT TO LAUNCH INTERLINEAR";
	    #say $tee "WITH, IN TAKEOPTIMA \$confinterlinear: " . dump($confinterlinear);
      #say $tee "WITH, IN TAKEOPTIMA \$prepfile: " . dump($prepfile);
	    #say $tee "WITH, IN TAKEOPTIMA \$metafile: " . dump($metafile);
	    #say $tee "WITH, IN TAKEOPTIMA \@blockelts: " . dump(@blockelts);
      #say $tee "WITH, IN TAKEOPTIMA \$countblock: " . dump($countblock);


      my @prepwelds = @{ $dowhat{prewelds} };
      my @parswelds = @{ $dowhat{parswelds} };
      my @weldsprepared;

      if ( scalar( @prepwelds ) > 0 )
      {
        my $c = 0;
        foreach my $weld ( @prepwelds )
        {
          unless ( -e $weld )
          {
            die;
          }
          my $prepared = $weld . ".weldprep.csv";
          push ( @weldsprepared, $prepared );

          $c++;
        }
      }

	    Sim::OPT::Interlinear::interlinear( $prepfile, $confinterlinear, $rawmetafile, \@blockelts, $tofile, $countblock );

      open( RAWMETAFILE, "$rawmetafile" ) or die;
      my @rawlines = <RAWMETAFILE>;
      close RAWMETAFILE;

      open( METAFILE, ">$metafile" ) or die;
      foreach my $line ( @rawlines )
      { #say $tee "CHECK. \%torecovers " . dump( %torecovers );
        foreach my $key ( keys %torecovers )
        {
          $line =~ s/$key-\d+/$key-$torecovers{$key}/ ;
        }
        print METAFILE $line;
      }
      close METAFILE;




	    open( METAFILE, "$metafile" ) or die "THERE IS NO METAFILE $metafile!\n";
	    my @totlines = <METAFILE>;
      @totlines = uniq( @totlines );
	    close METAFILE; #say $tee "IN TAKEOPTIMA OBTAINED TOTLINES: " . dump ( @totlines ) ;

	    if ( ( $direction eq "<" ) or ( $starorder eq "<" ) )
	    {
	      @sorted = sort { (split( ',', $a))[ 1 ] <=> ( split( ',', $b))[ 1 ] } @totlines;
	    }
	    elsif ( ( $direction eq ">" ) or ( $starorder eq ">" ) )
	    {
	      @sorted = sort { (split( ',', $b))[ 1 ] <=> ( split( ',', $a))[ 1 ] } @totlines;
	    } #say $tee "IN TAKEOPTIMA ORDERED TOTLINES IN \@sorted: " . dump( @sorted );

      @sorted = uniq( @sorted );

	    open( ORDMETA,  ">>$ordmeta" ) or die;
	    foreach my $ln ( @sorted )
	    {
	      print ORDMETA $ln;
	    }
	    close ORDMETA;
		}
	}  # END SUB metamodel
  #say $tee "HERE \%mids: " . dump( \%mids );


  sub takeoptima
  {
    my ( $sortmixed, $carrier_r, $blockelts_r, $searchname, $orderedfile, $direction, $starorder, $mids_r, $blocks_r,
    $totres, $objectivecolumn, $ordres, $starpositions_r, $countstring, $starnumber, $ordtot, $file, $ordmeta, $orderedfile,
        $dirfiles_r, $countcase, $countblock, $varnums_r ) = @_;
    my %carrier = %{ $carrier_r }; #say $tee "ENTRY TAKEOPTIMA:  \%carrier:" . dump( %carrier );
    my @blockelts = @{ $blockelts_r }; #say $tee "ENTRY TAKEOPTIMA: \@blockelts: " . dump( @blockelts );
    #my %mids = %{ $mids_r };
    my @blocks = @{ $blocks_r }; #say $tee "ENTRY TAKEOPTIMA: \@blocks: " . dump( @blocks );
    my @starpositions = @{ $starpositions_r }; #say $tee "ENTRY TAKEOPTIMA: \@starpositions: " . dump( @starpositions );
    my %dirfiles = %{ $dirfiles_r }; #say $tee "ENTRY TAKEOPTIMA: \%dirfiles: " . dump( %dirfiles );
    my %varnums = %{ $varnums_r }; #say $tee "ENTRY TAKEOPTIMA: \%varnums: " . dump( \%varnums );

    #say $tee "ENTRY TAKEOPTIMA: \$sortmixed: $sortmixed";
    #say $tee "ENTRY TAKEOPTIMA: \$direction: $direction";
    close SORTMIXED;
    my @lines;
    if ( $searchname eq "no" )
    {
      open( SORTMIXED, $sortmixed ) or die( "$!" );
      @lines = <SORTMIXED>;
      close SORTMIXED;
    }
    elsif ( $searchname eq "yes" )
    {
      open( ORDEREDFILE, $orderedfile ) or die( "$!" );
      @lines = <ORDEREDFILE>;
      close ORDEREDFILE;
    }

    my $winnerentry;
    if ( ( $direction eq ">" ) or ( ( $direction eq "star"  ) and ( $starorder eq ">"  ) ) )
    {
      $winnerentry = $lines[0]; #say $tee "DIRECTION > OR STAR IN SUB TAKEOPTIMA. \$winnerentry: " . dump($winnerentry);
    }
    elsif ( ( $direction eq "<" ) or ( ( $direction eq "star"  ) and ( $starorder eq "<"  ) ) )
    {
      $winnerentry = $lines[0]; #say $tee "DIRECTION < OR STAR IN SUB TAKEOPTIMA. \$winnerentry: " . dump($winnerentry);
    }
    elsif ( ( $direction eq "=" ) or ( ( $direction eq "star"  ) and ( $starorder eq "="  ) ) )
    {
      my $half = ( int( scalar( @lines ) / 2 )  );
      $winnerentry = $lines[ $half ];
    }
    chomp $winnerentry;

    my @winnerelms = split( /,/, $winnerentry );
    my $winneritem = $winnerelms[0];

    #my $addfile = $file . "_";
    #$winneritem =~ s/$mypath\/$addfile// ; say $tee "IN12 TAKEOPTIMA. \$winneritem: " . dump($winneritem);
    $winneritem =~ Sim::OPT::clean( $winneritem, $mypath, $file ); #say $tee "IN12 TAKEOPTIMA. \$winneritem: " . dump($winneritem);
    push ( @{ $datastruc{$closingelt} }, $winneritem );

    my $message;
    $message = "$mypath/attention.txt";

    open( MESSAGE, ">>$message");
    my $countelm = 0;
    foreach my $elm (@lines)
    {
      chomp $elm;
      my @lineelms = split( /\s+|,/, $elm );
      my $val = $lineelms[$objectivecolumn];
      my $case = $lineelms[0];
      {
        if ($countelm > 0)
        {
          if ( $val ==  $winnerval )
          {
            say MESSAGE "Attention. At case " . ( plus1( $countcase ) ) . ", block " . ( plus1( $countblock ) ) . "There is a tie between optimal cases. Besides case $winnerline, producing a compound objective function of $winnerval, there is the case $case producing the same objective function value. Case $winnerline has been used for the search procedures which follow.\n";
          }
        }
      }
      $countelm++;
    }
    close (MESSAGE);
    #say $tee "BEFORE PUSHING --->\@backvalues " . dump( @backvalues );

    push( @{ $datastruc{$word} }, $winnerline );  #say $tee "OBTAINED--->\@{ \$datastruc{\$word} } " . dump( @{ $datastruc{$word} } );


    #if ( $countblock == 0 )
    #{
    #  shift( @{ $winneritems[$countcase][$countblock] } );
    #}



    ################################################### STOP CONDITIONS!

    if ( $countblock == $#blocks )
    {
      #if ( $sourceblockelts[0] =~ />/ )
      #{
      #  $dirfiles{starsign} = "yes"; #say $tee "SETTING IN callblock: \$dirfiles{starsign} " . dump( $dirfiles{starsign} );
      #}

      #say $tee "IN CASE END."; say $tee "\$dirfiles{starsign} " . dump( $dirfiles{starsign} );
      if ( ( $dirfiles{starsign} eq "yes" ) or
    			( ( $dirfiles{random} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{latinhypercube} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{factorial} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{facecentered} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) ) ### BEGINNING OF THE PART ON STAR CONFIGURATIONS
      {
        #say $tee "IN CASE END AND STARSIGN.";
        #say $tee "NOT YET.";
        open( TOTRES, "$totres" ) or die;
        my @lins = <TOTRES>;
        close TOTRES;

        my @lins = uniq( @lins );
        my @sorted;
        if ( $direction ne "star" )
        {
          if ( $direction eq "<" )
          {
            @sorted = sort { (split( ',', $a))[ $objectivecolumn ] <=> ( split( ',', $b))[ $objectivecolumn ] } @lins;
          }
          elsif ( $direction eq ">" )
          {
            @sorted = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lins;
          }
          else
          {
            say $tee "THE OBJECTIVE IS NOT CLEAR IN THE \%dowhat PARAMETER OF THE CONFIGURATION FILE.";
          }
        }
        elsif ( $direction eq "star" )
        {
          if ( $starorder eq "<" )
          {
            @sorted = sort { (split( ',', $a))[ 0 ] <=> ( split( ',', $b))[ 0 ] } @lins;
          }
          elsif ( $starorder eq ">" )
          {
            @sorted = sort { (split( ',', $b))[ 0 ] <=> ( split( ',', $a))[ 0 ] } @lins;
          }
          else
          {
            say $tee "THE OBJECTIVE IS NOT CLEAR IN THE \%dowhat PARAMETER OF THE CONFIGURATION FILE.";
          }
        }


        open( ORDRES, ">>$ordres" ) or die;

        foreach my $lin ( @sorted )
        {
          print ORDRES $lin;
        }
        close ORDRES;


        if ( ( scalar( @starpositions ) > 0 ) and ( $countstring ) )
        {
          open( ORDRES, "$ordres" ) or die;
          my @ordlines = <ORDRES>;
          close ORDRES;

          open( TOTTOT, ">>$tottot" ) or die;
          foreach my $line ( @ordlines )
          {
            print TOTTOT $line;
          }
          close TOTTOT;

          if ( $countstring == $starnumber )
          {
            open( TOTTOT, "$tottot" ) or die;
            my @totlines = <TOTTOT>;
            close TOTTOT;


            my @lns = uniq( @totlines );
            my @sortedln;
            if ( $direction ne "star" )
            {
              if ( $direction eq "<" )
              {
                @sortedln = sort { (split( ',', $a))[ $objectivecolumn ] <=> ( split( ',', $b))[ $objectivecolumn ] } @lns;
              }
              elsif ( $direction eq ">" )
              {
                @sortedln = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lns;
              }
              else
              {
                say $tee "THE OBJECTIVE IS NOT CLEAR IN THE \%dowhat PARAMETER OF THE CONFIGURATION FILE.";
              }
            }
            elsif ( $direction eq "star" )
            {
              if ( $starorder eq "<" )
              {
                @sortedln = sort { (split( ',', $a))[ 0 ] <=> ( split( ',', $b))[ 0 ] } @lns;
              }
              elsif ( $starorder eq ">" )
              {
                @sortedln = sort { (split( ',', $b))[ 0 ] <=> ( split( ',', $a))[ 0 ] } @lns;
              }
              else
              {
                say $tee "THE OBJECTIVE IS NOT CLEAR IN THE \%dowhat PARAMETER OF THE CONFIGURATION FILE.";
              }
            }


            open( ORDTOT, ">>$ordtot" ) or die;
            foreach my $ln ( @sortedln )
            {
              print ORDTOT $ln;
            }
            close ORDTOT;
          }
        }

        #say $tee "TAKEOPTIMA FINAL ->\$countblock " . dump($countblock);
        my @morphcases = grep -d, <$mypath/$file_*>;
        unless ( $direction eq "star" )
        {
          say $tee "#Optimal option for case " . ( plus1( $countcase ) ) . ": $newtarget.";
        }
        #my $instnum = Sim::OPT::countarray( @{ $morphstruct[$countcase] } );

        #my $netinstnum = scalar( @morphcases );
        @totalcases = uniq( @totalcases );
        my $netinstnum = scalar( @totalcases );

        say $tee "#Net number of instances: $netinstnum." ;
        open( RESPONSE , ">>$mypath/response.txt" );
        unless ( $direction eq "star" )
        {
          say RESPONSE "#Optimal option for case " . ( plus1( $countcase ) ) . ": $newtarget.";
        }

        if ( $starstring eq "" )
        {
          say "NOT DOING";
          say RESPONSE "#Net number of instances: $netinstnum.\n" ;
        }
        elsif ( $starstring ne "" )
        {
          my @lines = uniq( @lines );
          if ( ( $starorder = ">" ) or ( $direction = ">" ) )
          {
            #say "DOING_1a";
            @lines = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lines;
          }
          elsif ( ( $starorder = "<" ) or ( $direction = "<" ) )
          {
            #say "DOING_1b";
            @lines = sort { (split( ',', $a))[ $objectivecolumn ] <=> ( split( ',', $b))[ $objectivecolumn ] } @lines;
          }
          else
          {
            say $tee "THE OBJECTIVE IS NOT CLEAR IN THE \%dowhat PARAMETER OF THE CONFIGURATION FILE.";
          }

          my $num = scalar( @lines );
          say RESPONSE "#Net number of instances: $num.\n" ;
        }

        say RESPONSE "Order of the parameters: " . dump( @sweeps );
        say RESPONSE "Number of parameter levels: " . dump( @varnumbers );
        say RESPONSE "Last initialization level: " . dump( @miditers );
        say RESPONSE "Descent directions: " . dump( $dowhat{direction} );

        my $metafile = $sortmixed . "_meta.csv";
        my $ordmeta = $sortmixed . "_ordmeta.csv";

        #say $tee "CARRIER " . dump( %carrier );

        my @blockelts = @{ Sim::OPT::getblockelts( \@sweeps, $countcase, $countblock ) }; say $tee "IN callblock \@blockelts " . dump( @blockelts );

        #say $tee "ABOUT TO CALL METAMODEL WITH COUNT EQUAL TO MAX; \$countblock: $countblock";
        metamodel( \%dowhat, $sortmixed, $file, \%dirfiles, \@blockelts, \%carrier, $metafile,
          $direction, $starorder, $ordmeta, \%varnums, $countblock );

        my @lines;
        if ( $dirfiles{metamodel} eq "yes" )
        {
          open( ORDMETA, $ordmeta ) or die( "$!" );
          @lines = <ORDMETA>;
          close ORDMETA;
        }
        else
        {
          if ( $searchname eq "no" )
          {
            open( SORTMIXED, $sortmixed ) or die( "$!" );
            @lines = <SORTMIXED>;
            close SORTMIXED;
          }
          elsif ( $searchname eq "yes" )
          {
            open( ORDEREDFILE, $orderedfile ) or die( "$!" );
            @lines = <ORDEREDFILE>;
            close ORDEREDFILE;
          }
        }


        my $winnerentry;
        if ( ( $direction eq ">" ) or ( ( $direction eq "star"  ) and ( $starorder eq ">"  ) ) )
        {
          $winnerentry = $lines[0]; #say $tee "dump( TAKEN_ IN SUB TAKEOPTIMA\$winnerentry): " . dump($winnerentry);
        }
        elsif ( ( $direction eq "<" ) or ( ( $direction eq "star"  ) and ( $starorder eq "<"  ) ) )
        {
          #$winnerentry = $lines[-1];
          $winnerentry = $lines[0]; #say $tee "dump( TAKEN_ IN SUB TAKEOPTIMA\$winnerentry): " . dump($winnerentry);
        }
        elsif ( ( $direction eq "=" ) or ( ( $direction eq "star"  ) and ( $starorder eq "="  ) ) )
        {
          my $half = ( int( scalar( @lines ) / 2 )  );
          $winnerentry = $lines[ $half ];
        }
        chomp $winnerentry;

        my @winnerelms = split( /,/, $winnerentry );
        my $winneritem = $winnerelms[0];

        $countblock = 0;
        $countcase++; ####!!!

        if ( $countcase > $#sweeps )# NUMBER OF CASES OF THE CURRENT PROBLEM
        {
          if ( $dirfiles{checksensitivity} eq "yes" )
          {
            Sim::OPT::sense( $dirfiles{ordtot}, $mypath, $dowhat{objectivecolumn} );
          }
          exit(say $tee "1 #END RUN.");
        }

        $countstring++;
        $dirfiles{countstring} = $countstring;
        #say $tee "IN12 TAKEOPTIMA-> CLOSECASE STARPATH \$winneritem " . dump($winneritem);
        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file ); #say $tee "IN12 TAKEOPTIMA-> CLOSECASE STARPATH \$winneritem " . dump($winneritem);

        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem ); #say $tee "IN12 TAKEOPTIMA-> CLOSECASE STARPATH \@winneritems " . dump(@winneritems);
        #say $tee "#Leaving case $countcase. Beginning with case " . ( plus1( $countcase ) ) . ".";

        @varnumbers = @{ dclone( $dirfiles{varnumbershold} ) };
        @miditers = @{ dclone( $dirfiles{miditershold} ) };

        #$dirfiles{starsign} = "no";

        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, datastruc => \%datastruc, dowhat => \%dowhat ,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst } );
      } ### END OF THE PART ON STAR CONFIGURATIONS
      else
      {
        #say $tee "IN CASE END NOT STARSIGN.";
        $countblock = 0;
        $countcase++; ####!!!

        if ( $countcase > $#sweeps )# NUMBER OF CASES OF THE CURRENT PROBLEM
        {
          if ( $dirfiles{checksensitivity} eq "yes" )
          {
            Sim::OPT::sense( $dirfiles{ordtot}, $mypath, $dowhat{objectivecolumn} );
          }
          exit(say $tee "2 #END RUN.");
        }

        $countstring++;
        $dirfiles{countstring} = $countstring;
        #say $tee "IN12 TAKEOPTIMA-> CLOSECASE MAINPATH \$winneritem " . dump($winneritem);
        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file ); #say $tee "IN12 TAKEOPTIMA-> CLOSECSE MAINPATH \$winneritem " . dump($winneritem);

        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem ); #say $tee "IN12 TAKEOPTIMA-> CLOSECSE MAINPATH \@winneritems " . dump(@winneritems);
        #say $tee "#Leaving case $countcase. Beginning with case " . ( plus1( $countcase ) ) . ".";

        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, datastruc => \%datastruc, dowhat => \%dowhat ,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst } );
      }
    }
    elsif( $countblock < $#blocks )
    {
      #say $tee "IN BLOCK END.";
      #say $tee "\$countcase : " . dump( $countcase );
      #say $tee "\$countblock : " . dump( $countblock );
      #say $tee "\@miditers : " . dump( @miditers );
      #say $tee "\@winneritems : " . dump( @winneritems );
      #say $tee "\%dirfiles : " . dump( %dirfiles );
      #say $tee "\@uplift : " . dump( @uplift );
      #say $tee "\@backvalues : " . dump( @backvalues );
      #say $tee "\@varnumbers : " . dump( @varnumbers );
      #say $tee "\@sweeps : " . @blockeltsdump( @sweeps );
      #say $tee "\%datastruc : " . dump( %datastruc );
      #say $tee "\%dowhat : " . dump( %dowhat );
      #say $tee " IN TAKEOPTIMA \$dirfiles{starsign} : " . dump( $dirfiles{starsign} );


      #if ( $sourceblockelts[0] =~ />/ )
      #{
      #  $dirfiles{starsign} = "yes"; #say $tee "SETTING IN callblock: \$dirfiles{starsign} " . dump( $dirfiles{starsign} );
      #}

      if ( ( $dirfiles{starsign} eq "yes" ) or
    			( ( $dirfiles{random} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{latinhypercube} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{factorial} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{facecentered} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) )
      { ### BEGINNING OF THE PART ABOUT STAR CONFIGURATIONS
        #say $tee "IN BLOCK END STARSIGN.";
        #say $tee "HERE AGAIN?!";
        #say $tee "HERE \$#blockelts : " . dump( $#blockelts );

        my $metafile = $sortmixed . "_tmp_meta.csv";
        my $ordmeta = $sortmixed . "_ordmeta.csv";

        #say $tee "CARRIER " . dump( %carrier );

        my @blockelts = @{ Sim::OPT::getblockelts( \@sweeps, $countcase, $countblock ) }; #say $tee "IN callblock \@blockelts " . dump( @blockelts );

        #say $tee "ABOUT TO CALL METAMODEL WITH COUNT LESSER THAN MAX; \$countblock: $countblock";
        metamodel( \%dowhat, $sortmixed, $file, \%dirfiles, \@blockelts, \%carrier, $metafile,
          $direction, $starorder, $ordmeta, \%varnums, $countblock );

        my @lines;
        if ( $dirfiles{metamodel} eq "yes" )
        {
          open( ORDMETA, $ordmeta ) or die( "$!" );
          @lines = <ORDMETA>;
          close ORDMETA;
        }
        else
        {
          if ( $searchname eq "no" )
          {
            open( SORTMIXED, $sortmixed ) or die( "$!" );
            @lines = <SORTMIXED>;
            close SORTMIXED;
          }
          elsif ( $searchname eq "yes" )
          {
            open( ORDEREDFILE, $orderedfile ) or die( "$!" );
            @lines = <ORDEREDFILE>;
            close ORDEREDFILE;
          }
        }

        my $winnerentry;
        if ( ( $direction eq ">" ) or ( ( $direction eq "star"  ) and ( $starorder eq ">"  ) ) )
        {
          $winnerentry = $lines[0]; #say TOFILE "dump( IN SUB TAKEOPTIMA\$winnerentry): " . dump($winnerentry);
        }
        elsif ( ( $direction eq "<" ) or ( ( $direction eq "star"  ) and ( $starorder eq "<"  ) ) )
        {
          #$winnerentry = $lines[-1];
          $winnerentry = $lines[0];
        }
        elsif ( ( $direction eq "=" ) or ( ( $direction eq "star"  ) and ( $starorder eq "="  ) ) )
        {
          my $half = ( int( scalar( @lines ) / 2 )  );
          $winnerentry = $lines[ $half ];
        }
        chomp $winnerentry;

        my @winnerelms = split( /,/, $winnerentry );
        my $winneritem = $winnerelms[0];

        #say $tee "IN12 STARPATH TAKEOPTIMA->\$winneritem " . dump($winneritem);
        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file ); #say $tee "IN12 STARPATH TAKEOPTIMA->\$winneritem " . dump($winneritem);

				#say $tee "IN12 STARPATH TAKEOPTIMA->\@winneritems " . dump( @winneritems );
        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem ); #say $tee "IN12 STARPATH TAKEOPTIMA->\@winneritems " . dump(@winneritems);
        #say $tee "#Leaving case " . ( plus1( $countcase ) ) . ", block " . ( plus1( $countcase ) ) . ", and descending!";

        @varnumbers = @{ dclone( $dirfiles{varnumbershold} ) };
        @miditers = @{ dclone( $dirfiles{miditershold} ) };
        #$dirfiles{starsign} = "no";

        $countblock++; ### !!!        push ( @{ $winneritems[$countcase][$countblock + 1] }, $winneritem ); say $tee "IN12 MA

        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, datastruc => \%datastruc, dowhat => \%dowhat,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst } );
      } ### END OF THE PART ABOUT STAR CONFIGURATIONS
      else
      { #say $tee "NOW I SHOULD ACT.";
        #say $tee "IN BLOCK END NOT STARSIGN.";
        #say $tee "IN12 MAINPATH TAKEOPTIMA->\$winneritem " . dump( $winneritem );
        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file ); #say $tee "IN12 MAINPATH TAKEOPTIMA->\$winneritem " . dump( $winneritem );

				#say $tee "IN12 MAINPATH TAKEOPTIMA->\@winneritems " . dump( @winneritems );
        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem ); #say $tee "IN12 MAINPATH TAKEOPTIMA->\@winneritems " . dump( @winneritems );
        #say $tee "#Leaving case " . ( plus1( $countcase ) ) . ", block " . ( plus1( $countcase ) ) . ", and descending!";

        $countblock++; ### !!!

        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, datastruc => \%datastruc, dowhat => \%dowhat,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst } );
      }
    }
  } # END SUB takeoptima



  takeoptima( $sortmixed, \%carrier, \@blockelts, $searchname, $orderedfile, $direction, $starorder, \%mids, \@blocks,
    $totres, $objectivecolumn, $ordres, \@starpositions, $countstring, $starnumber, $ordtot, $file, $ordmeta, $orderedfile,
      \%dirfiles, $countcase, $countblock, \%varnums ); #say $tee "TAKEOPTIMA \$sortmixed : " . dump( $sortmixed );
  close OUTFILE;
  close TOFILE;
}    # END SUB descend

1;

__END__

=head1 NAME

Sim::OPT::Descend.

=head1 SYNOPSIS

  use Sim::OPT;
  opt;

=head1 DESCRIPTION

Sim::OPT::Descent is a module collaborating with the Sim::OPT module for performing block coordinate descent or parallel blocks search, or free mixes of the two. It closes the circularly recursive loop formed by Sim::OPT -> Sim::OPT::Morph -> Sim::OPT::Sim -> Sim::OPT::Report::report -> Sim::OPT::Descent, which repeats at every search cycle.

The objective function for rating the performances of the candidate solutions can be obtained by the weighting of objective functions (performance indicators) performed by the Sim::OPT::Report module, which follows user-specified criteria.

=head2 EXPORT

"descend".

=head1 SEE ALSO

An example of configuration file for block search ("des.pl") is packed in "optw.tar.gz" file in "examples" directory in this distribution. But mostly, reference to the source code may be made.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2017 by Gian Luca Brunetti and Politecnico di Milano. This is free software. You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
