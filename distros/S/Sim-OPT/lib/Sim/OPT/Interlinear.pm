package Sim::OPT::Interlinear;

# INTERLINEAR, v. 0.0013
# Author: Gian Luca Brunetti, Politecnico di Milano. (gianluca.brunetti@polimi.it)
# Copyright reserved.  2018.
# GPL License 3.0 or newer.
# This is a program for filling a design space multivariate discrete dataseries
# by creatinng recursive and progressive relations by various strategies.
use v5.14;
use Math::Round;
use List::Util qw[ min max reduce shuffle];
use Statistics::Basic qw(:all);
use List::Compare;
use Set::Intersection;
use List::MoreUtils qw(uniq);
use List::AllUtils qw(sum);
use Data::Dump qw(dump);
use IO::Tee;
use feature 'say';
no strict;
no warnings;

use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Sim;
use Sim::OPT::Report;
use Sim::OPT::Descend;
use Sim::OPT::Takechance;
use Sim::OPT::Parcoord3d;

our @ISA = qw( Exporter );
our @EXPORT = qw( interlinear, interstart );

$VERSION = '0.013';
$ABSTRACT = 'Interlinear is a program for building metamodels from incomplete, multivariate, discrete dataseries on the basis of gradients weighted proportionally to multidimensional distances.';

#######################################################################
# Interlinear
#######################################################################


my $maxloops= 1000;
my $sourcefile = "/home/luca/int/starcloud_micro.csv";
my $newfile = $sourcefile . "_micro_cy_1_1_1_new.csv";
my $report = $newfile . "_report.txt";
my @mode = ( "wei" ); # #"wei" is weighted gradient linear interpolation of the nearest neighbours.
#my @mode = ( "near" ); # "nea" means "nearest neighbour"
#@mode = ( ""mix" ); # "mix" means sequentially mixed in each loop.
#my @mode = ( "wei", "near", "near", "purelin" ); # a sequence
my @weights = (  ); #my @weights = ( 0.7, 0.3 ); # THE FIRST IS THE WEIGHT FOR linear interpolation, THE SECOND FOR nearest neighbour.
# THEY ARE FRACTIONS OF 1 AND MUST GIVE 1 IN TOTAL. IF THE VALUES ARE UNSPECIFIED (IE. IF THE ARRAY IS EMPTY), THE VALUES ARE UNWEIGHTED.
my $linearprecedence = "no"; # PRECEDENCE TO LINEAR INTERPOLATES. IF "yes", THE VALUES DERIVED FROM LINEAR INTERPOLATION, WHERE PRESENT, WILL SUPERSEDE THE VALUES DERIVED FROM THE NEAREST NEIGHBUR STRATEGY. IF "no", THE OPPOSITE. IT CAN BE ACTIVE ONLY IF LOGARITHMIC IS OFF. IT WORKS WITH "LINEAR" AND "EXPONENTIAL"

my $relaxmethod = "logarithmic"; #It is relative to the "linnear" method. Options: "logarithmic", "linear" or "exponential". THE FARTHER NEIGHBOURS ARE WEIGHT LESS THAN THE NEAREST ONES: INDEED, LOGARITHMICALLY, LINEARLY OR EXPONENTIALLY. THE LOGARITHM BASE IS $relaxlimit OR $nearrelaxlimit, DEPENDING FROM THE CONTEXT. THE LINEAR MULTIPLICATOR OR THE EXPONENT IS DEFINED BY $overwerightnearest.
my $relaxlimit = 1; #THIS IS THE CEILING FOR THE RELAXATION OF THE RELATIONS OF PURE LINEAR INTERPOLATION. For greatest precision: 0, or a negative number near 0. IF > = 0, THE PROGRAM INTERPOLATES ALSO NEAREST NEIGHBOURS. THE HIGHER THE NUMBER, THE FARTHER THE NEIGHBOURS.
my $overweightnearest = 1; #A NUMBER. IT IS MADE NULL BY THE $logarithmicrelax "yes". THE HIGHER THE NUMBER, THE GREATER THE OVERWEIGHT GIVEN TO THE NEAREST. IN THIS MANNER, THE OVERWEIGHT IS NOT LOGARITHMIC, LIKE IT WHERE OTHERWISE, BUT LINEAR. THIS SLOWS DOWN THE COMPUTATIONS. UNLESS THE OVERWEIGHT IS 1, WHICH MAKES THE OVERWEIGHTING NULL.
my $nearrelaxlimit = 0; #THIS IS THE CEILING FOR THE RELAXATION OF THE RELATIONS OF THE NEAREST NEIGHBOUR STRATEGY. For greatest precision: 0, or a negative number near 0. IF > = 0, THE PROGRAM INCREASES THE DISTANCE OF THE NEAREST NEIGHBOURS INCLUDED. THE HIGHER THE NUMBER, THE FARTHER THE NEIGHBOURS. ONE IS NOT LIKELY TO WANT TO USE THIS OPTION.
my $nearconcurrencies = 1; #Requested minimum number of concurrencies for the nearest neighbour method. Minimum value: 1. The more the requested concurrencies, the greatest the precision, the slowest the convergence.
my $parconcurrencies = 1; #Requested minimum number of concurrencies for the linear interpolations for each parameter of each instance. Minimum value: 1. The more the requested concurrencies, the greatest the precision, the slowest the convergence.
my $instconcurrencies = 1; #Requested minimum number of concurrencies for the linear interpolations for each instance. Minimum value: 1. The more the requested concurrencies, the greatest the precision, the slowest the convergence.
# my %factlevels = ( pairs => { 1=>3, 2=>3, 3=>3, 4=>3, 5=>3 } ); #The keys are the factor numbers and the values are the number of levels in the data series. OBSOLETE.
my $minreq_forgrad = [1, 1, 1 ]; #THIS VALUES SPECIFY THE NUMBER OF PARAMETER DIFFERENCES (INTEGER NUMBERS) TELLING HOW WELL-ROOTED IN SIMULATED REALITY (I.E, NEAR FROM IT) A POINT MUST BE TO SELECT IT FOR CALCULATING THE GRADIENTS FOR THE METAMODEL. THEY ARE INTEGERS STARTING FROM 1 OR GREATER.
# THE FIRST VALUE IS RELATIVE TO THE FACTORS AND TELLS HOW RELAXED A SEARCH IS.
# THE SECOND VALUE IS RELATIVE TO THE LEVELS. ONE MAY WANT TO KEEP IT TO 1: THE GRADIENTS ARE CALCULATED USING ONLY ADJACENT INSTANCES.
# ONE MAY WANT TO KEEP IT TO 1: THE GRADIENTS ARE CALCULATED USING ONLY ADJACENT INSTANCES.
# THE THIRD VALUE HOW DIFFERENT (FAR, IN TERMS OF PARAMETER DIFFERENCES) MAY AN INSTANCE BE TO BE CALDULATED THROUGH THE GRADIENT IN QUESTION.
# ONE MAY WANT TO SET TO THE NUMBER OF PARAMETERS.
# A LARGE NUMBER, WEAK ENTRY BARRIER. NEVER LESS THAN 1.

my $minreq_forinclusion = 0; # THIS VALUE SPECIFIES A STRENGTH VALUE (LEVEL OF RELIABILITY) TELLING HOW WELL-ROOTED IN SIMULATED REALITY A DERIVED POINT (META-POINT) MUST BE FOR INCLUDING IT IN THE SET OF POINTS USED FOR THE METAMODEL.If 0, no entry barrier.
my $minreq_forcalc = 0; # THIS VALUE SPECIFIES A STRENGTH VALUE (LEVEL OF RELIABILITY) TELLING HOW WELL-ROOTED IN SIMULATED REALITY A DERIVED POINT MUST BE FOR INCLUDING IT IN THE CALCULATIONS FOR CREATING NEW META-POINTS.  A VALUE BETWEEN 1 (JUST SIMULATED POINT) AND 0. If 0, no entry barrier.
my $minreq_formerge = 0; # THIS VALUE SPECIFIES A STRENGTH VALUE (LEVEL OF RELIABILITY) TELLING HOW WELL-ROOTED IN SIMULATED REALITY A DERIVED POINT MUST BE FOR MERGING IT IN THE CALCULATIONS FOR MERGING IT IN THE METAMODEL. A VALUE BETWEEN 1 (JUST SIMULATED POINT) AND 0 (SIMULATED POINTS AND "META"POINTS WITH THE SAME RIGHT ) MUST BE SPECIFIED. If 0, no entry barrier.
my $minimumcertain = 0; # WHAT IS THE MINIMUM LEVEL OF STRENGTH (LEVEL OF RELIABILITY) REQUIRED TO USE A DATUM TO BUILD UPON IT. IT DEPENDS ON THE DISTANCE FROM THE ORIGINS OF THE DATUM. THE LONGER THE DISTANCE, THE SMALLER THE STRENGTH (WHICH IS INDEED INVERSELY PROPORTIONAL). A STENGTH VALUE OF 1 IS OF A SIMULATED DATUM, NOT OF A DERIVED DATUM. If 0, no entry barrier.
my $minimumhold = 1; # WHAT IS THE MINIMUM LEVEL OF STRENGTH (LEVEL OF RELIABILITY) REQUIRED FOR NOT AVERAGING A DATUM WITH ANOTHER, DERIVED DATUM. USUALLY IT HAS TO BE KEPT EQUAL TO $minimimcertain.  If 1, ONLY THE MODEL DATA ARE NOT SUBSTITUTABLE IN THE METAMODEL.
my $condweight = "yes"; # THIS CONDITIONS TELLS IF THE STRENGTH (LEVEL OF RELIABILITY) OF THE GRADIENTS HAS TO BE CUMULATIVELY TAKEN INTO ACCOUNT IN THE WEIGHTING CALCULATIONS.

