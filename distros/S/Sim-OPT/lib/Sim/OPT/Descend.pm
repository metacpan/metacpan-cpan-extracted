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
use Data::Dump qw(dump);
use Data::Dumper;
use feature 'say';
use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Sim;
use Sim::OPT::Report;
use Sim::OPT::Takechance;
use Sim::OPT::Modish;

$Data::Dumper::Indent = 0;
$Data::Dumper::Useqq  = 1;
$Data::Dumper::Terse  = 1;

no strict; 
no warnings;

@ISA = qw(Exporter); # our @adamkISA = qw(Exporter);
#%EXPORT_TAGS = ( DEFAULT => [qw( &opt &prepare )]); # our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#@EXPORT   = qw(); # our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( descend ); # our @EXPORT = qw( );

$VERSION = '0.58.00'; # our $VERSION = '';
$ABSTRACT = 'Sim::OPT::Descent is an module collaborating with the Sim::OPT module for performing block coordinate descent.';

#########################################################################################
# HERE FOLLOWS THE CONTENT OF "Descend.pm" - Sim::OPT::Descend
##############################################################################

sub descend 
{
  my $swap = shift; 
  my %dat = %$swap;
  my @instances = @{ $dat{instances} }; 
  my $countcase = $dat{countcase}; 
  my $countblock = $dat{countblock}; 
  my %dirfiles = %{ $dat{dirfiles} }; 
  my %datastruc = %{ $dat{datastruc} }; ######
  my @rescontainer = @{ $dat{rescontainer} }; ######
    
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
  
  #open( OUTFILE, ">>$outfile" ) or die "Can't open $outfile: $!"; 
#  open( TOFILE, ">>$tofile" ) or die "Can't open $tofile: $!";  
  $tee = new IO::Tee(\*STDOUT, ">>$tofile"); # GLOBAL ZZZ
  say $tee "\n#Now in Sim::OPT::Descend.\n";
  
  
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
  @report_loadsortemps = @main::report_loadsortemps;
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
  my @repstruct = @{ $dirfiles{repstruct} }; say $tee "dumpINDESCEND(\@repstruct): " . dump(@repstruct);
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
  my $repfile = $repstruct[$countcase][$countblock][0]; say $tee "OBTAINED \$repfile : " . dump( $repfile );
  if ( not ( defined( $repfile ) ) )
  {
    $repfile = $dirfiles{repfilebackup}; 
  }
  say $tee "OBTAINED BACKUP \$repfile : " . dump( $repfile );
  
  my $instance = $instances[0]; # THIS WOULD HAVE TO BE A LOOP HERE TO MIX ALL THE MERGECASES!!! ### ZZZ
  
  my %d = %{$instance};
  my $countcase = $d{countcase}; 
  my $countblock = $d{countblock}; 
  my %datastruc = %{ $d{datastruc} }; ######
  my @rescontainer = @{ $d{rescontainer} }; ######
  my @miditers = @{ $d{miditers} }; say $tee "BEGIN DESCENT \@miditers : " . dump(@miditers);
  my @winneritems = @{ $d{winneritems} }; say $tee " \@winneritems " . dump(@winneritems);
  my $countvar = $d{countvar}; 
  my $countstep = $d{countstep}; 
  my $to = $d{to}; 
  my $origin = $d{origin}; 
  my @uplift = @{ $d{uplift} }; 
  my @backvalues = @{ $d{backvalues} }; say $tee "IN DESCENT \@backvalues " . dump(@backvalues);
  my @sweeps = @{ $d{sweeps} }; say $tee "dump(\@sweeps): " . dump(@sweeps);
  my @sourcesweeps = @{ $d{sourcesweeps} }; say $tee "dump(\@sourcesweeps): " . dump(@sourcesweeps);
  
  my $counthold = 0;
  
  my $skip = $vals{$countvar}{skip}; 
  
  my $rootname = Sim::OPT::getrootname(\@rootnames, $countcase); 
  my @blockelts = Sim::OPT::getblockelts(\@sweeps, $countcase, $countblock); 
  my @blocks = Sim::OPT::getblocks(\@sweeps, $countcase);  
  my $toitem = Sim::OPT::getitem(\@winneritems, $countcase, $countblock); 
  my $from = Sim::OPT::getline($toitem); 
  my %varnums = Sim::OPT::getcase(\@varinumbers, $countcase); 
  my %mids = Sim::OPT::getcase(\@miditers, $countcase); 

  my $word = join( ", ", @blockelts ); ###NEW
  
  my $stepsvar = Sim::OPT::getstepsvar($countvar, $countcase, \@varinumbers); 
  my $varnumber = $countvar; 
  my $contblocksplus = ($countblock + 1);
  my $countcaseplus = ($countcase + 1);
  
  say $tee "Descending into case $countcaseplus, block $contblocksplus.";

  my @columns_to_report = @{ $reporttempsdata[1] };  
  my $number_of_columns_to_report = scalar(@columns_to_report); 
  my $number_of_dates_to_mix = scalar(@simtitles); 
  my @dates                    = @simtitles; 

  my $cleanmixed = "$repfile-clean.csv"; 
  my $throwclean = $cleanmixed; $throwclean =~ s/\.csv//;
  my $selectmixed = "$throwclean-select.csv"; 
  
  sub cleanselect
  {   # IT CLEANS THE MIXED FILE AND SELECTS SOME COLUMNS, THEN COPIES THEM IN ANOTHER FILE
    my ( $repfile, $cleanmixed, $selectmixed ) = @_;
    say $tee "Cleaning results for case $countcaseplus, block $contblocksplus.";
    open( MIXFILE, $repfile ) or die( "$!" ); say $tee "dump(\$repfile IN SUB cleanselect): " . dump($repfile); 
    my @lines = <MIXFILE>; 
    close MIXFILE;
    open( CLEANMIXED, ">$cleanmixed" ) or die( "$!" );
    
    foreach my $line ( @lines )
    {
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
        my @elts = split(/\s+|,/, $line); ### DDD
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

    if ( not ( Sim::OPT::checkdone( $to, @rescontainer ) eq "yes" ) )
  {
    cleanselect( $repfile, $cleanmixed, $selectmixed );
  }
  
  
  my $throw = $selectmixed; $throw =~ s/\.csv//;
  my $weight = "$throw-weight.csv"; 
  sub weight
  {  
    my ( $selectmixed, $weight ) = @_;
    say $tee "Scaling results for case $countcaseplus, block $contblocksplus.";
    open( SELECTEDMIXED, $selectmixed ) or die( "$!" ); 
    my @lines = <SELECTEDMIXED>; 
    close SELECTEDMIXED;
    my $counterline = 0;
    open( WEIGHT, ">$weight" ) or die( "$!" );
    
    my @containerone;
    my @containernames;
    foreach my $line (@lines)
    {
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
          
      print TOFILE "MAXES: " . Dumper(@maxes) . "\n";
      print TOFILE "DUMPCOLUMN: " . Dumper(@column) . "\n";
      
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
    print TOFILE "CONTAINERTWO " . Dumper(@containertwo) . "\n";
        
    my $countline = 0;
    foreach my $line (@lines)
    {
      $line =~ s/^[\n]//;
      my @elts = split(/\s+|,/, $line);    
      my $countcolm = 0;
      foreach $eltref (@containertwo)
      {
        my @col =  @{$eltref};
        my $max = max(@col); print TOFILE "MAX IN SUB weight: $max\n";
        my $min = min(@col); print TOFILE "MIN IN SUB weight: $min\n";
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
  if ( not ( Sim::OPT::checkdone( $to, @rescontainer ) eq "yes" ) )
  {
    weight( $selectmixed, $weight ); #
  }
  
  
  my $weighttwo = "$throw-weighttwo.csv"; # THIS WILL HOST PARTIALLY SCALED VALUES, MADE POSITIVE AND WITH A CELING OF 1
  sub weighttwo
  {
    my ( $weight, $weighttwo ) = @_;
    say $tee "Weighting results for case $countcaseplus, block $contblocksplus.";
    open( WEIGHT, $weight ); 
    my @lines = <WEIGHT>;
    close WEIGHT;
    open( WEIGHTTWO, ">$weighttwo" ); 
    my $counterline;
    foreach my $line (@lines)
    {
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
          print TOFILE "ELT: $elt\n";
          $newelt = ( $elt * abs($weights[$counterin]) ); 
          print TOFILE "ABS " . abs($weights[$counterin]) . "\n";
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
  if ( not ( Sim::OPT::checkdone( $to, @rescontainer ) eq "yes" ) )
  {
    weighttwo( $weight, $weighttwo );
  }
    
  
  
  my $sortmixed = "$repfile-sortmixed.csv"; 
  #if ($repfile) { $sortmixed = "$repfile-sortmixed.csv"; } else { die( "$!" ); } # globsAL!
  sub sortmixed
  {
    my ( $weighttwo, $sortmixed ) = @_;
    say $tee "Processing results for case $countcaseplus, block $contblocksplus.";
    open( WEIGHTTWO, $weighttwo ) or die( "$!" ); 
    open( SORTMIXED_, ">$sortmixed" ) or die( "$!" ); 
    my @lines = <WEIGHTTWO>;
    close WEIGHTTWO;
    
    my $count = 0;
    foreach ( @lines )
    {
      $_ = "$containernames[$count]," . "$_";
      $count++;
    }
    say TOFILE "TAKEOPTIMA--dump(\@lines): " . dump(@lines);
    
    my $line = $lines[0];
    my @eltstemp = split( /,/, $line );
    my $numberelts = scalar( @eltstemp );
    
    #my @sorted = sort { (split(/,/, $b))[$#eltstemp] <=> (split(/,/, $a))[$#eltstemp] } @lines;
    my @sorted = sort { ( split( /,/, $a ) )[ $#eltstemp ] <=> (split( /,/, $b ) )[ $#eltstemp ] } @lines;
    
    foreach my $line ( @sorted ) 
    {
      $line =~ s/^,//;
      $line =~ s/^\s+//;
      print SORTMIXED_ $line;

      if ( not ( Sim::OPT::checkdone( $to, @rescontainer ) eq "yes" ) )
      {
        push( @rescontainer, $line );
      }
    }
    
    #if ($numberelts > 0) { print SORTMIXED_ `sort -t, -k$numberelts -n $weighttwo`; } 
    
    #my @sorted = sort { $b->[1] <=> $a->[1] } @lines;
    
    
    #sort { $a->[$#eltstemp] <=> $b->[$#eltstemp] }
    #map { [ [ @lines ] , /,/ ] }
    #foreach my $elt (@sorted)
    #{
    #  print $SORTMIXED "$elt";
    #}

    #if ($numberelts > 0) { print SORTMIXED_ `sort -n -k$numberelts,$numberelts -t , $weighttwo`; } ### ZZZ
    
    close SORTMIXED_;
  }
  sortmixed( $weighttwo, $sortmixed );
  
  ##########################################################
  
  
  sub takeoptima
  {
    my ( $sortmixed, $uplift_ref ) = @_;
    my @uplift = @$uplift_ref;
    #my $pass_signal = ""; # IF VOID, GAUSS SEIDEL METHOD. IF 0, JACOBI METHOD. ...
    
    
    
    
    open( SORTMIXED_, $sortmixed ) or die( "$!" );
    my @lines = <SORTMIXED_>;
    close SORTMIXED_;
    
    my $winnerentry = $lines[0]; #ay TOFILE "dump( IN SUB TAKEOPTIMA\$winnerentry): " . dump($winnerentry);
    chomp $winnerentry;
    
    my @winnerelms = split(/\s+|,/, $winnerentry);
    my $winnerline = $winnerelms[0]; 
    my $winnerval = $winnerelms[-1];
    push ( @{ $uplift[$countcase][$countblock] }, $winnerval); 
    
    my $message;
    unless ( ( "$^O" eq "MSWin32" ) or ( "$^O" eq "MSWin64" ) ) 
    {
      $message = "$mypath/attention.txt";
    }
    else
    {
      $message = "$mypath\\attention.txt";
    }
    
    open( MESSAGE, ">>$message");
    my $countelm = 0;
    foreach my $elm (@lines)
    {
      my @lineelms = split( /\s+|,/, $elm );
      my $val = $lineelms[-1];
      my $case = $lineelms[0];
      {
        if ($countelm > 0)
        {
          if ( $val ==  $winnerval )
          {
            say MESSAGE "Attention. At case $countcaseplus, block $contblocksplus. There is a tie between optimal cases. Besides case $winnerline, producing a compound objective function of $winnerval, there is the case $case producing the same objective function value. Case $winnerline has been used for the search procedures which follow.\n";
          }
        }
      }
      $countelm++;
    }
    close (MESSAGE);
  say $tee "BEFORE PUSHING --->\@backvalues " . dump( @backvalues );
    my ( $copy, $newtarget );
    my ( @taken );
    my ( %newcarrier );  
    
    #my $openingelt = if ($sourcesweeps[ $countcase ][ $countblock ][0] =~ /\>/) { $sourcesweeps[ $countcase ][ $countblock ][0] =~ s/>//; };
    my $closingelt;
    if ( $sourcesweeps[ $countcase ][ $countblock ][-1] =~ /\>/ ) 
    { 
      $sourcesweeps[ $countcase ][ $countblock ][-1] =~ s/>//; 
      $closingelt = $sourcesweeps[ $countcase ][ $countblock ][-1];
    };
    
    #if ( defined( $openingelt ) )
    #{  
    #  my @contained = @{ $datastruc{$openingelt} };
    #  my @sorted = sort { ( split( /,/, $a ) )[ $#contained ] <=> (split( /,/, $b ) )[ $#contained ] } @contained ;
    #}
    
    push( @backvalues, [ $winnerline, $winnerval ] );  say $tee "OBTAINED--->\@backvalues " . dump( @backvalues );
    push( @{ $datastruc{$word} }, $winnerentry );  say $tee "OBTAINED--->\@{ \$datastruc{\$word} } " . dump( @{ $datastruc{$word} } );
    say $tee "\$sourcesweeps[ \$countcase ][ \$countblock ][0] " . dump( $sourcesweeps[ $countcase ][ $countblock ][0] );
    
    if ( ( not ( defined( $openingelt ) ) ) and ( not ( defined( $closingelt ) ) ) )
    {  
      my ( @values, @keys );
      foreach my $values_ref ( @backvalues )
      {
        my $key = $values_ref->[0];
        my $value = $values_ref->[1];
        push( @keys, $key );
        push( @values, $value );
      }
      my $optimal = min( @values );
      
      
      my $count = 0;
      my ( $truewinnerline );
      foreach my $value ( @values )
      {
        if ( $value == $optimal )
        {
          $truewinnerline = $keys[ $count ];
          $count++;
        }
      }
      
      
      $copy = $truewinnerline;
      $copy =~ s/$mypath\/$file//;
      @taken = Sim::OPT::extractcase( "$copy", \%mids ); 
      $newtarget = $taken[0]; 
      $newtarget =~ s/$mypath\///;
      %newcarrier = %{ $taken[1] }; 
      
      %{ $miditers[$countcase] } = %newcarrier; 
      @backvalues = ( ); #EMPTY THE CONTAINER
    }
    elsif ( defined( $closingelt ) )
    {
      foreach my $values_ref ( @backvalues )
      {
        my $key = $values_ref->[0];
        my $value = $values_ref->[1];
        push( @keys, $key );
        push( @values, $value );
      }
      my $optimal = min( @values );
      
      
      my $count = 0;
      my ( $truewinnerline );
      foreach my $value ( @values )
      {
        if ( $value == $optimal )
        {
          $truewinnerline = $keys[ $count ];
          $count++;
        }
      }
      
      
      $copy = $truewinnerline;
      $copy =~ s/$mypath\/$file//;
      @taken = Sim::OPT::extractcase( "$copy", \%mids ); 
      $newselected = $taken[0]; 
      $newselected =~ s/$mypath\///;
      push ( @{ $datastruc{$closingelt} }, $newselected ); 
    
      $copy_old = $winnerline;
      $copy_old =~ s/$mypath\/$file//;
      @taken_old = Sim::OPT::extractcase( "$copy_old", \%mids ); 
      $newtarget = $taken_old[0]; 
      $newtarget =~ s/$mypath\///;
      @backvalues = ( ); #EMPTY THE CONTAINER
    }
    
    
    say $tee "TAKEOPTIMA AFTER->\@miditers: " . dump(@miditers);
    
    
    $countblock++; ### !!!
    
        
    # STOP CONDITION
    if ( $countblock == scalar( @blocks ) ) # NUMBER OF BLOCK OF THE CURRENT CASE
    { 
      say $tee "TAKEOPTIMA FINAL ->\$countblock " . dump($countblock);
      my @morphcases = grep -d, <$mypath/$file_*>;
      say $tee "#Optimal option for case  $countcaseplus: $newtarget";
      #my $instnum = Sim::OPT::countarray( @{ $morphstruct[$countcase] } );
      
      my $netinstnum = scalar( @morphcases );
      say $tee "#Net number of instances: $netinstnum." ;
      open( RESPONSE , ">$mypath/response.txt" );
      say RESPONSE "#Optimal option for case  $countcaseplus: $newtarget";
      
      say RESPONSE "#Net number of instances: $netinstnum." ;
        
      $countblock = 0;
      $countcase = $countcase++;
      if ( $countcase == scalar( @sweeps ) )# NUMBER OF CASES OF THE CURRENT PROBLEM
      {
        exit (say $tee "#END RUN.");          
      }
    }
    else
    {
      push ( @{ $winneritems[$countcase][$countblock] }, $newtarget ); say $tee "TAKEOPTIMA->\@winneritems " . dump(@winneritems);
      say $tee "#Leaving case " . ($countcase + 1) . ", block " . ($countblock + 1) . " and descending!\ ";
      Sim::OPT::callcase( { countcase => $countcase, countblock => $countblock, 
      miditers => \@miditers,  winneritems => \@winneritems, 
      dirfiles => \%dirfiles, uplift => \@uplift,
      backvalues => \@backvalues,
      sweeps => \@sweeps, sourcesweeps => \@sourcesweeps, datastruc => \%datastruc } );
    }
  }
  takeoptima( $sortmixed, \@uplift );
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

Sim::OPT::Descent is an module collaborating with the Sim::OPT module for performing block coordinate descent, or parallel blocks search, or free mixes of the two. It closes the circularly recursive loop formed by Sim::OPT -> Sim::OPT::Morph -> Sim::OPT::Sim -> Sim::OPT::Report::retrieve -> Sim::OPT::Report::report -> Sim::OPT::Descent, which repeats at every block search cycle.

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
