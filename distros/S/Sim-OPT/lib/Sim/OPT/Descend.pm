package Sim::OPT::Descend;
# Copyright (C) 2008-2021 by Gian Luca Brunetti and Politecnico di Milano.
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

$VERSION = '0.153'; # our $VERSION = '';
$ABSTRACT = 'Sim::OPT::Descent is an module collaborating with the Sim::OPT module for performing block coordinate descent.';

#########################################################################################
# HERE FOLLOWS THE CONTENT OF "Descend.pm" - Sim::OPT::Descend
##############################################################################

sub odd
{
    my $number = shift;
    return !even ($number);
}

sub even
{
    my $number = abs shift;
    return 1 if $number == 0;
    return odd ($number - 1);
}

sub descend
{
  my $configfile = $main::configfile;
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

  $tee = new IO::Tee(\*STDOUT, ">>$tofile"); # GLOBAL
  say $tee "\n#Now in Sim::OPT::Descend.\n";

  my %simtitles = %main::simtitles;
  my %retrievedata = %main::retrievedata;
  my @keepcolumns = @main::keepcolumns;
  my @weights = @main::weights;
  my @weighttransforms = @main::weighttransforms;
  my @weightsaim = @main::weightsaim;
  my @varthemes_report = @main::varthemes_report;
  my @varthemes_variations = @vmain::arthemes_variations;
  my @varthemes_steps = @main::varthemes_steps;
  my @rankdata = @main::rankdata; # CUT
  my @rankcolumn = @main::rankcolumn;
  my %reportdata = %main::reportdata;
  my @report_loadsortemps = @main::report_loadsortemps;
  my @files_to_filter = @main::files_to_filter;
  my @filter_reports = @main::filter_reports;
  my @base_columns = @main::base_columns;
  my @maketabledata = @main::maketabledata;
  my @filter_columns = @main::filter_columns;
  my %vals = %main::vals;

  my %dt = %{ $_[0] };

  my @instances = @{ $dt{instances} }; say $tee "HEEERE IN DESCEND \@instances: " . dump( @instances );
  my %dirfiles = %{ $dt{dirfiles} }; say $tee "HEEERE IN DESCEND \%dirfiles: " . dump( \%dirfiles );
  my %vehicles = %{ $dt{vehicles} }; say $tee "HEEERE IN DESCEND \%vehicles: " . dump( \%vehicles );
  my %winhash = %{ $dt{winhash} }; say $tee "HEEERE IN DESCEND \%winhash: " . dump( \%winhash );
  #my $winning = $winhash{winning};
  my %inst = %{ $dt{inst} }; say $tee "HEEERE IN DESCEND \%inst: " . dump( \%inst );
  my @precedents = @{ $dt{precedents} }; say $tee "HEEERE IN DESCEND \@precedents: " . dump( @precedents );

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

  my $exitname = $dirfiles{exitname};

  #say $tee "IN ENTRY DESCEND3  \$dirfiles{starsign} " . dump( $dirfiles{starsign} );

  my %d = %{ $instances[0] };
  my $countcase = $d{countcase}; say $tee "HEEERE IN DESCEND \$countcase: " . dump( $countcase );
  my $countblock = $d{countblock}; say $tee "HEEERE IN DESCEND \$countblock: " . dump( $countblock );
  my %datastruc = %{ $d{datastruc} }; say $tee "HEEERE IN DESCEND \%datastruc: " . dump( \%datastruc );
  my @varnumbers = @{ $d{varnumbers} };
  @varnumbers = Sim::OPT::washn( @varnumbers ); say $tee "HEEERE IN DESCEND \@varnumbers: " . dump( @varnumbers );
  my @miditers = @{ $d{miditers} };
  @miditers = Sim::OPT::washn( @miditers ); say $tee "HEEERE IN DESCEND \@miditers: " . dump( @miditers );
  my @sweeps = @{ $d{sweeps} }; say $tee "HEEERE IN DESCEND \@sweeps: " . dump( @sweeps );
  my @sourcesweeps = @{ $d{sourcesweeps} }; say $tee "HEEERE IN DESCEND \@sourcesweeps: " . dump( @sourcesweeps );
  my @rootnames = @{ $d{rootnames} }; say $tee "HEEERE IN DESCEND \@rootnames: " . dump( @rootnames );
  my @winneritems = @{ $d{winneritems} }; say $tee "HEEERE IN DESCEND \@winneritems: " . dump( @winneritems );
  my $instn = $d{instn}; say $tee "HEEERE IN DESCEND \$instn: " . dump( $instn );

  my %dowhat = %{ $d{dowhat} }; ######

  my $skipfile = $vals{skipfile};
	my $skipsim = $vals{skipsim};
	my $skipreport = $vals{skipreport};

	my @blockelts = @{ $d{blockelts} };

	my @blocks = @{ $d{blocks} };
	my $toitem = Sim::OPT::getitem( \@winneritems, $countcase, $countblock );
  $toitem = Sim::OPT::clean( $toitem, $mypath, $file );
  my $from = Sim::OPT::getline( $toitem );
  $from = Sim::OPT::clean( $from, $mypath, $file );
  my $rootname = Sim::OPT::getrootname(\@rootnames, $countcase);
  $rootname = Sim::OPT::clean( $rootname, $mypath, $file );
  my %varnums = %{ $d{varnums} };
  my %mids = %{ $d{mids} };
  my %carrier = %{ $d{carrier} };
  my $outstarmode = $dowhat{outstarmode};

  say $tee "HEEERE \$toitem $toitem \$from $from \$rootname $rootname ";

  say $tee "RELAUNCHED IN DESCEND WITH INST " . dump( %inst );

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
		$starorder = $dirfiles{starorder};
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

  my $precomputed = $dowhat{precomputed};
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

  my $starnumber = scalar( @starpositions );
  my $starobjective = $dowhat{starobjective};
  my $objectivecolumn = $dowhat{objectivecolumn};
  my $searchname = $dowhat{searchname};

  my $countstring = $dirfiles{countstring};
  my $starstring = $dirfiles{starstring};
  my $starsign = $dirfiles{starsign};
  my $totres = $dirfiles{totres};
  my $ordres = $dirfiles{ordres};
  my $tottot = $dirfiles{tottot};
  my $ordtot = $dirfiles{ordtot};

  my $confinterlinear = "$mypath/" . $dowhat{confinterlinear} ;

  my $repfile = $dirfiles{repfile};
  if ( not( $repfile ) ){ die; }
  my $sortmixed = $dirfiles{sortmixed};
  if ( not( $sortmixed ) ){ die; }

  my ( $entryfile, $exitfile, $orderedfile );
  my $entryname = $dirfiles{entryname};
  if ( $entryname ne "" )
  {
    $entryfile = "$mypath/" . "$file" . "_tmp_" . "$entryname" . ".csv";
  }
  else
  {
    $entryfile = "";
  }

  my $exitname = $dirfiles{exitname};
  if ( $exitname ne "" )
  {
    $exitfile = "$mypath/" . "$file" . "_tmp_" . "$exitname" . ".csv";
  }
  else
  {
    $exitfile = "";
  }

  my $orderedname = "$exitname" . "-ord";
  if ( $orderedname ne "" )
  {
    $orderedfile = "$mypath/" . "$file" . "_tmp_" . "$orderedname" . ".csv";
  }
  else
  {
    $orderedfile = "";
  }

  #if ( $winning ne "" )
  #{
  #  Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
  #  miditers => \@miditers,  winneritems => \@winneritems,
  #  dirfiles => \%dirfiles, varnumbers => \@varnumbers,
  #  sweeps => \@sweeps, datastruc => \%datastruc, dowhat => \%dowhat ,
  #  sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
  #}

  say $tee " \$repfile " . dump($repfile);
  if ( not( -e $repfile ) ){ die "There isn't \$repfile: $repfile"; };


  my $instance = $instances[0]; # THIS WOULD HAVE TO BE A LOOP HERE TO MIX ALL THE MERGECASES!!! ### ZZZ

  my %dat = %{$instance};
  my @winneritems = @{ $dat{winneritems} };
  my $countvar = $dat{countvar};
  my $countstep = $dat{countstep};


  my $counthold = 0;

  my $skip = $dowhat{$countvar}{skip};

  my $word = join( ", ", @blockelts ); ###NEW

  my $varnumber = $countvar;
  my $stepsvar = $varnums{$countvar};

  say $tee "Descending into case " . ( $countcase + 1 ) . ", block " . ( $countcase + 1 ) . ".";

  my @columns_to_report = @{ $reporttempsdata[1] };
  my $number_of_columns_to_report = scalar(@columns_to_report);
  my $number_of_dates_to_mix = scalar(@simtitles);
  my @dates                    = @simtitles;


  my $throwclean = $repfile;
  $throwclean =~ s/\.csv//;
  my $selectmixed = "$throwclean-select.csv";

  my $remember;

  sub cleanselect
  {   # IT CLEANS THE MIXED FILE AND SELECTS SOME COLUMNS, THEN COPIES THEM IN ANOTHER FILE
    my ( $repfile, $selectmixed ) = @_;
    say $tee "Cleaning results for case " . ( $countcase + 1 ) . ", block " . ( $countcase + 1 ) . ".";
    open( MIXFILE, $repfile ) or die( "$!" );
    my @lines = <MIXFILE>;
    close MIXFILE; say $tee "\@lines: " . dump( @lines );

    open( SELECTEDMIXED, ">$selectmixed" ) or die( "$!" );
    foreach my $line (@lines)
    {
      if ( ( $line ne "" ) and ( $line ne " " ) and ( $line ne "\n" ) )
      {
        chomp $line;
        $line =~ s/\n/°/g;
        $line =~ s/\s+/,/g;
        $line =~ s/°/\n/g;
        $line =~ s/,,/,/g;
        my @elts = split(/,/, $line); say $tee "ELTS: " . dump( @elts );
        my $touse = $elts[0];

        my ( @elements, @names, @obtaineds, @newnames ); say $tee "\@keepcolumns: " . dump( @keepcolumns );
        foreach my $elm_ref (@keepcolumns)
        {
          my @cols = @{ $elm_ref };
          my $name = $cols[0];
          my $number = $cols[1];
          push ( @elements, $elts[$number] ); say $tee "\PUSH \$elts[\$number]: " . dump( $elts[$number] );
          say $tee "\$elts: $elts, \$number: $number";
          push ( @names, $name );
        } say $tee "ELEMENTS: ". dump( @elements ); say $tee "NAMES: ". dump( @names );

        if ( not ( scalar( @weighttransforms ) == 0 ) )
        {
          my $coun = 0;
          foreach my $elt_ref ( @weighttransforms )
          {
            my @els = @{ $elt_ref };
            my $newname = $els[0];
            my $transform = $els[1];
            my $obtained = eval ( $transform ); say $tee "HERE \$transform: $transform, \$obtained: $obtained";
            push ( @obtaineds, $obtained );
            push ( @newnames, $newname );
            $coun++;
          }
          @names = @newnames;
        }
        else
        {
          @obtaineds = @elements;
        }
        say $tee "ELEMENTS: ". dump( @elements ); say $tee "\@obtaineds: ". dump( @obtaineds );
        say $tee "NAMES: ". dump( @names ); say $tee "NEWNAMES: ". dump( @newnames );

        print SELECTEDMIXED "$touse,";

        my $coun = 0; say $tee "PRINTNG OBTAINEDS: " . dump ( @obtaineds ) ;
        foreach my $elt ( @obtaineds )
        {
          print SELECTEDMIXED "$names[$coun],";
          print SELECTEDMIXED "$elt,";
          $coun++;
        }
        print SELECTEDMIXED "\n";
      }
    }
    close SELECTEDMIXED;
  }

  if ( $precomputed eq "" )
  {
    cleanselect( $repfile, $selectmixed );
  }

  say $tee "IN DESCEND AFTER CLEANSELECT; INST " . dump( %inst );


  my $throw = $selectmixed;
  $throw =~ s/\.csv//;
  my $weight = "$throw-weight.csv";
  sub weight
  {
    my ( $selectmixed, $weight ) = @_;
    say $tee "Scaling results for case " . ( $countcase + 1 ). ", block " . ( $countcase + 1 ) . ".";
    open( SELECTEDMIXED, $selectmixed ) or die( "$!" );
    my @lines = <SELECTEDMIXED>;
    close SELECTEDMIXED;

    my $counterline = 0;
    open( WEIGHT, ">$weight" ) or die( "$!" );

    my ( @containerone, @containernames, @containertitles, @containertwo, @containerthree, @maxes, @mins );
    foreach my $line (@lines)
    {
      $line =~ s/^[\n]//;
      chomp $line;
      my @elts = split( /\s+|,/, $line );
      my $touse = shift( @elts ); # IT CHOPS AWAY THE FIRST ELEMENT DESTRUCTIVELY
      my $countel = 0;
      my $countcol = 0;
      my $countcn = 0;
      foreach my $elt ( @elts )
      {
        if ( odd( $countel ) )
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


    $countcolm = 0;
    foreach my $colref ( @containerone )
    {
      my @column = @{ $colref }; # DEREFERENCE

      if ( max( @column ) != 0) # FILLS THE UNTRACTABLE VALUES
      {
        push ( @maxes, max( @column ) );
      }
      else
      {
        push ( @maxes, "NOTHING1" );
      }

      push ( @mins, min( @column ) );

      foreach my $el ( @column )
      {
        my $eltrans;
        if ( $maxes[ $countcolm ] != 0 )
        {
          print TOFILE "\$weights[\$countcolm]: $weights[$countcolm]\n";
          $eltrans = ( $el / $maxes[$countcolm] ) ;
        }
        else
        {
          $eltrans = "NOTHING2" ;
        }
        push ( @{ $containertwo[$countcolm] }, $eltrans) ; print TOFILE "ELTRANS: $eltrans\n";
      }
      $countcolm++;
    }
    say $tee "HERE \@containerone: " . dump( @containerone ); say $tee "\@containertwo: " . dump( @containertwo );
    say $tee "\@maxes: " . dump( @maxes ); say $tee "\@mins: " . dump( @mins );
    say $tee "\@containernames: " . dump( @containernames );

    my $countrow = 0;
    foreach ( @lines )
    {
      my ( @c1row, @c2row );

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

      say $tee "HERE \@cnamesrow: " . dump( @cnamesrow ); say $tee "\@c1row: " . dump( @c1row ); say $tee "\@c2row: " . dump( @c2row );

      print WEIGHT "$containertitles[ $countrow ],";

      $countel = 0;
      foreach my $el ( @c1row )
      {
        print WEIGHT "$cnamesrow[$countel],";
        print WEIGHT "$el,";
      }

      foreach my $el ( @c2row )
      {
        print WEIGHT "$el,";
      }

      print WEIGHT "$wsum\n";

      $countrow++;
    }
    close WEIGHT;
  }

  if ( $precomputed eq "" )
  {
    weight( $selectmixed, $weight ); #
  }

  say $tee "IN DESCEND AFTER WEIGHT; INST " . dump( %inst );

  my $weighttwo = $weight;


  if ( $precomputed ne "" )
  {
    $weighttwo = $repfile; ############### TAKE CARE!
  }


  if ( not( -e $weighttwo ) ){ die; };


  if ( not( ( $repfile ) and ( -e $repfile ) ) )
  {
    die( "$!" );
  }

  sub sortmixed
  {
    my ( $weighttwo, $sortmixed, $searchname, $entryfile, $exitfile, $orderedfile, $outstarmode, $instn, $inst_r, $dirfiles_r, $vehicles_r, $countcase, $countblock ) = @_;
    say $tee "Processing results for case " . ( $countcase + 1 ) . ", block " . ( $countcase + 1 ) . ".";
    my %inst = %{ $inst_r }; #say $tee "IN SORTMIXED \%inst" . dump( \%inst );
    my %dirfiles = %{ $dirfiles_r };
    my %vehicles = %{ $vehicles_r };

    if ( $searchname eq "no" )###################################
    {
      open( WEIGHTTWO, $weighttwo ) or die( "$!" ); #say $tee "IN SORTMIXED \$weighttwo" . dump( $weighttwo );
      my @lines = <WEIGHTTWO>;
      close WEIGHTTWO;

      if ( $dirfiles{popsupercycle} eq "yes" )
      {
        my $openblock = pop( @{ $vehicles{nesting}{$dirfiles{nestclock}} } );
        while ( $openblock <= $countblock )
        {
          push( @lines, @{ $vehicles{$countcase}{$openblock} } );
          $openblock++;
        }
        unless ( $dowhat{metamodel} eq "yes" )
        {
          $dirfiles{nestclock} = $dirfiles{nestclock} - 1;
        }
      }

      @lines = uniq( @lines );

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

      open( SORTMIXED, ">$sortmixed" ) or die( "$!" );
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
      #########################################à
    }
    elsif ( $searchname eq "yes" )###################################à
    {
      my @theselines;
      if ( ( $weighttwo ne "" ) and ( -e $weighttwo ) )
      {
        open( WEIGHTTWO, $weighttwo ) or die( "$!" );
        @theselines = <WEIGHTTWO>;
        close WEIGHTTWO;
      }

      if ( $dirfiles{popsupercycle} eq "yes" )
      {
        my $openblock = pop( @{ $vehicles{nesting}{$dirfiles{nestclock}} } );
        while ( $openblock <= $countblock )
        {
          push( @lines, @{ $vehicles{$countcase}{$openblock} } );
          $openblock++;
        }
        unless ( $dowhat{metamodel} eq "yes" )
        {
          $dirfiles{nestclock} = $dirfiles{nestclock} - 1;
        }
      }

      if ( $exitfile ne "" )
      {
        open( EXITFILE, ">>$exitfile" ) or die;
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
        open( EXITFILE, "$exitfile" ) or die;
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

  close SORTMIXED;
  if ( not( -e $weighttwo) ){ die; };
  if ( not( $sortmixed) ){ die; };
  sortmixed( $weighttwo, $sortmixed, $searchname, $entryfile, $exitfile, $orderedfile, $outstarmode,
  $instn, \%inst, \%dirfiles, \%vehicles, $countcase, $countblock );

  say $tee "IN DESCEND AFTER SORTMIXED; INST " . dump( %inst );

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
    my @blockelts = @{ $blockelts_r };
    my %carrier = %{ $carrier_r };
    my %varnums = %{ $varnums_r };
    close SORTMIXED;

		if ( $dowhat{metamodel} eq "yes" )
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
	      my %varnums = %{ $varnums_r };
	      my @blockelts = ( sort { $a <=> $b } @{ $blockelts_r } );
        my @bag = @{ $bag_r };
        my %carrier = %{ $carrier_r };
        open( BLANKFILE, ">$blankfile" ) or die;

        my @box = @{ Sim::OPT::toil( \@blockelts, \%varnums, $bag_r ) };
	      @box = @{ $box[-1] };
	      my $integrated_r = Sim::OPT::integratebox( \@box, \%carrier, $file, \@blockelts );

	      my @finalbox = @{ $integrated_r };

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

      my %varns;
      if ( $dirfiles{starsign} eq "yes ")
      {
        %varns = prepvarnums( $dirfiles{varnumbershold}->[0], \@blockelts );
      }
      else
      {
        %varns = prepvarnums( \%varnums, \@blockelts );
      }

      my $cleanordres = cleanres( $sortmixed );
	    my $blankfile = "$sortmixed" . "_tmp_blank.csv";
	    my $bit = $file . "_";
	    my @bag =( $bit );
	    prepareblank( \%varns, $blankfile, \@blockelts, \@bag, $file, \%carrier ) ;


      sub prepfile
      {
        my ( $blankfile, $prepblank, $cleanordres, $prepsort, $blockelts_r, $varnums_r, $carrier_r, $metafile ) = @_;
        my @blockelts = @{ $blockelts_r };
        my %varnums = %{ $varnums_r };
        my %carrier = %{ $carrier_r };

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

        open( BLANKFILE, "$blankfile" ) or die;
        my @lines = <BLANKFILE>;
        close BLANKFILE;

        open( PREPBLANK, ">$prepblank" ) or die;
        foreach my $line ( @lines )
        {
          foreach my $key ( keys %modhs )
          {
            $line =~ s/$key-\d+/$key-$modhs{$key}/ ;
          }
          print PREPBLANK $line;
        }
        close PREPBLANK;

        open( CLEANORDRES, "$cleanordres" ) or die;
        my @lines = <CLEANORDRES>;
        close CLEANORDRES;

        open( PREPSORT, ">$prepsort" ) or die;
        foreach my $line ( @lines )
        {
          foreach my $key ( keys %modhs )
          {
            $line =~ s/$key-\d+/$key-$modhs{$key}/ ;
          }
          print PREPSORT $line;
        }
        close PREPSORT;

        return( %torecovers );
      }

      my $prepblank = $sortmixed . "_tmp_prepblank.csv";
      my $prepsort = $sortmixed . "_tmp_prepsort.csv";
      my %torecovers = prepfile( $blankfile, $prepblank, $cleanordres, $prepsort, \@blockelts, \%varnums, \%carrier, $metafile );

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
      {
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
	    close METAFILE;

	    if ( ( $direction eq "<" ) or ( $starorder eq "<" ) )
	    {
	      @sorted = sort { (split( ',', $a))[ 1 ] <=> ( split( ',', $b))[ 1 ] } @totlines;
	    }
	    elsif ( ( $direction eq ">" ) or ( $starorder eq ">" ) )
	    {
	      @sorted = sort { (split( ',', $b))[ 1 ] <=> ( split( ',', $a))[ 1 ] } @totlines;
	    }

      @sorted = uniq( @sorted );

	    open( ORDMETA,  ">>$ordmeta" ) or die;
	    foreach my $ln ( @sorted )
	    {
	      print ORDMETA $ln;
	    }
	    close ORDMETA;
		}
	}  # END SUB metamodel


  sub takeoptima
  {
    my ( $sortmixed, $carrier_r, $blockelts_r, $searchname, $orderedfile, $direction, $starorder, $mids_r,
    $blocks_r, $totres, $objectivecolumn, $ordres, $starpositions_r, $countstring, $starnumber, $ordtot,
    $file, $ordmeta, $orderedfile, $dirfiles_r, $countcase, $countblock, $varnums_r, $vehicles_r, $inst_r ) = @_;
    my %carrier = %{ $carrier_r };
    my @blockelts = @{ $blockelts_r };
    my @blocks = @{ $blocks_r };
    my @starpositions = @{ $starpositions_r };
    my %dirfiles = %{ $dirfiles_r };
    my %varnums = %{ $varnums_r };
    my %vehicles = %{ $vehicles_r };
    my $slicenum = $dirfiles->{slicenum};
    my %inst = %{ $inst_r };
    say $tee "HEEERE 3 CARRIER: " . dump( \%carrier );

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

    if ( $slicenum eq "" )
    {
      $slicenum = scalar( @lines ) - 1;
    }

    my $halfremainder = ( ( scalar( @lines ) - $slicenum ) / 2 );
    my $winnerentry;
    if ( ( $direction eq ">" ) or ( ( $direction eq "star"  ) and ( $starorder eq ">"  ) ) )
    {
      $winnerentry = $lines[0];
      if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
      {
        push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
      }
    }
    elsif ( ( $direction eq "<" ) or ( ( $direction eq "star"  ) and ( $starorder eq "<"  ) ) )
    {
      $winnerentry = $lines[0];
      if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
      {
        push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
      }
    }
    elsif ( ( $direction eq "=" ) or ( ( $direction eq "star"  ) and ( $starorder eq "="  ) ) )
    {
      my $half = ( int( scalar( @lines ) / 2 )  );
      $winnerentry = $lines[ $half ];
      if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
      {
        push( @{ $vehicles{$countcase}{$countblock} }, @lines[$halfremainder..(-$halfremainder)]);
      }
    }
    chomp $winnerentry;

    my @winnerelms = split( /,/, $winnerentry );
    my $winneritem = $winnerelms[0];

    say $tee "HEEERE WINNERITEM BEFORE CLEANING: $winneritem.";
    $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file );
    say $tee "HEEERE WINNERITEM AFTER CLEANING: $winneritem.";
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
            say MESSAGE "Attention. At case " . ( $countcase + 1 ) . ", block " . ( $countcase + 1 ) . "There is a tie between optimal cases. Besides case $winnerline, producing a compound objective function of $winnerval, there is the case $case producing the same objective function value. Case $winnerline has been used for the search procedures which follow.\n";
          }
        }
      }
      $countelm++;
    }
    close (MESSAGE);

    push( @{ $datastruc{$word} }, $winnerline );

    #if ( $countblock == 0 )
    #{
    #  shift( @{ $winneritems[$countcase][$countblock] } );
    #}



    ################################################### STOP CONDITIONS!

    if ( $countblock == $#blocks )
    {
      #if ( $sourceblockelts[0] =~ />/ )
      #{
      #  $dirfiles{starsign} = "yes";
      #}

      if ( ( $dirfiles{starsign} eq "yes" ) or
    			( ( $dirfiles{random} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
          ( ( $dirfiles{randompick} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{latinhypercube} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{factorial} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{facecentered} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) ) ### BEGINNING OF THE PART ON STAR CONFIGURATIONS
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

        my @morphcases = grep -d, <$mypath/$file_*>;
        unless ( $direction eq "star" )
        {
          say $tee "#Optimal option for case " . ( $countcase + 1 ) . ": $newtarget.";
        }

        @totalcases = uniq( @totalcases );
        my $netinstnum = scalar( @totalcases );

        say $tee "#Net number of instances: $netinstnum." ;
        open( RESPONSE , ">>$mypath/response.txt" );
        unless ( $direction eq "star" )
        {
          say RESPONSE "#Optimal option for case " . ( $countcase + 1 ) . ": $newtarget.";
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
            @lines = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lines;
          }
          elsif ( ( $starorder = "<" ) or ( $direction = "<" ) )
          {
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

        my @blockelts = @{ Sim::OPT::getblockelts( \@sweeps, $countcase, $countblock ) }; say $tee "IN callblock \@blockelts " . dump( @blockelts );

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

        if ( $slicenum eq "" )
        {
          $slicenum = scalar( @lines ) - 1;
        }

        my $winnerentry;
        if ( ( $direction eq ">" ) or ( ( $direction eq "star"  ) and ( $starorder eq ">"  ) ) )
        {
          $winnerentry = $lines[0];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
          }
        }
        elsif ( ( $direction eq "<" ) or ( ( $direction eq "star"  ) and ( $starorder eq "<"  ) ) )
        {
          $winnerentry = $lines[0];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
          }
        }
        elsif ( ( $direction eq "=" ) or ( ( $direction eq "star"  ) and ( $starorder eq "="  ) ) )
        {
          my $half = ( int( scalar( @lines ) / 2 )  );
          $winnerentry = $lines[ $half ];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[$halfremainder..(-$halfremainder)]);
          }
        }
        chomp $winnerentry;


        if ( $dirfiles{popsupercycle} = "yes" )
        {
          $dirfiles{launching} = "yes";
          my $revealnum = $dirfiles{revealnum} - 1;
          my $revealfile = $file . "_" . "reveal-" . "$countcase-$countblock.csv";
          my @group = @lines[0..$revealnum];
          my @reds;
          foreach my $el ( @group )
          {
            my @els = split( ",", $el );
            push( @reds, $els[0] );
          }

          my $c = 0;
          foreach my $instance ( @{ $vehicles{cumulateall} } )
          {
            if ( $instance->{is} ~~ @reds )
            {
              my @instancees;
              push( @instancees, $instance );
              if ( $dowhat{morph} eq "y" )
              {
                say $tee "#Calling morphing operations for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
                my @result = Sim::OPT::Morph::morph( $configfile, \@instancees, \%dirfiles, \%dowhat, \%vehicles, \%inst );
              }

              if ( ( $dowhat{simulate} eq "y" ) or ( $dowhat{newreport} eq "y" ) )
              {

                say $tee "#Calling simulations, reporting and retrieving for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
                my ( $simcases_ref, $simstruct_ref, $repcases_ref, $repstruct_ref,
                  $mergestruct_ref, $mergecases_ref, $c ) = Sim::OPT::Sim::sim(
                    { instances => \@instancees, dirfiles => \%dirfiles, vehicles => \%vehicles, inst => \%inst } );
                    $dirfiles{simcases} = $simcases_ref;
                    $dirfiles{simstruct} = $simstruct_ref;
                    $dirfiles{repcases} = $repcases_ref;
                    $dirfiles{repstruct} = $repstruct_ref;
                    $dirfiles{mergestruct} = $mergestruct_ref;
                    $dirfiles{mergecases} = $mergecases_ref;
              }
            }
          }
          if ( $dowhat{metamodel} eq "yes" )
          {
            $dirfiles{nestclock} = $dirfiles{nestclock} - 1;
          }
          $dirfiles{launching} = "no";
        }

        my @winnerelms = split( /,/, $winnerentry );
        my $winneritem = $winnerelms[0];

        $countblock = 0;
        $countcase++; ####!!!

        $countstring++;
        $dirfiles{countstring} = $countstring;
        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file );

        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem );

        @varnumbers = @{ dclone( $dirfiles{varnumbershold} ) };
        @miditers = @{ dclone( $dirfiles{miditershold} ) };

        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, datastruc => \%datastruc, dowhat => \%dowhat ,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
      } ### END OF THE PART ON STAR CONFIGURATIONS
      else
      {
        #say $tee "IN CASE END NOT STARSIGN.";
        $countblock = 0;
        $countcase++; ####!!!

        $countstring++;
        $dirfiles{countstring} = $countstring;
        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file );

        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem );

        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, datastruc => \%datastruc, dowhat => \%dowhat ,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
      }
    }
    elsif( $countblock < $#blocks )
    {
      if ( ( $dirfiles{starsign} eq "yes" ) or
    			( ( $dirfiles{random} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
          ( ( $dirfiles{randompick} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{latinhypercube} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{factorial} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) or
    			( ( $dirfiles{facecentered} eq "yes" ) and ( $dowhat{metamodel} eq "yes" ) ) )
      { ### BEGINNING OF THE PART ABOUT STAR CONFIGURATIONS
        my $metafile = $sortmixed . "_tmp_meta.csv";
        my $ordmeta = $sortmixed . "_ordmeta.csv";

        my @blockelts = @{ Sim::OPT::getblockelts( \@sweeps, $countcase, $countblock ) };

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
          $winnerentry = $lines[0];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
          }
        }
        elsif ( ( $direction eq "<" ) or ( ( $direction eq "star"  ) and ( $starorder eq "<"  ) ) )
        {
          $winnerentry = $lines[0];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
          }
        }
        elsif ( ( $direction eq "=" ) or ( ( $direction eq "star"  ) and ( $starorder eq "="  ) ) )
        {
          my $half = ( int( scalar( @lines ) / 2 )  );
          $winnerentry = $lines[ $half ];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[$halfremainder..(-$halfremainder)]);
          }
        }
        chomp $winnerentry;

        if ( $dirfiles{popsupercycle} = "yes" )
        {
          $dirfiles{launching} = "yes";
          my $revealnum = $dirfiles{revealnum} - 1;
          my $revealfile = $file . "_" . "reveal-" . "$countcase-$countblock.csv";
          my @group = @lines[0..$revealnum];
          my @reds;
          foreach my $el ( @group )
          {
            my @els = split( ",", $el );
            push( @reds, $els[0] );
          }

          my $c = 0;
          foreach my $instance ( @{ $vehicles{cumulateall} } )
          {
            if ( $instance->{is} ~~ @reds )
            {
              my @instancees;
              push( @instancees, $instance );
              if ( $dowhat{morph} eq "y" )
              {
                say $tee "#Calling morphing operations for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
                my @result = Sim::OPT::Morph::morph( $configfile, \@instancees, \%dirfiles, \%dowhat, \%vehicles, \%inst );
              }

              if ( ( $dowhat{simulate} eq "y" ) or ( $dowhat{newreport} eq "y" ) )
              {

                say $tee "#Calling simulations, reporting and retrieving for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
                my ( $simcases_ref, $simstruct_ref, $repcases_ref, $repstruct_ref,
                  $mergestruct_ref, $mergecases_ref, $c ) = Sim::OPT::Sim::sim(
                    { instances => \@instancees, dirfiles => \%dirfiles, vehicles => \%vehicles, inst => \%inst } );
                    $dirfiles{simcases} = $simcases_ref;
                    $dirfiles{simstruct} = $simstruct_ref;
                    $dirfiles{repcases} = $repcases_ref;
                    $dirfiles{repstruct} = $repstruct_ref;
                    $dirfiles{mergestruct} = $mergestruct_ref;
                    $dirfiles{mergecases} = $mergecases_ref;
              }
              #if ( $dowhat{descend} eq "y" )
              #{
              #	say $tee "#Calling descent for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ".";
              #	#say $tee "\@sourcesweeps: " . dump( @sourcesweeps );
              #	Sim::OPT::Descend::descend(	{ instances => \@instancees, dirfiles => \%dirfiles, vehicles => \%vehicles } );
              #}
            }
          }
          $dirfiles{launching} = "no";
        }

        my @winnerelms = split( /,/, $winnerentry );
        my $winneritem = $winnerelms[0];

        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file );

        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem );

        @varnumbers = @{ dclone( $dirfiles{varnumbershold} ) };
        @miditers = @{ dclone( $dirfiles{miditershold} ) };

        $countblock++; ### !!!        push ( @{ $winneritems[$countcase][$countblock + 1] }, $winneritem );

        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, datastruc => \%datastruc, dowhat => \%dowhat,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
      } ### END OF THE PART ABOUT STAR CONFIGURATIONS
      else
      { say $tee "RELAUNCHING WITH INST " . dump( %inst );
        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file );

        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem );

        $countblock++; ### !!!

        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, datastruc => \%datastruc, dowhat => \%dowhat,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
      }
    }
  } # END SUB takeoptima

  say $tee "IN DESCEND BEFORE TAKEOPTIMA; INST " . dump( %inst );
  say $tee "HEEERE 2 CARRIER: " . dump( \%carrier );
  takeoptima( $sortmixed, \%carrier, \@blockelts, $searchname, $orderedfile, $direction, $starorder,
  \%mids, \@blocks, $totres, $objectivecolumn, $ordres, \@starpositions, $countstring, $starnumber,
  $ordtot, $file, $ordmeta, $orderedfile, \%dirfiles, $countcase, $countblock, \%varnums, \%vehicles, \%inst ); #say $tee "TAKEOPTIMA \$sortmixed : " . dump( $sortmixed );
  close OUTFILE;
  close TOFILE;
}    # END SUB descend

# TO DO: TEST NUM META WINNERS.

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

Copyright (C) 2008-2021 by Gian Luca Brunetti and Politecnico di Milano. This is free software. You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