#######################################################################


sub odd
{
  my ( $number ) = @_;
  if ( $number % 2 == 1 )
  {
    return ( "odd" );
  }
  else
  {
    return ( "even" );
  }
}


sub tellstepsize
{
  my ( $flev_ref ) = @_;
  my %factlevels =  %{ $flev_ref }; #say $tee "FACTLEVELS0: " . dump( %factlevels ); say $tee "\$factlevels{pairs}: " . dump( $factlevels{pairs} );
  foreach my $fact ( sort {$a <=> $b} ( keys %{ $factlevels{pairs} } ) )
  { #say $tee "\$fact: " . dump( $fact );
    my $stepsize = ( 1 / ( $factlevels{pairs}{$fact} - 1 ) ); #say $tee "\$stepsize: " . dump( $stepsize );
    $factlevels{stepsizes}{$fact} = $stepsize ;
  } #say $tee "FACTLEVELS1: " . dump( %factlevels );
  return( \%factlevels );
}


sub union
{
  my $aref = shift;
  my $bref = shift;
  my @aa = @$aref; #say $tee ""\@aa: " . dump( @aa );
  my @bb = @$bref; #say $tee "\@bb: " . dump( @bb );

  my @union = uniq( @aa, @bb );
  return @union;
}

sub diff__
{
  my $aref = shift;
  my $bref = shift;
  my @aa = @$aref; #say "\@aa: " . dump( @aa );
  my @bb = @$bref; #say "\@bb: " . dump( @bb );
  my @difference;

  my @int = get_intersection( \@aa, \@bb );
  foreach ( @aa )
  {
    if ( not ( $_ ~~ @int ) )
    {
      push ( @difference, $_ );
    }
  }
  return @difference;
}


sub diff_old
{
  my $aref = shift;
  my $bref = shift;
  my @aa = @$aref; #say $tee "\@aa: " . dump( @aa );
  my @bb = @$bref; #say $tee "\@bb: " . dump( @bb );
  my @diff;
  my %bb_hash;
  undef @bb_hash{ @bb };
  my @diff = grep !exists $bb_hash{ $_ }, @aa;
  return @diff;
}


sub diff
{
  my $aref = shift;
  my $bref = shift;
  my @aa = @$aref; #say $tee "\@aa: " . dump( @aa );
  my @bb = @$bref; #say $tee "\@bb: " . dump( @bb );
  my %diff3;
  @diff3{@aa} = @aa;
  delete @diff3{@bb};
  my @diff = ( keys %diff3 );
  return @diff;
}


sub adjustmode
{
  my ( $maxloops, $mode_ref ) = @_;
  my @mode = @{ $mode_ref };
  my $count = 0;
  my @new;
  while ( scalar( @new ) <= ( $maxloops + scalar( @mode ) ) )
  {
    push ( @new, @mode );
    $count++;
  }
  @mode = @new;
  return( @mode );
}



sub preparearr
{
  my ( $lines_ref ) = @_;
  my $optformat = "yes";
  my @lines = @{ $lines_ref };
  if ( $lines[1] =~ /_/ )
  {
    foreach my $line ( @lines )
    {
      chomp( $line );
      my @row = split( /,/ , $line );
      @pars = split( /_/ , $row[0] );
      if ( $row[1] eq undef )
      {
        push ( @arr, [ $row[0], [ @pars ] ] );
      }
      else
      {
        push ( @arr, [ $row[0], [ @pars ], $row[1], 1 ] );
      }
    }
  }
  else
  {
    $optformat = "no";
    my @arrnumbers;
    foreach my $line ( @lines )
    {
      chomp( $line );
      my @row = split( /,/ , $line );
      @arrnumbers;
      push ( @arrnumbers , scalar( @row ) );
    }
    my $maxnum = max( @arrnumbers );

    foreach my $line ( @lines )
    {
      my @row = split( /,/ , $line );
      my $rightnum = ( $maxnum - 1 );
      my $count = 1;
      my @pars;
      while ( $count <= $rightnum )
      {
        my $bit = join( "-", ( $count, $row[$count-1] ) );
        push( @pars, $bit );
        $count++;
      }
      my $header = join( "_", @pars );

      if ( scalar( @row ) < $maxnum )
      {
        push ( @arr, [ $header, [ @pars ] ] );
      }
      else
      {
        push ( @arr, [ $header, [ @pars ], $row[-1], 1 ] );
      }
    }
  } #say $tee "ARR: " . dump( @arr );
  return( \@arr, $optformat );
}



sub pythagoras
{
  my ( $factbag_ref, $levbag_ref, $stepbag_ref ) = @_;
  my @factbag = @{ $factbag_ref }; #say $tee "\@factbag: " . dump( @factbag );
  my @levbag = @{ $levbag_ref }; #say $tee "\@levbag: " . dump( @levbag );
  my @stepbag = @{ $stepbag_ref }; #say $tee "\@stepbag: " . dump( @stepbag );
  my $powdist;
  my $inc = 0;
  foreach ( @factbag )
  {
    my $step = $stepbag[$inc]; #say "\$step: $step" ;
    my $difflevel = $levbag[$inc]; #say "\$difflevel: $difflevel" ;
    $powdist = $powdist + ( ( $difflevel * $step ) ** 2 );
    $inc++;
  }
  my $dist = $powdist ** ( 1/2 ); #say "DIST: $dist" ;
  return ( $dist );
}


sub weightvals1
{
  my ( $elt1, $boxgrads_ref, $boxdists_ref, $boxors_ref, $minreq_forcalc, $factbag_ref, $levbag_ref, $stepbag_ref, $elt2, $factlevels_ref, $maxdist, $elt3, $condweight ) = @_;
  my @boxgrads = @{ $boxgrads_ref }; #say $tee "weightvals1 \@boxgrads: " . dump( @boxgrads );
  my @boxdists = @{ $boxdists_ref }; #say $tee "weightvals1 \@boxdists: " . dump( @boxdists );
  my @boxors = @{ $boxors_ref }; #say $tee "weightvals1 \@boxors: " . dump( boxors );
  my @factbag = @{ $factbag_ref }; #say $tee "weightvals12 \@factbag: " . dump( @factbag );
  my @levbag = @{ $levbag_ref }; #say $tee "weightvals12 \@levbag: " . dump( @levbag );
  my @stepbag = @{ $stepbag_ref }; #say $tee "weightvals12 \@stepbag: " . dump( @stepbag );
  my %factlevels = %{ $factlevels_ref }; #say $tee "weightvals12 \%factlevels: " . dump( %factlevels );
  #say $tee "weightvals1 \$maxdist: " . dump( $maxdist );
  #say $tee "weightvals12 \$elt3: " . dump( $elt3 ); say $tee "weightvals12 \$condweight: " . dump( $condweight );
  #if ( ref( $minreq_forcalc ) )
  #{
  #  my $num = $minreq_forcalc->[0];
  #  my @sorteddists = sort( @boxdists );
  #  my @box;
  #  my $ci = 0;
  #  while ( $c1 < $num )
  #  {
  #    push ( @box, $sorteddists[$ci] );
  #    $ci++;
  #  }
  #  @boxdists = @box;
  #} #say $tee "weightvals1 \@boxdists: " . dump( @boxdists );

  my @newboxdists;
  foreach my $or ( @boxors )
  {
    my $hsh_ref = calcdist( $elt1, $or, \%factlevels, $maxdist, $elt3, $condweight ); #say $tee "555 \$hsh_ref: " . dump( $hsh_ref );
    my %hsh = %{ $hsh_ref }; #say $tee "556 \%hsh: " . dump( %hsh ); #say $tee "555 \$or: " . dump( $or );
    my $dist = $hsh{dist}; #say $tee "556 \$dist: " . dump( $dist );
    push ( @newboxdists, $dist );
  } #say $tee "556 \@newboxdists: " . dump( @newboxdists );

  my @boxstrengths;
  foreach my $dist ( @newboxdists )
  {
    if ( ( $dist ne "" ) and ( $dist != 0 ) )
    { #say $tee "IN \@boxstrengths: " . dump( @boxstrengths );
      my $strength = ( 1 - $dist );
      push ( @boxstrengths, $strength );
    }
  } #say $tee "556 \@boxstrengths: " . dump( @boxstrengths );

  my $sum_strengths;

  $sum_strengths = sum( @boxstrengths ); #say $tee "557 \$sum_strengths: " . dump( $sum_strengths );

  my $totdist;
  my $soughtgrad = 0;
  if ( not ( scalar( @boxgrads ) == 0 ) )
  {
    my $in = 0;
    foreach my $grad ( @boxgrads )
    {
      #say $tee "577 taken \$grad: " . dump( $grad );
      my $strength = $boxstrengths[$in]; #say $tee "577 taken \$strength: " . dump( $strength );

      if ( ( $strength ne "" ) and ( $sum_strengths ne "" ) )
      {
        $soughtgrad = ( $soughtgrad + ( $grad * ( $strength / $sum_strengths ) ) ); say $tee "887 SAYY \$soughtgrad: " . dump( $soughtgrad );
        #say $tee "577 produced \$soughtgrad: " . dump( $soughtgrad );
      }
      $in++;
    }
  }
  #my $soughtgrad = $boxgrads[0]; ###HERE. REMOVE.

  my ( $totdist, $totstrength );
  unless ( ( scalar( @levbag ) == 0 ) or ( scalar( @factbag ) == 0 ) or ( scalar( @stepbag ) == 0 ) )
  {
    my $rawtotdist = pythagoras( \@factbag, \@levbag, \@stepbag ); #say $tee "877 \$rawtotdist: " . dump( $rawtotdist );
    $totdist = ( $rawtotdist / $maxdist ); #say $tee "877 \$totdist: " . dump( $totdist );
  } #say $tee "weightvals15out \$totdist: " . dump( $totdist );

  if ( ( $totdist ne "" ) and ( $totdist != 0 ) )
  {
    $totstrength = ( 1 - $totdist ); #say $tee "877 \$totstrength: " . dump( $totstrength );
  } #say $tee "weightvals15out \$totstrength: " . dump( $totstrength );

  my $soughtinc = $soughtgrad;
  ###my $soughtinc = ( $elt2 + $soughtgrad ); say $tee "887 \$soughtinc: " . dump( $soughtinc );###ATTENTION HERE

  if ( ( $soughtinc ne "" ) and ( $totdist ne "" ) and ( $totstrength ne "" ) and ( $totstrength >= $minreq_forcalc ) )
  { #say $tee "DONE.";
    return ( $soughtinc, $totdist, $totstrength );
  }
} #END SUB weightvals1


