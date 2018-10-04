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
our @EXPORT = qw( descend ); # our @EXPORT = qw( );

$VERSION = '0.79'; # our $VERSION = '';
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
  @report_loadsortemps = @main::report_loadsortemps;
  @files_to_filter = @main::files_to_filter;
  @filter_reports = @main::filter_reports;
  @base_columns = @main::base_columns;
  @maketabledata = @main::maketabledata;
  @filter_columns = @main::filter_columns;
  %vals = %main::vals;

  my %d = %{ $_[0] };
  my @instances = @{ $d{instances} };
  my $countcase = $d{countcase}; say $tee "IN ENTRY DESCEND \$countcase : " . dump( $countcase );
  my $countblock = $d{countblock}; say $tee "IN ENTRY DESCEND \$countblock : " . dump( $countblock );
  my %dirfiles = %{ $d{dirfiles} };
  my %datastruc = %{ $d{datastruc} }; ######
  my @varnumbers = @{ $d{varnumbers} }; #say $tee "IN ENTRY DESCEND \@varnumbers : " . dump( @varnumbers );
  @varnumbers = Sim::OPT::washn( @varnumbers ); #say $tee "IN ENTRY DESCEND WASHED \@varnumbers : " . dump( @varnumbers );
  my @miditers = @{ $d{miditers} }; #say $tee "IN ENTRY DESCEND \@miditers : " . dump( @miditers );
  @miditers = Sim::OPT::washn( @miditers ); #say $tee "IN ENTRY DESCEND WASHED \@miditers : " . dump( @miditers );
  my @sweeps = @{ $d{sweeps} }; #say $tee "IN ENTRY DESCEND \@sweeps : " . dump( @sweeps );
  my @sourcesweeps = @{ $d{sourcesweeps} }; #say $tee "IN ENTRY DESCEND \@sourcesweeps : " . dump( @sourcesweeps );
  my @rootnames = @{ $d{rootnames} }; ######
  my %dowhat = %{ $d{dowhat} }; ######
  #my $tee = ${datastruc}{tee};

  if ( $countcase > $#sweeps )# NUMBER OF CASES OF THE CURRENT PROBLEM
  {
    exit(say $tee "#END RUN.");
  }

  ( my $blockelts_ref ) = Sim::OPT::getblockelts(\@sweeps, $countcase, $countblock );
	my @blockelts = @{ $blockelts_ref }; say $tee "IN ENTRY DESCEND \@blockelts : " . dump( @blockelts );

	my @blocks = Sim::OPT::getblocks( \@sweeps, $countcase ); #say $tee "IN ENTRY DESCEND \@blocks : " . dump( @blocks );
	my $toitem = Sim::OPT::getitem( \@winneritems, $countcase, $countblock ); #say $tee "IN ENTRY DESCEND \$toitem : " . dump( $toitem );
	my $from = Sim::OPT::getline( $toitem ); #say $tee "IN ENTRY DESCEND \$from : " . dump( $from );
	#say $tee "IN ENTRY DESCEND \$varnumbers[\$countcase]" . dump( $varnumbers[$countcase] );
  my $rootname = Sim::OPT::getrootname(\@rootnames, $countcase);
	my %varnums = Sim::OPT::getcase( \@varnumbers, $countcase ); #say $tee "IN DEFFILES \%varnums" . dump( %varnums );
	my %mids = Sim::OPT::getcase(\@miditers, $countcase); #say $tee "IN DEFFILES \%mids" . dump( %mids );


  my $direction = ${$dowhat{direction}}[$countcase][$countblock];
  my $starorder = ${$dowhat{starorder}}[$countcase][$countblock];

  if ( $direction eq "" )
  {
    $direction = $dowhat{newdirection};
  }

  if ( $starorder eq "" )
  {
    $starorder = $dowhat{newstarorder};
  }
  #say $tee "IN ENTRY DESCEND \$direction : " . dump( $direction ); #NEW
  #say $tee "IN ENTRY DESCEND \$starorder : " . dump( $starorder ); #NEW

  my $precomputed = $dowhat{precomputed}; say $tee "IN DESCEND \$precomputed: " . dump($precomputed); #NEW
  my @takecolumns = @{ $dowhat{takecolumns} }; #NEW
  my @starpositions = @{ $dowhat{starpositions} }; #say $tee "IN ENTRY DESCEND \@starpositions : " . dump( @starpositions );
  my $starnumber = scalar( @starpositions ); #say $tee "IN ENTRY DESCEND \$starnumber : " . dump( $starnumber );
  my $starobjective = $dowhat{starobjective}; #say $tee "IN ENTRY DESCEND \$starobjective : " . dump( $starobjective );
  my $objectivecolumn = $dowhat{objectivecolumn}; #say $tee "IN ENTRY DESCEND \$objectivecolumn : " . dump( $objectivecolumn );
  my $searchname = $dowhat{searchname}; say $tee "IN ENTRY DESCEND \$searchname: " . dump( $searchname );

  my $countstring = $dirfiles{countstring}; #say $tee "IN ENTRY DESCEND \$countstring: " . dump( $countstring );
  my $starstring = $dirfiles{starstring}; #say $tee "IN ENTRY DESCEND \$starstring: " . dump( $starstring );
  my $totres = $dirfiles{totres}; #say $tee "IN ENTRY DESCEND \$totres: " . dump( $totres );
  my $ordres = $dirfiles{ordres}; #say $tee "IN ENTRY DESCEND \$ordres: " . dump( $ordres );
  my $tottot = $dirfiles{tottot}; #say $tee "IN ENTRY DESCEND \$tottot: " . dump( $tottot );
  my $ordtot = $dirfiles{ordtot}; #say $tee "IN ENTRY DESCEND \$ordtot: " . dump( $ordtot );

  my $repfile = $dirfiles{repfile}; say $tee "IN DESCEND \$repfile: " . dump( $repfile );
  if ( not( $repfile ) ){ die; }
  my $sortmixed = $dirfiles{sortmixed}; say $tee "IN DESCEND \$sortmixed: " . dump( $sortmixed );
  if ( not( $sortmixed ) ){ die; }

  my ( $entryfile, $exitfile, $orderedfile );
  my $entryname = $dirfiles{entryname}; say $tee "IN DESCEND \$entryname: " . dump( $entryname );
  if ( $entryname ne "" )
  {
    $entryfile = "$mypath/" . "$file" . "_" . "$entryname" . ".csv";
  }
  else
  {
    $entryfile = "";
  } say $tee "IN DESCEND \$entryfile: " . dump( $entryfile );

  my $exitname = $dirfiles{exitname}; say $tee "IN DESCEND \$exitname: " . dump( $exitname );
  if ( $exitname ne "" )
  {
    $exitfile = "$mypath/" . "$file" . "_" . "$exitname" . ".csv";
  }
  else
  {
    $exitfile = "";
  } say $tee "IN DESCEND \$exitfile: " . dump( $exitfile );

  my $orderedname = "$exitname" . "-ord";
  if ( $orderedname ne "" )
  {
    $orderedfile = "$mypath/" . "$file" . "_" . "$orderedname" . ".csv";
  }
  else
  {
    $orderedfile = "";
  } say $tee "IN DESCEND \$orderedfile: " . dump( $orderedfile );


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

  my $skipfile = $vals{skipfile};
  my $skipsim = $vals{skipsim};
  my $skipreport = $vals{skipreport};

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
    exit(say $tee "#END RUN.");
  }


  if ( not( -e $repfile ) ){ die; }; #say $tee " \$repfile " . dump($repfile);


  my $instance = $instances[0]; # THIS WOULD HAVE TO BE A LOOP HERE TO MIX ALL THE MERGECASES!!! ### ZZZ

  my %dat = %{$instance};
  my @winneritems = @{ $dat{winneritems} }; #say $tee " \@winneritems " . dump(@winneritems);
  my $countvar = $dat{countvar}; #say $tee "IN DESCEND \$countvar " . dump( $countvar );
  my $countstep = $dat{countstep}; #say $tee "IN DESCEND \$countstep " . dump( $countstep );
  my $to = $dat{to};
  my $origin = $dat{origin};

  my $counthold = 0;

  my $skip = $vals{$countvar}{skip};

  my $word = join( ", ", @blockelts ); ###NEW

  my $stepsvar = Sim::OPT::getstepsvar($countvar, $countcase, \@varnumbers);
  my $varnumber = $countvar;

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
    $weighttwo = $repfile;###############
  }

  if ( not( -e $weighttwo) ){ die; };


  if ( not( ( $repfile ) and ( -e $repfile ) ) )
  {
    die( "$!" );
  }



  sub sortmixed
  {
    my ( $weighttwo, $sortmixed, $searchname, $entryfile, $exitfile, $orderedfile ) = @_;
    say $tee "Processing results for case " . ( plus1( $countcase ) ) . ", block " . ( plus1( $countblock ) ) . ".";

    if ( $searchname eq "no" )###################################à
    {
      open( WEIGHTTWO, $weighttwo ) or die( "$!" ); say $tee "\$weighttwo" . dump( $weighttwo );
      my @lines = <WEIGHTTWO>;
      close WEIGHTTWO;

      #if ( not( scalar( @{ $dowhat{starpositions} } ) == 0 ) )##############CHECK HERE. IT ONCE WAS.
      #{
      #  open( SORTMIXED, ">>$sortmixed" ) or die( "$!" );
      #}
      #else
      #{
      #  open( SORTMIXED, ">$sortmixed" ) or die( "$!" );
      #}

      foreach my $line ( @lines )
      {
        #chomp $line;
        $line =~ s/\,+$//;
        $line =~ s/"//g;
      }

      #say TOFILE "TAKEOPTIMA--dump(\@lines): " . dump(@lines);

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

      open( SORTMIXED, ">$sortmixed" ) or die( "$!" ); say $tee "OPENING SORTMIXED: " . dump( $sortmixed );
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
        open( EXITFILE, ">>$exitfile" ) or die; say $tee "IN DESCENT OPENING IN WRITING \$exitfile" . dump( $exitfile );
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
        open( EXITFILE, "$exitfile" ) or die; say $tee "IN DESCENT OPENING IN READING \$exitfile" . dump( $exitfile );
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

  } ### END SUB sortmixed

  if ( not( -e $weighttwo) ){ die; };
  if ( not( $sortmixed) ){ die; };
  sortmixed( $weighttwo, $sortmixed, $searchname, $entryfile, $exitfile, $orderedfile );


  sub takeoptima
  {
    my ( $sortmixed ) = @_;

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
      $winnerentry = $lines[0]; #say TOFILE "dump( IN SUB TAKEOPTIMA\$winnerentry): " . dump($winnerentry);
    }
    elsif ( ( $direction eq "<" ) or ( ( $direction eq "star"  ) and ( $starorder eq "<"  ) ) )
    {
      $winnerentry = $lines[-1];
    }
    elsif ( ( $direction eq "=" ) or ( ( $direction eq "star"  ) and ( $starorder eq "="  ) ) )
    {
      my $half = ( int( scalar( @lines ) / 2 )  );
      $winnerentry = $lines[ $half ];
    }
    chomp $winnerentry;


    my @winnerelms = split( /,/, $winnerentry );
    my $winnerline = $winnerelms[0];
    my $winneritem = $winnerline;
    my $addfile = $file . "_";
    $winneritem =~ s/$mypath\/$addfile// ;
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


    if ( $countblock == 0 )
    {
      shift( @{ $winneritems[$countcase][$countblock] } );
    }



    ################################################### STOP CONDITIONS!
    #if ( ( $countblock == $#blocks )
    #  and ( ( $starstring eq "" )
    #    or ( ( $starstring ne "" ) and ( $countstring ) ) ) ) # NUMBER OF BLOCK OF THE CURRENT CASE

    if ( $countblock == $#blocks )
    {
      if ( ( ( $dirfiles{starsign} eq "yes" ) and ( $dirfiles{d} == scalar( @{ $dirfiles{starpositions} } ) )
              and ( $dirfiles{c} == scalar( @{ $dirfiles{dummyblockelts} } ) ) )
            or ( ( $dirfiles{starsign} ne "yes" ) ) )
      {

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


        open( ORDRES, ">$ordres" ) or die;

        foreach my $lin ( @sorted )
        {
          print ORDRES $lin;
        }
        close ORDRES;


        if ( ( scalar( @starpositions > 0) ) and ( $countstring ) )
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


            open( ORDTOT, ">$ordtot" ) or die;
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

      }


      if ( $dirfiles{starsign} eq "yes" )
      {
        ;# COPY HERE THE FUNCTION BELOW
      }



      if ( ( $dirfiles{starsign} eq "yes" ) and ( $dirfiles{d} == scalar( @{ $dirfiles{starpositions} } ) )
          and ( $dirfiles{c} == scalar( @{ $dirfiles{dummyblockelts} } ) ) )
      {
        $countblock = 0;
        $countcase++; ####!!!
        $countstring++;
        $dirfiles{countstring} = $countstring;

        push ( @{ $winneritems[$countcase][$countblock] }, $winneritem ); say $tee "TAKEOPTIMA->\@winneritems " . dump(@winneritems);
        say $tee "#Leaving case $countcase. Beginning with case " . ( plus1( $countcase ) ) . ".";

        @varnumbers = @{ dclone( \@{ $dowhat{varnumbershold} } ) };
        $dirfiles{starsign} = "no";
        $countblock++; ### !!!
      }
      elsif ( $dirfiles{starsign} ne "yes" )
      {
        $countblock = 0;
        $countcase++; ####!!!
        $countstring++;
        $dirfiles{countstring} = $countstring;

        push ( @{ $winneritems[$countcase][$countblock] }, $winneritem ); say $tee "TAKEOPTIMA->\@winneritems " . dump(@winneritems);
        say $tee "#Leaving case $countcase. Beginning with case " . ( plus1( $countcase ) ) . ".";

        $countblock++; ### !!!
      }

      Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
      miditers => \@miditers,  winneritems => \@winneritems,
      dirfiles => \%dirfiles, varnumbers => \@varnumbers,
      sweeps => \@sweeps, datastruc => \%datastruc, dowhat => \%dowhat ,
      sourcesweeps => \@sourcesweeps, } )
    }
    elsif( $countblock < $#blocks )
    {
      #say $tee "\$countcase : " . dump( $countcase );
      #say $tee "\$countblock : " . dump( $countblock );
      #say $tee "\@miditers : " . dump( @miditers );
      #say $tee "\@winneritems : " . dump( @winneritems );
      #say $tee "\%dirfiles : " . dump( %dirfiles );
      #say $tee "\@uplift : " . dump( @uplift );
      #say $tee "\@backvalues : " . dump( @backvalues );
      #say $tee "\@varnumbers : " . dump( @varnumbers );
      #say $tee "\@sweeps : " . dump( @sweeps );
      #say $tee "\%datastruc : " . dump( %datastruc );
      #say $tee "\%dowhat : " . dump( %dowhat );

      if ( $dirfiles{starsign} eq "yes" )
      {
        if ( ( $dirfiles{d} == scalar( @{ $dirfiles{starpositions} } ) )
          and ( $dirfiles{c} == scalar( @{ $dirfiles{dummyblockelts} } ) ) )
        {
          if ( $dirfiles{metamodel} eq "yes" )
          {
            sub cleanres
            {
              open( ORDRES, "$_") or die;
              my $cleanordres = $_ . "-cleaned.csv";
              my @lines = <ORDRES>;
              close ORDRES;

              open( CLEANORDRES, ">$cleanordres" ) or die;

              foreach my $line ( @lines )
              {
                $line =~ s/$mypath\/$file// ;
                $line =~ s/^_// ;
                $line =~ /(\d+)_-(\d+),(\d+)/ ;
                $line =~ s/$2// ;
                $line =~ s/_-// ;
                print CLEANORDRES $line;
              }
              close CLEANORDRES;
              return( $cleanordres );
            };

            sub prepareblank { ;};
            sub jointwo { ;};
            sub givename { ;};
            sub writefile { ;};

            my $cleanordres = cleanres( $ordres ); say $tee "IN TAKEOPTIMA1 \$cleanordres : " . dump( $cleanordres );
            my @blank = @{ prepareblank( \%miditers ) };
            my @prepared = @{ jointwo( $cleanordres, \@blank ) };
            my ( $metafill ) = givename( $cleanordtot );
            my $metafile = "$metafill" . "_meta.csv";
            my $ordmeta = "$metafill" . "_ordmeta.csv";
            writefile( $metafill, \@prepared );
            Sim::OPT::Interlinear( $metafill );


            open( METAFILE, "$metafile" ) or die;
            my @totlines = <METAFILE>;
            close METAFILE;


            if ( ( $direction eq "<" ) or ( $starorder eq "<" ) )
            {
              @sorted = sort { (split( ',', $a))[ 0 ] <=> ( split( ',', $b))[ 0 ] } @totlines;
            }
            elsif ( ( $direction eq ">" ) or ( $starorder eq ">" ) )
            {
              @sorted = sort { (split( ',', $b))[ 0 ] <=> ( split( ',', $a))[ 0 ] } @totlines;
            }


            open( ORDMETA, ">$ordmeta" ) or die;
            foreach my $ln ( @sorted )
            {
              print ORDMETA $ln;
            }
            close ORDMETA;
          }


          my @lines;
          {
            open( ORDMETA, $ordmeta ) or die( "$!" );
            @lines = <ORDMETA>;
            close ORDMETA;
          }
          my $winnerentry;

          if ( ( $direction eq ">$cleanordres" ) or ( ( $direction eq "star"  ) and ( $starorder eq ">"  ) ) )
          {
            $winnerentry = $lines[0]; #say TOFILE "dump( IN SUB TAKEOPTIMA\$winnerentry): " . dump($winnerentry);
          }
          elsif ( ( $direction eq "<" ) or ( ( $direction eq "star"  ) and ( $starorder eq "<"  ) ) )
          {
            $winnerentry = $lines[-1];
          }
          elsif ( ( $direction eq "=" ) or ( ( $direction eq "star"  ) and ( $starorder eq "="  ) ) )
          {
            my $half = ( int( scalar( @lines ) / 2 )  );
            $countblock = 0;
            $countcase++; ####!!!
            $countstring++;
            $dirfiles{countstring} = $countstring;

            push ( @{ $winneritems[$countcase][$countblock] }, $winneritem ); say $tee "TAKEOPTIMA->\@winneritems " . dump(@winneritems);
            say $tee "#Leaving case $countcase. Beginning with case " . ( plus1( $countcase ) ) . ".";      $winnerentry = $lines[ $half ];
          }
          chomp $winnerentry;



          push ( @{ $winneritems[$countcase][$countblock] }, $winneritem ); say $tee "TAKEOPTIMA->\@winneritems " . dump(@winneritems);
          say $tee "#Leaving case " . ( plus1( $countcase ) ) . ", block " . ( plus1( $countcase ) ) . ", and descending!";

          @varnumbers = @{ dclone( \@{ $dowhat{varnumbershold} } ) };
          $dirfiles{starsign} = "no";
          $countblock++; ### !!!
        }
      }
      elsif ( $dirfiles{starsign} ne "yes" )
      {
        push ( @{ $winneritems[$countcase][$countblock] }, $winneritem ); say $tee "TAKEOPTIMA->\@winneritems " . dump(@winneritems);
        say $tee "NOT DONE.";
        say $tee "#Leaving case " . ( plus1( $countcase ) ) . ", block " . ( plus1( $countcase ) ) . ", and descending!";

        $countblock++; ### !!!
      }

      Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
      miditers => \@miditers,  winneritems => \@winneritems,
      dirfiles => \%dirfiles, varnumbers => \@varnumbers,
      sweeps => \@sweeps, datastruc => \%datastruc, dowhat => \%dowhat,
      sourcesweeps => \@sourcesweeps, } )
    }
  } # END SUB takeoptima

  takeoptima( $sortmixed ); say $tee "TAKEOPTIMA \$sortmixed : " . dump( $sortmixed );
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

Sim::OPT::Descent is a module collaborating with the Sim::OPT module for performing block coordinate descent, or parallel blocks search, or free mixes of the two. It closes the circularly recursive loop formed by Sim::OPT -> Sim::OPT::Morph -> Sim::OPT::Sim -> Sim::OPT::Report::retrieve -> Sim::OPT::Report::report -> Sim::OPT::Descent, which repeats at every block search cycle.

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