sub weightvals_merge
{
  my ( $vals_ref, $strengths_ref, $minreq_formerge, $maxdist ) = @_;
  my @vals = @{ $vals_ref };  #say $tee "INEND \@vals: " . dump( @vals );
  my @strengths = @{ $strengths_ref }; #say $tee "INEND \@dists: " . dump( @dists );

  my ( $soughtval, $totstrength, $sum_strengths );
  my $strengthsnum = scalar( @strengths ); #say $tee "INEND \$strengthsnum: " . dump( $strengthsnum );
  if ( $strengthsnum > 0 )
  {
    $sum_strengths = sum( @strengths );
  }

  my $totstrength;
  my $value;
  my $soughtval = 0;
  if ( ( $sum_strengths ne "" ) and ( $sum_strengths > 0 ) )
  {
    #say $tee "INEND \$sum_strengths: " . dump( $sum_strengths );
    my $in = 0;
    foreach my $val ( @vals )
    {
      #say $tee "IN FOREACH VAL \$val: " . dump( $val );
      my $strength = $strengths[$in]; #say $tee "IN FOREACH VAL \$strength: " . dump( $strength );
      $soughtval = ( $soughtval + ( $val * ( $strength / $sum_strengths ) ) ); #say $tee "IN FOREACH VAL \$soughtval: " . dump( $soughtval );
      $in++;
    } #say $tee "INEND \$soughtval: " . dump( $soughtval );
    my $seedstrength = 1;

    my $inc = 0;
    foreach my $strength ( @strengths )
    {
      if ( not ( $strength == 1 ) )
      {
        #say $tee "IN FOREACH STRENGTH \$strength: " . dump( $strength );
        $seedstrength = ( $seedstrength * $strength ); #say $tee "IN FOREACH STRENGTH \$seedstrength: " . dump( $seedstrength );
      }
      else
      {
        $seedstrength = 1;
        $value = $vals[$inc];
        last;
      }
      $inc++;
    }
    #say $tee "INEND0 \$seedstrength: " . dump( $seedstrength );
    #say $tee "INEND0 \$strengthsnum: " . dump( $strengthsnum );
    unless ( $seedstrength == 1 )
    {
      $totstrength = ( $seedstrength ** ( 1 / $strengthsnum ) );
    }
    else
    {
      $totstrength = 1;
      $soughtval = $value;
    }
  }
  #say $tee "INEND \$totstrength: " . dump( $totstrength );

  if ( ( $soughtval ne "" ) and ( $totstrength ne "" ) and ( $totstrength >= $minreq_formerge ) )
  {
    #say $tee "ENDEND \$soughtval: " . dump( $soughtval );
    #say $tee "ENDEND \$totstrength: " . dump( $totstrength );
    return ( $soughtval, $totstrength );
  }
}# END SUB weightvals_merge


sub calcdist
{
  my ( $el1, $elt1, $factlevels_ref, $maxdist, $el3, $elt3, $condweight ) = @_;
  my %factlevels = %{ $factlevels_ref };
  my @diff1 = diff( \@{ $el1 }, \@{ $elt1 } );
  my $dist;
  my ( @factbag, @levbag, @stepbag, @da1, @da1par, @da2, @da2par, @diff2 );

  #say $tee "777\scalar( \@diff1 ): " . dump( scalar( @diff1 ) );
  if ( scalar( @diff1 ) > 0 )
  {
    @diff2 = diff( \@{ $elt1 } , \@{ $el1 } ); #say $tee "777b \@diff2: " . dump( @diff2 );

    my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
    @da1 = keys %h1; #say $tee "THEN \@da1: " . dump( @da1 );
    @da1par = values %h1; #say $tee "\@da1par: " . dump( @da1par );
    my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
    @da2 = keys %h2; #say $tee "THEN \@da2: " . dump( @da2 );
    @da2par = values %h2; #say $tee "\@da2par: " . dump( @da2par );

    my $c = 0;
    foreach my $e ( @da1par )
    { #say $tee "\$e: " . dump( $e );
      my $e = $da1par[$c];
      my $ei = $da2par[$c]; #say $tee "22 \$ei: " . dump( $ei );
      my $fact = $da1[$c]; #say $tee "22 \$fact: " . dump( $fact );
      my $diffpar = abs( $e - $ei ); #say $tee "22 \$diffpar: " . dump( $diffpar ); say $tee "22 \$factlevels{stepsizes}{\$fact}: " . dump( $factlevels{stepsizes}{$fact} );
      if ( ( $fact ne "" ) and ( $diffpar ne "" ) and ( $factlevels{stepsizes}{$fact} ne "" ) )
      {
        push ( @factbag, $fact );
        push ( @levbag, $diffpar );
        push ( @stepbag, $factlevels{stepsizes}{$fact} );
      }
      #say $tee "777b \@factbag : " . dump( @factbag ); say $tee "777b \@levbag : " . dump( @levbag ); say $tee "777b \@stepbag : " . dump( @stepbag );
      $c++;
    }
  }
  unless ( ( scalar( @levbag ) == 0 ) or ( scalar( @factbag ) == 0 ) or ( scalar( @stepbag ) == 0 ) )
  {
    my $ordist = scalar( @levbag ); #say $tee "\$ordist: " . dump( $ordist );
    my $rawdist = pythagoras( \@factbag, \@levbag, \@stepbag ); #say $tee "776b\$rawdist: " . dump( $rawdist );
    my ( $dist, $strength );

    if ( $maxdist ne "" )
    {
      $dist = ( $rawdist / $maxdist );
      $strength = ( 1 - $dist );
    }

    if ( ( $el3 ne "" ) and ( $elt3 ne "" ) and ( $condweight = "yes") )
    {
      $strength = ( $strength * $el3 * $elt3 );
    }
    elsif ( ( $elt3 ne "" ) and ( $condweight = "yes") )
    {
      $strength = ( $strength * $elt3 );
    }

    return( { dist => $dist, strength => $strength, ordist => $ordist, rawdist => $rawdist,
      diff1 => \@diff1, diff2 => \@diff2, da1 => \@da1, da2 => \@da2, da1par => \@da1par, da2par => \@da2par } );
  }
}


sub calcdistgrad
{
  my ( $el1, $elt1, $factlevels_ref, $minreq, $maxdist, $el3, $elt3, $condweight ) = @_; #say $tee "777c\$el1: " . dump( $el1 ); say $tee "777c\$elt1: " . dump( $elt1 ); say $tee "777c\$minreq: " . dump( $minreq );
  my %factlevels = %{ $factlevels_ref };
  my @diff1 = diff( \@{ $el1 }, \@{ $elt1 } ); #say $tee "777\@diff1: " . dump( @diff1 );
  my $dist;
  my ( @factbag, @levbag, @stepbag, @da1, @da1par, @da2, @da2par, @diff2 );
  #say $tee "777\scalar( \@diff1 ): " . dump( scalar( @diff1 ) ); say $tee "777\$minreq: " . dump( $minreq );
  if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= $minreq->[0] ) )
  {
    @diff2 = diff( \@{ $elt1 } , \@{ $el1 } ); #say $tee "777b \@diff2: " . dump( @diff2 ); say $tee "777\@diff1: " . dump( @diff1 );

    my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
    @da1 = keys %h1; #say $tee "THEN \@da1: " . dump( @da1 );
    @da1par = values %h1; #say $tee "\@da1par: " . dump( @da1par );
    my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
    @da2 = keys %h2; #say $tee "THEN \@da2: " . dump( @da2 );
    @da2par = values %h2; #say $tee "\@da2par: " . dump( @da2par );

    my $c = 0;
    foreach my $lev1 ( @da1par )
    { #say $tee "\$e: " . dump( $e );
      my $da1 = $da1[$c];
      my $i = 0;
      foreach my $lev2 ( @da2par )
      {
        my $da2 = $da2[$i];
        if ( $da1 == $da2 )
        {
          my $fact = $da1;
          my $diffpar = abs( $lev1 - $lev2 ); #say $tee "22 \$diffpar: " . dump( $diffpar );
          if ( ( $diffpar <= $minreq->[1] ) and ( $fact ne "" ) and ( $diffpar ne "" ) and ( $factlevels{stepsizes}{$fact} ne "" ) )
          {
            push ( @factbag, $fact );
            push ( @levbag, $diffpar );
            push ( @stepbag, $factlevels{stepsizes}{$fact} );
          }
        }
        $i++;
      }
      $c++;
    }
  }

  unless ( ( scalar( @levbag ) == 0 ) or ( scalar( @factbag ) == 0 ) or ( scalar( @stepbag ) == 0 ) )
  {
    my $ordist = scalar( @levbag ); #say $tee "777b \$ordist: " . dump( $ordist );
    my $rawdist = pythagoras( \@factbag, \@levbag, \@stepbag ); #say $tee "777b \$rawdist: " . dump( $rawdist );
    my ( $dist, $strength );

    if ( $maxdist ne "" )
    {
      $dist = ( $rawdist / $maxdist );
      $strength = ( 1 - $dist );
    }

    if ( ( $el3 ne "" ) and ( $elt3 ne "" ) and ( $condweight = "yes") )
    {
      $strength = ( $strength * $el3 * $elt3 );
    }

    return( { dist => $dist, strength => $strength, ordist => $ordist, rawdist => $rawdist, diff1 => \@diff1, diff2 => \@diff2, da1 => \@da1, da2 => \@da2, da1par => \@da1par, da2par => \@da2par } );
  }
}


sub calcmaxdist
{
  my ( $arr_ref, $factlevels_ref ) = @_;
  my @arr = @{ $arr_ref };
  my @rawdists;
  foreach my $el ( @arr )
  {
    foreach my $elt ( @arr )
    {
      my $hash_ref = calcdist( $el->[1], $elt->[1], $factlevels_ref );
      my %hash = %{ $hash_ref }; #say $tee "00\%hash: " . dump( %hash );
      push ( @rawdists, $hash{rawdist} );
    }
  }  #say $tee "00\@rawdists: " . dump( @rawdists );
  my $maxdist = max( @rawdists ); #say $tee "00\$maxdist: " . dump( $maxdist );
  return( $maxdist );
}


sub wei
{
  my ( $arr_ref, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count,
    $factlevels_ref, $minreq_forgrad, $minreq_forinclusion, $minreq_forcalc, $minreq_formerge, $maxdist ) = @_;
  my @arr = @{ $arr_ref };
  #say $tee "ARR VERY_BEFORE: " . dump(@arr);
  my %factlevels = %{ $factlevels_ref };  #say $tee "AND \%factlevels: " . dump( %factlevels );
  # my ( %magic, %wand, %spell, %bank );

  sub fillbank
  { #say $tee "NOW IN FILLBANK.";
    my %bank;
    foreach my $el ( @arr )
    { #say $tee "\$el->[1]: " . dump( $el->[1] ); #say $tee "EL: " . dump( $el );
      my $key =  $el->[0] ; #say $tee "\$key: " . dump( $key );
      if ( ( $el->[2] ne "" ) and ( $el->[3] >= $minimumcertain ) )
      { #say $tee "\nTRYING \$el->[1]: " . dump( $el->[1] );
        foreach my $elt ( @arr )
        { #say $tee "SO, ELT: " . dump( $elt ); #say $tee "IN WHICH, ELT0: " . dump( @{ $elt->[0] } );
          if ( ( $elt->[2] ne "" ) and ( $elt->[0] ne $el->[0] ) and ( $el->[3] >= $minimumcertain ) )
          { #say $tee "NOW CHECKING .";

            #my $d_ref; say $tee "\$el->[1] : " . dump( $el->[1] ); say $tee "\$elt->[1]: " . dump( $elt->[1] );
            my ( $res_ref ) = calcdistgrad( $el->[1], $elt->[1], \%factlevels, $minreq_forgrad, $maxdist, $el->[3], $elt->[3], $condweight );
            #say $tee "\OBTAINED11 \$res_ref: " . dump( $res_ref );
            #if ( $res_ref ne "" )
            unless ( !keys %{ $res_ref } )
            {
              $d_ref = $res_ref; #say $tee "FOUND \$d_ref: " . dump( $d_ref );
              #say $tee "\$el->[1]: " . dump( $el->[1] );
              #say $tee "\$elt->[1]: " . dump( $elt->[1] );
            }
            #else
            #{
            #  say $tee "NULL!";
            #} #say $tee "D_REF: " . dump( $d_ref );

            my %d;
            my ( @diff1, @diff2, @da1, @da2, @da1par, @da2par );
            my ( $ordist, $dist, $strength );

            unless ( !keys %{ $res_ref } )
            {
              %d = %{ $d_ref }; #say $tee "\%d: " . dump( %d );
              @diff1 = @{$d{diff1}};
              @diff2 = @{$d{diff2}};
              @da1 = @{$d{da1}};
              @da2 = @{$d{da2}};
              @da1par = @{$d{da1par}};
              @da2par = @{$d{da2par}};
              $ordist = $d{ordist}; #say $tee "\$ordist: " . dump ( $ordist ); #say $tee "D: " . dump ( %d );
              $dist = $d{dist};
              $strength = $d{strength};
            }
            #else
            #{
            #  say $tee "NULL!";
            #}

            unless ( !keys %{ $res_ref } and ( $ordist > 0 ) and ( $ordist ne "" ) ) ######## IMPROVE THIS SO AS TO ALLOW VERY DIFFERENT NUMBERS OF LEVELS FOR EACH FACTOR
            { #say $tee " SO I AM IN. ";
              my $count = 0;
              foreach my $d10 ( @da1 )
              { #say $tee "WORKING \$d10: " . dump( $d10 );

                my $d11 = $da1par[$count]; #say $tee "WORKING \$d11: " . dump( $d11 );
                #my $nearness = abs( $d11 - $d21 );
                #my $d20 = $da2[$count]; #say $tee "\$d21: " . dump( $d21 );
                my $co = 0;
                foreach my $d20 ( @da2 )
                { #say $tee "WORKING \$d20: " . dump( $d20 );

                  if ( $d10 == $d20 )
                  {
                    my $stepsize = $factlevels{stepsizes}{$d20}; #say $tee "454\$stepsize: " . dump( $stepsize );
                    my $d21 = $da2par[$co]; #say $tee "WORKING \$d21: " . dump( $d21 );
                    #if ( ( $d10 eq $d20 ) and ( abs( $d11 - $d21 ) == 1 ) and ( $d11 > 0 ) and ( $d21 > 0 ) and ( $d11 ne "" ) and ( $d21 ne "" )
                    #  and ( $d11 ne $d21 ) ) #### if ( ( $d10 eq $d20 ) and ( $d11 ne $d21 ) ) ###  THE SECOND CONDITION COULD BE LOGICALLY REDUNDANT. CHECK. ####
                    #{
                      my $pair = join( "-", $d11, $d21 );
                      my @sorted = sort( $d11, $d21 );
                      my $orderedpair = join( "-", @sorted );
                      my $trio = join( "-", $d10, $pair );
                      my $orderedtrio = join( "-", $d10, $orderedpair );

                      unless ( $trio eq "" )
                      {
                        $bank{$trio}{par} = $d10;
                        push ( @{ $bank{$trio}{trio} }, $trio );
                        push ( @{ $bank{$trio}{orderedtrio} }, $orderedtrio );

                        push ( @{ $bank{$trio}{orvals} }, [ $el->[2], $elt->[2] ] );
                        push ( @{ $bank{$trio}{origins} }, $el->[1], $elt->[1] );

                        if ( ( $ordist > 0 ) and ( $ordist ne "" ) and ( $dist ne "" ) and ( $strength ne "" ) )
                        {
                          push ( @{ $bank{$trio}{ordists} }, $ordist );
                          #push ( @{ $bank{$reversedtrio}{ordists} }, $ordist );
                          push ( @{ $bank{$trio}{dists} }, $dist );
                          #push ( @{ $bank{$reversedtrio}{dists} }, $dist );
                          push ( @{ $bank{$trio}{strengths} }, $strength );
                        }

                        #my $cn = 0;
                        #foreach my $vals ( @{ $bank{$trio}{orvals} } )
                        #{

                        my $pos1 = $d11; #say $tee "WORKING \$pos1: " . dump( $pos1 );
                        my $pos2 = $d21; #say $tee "WORKING \$pos2: " . dump( $pos2 );
                        my $val1 = $el->[2]; #say $tee "WORKING \$val1: " . dump( $val1 );
                        my $val2 = $elt->[2]; #say $tee "WORKING \$val2: " . dump( $val2 );

                        my $diffpos = ( $pos1 - $pos2 ); #say $tee "WORKING \$diffpos: " . dump( $diffpos );
                        my $diffval = ( $val1 - $val2 ); #say $tee "WORKING \$diffval: " . dump( $diffval );
                        my $grad;
                        if ( ( $diffpos ne "" ) and ( $diffpos != 0 ) )
                        {
                          $grad = ( $diffval / $diffpos ); #say $tee "WORKING \$grad: " . dump( $grad );
                        }

                        if ( $grad ne "" )
                        { #say $tee "PUSHING \$grad: " . dump( $grad ) . " IN \$trio" . dump( $trio ) ;

                          if ( $orderedtrio eq $trio )
                          {
                            push ( @{ $bank{$trio}{grads} }, (- $grad ) );
                          }
                          else
                          {
                            push ( @{ $bank{$trio}{grads} }, $grad );
                          }
                        }
                      }
                    }

                  $co++;
                }
                $count++;
              }
            }
          }
        }
      }
    }
    return ( \%bank );
  }


  my $bank_ref = fillbank;
  my %bank =  %{ $bank_ref }; #say $tee "\%bank: " . dump( %bank );

  sub clean
  {
    my %bank = @_;
    foreach my $trio ( keys ( %bank ) )
    {
      my ( @grads, @ordists, @dists, @strengths );
      unless( ( $bank{$trio}{grad} eq "" ) or ( $bank{$trio}{ordists} eq "" )
        or ( $bank{$trio}{dists} eq "" ) or ( $bank{$trio}{strengths} eq "" ) )
      {
        push ( @grads,$bank{$trio}{grad} );
        push ( @ordists,$bank{$trio}{ordists} );
        push ( @dists,$bank{$trio}{dists} );
        push ( @strengths,$bank{$trio}{strengths} );
        $bank{$trio}{grad} = [ @grads ];
        $bank{$trio}{ordists} = [ @ordists ];
        $bank{$trio}{dists} = [ @dists ];
        $bank{$trio}{strengths} = [ @strengths ];
      }
    }
  }
  my %bank = clean( %bank );
  my %bank =  %{ $bank_ref }; #say $tee "CLEANED \%bank: " . dump( %bank );

  sub cyclearr
  { #say $tee "NTH ARR: " . dump( @arr );
    my %wand;
    my $coun = 0;
    foreach my $el ( @arr )
    { #say $tee "\$el->[1]: " . dump( $el->[1] ); #say $tee "EL: " . dump( $el );
      my $key =  $el->[0] ; #say $tee "\$key: " . dump( $key );
      if ( $el->[2] eq "" )
      { #say $tee "TRYING \$el->[1]: " . dump( $el->[1] );
        foreach my $elt ( @arr )
        { #say $tee "SO, ELT: " . dump( $elt ); #say $tee "IN WHICH, ELT0: " . dump( @{ $elt->[0] } );
          if ( ( $elt->[2] ne "" ) and ( $el->[3] >= $minreq_forinclusion ) )
          {
            my @diff1 = diff( \@{ $el->[1] }, \@{ $elt->[1] } ); #say $tee "AND \@diff1: " . dump( @diff1 );

            if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= $minreq_forgrad->[2] ) )
            { #say $tee "AND \@diff1 IS 1: " . dump( @diff1 );
              #say "NOW IN.";
              my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } ); #say $tee "SO \@diff2: " . dump( @diff2 );
              my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
              my @da1 = keys %h1;
              my @da1par = values %h1; # $tee "\@da1par: " . dump( @da1par );
              my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " .yes dump( %h2 );
              my @da2 = keys %h2;
              my @da2par = values %h2; #say $tee "\@da2par: " . dump( @da2par );
              #say $tee "SAYYY \$el->[1]: " . dump( $el->[1] );

              my $soughtval;
              my $count = 0;
              foreach my $d10 ( @da1 )
              {
                #my $d10 = $da1[$count];
                my $d11 = $da1par[$count]; #say $tee "NOW IN1 \$d11: " . dump( $d11 );
                my $co = 0;
                foreach my $d20 ( @da2 )
                {
                  if ( $d20 ne "" )
                  {
                    my $d20 = $da2[$co];
                    my $d21 = $da2par[$co]; #say $tee "NOW IN2 \$d21: " . dump( $d21 );
                    if ( ( $d10 eq $d20 ) ) #### if ( ( $d10 eq $d20 ) and ( $d11 ne $d21 ) ) ###  THE SECOND CONDITION COULD BE LOGICALLY REDUNDANT. CHECK. ####
                    { #say $tee "NOW IN3";
                      my $newpair = join( "-", ( $d11, $d21 ) );
                      #my $newunordpair = join( "-", ( $d11, $d21 ) );

                      my $newtrio = join( "-", $d10, $newpair ); #say $tee "NEWTRIO: " . dump ( $newtrio );

                      #my $nowgrad;
                      #if ( $newpair eq $newunordpair )
                      #{
                      #  $nowgrad = $bank{$newtrio}{grads};
                      #}
                      #else
                      #{
                      #  $nowgrad = - $bank{$newtrio}{grads};
                      #}

                      my ( @boxgrads, @boxdists, @boxors );
                      my $cn = 0;
                      foreach my $grad ( @{ $bank{$newtrio}{grads} } )
                      {
                        if ( $grad ne "" )
                        {
                          #say $tee "NOW IN4";
                          push ( @boxgrads, $grad );
                          my $ordist = $bank{$newtrio}{ordists}[$cn];
                          push ( @boxdists, $ordist );
                          my $origin = $bank{$newtrio}{origins}[$cn];
                          push ( @boxors, $origin );
                        }
                        #else
                        #{
                        #  say $tee "NOT PUSHING INTO BANK!";
                        #}
                        $cn++;
                      } #say $tee "HERE \@boxgrads: " . dump( @boxgrads ); say $tee "HERE \@boxdists: " . dump( @boxdists );
                      #if ( scalar( @{ $bank{$newtrio}{grads} } ) == 0 ) { say $tee "BANK EMPTY OF GRADS!"; }

                      my ( @factbag, @levbag, @stepbag );
                      my $c = 0;
                      foreach my $e ( @da1par )
                      {
                        if ( $e ne "" )
                        { #say $tee "NOW IN5"; say $tee "33\$e: " . dump( $e );
                          my $fact = $da1[$c]; #say $tee "33\$fact: " . dump( $fact );

                          my $i = 0;
                          foreach my $ei ( @da2par )
                          {
                            if ( $da1[$c] == $da2[$i] )
                            {
                              my $diffpar = abs( $e - $ei ); say $tee "335 \$diffpar: " . dump( $diffpar );
                              #if ( ( $diffpar >= $minreq_forgrad->[1] ) and ( $diffpar > 0 ) )
                              if ( ( $diffpar <= $minreq_forgrad->[1] ) and ( $diffpar > 0 ) ) ############################à
                              {
                                push ( @factbag, $fact );
                                push ( @levbag, $diffpar );
                                push ( @stepbag, $factlevels{stepsizes}{$fact} );
                              }
                            }
                            $i++;
                          }
                        }
                        $c++;
                      }

                      #say $tee "889 OBTAINED \@factbag: " . dump( @factbag ); say $tee "889 \@levbag: " . dump( @levbag ); say $tee "\@stepbag: " . dump( @stepbag );
                      #say $tee "889 OBTAINED \@boxgrads: " . dump( @boxgrads ); say $tee "889 \@boxdists: " . dump( @boxdists ); say $tee "\@boxors: " . dump( @boxors );

                      my ( $soughtinc, $totdist, $totstrength );

                      unless ( ( scalar( @boxgrads ) == 0 ) and ( scalar( @boxdists ) == 0 ) and ( scalar( @boxors ) == 0 ) )
                      { #say $tee "CHEKK \$el->[3]: " . dump( $el->[3] );
                        ( $soughtinc, $totdist, $totstrength ) = weightvals1( $elt->[1], \@boxgrads, \@boxdists, \@boxors, $minreq_forcalc, \@factbag, \@levbag, \@stepbag, $elt->[2], \%factlevels, $maxdist, $elt->[3], $condweight );
                        #say $tee "332 OBTAINED \$soughtinc: " . dump( $soughtinc );
                        #say $tee "332 OBTAINED \$totdist: " . dump( $totdist );
                        #say $tee "332 OBTAINED \$totstrength: " . dump( $totstrength );

                        unless ( ( $soughtinc eq "" ) or ( $totdist eq "" ) )
                        {
                          my $soughtval = ( $elt->[2] + $soughtinc );
                          push ( @{ $wand{$key}{vals} }, $soughtval );
                          push ( @{ $wand{$key}{dists} }, $totdist );
                          #say $tee "PUSHING \$soughtval $soughtval INTO \@{ \$wand{\$key}{vals} }: " . dump( @{ $wand{\$key}{vals} } ) . " BECAUSE KEY: $key . " ;

                          #my $strength = ( ( $elt->[3] ** $totstrength ) ** ( 1/2 ) );


                          #push ( @{ $wand{$key}{strength} }, $strength );
                          push ( @{ $wand{$key}{strength} }, $totstrength );
                          push ( @{ $wand{$key}{origin} }, $elt->[0] );
                          $wand{$key}{name} = $key;
                          $wand{$key}{bulk} = [ @{ $elt->[1] } ] ;
                          #say $tee "EXECUTING";
                        }
                        #else
                        #{
                        #  say $tee "NOT PUSHING INTO WAND ";
                        #}
                      }
                      #else
                      #{
                      #  say $tee "NOT WEIGHTVALS1ING ";
                      #}
                    }
                  }
                  $co++
                }
                $count++;
              }
            }
          }
        }
      }
    } #say $tee "END77 \%wand IN: " . dump( %wand );
    return( \%wand );
  }

  my $wand_ref = cyclearr;
  my %wand = %{ $wand_ref }; #say $tee "\%wand OUT: " . dump( %wand );


  my @limb0;
  foreach my $ke ( keys %wand )
  {
    my ( $soughtval, $totstrength ) = weightvals_merge( \@{ $wand{$ke}{vals} }, \@{ $wand{$ke}{strength} }, $minreq_formerge, $maxdist );
    #say $tee "ENDPIPE \$soughtval, " . dump( $soughtval );
    #say $tee "ENDPIPE \$totstrength, " . dump( $totstrength );
    if ( ( $soughtval ne "" ) and ( $totstrength ne "" ) )
    {
      push ( @limb0, [ $wand{$ke}{name}, $wand{$ke}{bulk}, $soughtval, $totstrength ] ); #say $tee "\$avg: $avg"; say $tee "\${ \$magic{\$ke}{\$dee} }->[1] : ${ $magic{$ke}{$dee} }->[1] ";
    }
  }
  #say $tee "LIMBO_WEI: " . dump( @limbo_wei );
  return( @limb0 )
} ##### END SUB wei


sub purelin
{
  my ( $arr_refillf, $relaxlimit, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count, $factlevels_ref, $maxdist ) = @_;
  my @arr = @{ $arr_ref };
  my ( @linneabagbox );
  my ( %magic, %wand, %spell );
  foreach my $el ( @arr )
  { #say $tee "\$el->[1]: " . dump( $el->[1] ); #say $tee "EL: " . dump( $el );
    my $key =  $el->[0] ; #say $tee "\$key: " . dump( $key );
    if ( $el->[2] eq "" )
    { #say $tee "TRYING \$el->[1]: " . dump( $el->[1] );
      foreach my $elt ( @arr )
      { #say $tee "SO, ELT: " . dump( $elt ); #say $tee "IN WHICH, ELT0: " . dump( @{ $elt->[0] } );
        if ( not ( $elt->[2] eq "" ) )
        {
          my @diff1 = diff( \@{ $el->[1] }, \@{ $elt->[1] } ); #say $tee "AND \@diff1: " . dump( @diff1 );

          if ( $relaxmethod eq "logarithmic" )
          {
            my $index = 0;
            while ( $index <= $relaxlimit )
            {
              if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= ( 1 + $relaxlimit ) ) )
              { #say $tee "AND \@diff1 IS 1: " . dump( @diff1 );

                my @diffo_wei2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } ); #say $tee "SO \@diff2: " . dump( @diff2 );
                my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
                my @da1 = keys %h1;
                my @da1par = values %h1; # $tee "\@da1par: " . dump( @da1par );
                my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " .yes dump( %h2 );
                my @da2 = keys %h2;
                my @da2par = values %h2; #say $tee "\@da2par: " . dump( @da2par );
                #say $tee "SAYYY \$el->[1]: " . dump( $el->[1] );

                my $count = 0;
                foreach my $d10 ( @da1 )
                { #say $tee "\$d10: " . dump( $d10 );
                  my $d11 = $da1par[$count]; #say $tee "\$d11: " . dump( $d11 );
                  my $co = 0;
                  foreach my $d20 ( @da2 )
                  { #say $tee "\$d20: " . dump( $d20 );
                    my $d21 = $da2par[$co]; #say $tee "\$d21: " . dump( $d21 );
                    if ( ( $d10 eq $d20 ) ) #### if ( ( $d10 eq $d20 ) and ( $d11 ne $d21 ) ) ###  THE SECOND CONDITION COULD BE LOGICALLY REDUNDANT. CHECK. ####
                    {
                      push ( @{ $magic{$key}{$d10} }, [ $el->[0], $el->[1], $d11, $d21, $elt->[2] ] ); #key, array, factornum missing, factornum gotten, value
                      #say $tee "PUSHING THIS: [ \$el->[0], \$el->[1], \$d11, \$d21, \$elt->[2] ] " . dump([ $el->[0], $el->[1], $d11, $d21, $elt->[2] ]);
                    }
                    $co++;
                  }
                  $count++;
                }

              } #say $tee "FACTLEVELS: " . dump( %factlevels );
              $index++;
            }
          }
          elsif ( ( $relaxmethod eq "linear" ) or ( $relaxmethod eq "exponential" ) ) ##############CHECK
          {
            my $index = 0;
            while ( $index <= $relaxlimit )
            {
              if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) == ( 1 + $relaxlimit ) ) )
              { #say $tee "AND \@diff1 IS 1: " . dump( @diff1 );#SAME CONTENT AS THE PREVIOUS WHILE HERE BELOW
                my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } ); #say $tee "SO \@diff2: " . dump( @diff2 );

                my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
                my @da1 = keys %h1;
                my @da1par = values %h1; # $tee "\@da1par: " . dump( @da1par );
                my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
                my @da2 = keys %h2;
                my @da2po_weiar = values %h2; #sa_refy $tee "\@da2par: " . dump( @da2par );
                #say $tee "\$el->[2]: " . dump( $el->[2] );

                if ( $relaxmethod eq "linear" )
                {
                  my $indinc = ( $overweightnearest - $index );
                }
                elsif ( $relaxmethod eq "exponential" )
                {
                  my $indinc = ( ( $overweightnearest - $index ) * ( $overweightnearest - $index ) );
                }

                my $coufillnt = 0;
                foreach my $d10 ( @da1 )
                { #sayo_wei $tee "\$d10: " . dump( $d10 );
                  my $d11 = $da1par[$count]; #say $tee "\$d11: " . dump( $d11 );
                  my $co = 0;
                  foreach my $d20 ( @da2 )
                  { #say $tee "\$d20: " . dump( $d20 );
                    my $d21 = $da2par[$co]; #say $tee "\$d21: " . dump( $d21 );
                    while ( $indinc > 0 )
                    {
                      if ( ( $d10 eq $d20 ) ) #### if ( ( $d10 eq $d20 ) and ( $d11 ne $d21 ) ) ###  THE SECOND CONDITION COULD BE LOGICALLY REDUNDANT. CHECK. ####
                      { #say $tee "PUSH " . dump( $elt->[2] );
                        push ( @{ $magic{$key}{$d10} }, [ $el->[0], $el->[1], $d11, $d21, $elt->[2] ] ); #key, array, factornum missing, factornum gotten, value
                        $indinc--;
                      }
                    }
                    $co++;
                  }
                  $count++;
                }
              }
              $index++;
            }
          }
        }
      }
    }
  }
  #say $tee "\%magic: " . dump( %magic );

  foreach my $ke ( sort {$a <=> $b} ( keys %magic ) )
  {
    foreach my $dee ( sort {$a <=> $b} ( keys %{ $magic{$ke} } ) )
    { #say $tee "\$r: " . dump( $r );
      #my @array = @{ $dee }; say $tee "\$dee: " . dump( $dee ); say $tee "\@array: " . dump( @array );
      my @array = @{ $magic{$ke}{$dee} }; #say $tee "\$dee: " . dump( $dee ) . ", "; say $tee "\@array: " . dump( @array );
      my @bag;
      my $bagmean;
      unless ( scalar( @array ) <= 1 )
      {

        my $i = 0;
        foreach my $elem ( @array )
        {
          my $pos1 = $elem->[3];
          my $pos2 = $array[i+1]->[3];
          my $val1 = $elem->[4];
          my $val2 = $afillrray[i+1]->[4];
          my $posor = $elem->[2];

          if ( $i == ( scalar( @array ) - 1 ) )
          {
            $pos2 = $array[0]->[3];my $index = 0;
          if ( $relaxmethod eq "logarithmic" )
          {
            my $index = 0;
            while ( $index <= $relaxlimit )
            {
              if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= ( 1 + $relaxlimit ) ) )
              { #say $tee "AND \@diff1 IS 1: " . dump( @diff1 );
                my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } ); #say $tee "SO \@diff2: " . dump( @diff2 );

                my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
                my @da1 = keys %h1;
                my @da1par = values %h1; # $tee "\@da1par: " . dump( @da1par );
                my %h2fill = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
                my @da2 = keys %h2;
                my @da2par = values %h2; #say $tee "\@da2par: " . dump( @da2par );
                #say $tee "SAYYY \$el->[1]: " . dump( $el->[1] );

                my $count = 0;
                foreach my $d10 ( @da1 )
                { #say $tee "\$d10: " . dump( $d10 );
                  my $d11 = $da1par[$count]; #say $tee "\$d11: " . dump( $d11 );
                  my $co = 0;
                  foreach my $lineard20 ( @da2 )
                  { #say $tee "\$d20: " . dump( $d20 );
                    my $d21 = $da2par[$co]; #say $tee "\$d21: " . dump( $d21 );
                    if ( ( $d10 eq $d20 ) ) #### if ( ( $d10 eq $d20 ) and ( $d11 ne $d21 ) ) ###  THE SECOND CONDITION COULD BE LOGICALLY REDUNDANT. CHECK. ####
                    {
                      push ( @{ $magic{$key}{$d10} }, [ $el->[0], $el->[1], $d11, $d21, $elt->[2] ] ); #key, array, factornum missing, factornum gotten, value
                      #say $tee "PUSHING [ \$el->[0], \$el->[1], \$d11, \$d21, \$elt->[2] ] " . dump( [ $el->[0], $el->[1], $d11, $d21, $elt->[2] ]) . " SO I HAVE " . dump(@{ $magic{$key}{$d10} });

                      #say $tee "\$dee: " . dump( $dee ) . ", "; say $tee "\@array: " . dump( @array );
                    }
                    $co++;
                  }
                  $count++;
                }

              }
              $index++;
            }
          }
          elsif ( ( $relaxmethod eq "linear" ) or ( $relaxmethod eq "exponential" ) )
          {
            my $index = 0;
            while ( $index <= $relaxlimit )
            {
              if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) == ( 1 + $relaxlimit ) ) )
              { #say $tee "AND \@diff1 IS 1: " . dump( @diff1 );#SAME CONTENT AS THE PREVIOUS WHILE HERE BELOW
                my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } ); #say $tee "SO \@diff2: " . dump( @diff2 );

                my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
                my @da1 = keys %h1;
                my @da1par = values %h1; # $tee "\@da1par: " . dump( @da1par );
                my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
                my @da2 = keys %h2;
                my @da2par = values %h2; #say $tee "\@da2par: " . du$presence mp( @da2par );
                #say $tee "SAYYY \$el->[1]: " . dump( $el->[1] );

                my $count = 0;
                foreach my $d10 ( @da1 )
                { #say $tee "\$d10: " . dump( $d10 );
                  my $d11 = $da1par[$count]; #say $tee "\$d11: " . dump( $d11 );
                  my $co = 0;
                  foreach my $d20 ( @da2 )
                  { #say $tee "\$d20: " . dump( $d20 );
                    my $d21 = $da2par[$co]; #say $tee "\$d21: " . dump( $d21 );
                    if ( ( $d10 eq $d20 ) ) #### if ( ( $d10 eq $d20 ) and ( $d11 ne $d21 ) ) ###  THE SECOND CONDITION COULD BE LOGICALLY REDUNDANT. CHECK. ####
                    {
                      push ( @{ $magic{$key}{$d10} }, [ $el->[0], $el->[1], $d11, $d21, $elt->[2] ] ); #key, array, factornum missing, factornum gotten, value
                    }
                    $co++;
                  }
                  $count++;
                }
              }
              $index++;
            }
          }
            $val2 = $array[0]->[4];
          }

          unless ( $pos1 == $pos2 )
          {
            my $diffp = ( $pos1 - $pos2 );
            my $diffval = ( $val1 - $val2 );
            my $unit = ( $diffval / $diffp );
            my $halfunit = ( $unit / 2 );
            my $halfdiffval = ( $diffval / 2 );
            my $avgval = ( ( $val1 + $val2 ) / 2 ); #say $tee "\$avgval: $avgval";
            my $avgpos = ( ( $pos1 + $pos2 ) / 2); #say $tee "\$avgpos: $avgpos";
            my $distp = ( $posor - $avgpos ); #say $tee "\$distp: $distp";
            my $change = ( $distp * $unit ); #say $tee "\$change: $change";
            my $soughtval = ( $avgval + $change ); #say $tee "\$soughtval: $soughtval";
            push( @bag, $soughtval );
          }
          $i++;
        }

        unless ( scalar( @bag ) <= ( $parconcurrencies - 1 ) )
        {
          unless ( scalar( @bag ) == 0 )
          {
            $bagmean = mean( @bag ); #say $tee "\$bagmean: $bagmean";
          }
        }
      }
      unless ( $bagmean eq "" )
      {
        $wand{$ke}{$dee} = $bagmean ;
        $spell{$ke} = $magic{$ke}{$dee}->[0] ;
      }
    }
  }

  #say $tee "MAGIC: " . dump(%magic);
  #say $tee "WAND: " . dump(%wand);

  my @limb0;
  foreach my $ke ( sort {$a <=> $b} ( keys %wand ) )
  {
    my $eltnum = scalar( keys %{ $wand{$ke} } );
    unless ( $eltnum <= ( $instconcurrencies - 1 ) )
    {
      my $avg = mean( values( %{ $wand{$ke} } ) ); #say $tee "\$avg: " .  dump( $avg );
      push ( @limb0, [ $spell{$ke}[0], $spell{$ke}[1] , $avg ] ); #say $tee "\$avg: $avg"; say $tee "\${ \$magic{\$ke}{\$dee} }->[1] : ${ $magic{$ke}{$dee} }->[1] ";
    }
  }
  return( @limb0 );
} ##### END SUB purelin


sub near
{
  my ( $arr_ref, $nearrelaxlimit, $relaxmethod, $overweightnearest, $nearconcurrencies, $count, $factlevels_ref, $maxdist ) = @_;
  my @arr = @{ $arr_ref };
  my %factlevels = $factlevels_ref;
  foreach my $el ( @arr )
  { #say $tee "\$el->[1]: " . dump( $el->[1] ); #say $tee "EL: " . dump( $el );
    if ( $el->[2] eq "" )
    { #say $tee "TRYING \$el->[1]: " . dump( $el->[1] );

      my @bag;
      foreach my $elt ( @arr )
      { #say $tee "SO, ELT: " . dump( $elt ); #say $tee "IN WHICH, ELT0: " . dump( @{ $elt->[0] } );
        if ( not ( $elt->[2] eq "" ) )
        {
          my @diff1 = diff( \@{ $el->[1] }, \@{ $elt->[1] } ); #say $tee "AND \@diff1: " . dump( @diff1 );

          my $index = 0;
          while ( $index <= $nearrelaxlimit )
          {
            if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= ( 1 + $nearrelaxlimit ) ) )
            { #say $tee "AND \@diff1 IS 1: " . dump( @diff1 );
              my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } ); #say $tee "SO \@diff2: " . dump( @diff2 );

              my ( $da1_ref, $da1par_ref, $da2_ref, $da2par_ref ) = setvalues( \@diff1, \@diff2 );
              my @da1 = @{ $da1_ref };
              my @da2 = @{ $da2_ref };

              my $count = 0;
              foreach my $d10 ( @da1 )
              { #say $tee "\$d10: " . dump( $d10 );
                my $d11 = $da1par[$count]; #say $tee "\$d11: " . dump( $d11 );
                my $co = 0;
                foreach my $d20 ( @da2 )
                { #say $tee "\$d20: " . dump( $d20 );
                  my $d21 = $da2par[$co]; #say $tee "\$d21: " . dump( $d21 );
                  if ( ( $d10 eq $d20 ) ) #### if ( ( $d10 eq $d20 ) and ( $d11 ne $d21 ) ) ###  THE SECOND CONDITION COULD BE LOGICALLY REDUNDANT. CHECK. ####
                  {
                    push( @bag, $elt->[2] ); #say $tee "PUSHING " . $elt->[1] . " IN BAG"; #key, array, factornum missing, factornum gotten, value
                    #say $tee dump( $el->[0], $el->[1], $d11, $d21, $elt->[2] );
                  }
                  $co++;
                }
                $count++;
              }
            }
            $index++;
          }
        }
      }

      my @limb0;
      if ( not ( scalar( @bag ) <= ( $nearconcurrencies - 1 ) ) )
      { #say $tee "\@bag: " . dump( @bag );
        my $bagmean = mean( @bag ); #say $tee "\$bagmean: $bagmean";
        unless ( scalar( @bag ) == 0 )
        {
          push ( @limb0, [ $el->[0], $el->[1], $bagmean ] ); #say $tee "PUSHIN \$bagmean $bagmean in \@limbo2 ";
        }
      }
    }
  }
  return( @limb0 );
}############ END SUB nearest


sub mixlimbo
{
  my ( $limbo1_ref, $limbo2_ref, $presence, $linearprecedence, $weights_ref ) = @_;
  my @limbo1 = @{ $limbo1_ref };
  my @limbo2 = @{ $limbo2_ref };
  my @weights = @{ $weights_ref };
  my @limbo = @limbo1 ;
  foreach my $el ( @limbo2 )
  { #say $tee "EL AGAIN: " . dump( $el );
    my $presence = "absent";
    if ( exists( $limbo1copy{$el->[0]} ) )
    {
      $elt = $limbo1copy{$el->[0]};
      if ( $el->[0] eq $elt->[0] )
      {
        $presence = "present";
      }
    }

    if ( $presence eq "absent" )
    {
      push ( @limbo, $el );
    }
    else
    {
      if ( not ( $linearprecedence eq "no" ) )
      {unless ( $pos1 == $pos2 )
          {
            my $diffp = ( $pos1 - $pos2 );
            my $diffval = ( $val1 - $val2 );
            my $unit = ( $diffval / $diffp );
            my $halfunit = ( $unit / 2 );
            my $halfdiffval = ( $diffval / 2 );
            my $avgval = ( ( $val1 + $val2 ) / 2 ); #say $tee "\$avgval: $avgval";
            my $avgpos = ( ( $pos1 + $pos2 ) / 2); #say $tee "\$avgpos: $avgpos";
            my $distp = ( $posor - $avgpos ); #say $tee "\$distp: $distp";
            my $change = ( $distp * $unit ); #say $tee "\$change: $change";
            my $soughtval = ( $avgval + $change ); #say $tee "\$soughtval: $soughtval";
            push( @bag, $soughtval );
          }
        push ( @limbo, $el );
      }
      else
      {
        if ( not ( scalar( @weights ) == 0 ) )
        {
          $newelt = ( $elt->[2] * $weights[0] );
          $newel = ( $el->[2] * $weights[1] );
          my $val = ( $newel + $newelt );
          $el->[2] = $val;
          push ( @limbo, $el );
        }
      }
    }
  }
  return ( @limbo );
}


sub prepfactlev
{
  my @aarr = @_;
  my %hsh;
  foreach my $el ( @aarr )
  {
    foreach my $bit ( @{ $el->[1] } )
    {
      my ( $head, $tail ) = split( /-/ , $bit );
      $hsh{pairs}{$head} = $tail;
    }
  }
  return( %hsh );
}


sub interstart
{
say "
This is Interlinear.
Name of a configuration file (Unix path):
";
	my $configfile = <STDIN>;
	chomp $configfile;
	if (-e $configfile )
  {
    say "\
    Now the name of a csv file:
    ";
    my $sourcefile = <STDIN>;
  }
  if ( not (-e $sourcefile ) )
	{
    say "\
    This csv file seem to be not there.
    It may be specified in the configuration file.
    ";
  }
  @arr = interlinear( $configfile, $sourcefile );
}


########################################### END SUBS

my $optformat;
my @arr;

sub interlinear
{
  my ( $configf, $sourcef ) = @_;
  if ( $sourcef ne "" ){ $sourcefile = $sourcef; }
  if ( $configf ne "" ){ $configfile = $configf; }

  $tee = new IO::Tee(\*STDOUT, ">$report");

  my @mode = adjustmode( $maxloops, \@mode ); say $tee
  open( SOURCEFILE, "$sourcefile" ) or die;
  my @lines = <SOURCEFILE>;
  close SOURCEFILE;

  say $tee "Preparing the dataseries.";
  my $aarr_ref;
  ( $aarr_ref, $optformat ) = preparearr( \@lines );

  my @aarr = @{ $aarr_ref };

  say $tee "Checking factors and levels.";
  my %factlevels = prepfactlev( @aarr );

  my ( $factlev_ref ) = tellstepsize( \%factlevels );
  my %factlev = %{ $factlev_ref }; #say $tee "\%factlev: " . dump( %factlev );

  my $maxdist = calcmaxdist( \@aarr, \%factlev ); #say $tee "001\$maxdist: " . dump( $maxdist );

  my $count = 0;
  while ( $count < $maxloops )
  {

    if ( $count == 0 )
    {
      @arr = @aarr;
    }
    else
    {
      @arr = @arr2;
    }

    say $tee "COUNT: " . dump( $count + 1 );
    my $mode__ = $mode[$count] ;

    my ( @limbo_wei, @limbo_purelin, @limbo_near, @limbo, %bank, %wand );


    #if ( ( $mode__ eq "vault" ) or ( $mode__ eq "mix" ) )
    #{
    #  @limbo_vault = vault( \@arr, $relaxlimit, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count, \%factlev );
    #}
    #say $tee "OBTAINED limbo_vault: " . dump( @limbo_vault );
    #say $tee "THERE ARE " . scalar( @limbo_vault ) . " ITEMS IN THIS LOOP , NUMBER " . ( $count + 1 ). ", 1, FOR GLOBALLY WEIGHTED GRADIENT INTERPOLATION.";


    if ( ( $mode__ eq "wei" ) or ( $mode__ eq "mix" ) )
    {
      @limbo_wei = wei( \@arr, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count, \%factlev, $minreq_forgrad, $minreq_forinclusion, $minreq_forcalc, $minreq_formerge, $maxdist );
      say $tee "THERE ARE " . scalar( @limbo_wei ) . " ITEMS IN THIS LOOP , NUMBER " . ( $count + 1 ). ", 1, FOR WEIGHTED GRADIENT INTERPOLATION OF THE NEAREST NEIGHBOUR.";
    }
    #say $tee "OBTAINED LIMBO_WEI: " . dump( @limbo_wei );

    if ( ( $mode__ eq "purelin" ) or ( $mode__ eq "mix" ) )
    {
      @limbo_purelin = purelin( \@arr, $relaxlimit, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count, \%factlev, $maxdist );
      say $tee "THERE ARE " . scalar( @limbo_purelin ) . " ITEMS IN THIS LOOP , NUMBER " . ( $count + 1 ). ", 1, FOR PURE LINEAR INTERPOLATION.";
    }
    #say $tee "OBTAINED LIMBO_PURELIN: " . dump( @limbo_purelin );

    if ( ( $mode__ eq "near" ) or ( $mode__ eq "mix" ) )
    {
      @limbo_near = near( @arr, $nearrelaxlimit, $relaxmethod, $overweightnearest, $nearconcurrencies, $count, \%factlev, $maxdist );
      say $tee "THERE ARE " . scalar( @limbo_near ) . " ITEMS IN THIS LOOP, NUMBER " . ( $count + 1 ) . ", 2, FOR THE NEAREST NEIGHBOUR STRATEGY.";
    }
    #say $tee "MAGIC: " . dump( %magic );
    #say $tee "OBTAINED LIMBO_NEAR: " . dump( @limbo_near );


    if ( $mode__ eq "wei" )
    {
      @limbo = @limbo_wei;
    }

    if ( $mode__ eq "purelin" )
    {
      @limbo = @limbo_purelin;
    }

    if ( $mode__ eq "near" )
    {
      @limbo = @limbo_near;
    }

    #if ( $mode__ eq "mix" )
    #{
    #  my @limbo_prov = mixlimbo( \@limbo_wei, \@limbo_purelin, $presence, $linearprecedence, \@weights );
    #  @limbo = mixlimbo( \@limbo_prov, \@limbo_near, $presence, $linearprecedence, \@weights );
    #}

    say $tee "OBTAINED LIMBO: " . dump( @limbo );
    say $tee "MIXING THE ARRAY UPDATES " . ( $count + 1 ) . " for $sourcefile";
    say $tee "THERE ARE " . scalar( @limbo ) . " ITEMS COMING OUT FROM THIS MIX " . ( $count + 1 );



    if ( ( scalar( @limbo ) == 0 ) )
    {
      #say $tee "ARR END: " . dump( @arr );
      last;
    }

    #say $tee "ARR BEFORE: " . dump( @arr );
    foreach my $el ( @limbo )
    { #say $tee "EL AGAIN: " . dump( $el );
      foreach $elt ( @arr )
      { #say $tee "44a\$el->[0]: " . dump( $el->[0] ); say $tee "44a\$elt->[0]: " . dump( $elt->[0] );
        if ( $el->[0] eq $elt->[0] )
        { #say $tee "INQUIRING ";
          if ( $elt ->[2] eq "" )
          {   #say $tee "WITHIN ";
              push ( @{ $elt }, $el->[2], $el->[3] );
          }
          else
          {
            #say $tee "ENTERED0 ";
            #if ( $elt->[3] <= $minimumhold )
            { #say $tee "ENTERED1 ";
              my ( $soughtval, $totstrength ) = weightvals_merge( [ $elt->[2], $el->[2] ], [ $elt->[3], $el->[3] ], $minreq_formerge, $maxdist  );
              #say $tee "OBTAINED1 \$soughtval: " . dump( $soughtval ) . "FOR " . dump( $elt->[0] ) ;
              #say $tee "OBTAINED1 \$totstrength: " . dump( $totstrength ) . "FOR " . dump( $elt->[0] ) ;
              if ( ( $soughtval ne "" ) and ( $totstrength ne "" ) )
              { #say $tee "OBTAINED2 \$elt: " . dump( $elt ) . "1 ";
                pop @{ $elt }; #say $tee "OBTAINED2 \$elt: " . dump( $elt ) . "2 ";
                pop @{ $elt }; #say $tee "OBTAINED2 \$elt: " . dump( $elt ) . "3 ";
                #say $tee "OBTAINED2 \$soughtval: " . dump( $soughtval ) . "FOR " . dump( $elt->[0] ) ;
                #say $tee "OBTAINED2 \$totstrength: " . dump( $totstrength ) . "FOR " . dump( $elt->[0] ) ;
                push ( @{ $elt }, $soughtval, $totstrength ); #say $tee "OBTAINED \$elt: " . dump( $elt ) . "LAST ";
              }
              #else { say $tee "CHECK! WRONG!"; }
            }
          }
        }
      }
    }
    @arr2 = @arr ;
    say $tee "INSERTING THE ARRAY UPDATES " . ( $count + 1 ) . " for $sourcefile";
    #say $tee "ARR AFTER: " . dump( @arr );
    $count++;
  }
  return( @arr );
}



if ( @ARGV )
{my $maxloops= 1000;
  my $first = $_[0];
  if ( $first eq "interstart" )
  {
    interstart;
  }
  elsif ( $first eq "." )
  {
    @arr = interlinear;
  }
  else
  {
    @arr = interlinear( @ARGV );
  }
}

open( NEWFILE, ">$newfile" ) or die;

foreach my $entry ( @arr )
{
  if ( $optformat eq "yes" )
  {
    print NEWFILE "$entry->[0],$entry->[2]\n";
  }
  elsif ( $optformat eq "no" )
  {
    my $coun = 0;
    foreach my $item ( @{ $entry->[1] } )
    {
      my $response = odd( $coun );
      if ( $response eq "odd" )
      {
        print NEWFILE "$item,";
      }
      $coun++;
    }
    print NEWFILE "$entry->[2]\n";
  }
}


close NEWFILE;

#############################################################################

1;

__END__

=head1 NAME


Sim::OPT::Interlinear


=head1 SYNOPSIS


  From Perl (via "re.pl" or in a Perl program):
  interlinear( "/path/to/a/pre-prepared-configfile.pl", "/path/to/a/pre-prepared-sourcefile.csv" );
  or from the command line:
  interlinear .
  (note the dot at the end), to use the file as a script and include the location of the source file directly in the configuration file;
  or, again, from the command line:
  interlinear interstart
  to begin with a dialogue question.


=head1 DESCRIPTION


Interlinear is a program for computing the missing values in multivariate datasieries pre-prepared in csv format.
The program can adopt the following algorithmic strategies and intermix their result:

a) a propagating distance-weighted gradient-based strategy (by far the best one so far, keeping into account that the behaviour of factors is often not linear and there are curvatures all aroung the design space);

b) pure linear interpolation (one may want to use this in some occasions: for example, on factorials);

c) nearest neighbour (a strategy of last resort. One may want to use it to unlock a computation which is based on data which are too sparse to proceed, or when nothing else works).

A configuration file should be prepared following the example in the "examples" folder in this distribution.
If the configuration file is incomplete or missing, the program adopts its own defaults, exploiting the distance-weighted gradient-based strategy.

The only variable that must mandatorily be specified in a configuration file is $sourcefile : the Unix path to the source file containining the dataseries.

The source file has to be prepared by listing in each column the values (levels) of the parameters (factors, variables), putting in the last column the objective function value, when present.

The parameter number is given by the position of the column (i.e. column 4 host parameter 4).

Here below is shown an example of multivatiate dataseries of 3 parameters assuming 3 levels each. having with missing objecive function entries.


1,1,1,1.234

1,2,3,2,1.500

1,3,3,3

2,1,3,1,1.534

2,2,3,2,0.000

2,3,3,0.550

3,1,3,1

3,2,3,2,0.670

3,3,3,3


Note that the parameter listings cannot be incomplete. Just the objective function entries can be.
The program converts this format into the one liked by Sim::OPTS, which is the following:


1-1_2-1_3-1,9.234

1-1_2-2_3-2,4.500

1-1_2-3_3-3

1-2_2-1_3-1,7.534

1-2_2-2_3-2,0.000

1-2_2-3_3-3,0.550

1-3_2-1_3-1

1-3_2-2_3-2,0.670

1-3_2-3_3-3


After some computations, Interlinear will output a new dataseries, with the missing values filled in.


=head2 EXPORT


interlinear, interstart.


=head1 SEE ALSO


An example of configuration file can be found in the "examples" folder in this distribution.


=head1 AUTHOR


Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>


=head1 COPYRIGHT AND LICENSE


Copyright (C) 2018 by Gian Luca Brunetti and Politecnico di Milano. This is free software. You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 or newer.


=cut
