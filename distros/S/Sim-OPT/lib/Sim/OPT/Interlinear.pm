#package Sim::OPT::Interlinear;
# NOTE: TO USE THE PROGRAM AS A SCRIPT, THE LINE ABOVE SHOULD BE DELETED.

# INTERLINEAR
# Author: Gian Luca Brunetti, Politecnico di Milano. (gianluca.brunetti@polimi.it)
# Copyright reserved.  2018-2019.
# GPL License 3.0 or newer.
# This is a program for filling a design space multivariate discrete dataseries
# through a strategy entailing distance-weighting the nearest-neihbouring gradients.

use v5.14;
use Math::Round;
use List::Util qw( min max reduce shuffle any );
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

#use Sim::OPT;
#use Sim::OPT::Morph;
#use Sim::OPT::Sim;
#use Sim::OPT::Report;
#use Sim::OPT::Descend;
#use Sim::OPT::Takechance;
#use Sim::OPT::Parcoord3d;
# NOTE: TO USE THE PROGRAM AS A SCRIPT, THE ABOVE "use Sim::OPT..." lines should be deleted.

our @ISA = qw( Exporter );
our @EXPORT = qw( interlinear, interstart prepfactlev tellstepsize );

$VERSION = '0.147';
$ABSTRACT = 'Interlinear is a program for building metamodels from incomplete, multivariate, discrete dataseries on the basis of nearest-neighbouring gradients weighted by distance.';

#######################################################################
# Interlinear
#######################################################################

########## AN EXAMPLE OF SETTINGS TO BE PUT IN A CONFIGURATION FILE FOLLOWS.

############# END OF THE EXAMPLE SETTINGS TO BE PUT IN A CONFIGURATION FILE.


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
  my ( $factlevels_ref, $lvconv ) = @_;
  my %factlevels = %{ $factlevels_ref }; #say $tee "FACTLEVELS IN tellstepsize: " . dump( %factlevels ); say $tee "\$factlevels{pairs}: " . dump( $factlevels{pairs} );
  foreach my $fact ( sort {$a <=> $b} ( keys %{ $factlevels{pairs} } ) )
  { #say $tee "\$fact: " . dump( $fact );

    if ( $lvconv eq "" )
    {
      $lvconv = 1;
    }
    elsif ( $lvconv eq "equal" )
    {
      $lvconv = ( $factlevels{pairs}{$fact} - 1 ) ;
    }


    my $stepsize;
    if ( not( $factlevels{pairs}{$fact} == 1 ) )
    {
      $stepsize = ( 1 / ( $factlevels{pairs}{$fact} - 1 ) ) * $lvconv; #say $tee "\$stepsize: " . dump( $stepsize );
    }
    else
    {
      $stepsize = 0; #say $tee "\$stepsize: " . dump( $stepsize );
    }
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

sub diff_OLD
{
  my $aref = shift;
  my $bref = shift;
  my @aa = @$aref; #say "\@aa: " . dump( @aa );
  my @bb = @$bref; #say "\@bb: " . dump( @bb );
  my @difference;

  my @int = get_intersection( \@aa, \@bb );
  foreach my $el ( @aa )
  {
    if ( not ( $_ ~~ @int ) )
    #if ( not ( any { $_ eq $el } @int ) )
    {
      push ( @difference, $_ );
    }
  }
  return @difference;
}


sub diff
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


sub diff_THIS
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
  my @lines = @_;
  my $optformat = "yes";
  my @arr;
  if ( $lines[1] =~ /_/ )
  {
    foreach my $line ( @lines )
    {
      chomp( $line );
      my @row = split( /,/ , $line ); #say $tee "IN PREPAREARR \@row " . dump( @row );
      @pars = split( /_/ , $row[0] ); #say $tee "IN PREPAREARR \@pars " . dump( @pars );

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

      if ( ( $strength ne "" ) and ( $sum_strengths ne "" ) and ( $sum_strengths != 0 ))
      {
        $soughtgrad = ( $soughtgrad + ( $grad * ( $strength / $sum_strengths ) ) ); #say $tee "887 SAYY \$soughtgrad: " . dump( $soughtgrad );
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

    foreach my $el ( @diff1 )
    {
      my @elts = split( "-", $el );
      push( @da1, $elts[0] );
      push( @da1par, $elts[1] );
    }
    foreach my $el ( @diff2 )
    {
      my @elts = split( "-", $el );
      push( @da2, $elts[0] );
      push( @da2par, $elts[1] );
    } # say $tee "YES, I AIM.";

    #my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
    #@da1 = keys %h1; #say $tee "THEN \@da1: " . dump( @da1 );
    #@da1par = values %h1; #say $tee "\@da1par: " . dump( @da1par );
    #my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
    #@da2 = keys %h2; #say $tee "THEN \@da2: " . dump( @da2 );
    #@da2par = values %h2; #say $tee "\@da2par: " . dump( @da2par );

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
  my ( $el1, $elt1, $factlevels_ref, $minreq, $maxdist, $el3, $elt3, $condweight, $el, $elt ) = @_; #say $tee "777c\$el1: " . dump( $el1 ); say $tee "777c\$elt1: " . dump( $elt1 ); say $tee "777c\$minreq: " . dump( $minreq );
  my %factlevels = %{ $factlevels_ref };
  #say $tee "IN CALCDISTGRAD \$el1: " . dump( $el1 );
  #say $tee "IN CALCDISTGRAD \$elt1: " . dump( $elt1 );
  my @diff1 = diff( \@{ $el1 }, \@{ $elt1 } ); #say $tee "IN CALCDISTGRAD \@diff1: " . dump( @diff1 );
  my $dist;
  my ( @factbag, @levbag, @stepbag, @da1, @da1par, @da2, @da2par, @diff2 );
  #say $tee "777\scalar( \@diff1 ): " . dump( scalar( @diff1 ) ); say $tee "777\$minreq: " . dump( $minreq );
  #say $tee "\$minreq->[0]: " . dump( $minreq->[0] );
  if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= $minreq->[0] ) )
  {
    @diff2 = diff( \@{ $elt1 } , \@{ $el1 } ); #say $tee "IN CALCDISTGRAD \@diff2: " . dump( @diff2 );

    foreach my $el ( @diff1 )
    {
      my @elts = split( "-", $el );
      push( @da1, $elts[0] );
      push( @da1par, $elts[1] );
    }
    foreach my $el ( @diff2 )
    {
      my @elts = split( "-", $el );
      push( @da2, $elts[0] );
      push( @da2par, $elts[1] );
    }

    #my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "IN CALCDISTGRAD \%h1: " . dump( \%h1 );
    #@da1 = keys %h1; # $tee "IN CALCDISTGRAD \@da1: " . dump( @da1 );
    #@da1par = values %h1; #say $tee "IN CALCDISTGRAD \@da1par: " . dump( @da1par );
    #my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "IN CALCDISTGRAD \%h2: " . dump( \%h2 );
    #@da2 = keys %h2; #say $tee "IN CALCDISTGRAD \@da2: " . dump( @da2 );
    #@da2par = values %h2; #say $tee "IN CALCDISTGRAD \@da2par: " . dump( @da2par );

    my $c = 0;
    foreach my $lev1 ( @da1par )
    {
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
  else
  {

  }

  unless ( ( scalar( @levbag ) == 0 ) or ( scalar( @factbag ) == 0 ) or ( scalar( @stepbag ) == 0 ) )
  {
    my $ordist = scalar( @levbag ); #say $tee "IN CALCDISTGRAD \$ordist: " . dump( $ordist );
    my $rawdist = pythagoras( \@factbag, \@levbag, \@stepbag ); #say $tee "IN CALCDISTGRAD \$rawdist: " . dump( $rawdist );
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
  #my @sortarr = sort { $a->[0] <=> $b->[0] } @arr;
  my $first = $arr[0];
  my $last = $arr[-1];
  my %hash = %{ calcdist( $first->[1], $last->[1], $factlevels_ref ) };
  #say $tee "\$first->[0]: " . dump( $first->[0] );
  #say $tee "\$last->[0]: " . dump( $last->[0] );
  say $tee "raw max distance: " . dump( $hash{rawdist} ); #say $tee "00\%hash: " . dump( %hash );

  #my %nears;
  #foreach my $ar ( @arr )
  #{
  #  my @nrs = @{ isnear( $ar->[0], $first, $last ) };
  #  $nears{$ar->[0]} = [ @nrs ];
  #}
  #say $tee "NEARS: " . dump( %nears );
  return( $hash{rawdist}, $first->[0], $last->[0] );
}


sub calcmaxdist_old
{
  my ( $arr_ref, $factlevels_ref) = @_;
  my $thislimit; # $limit is unused.
  my @arr = @{ $arr_ref };

  my @arrc;
  #if ( $limit ne "" )
  #{
    if ( ( scalar( @arr ) > 3000 ) and ( scalar( @arr ) <= 20000 ) )
    {
      $thislimit = int( scalar( @arr ) ** ( 3 / 4 ) );
      #$thislimit = int( scalar( @arr ) ** ( 2 / 3 ) );
    }
    elsif ( scalar( @arr ) > 20000 )
    {
      $thislimit = int( scalar( @arr ) ** ( 2 / 3 ) );
    }
    else
    {
      $thislimit = scalar( @arr );
    }

    @arrc = shuffle( @arr );
    @arrc = @arrc[0..$thislimit];
  #}

  my @rawdists;
  foreach my $el ( @arrc )
  {
    foreach my $elt ( @arrc )
    {
      my $hash_ref = calcdist( $el->[1], $elt->[1], $factlevels_ref );
      my %hash = %{ $hash_ref }; #say $tee "00\%hash: " . dump( %hash );
      push ( @rawdists, $hash{rawdist} );
    }
  } #say $tee "00\@rawdists: " . dump( @rawdists );
  my $maxdist = max( @rawdists ); #say $tee "00\$maxdist: " . dump( $maxdist );
  return( $maxdist );
}


sub isnear
{
  my ( $this, $first, $last ) = @_;
  my @bits = split( "_", $this ); #say "\@bits" . dump( @bits );
  my @firstbits = split( "_", $first ); #say "\@firstbits" . dump( @firstbits );
  my @lastbits = split( "_", $last ); #say "\@lastbits" . dump( @lastbits );

  my $c = 0;
  foreach my $bit ( @bits)
  {
    my @els = split( "-", $bit); #say "\@els" . dump( @els );
    my @firstels = split( "-", $firstbits[$c] ); #say "\@firstels" . dump( @firstels );
    my @lastels = split( "-", $lastbits[$c] ); #say "\@lastels" . dump( @lastels );

    if ( not( $firstels[1] > ( $els[1] - 1 ) ) )
    {
      my @newels1 = ( $els[0], ( $els[1] - 1 ) ); #say "\@newels1" . dump( @newels1 );
      my $newl = join( "-", @newels1 ); #say "\$newl" . dump( $newl );
      push( @newels, $newl ); #say "DYNADEC \@newels" . dump( @newels );
    }
    else
    {
      push( @newels, $bit ); #say "FLATDEC \@newels" . dump( @newels );
    }

    if ( not( $lastels[1] < ( $els[1] + 1 ) ) )
    {
      my @newels2 = ( $els[0], ( $els[1] + 1 ) ); #say "\@newels2" . dump( @newels2 );
      my $newl = join( "-", @newels2 ); #say "\$newl" . dump( $newl );
      push( @newels, $newl ); #say "DYNATINC \@newels" . dump( @newels );
    }
    else
    {
      push( @newels, $bit ); #say "FLATINC \@newels" . dump( @newels );
    }
    $c++;
  }

  my ( @neighs, @neighbours );
  foreach my $newel ( @newels )
  {
    my @ns = split( "-", $newel ); #say "\@ns" . dump( @ns );
    my $n = $ns[0] . "-"; #say "\$n" . dump( $n );
    my $word = $this;
    $word =~ s/$n(\d+)/$newel/ ; #say "\$word" . dump( $word );
    push( @neighs, $word ); #say "\@neighs" . dump( @neighs );
  }
  @neighs = uniq( @neighs );
  my @neighbours = sort { $a <=> $b } @neighs; #say "\@neighbours" . dump( @neighbours );
  return( \@neighbours );
}


sub wei
{
  my ( $arr_ref, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count,
    $factlevels_ref, $minreq_forgrad, $minreq_forinclusion, $minreq_forcalc, $minreq_formerge, $maxdist, $nfilter, $limit_checkdistgrades, $limit_checkdistpoints, $bank_ref, $fulldo, $first0, $last0, $nears_ref, $checkstop,
    $weldsprepared_ref, $weldaarrs_ref, $parswelds_ref, $recedes_ref ) = @_;
  my @arr = @{ $arr_ref };
  #say $tee "ARR VERY_BEFORE: " . dump(@arr);
  my %factlevels = %{ $factlevels_ref };  #say $tee "AND \%factlevels: " . dump( %factlevels );
  # my ( %magic, %wand, %spell, %bank );
  my %bank = %{ $bank_ref };
  my %nears = %{ $nears_ref }; #say $tee " \%nearsIN1: " . dump( \%nears );

  my %weldnears;

###--###
  my @weldsprepared = @{ $weldsprepared_ref }; #say $tee "NOW \@weldsprepared: " . dump( @weldsprepared );
  my @weldaarrs = @{ $weldaarrs_ref }; #say $tee "NOW \@weldaarrs: " . dump( @weldaarrs );
  my @parswelds = @{ $parswelds_ref }; #say $tee "NOW \@parswelds: " . dump( @parswelds );
  my @recedes = @{ $recedes_ref }; #say $tee "NOW \@recedes: " . dump( @recedes );
###--###

  #say "nfilter: $nfilter.";
  $nfilter = ( $nfilter - 1 );

  my @arr__;
  if ( ( $limit_checkdistgrades ne "" ) or ( $limit_checkdistpoints ne "" ) )
  {
    @arr__ = shuffle( @arr );
  }
  else
  {
    @arr__ = @arr;
  }

  my ( @arra, @arrah );
  if ( ( $limit_checkdistgrades ne "" ) and ( $limit_checkdistgrades > $checkstop ) )
  {
    @arrah = @arr__;
    @arra = @arrah[0..$limit_checkdistgrades];
  }
  else
  {
    @arra = @arr__;
  }

  my @arrb;
  if ( ( $limit_checkdistgrades ne "" ) and ( $limit_checkdistgrades > $checkstop ) )
  {
    @arrb = @arrah[0..$limit_checkdistpoints];
  }
  elsif ( ( $limit_checkdistpoints ne "" ) and ( $limit_checkdistpoints > $checkstop ) )
  {
    my @arrb_ = @arr__;
    @arrb = @arrb_[0..$limit_checkdistpoints];
  }
  else
  {
    @arrb = @arr__;
  }


  sub fillbank
  { #say $tee "NOW IN FILLBANK.";
    #say $tee " \%nearsIN2: " . dump( \%nears );
    my ( $arr_r, $minimumcertain, $minreq_forgrad, $maxdist, $condweight, $factlevels_r, $nfilter, $arra_r, $first0, $last0, $nears_ref ) = @_;
    my @arr = @{ $arr_r };
    my @arra = @{ $arra_r };
    my %factlevels = %{ $factlevels_r };
    my %nears = %{ $nears_ref }; #say $tee " \%nearsIN3: " . dump( \%nears );
    #my $nstop;
    #if ( $nfilter ne "" )
    #{
    #  $nstop = ( $nfilter * 2 );
    #}

    my %bank;
    foreach my $el ( @arr )
    { #say $tee "SO IN FIRST ARR CHECK" ;  say $tee "\$el->[1]: " . dump( $el->[1] ); #say $tee "EL: " . dump( $el );
      #my $key =  $el->[0] ; #say $tee "\$key: " . dump( $key );
      if ( ( $el->[2] ne "" ) and ( $el->[3] >= $minimumcertain ) )
      { #say $tee "SO IN SECOND ARR CHECK" ; say $tee "\nTRYING \$el->[1]: " . dump( $el->[1] );

        my @neighbours;
        #if ( $el->[2] ne "" )
        {
          if ( scalar( @{ $nears{$el->[0]}{neighbours} } ) == 0 )
          {
            @neighbours = @{ isnear( $el->[0], $first0, $last0 ) };
            $nears{$el->[0]}{neighbours} = [ @neighbours ];
          }
          else
          {
            @neighbours = @{ $nears{$el->[0]}{neighbours} };
          }
          #say $tee "\IT DO NOT EXIST.";
        }

        #foreach my $elt ( @arra )
        foreach my $it ( @neighbours )
        { #say $tee "SO, ELT: " . dump( $elt ); say $tee "IN WHICH, ELT0: " . dump( @{ $elt->[0] } );
          #if ( ( $elt->[0] ~~ @neighbours ) and ( $elt->[2] ne "" ) and ( $elt->[0] ne $el->[0] ) and ( $el->[3] >= $minimumcertain ) )
          #if ( ( $elt->[0] ~~ @neighbours ) and ( $elt->[2] ne "" ) and ( $elt->[0] ne $el->[0] ) and ( $el->[3] >= $minimumcertain ) )
          #if ( ( $elt->[2] ne "" ) and ( $elt->[0] ne $el->[0] ) and ( $el->[3] >= $minimumcertain ) )
          #if ( ( any { $_ eq $elt->[0] } @neighbours ) and ( $elt->[2] ne "" ) and ( $elt->[0] ne $el->[0] ) and ( $el->[3] >= $minimumcertain ) )
          my $elt = $nears{$it}{all};
          if ( ( $elt->[2] ne "" ) and ( $elt->[0] ne $el->[0] ) and ( $el->[3] >= $minimumcertain ) )
          { #say $tee "NOW CHECKING .";

            my ( $res_ref ) = calcdistgrad( $el->[1], $elt->[1], \%factlevels, $minreq_forgrad, $maxdist, $el->[3], $elt->[3], $condweight, $el, $elt );
            #say $tee "\OBTAINED DIST \$res_ref: " . dump( $res_ref );

            my %d;
            my ( @diff1, @diff2, @da1, @da2, @da1par, @da2par );
            my ( $ordist, $dist, $strength );

            unless ( !keys %{ $res_ref } )
            {
              %d = %{ $res_ref }; #say $tee "FOUND \%d: " . dump( \%d );
              my @diff1 = @{$d{diff1}}; #say $tee "FOUND \@diff1: " . dump( @diff1 );
              @diff2 = @{$d{diff2}}; #say $tee "FOUND \@diff2: " . dump( @diff2 );
              @da1 = @{$d{da1}}; #say $tee "FOUND \@da1: " . dump( @da1 );
              @da2 = @{$d{da2}}; #say $tee "FOUND \@da2: " . dump( @da2 );
              @da1par = @{$d{da1par}}; #say $tee "FOUND \@da1par: " . dump( @da1par );
              @da2par = @{$d{da2par}}; #say $tee "FOUND \@da2par: " . dump( @da2par );
              $ordist = $d{ordist}; #say $tee "FOUND \$ordist: " . dump ( $ordist ); #say $tee "D: " . dump ( %d );
              $dist = $d{dist}; #say $tee "FOUND \$dist: " . dump( $dist );
              $strength = $d{strength}; #say $tee "FOUND \$strength: " . dump( $strength );
            }
            #else
            #{
            #  say $tee "NULL!";
            #}

            unless ( !keys %{ $res_ref } and ( $ordist > 0 ) and ( $ordist ne "" ) ) ######## IMPROVE THIS SO AS TO ALLOW VERY DIFFERENT NUMBERS OF LEVELS FOR EACH FACTOR
            { #say $tee " SO I AM IN. ";

              my $benchmark;
              if ( $nfilter ne "" )
              {
                if ( scalar( @{ $bank{$trio}{strengths} } ) > $nfilter )
                {
                  $benchmark = ${ $bank{$trio}{strengths} }[$nfilter]; #say "BENCHMARK1: $benchmark.";
                }
                else
                {
                  $benchmark = 0;
                }
              }
              #say "BENCHMARK2: $benchmark.";
              #say $tee "\$strength: " . dump( $strength );

              if ( ( $strength > $benchmark ) or ( $nfilter eq "" ) )
              {
                #say "NOW INTO.";

                my $count = 0;
                foreach my $d10 ( @da1 )
                { #say $tee "WORKING \$d10: " . dump( $d10 );
                  #say "IN FOREACH.";

                  if ( ( $nfilter ne "" ) and ( scalar( @{ $bank{$trio}{strengths} } ) > $nfilter ) )
                  {
                    #say "NEXT!";
                    next;
                  }

                  my $d11 = $da1par[$count]; #say $tee "WORKING \$d11: " . dump( $d11 );
                  #my $nearness = abs( $d11 - $d21 );
                  #my $d20 = $da2[$count]; #say $tee "\$d21: " . dump( $d21 );
                  my $co = 0;
                  foreach my $d20 ( @da2 )
                  { #say $tee "WORKING \$d20: " . dump( $d20 );

                    if ( $d10 == $d20 )
                    { #say $tee "THIS: d10 AND d20: " . dump( $d20 );
                      my $stepsize = $factlevels{stepsizes}{$d20}; #say $tee "$stepsize: " . dump( $stepsize );
                      my $d21 = $da2par[$co]; #say $tee "WORKING \$d21: " . dump( $d21 );

                      my @duo = ( 1, 2 );
                      my ( $pair, @sorted, $orderedpair, $trio, $orderedtrio );
                      my ( $pos1, $pos2, $val1, $val2 );
                      foreach my $turn ( @duo )
                      {
                        if ( $turn == 1 )
                        {
                          $pair = join( "-", $d11, $d21 );
                        }
                        elsif ( $turn == 2 )
                        {
                          $pair = join( "-", $d21, $d11 );
                        }

                        @sorted = sort( $d11, $d21 );
                        $orderedpair = join( "-", @sorted );
                        $trio = join( "-", $d10, $pair );
                        $orderedtrio = join( "-", $d10, $orderedpair ); #say $tee "\$orderedtrio: " . dump( $orderedtrio );

                        #unless ( ( $trio eq "" ) or ( $el[0] ~~ @{ $bank{$trio}{orstring} } ) )
                        unless ( ( $trio eq "" ) or ( any { $_ eq $el[0] } @{ $bank{$trio}{orstring} } ) )
                        {
                          $bank{$trio}{par} = $d10;
                          push ( @{ $bank{$trio}{trio} }, $trio );

                          if ( $turn == 1 )
                          {
                            push ( @{ $bank{$trio}{orstrings} }, [ $el->[0], $elt->[0] ] );
                            push ( @{ $bank{$trio}{orstring} }, $el->[0] );
                          }
                          elsif ( $turn == 2 )
                          {
                            push ( @{ $bank{$trio}{orstrings} }, [ $elt->[0], $el->[0] ] );
                            push ( @{ $bank{$trio}{orstring} }, $elt->[0] );
                          }

                          push ( @{ $bank{$trio}{orderedtrio} }, $orderedtrio );

                          if ( $turn == 1 )
                          {
                            push ( @{ $bank{$trio}{orvals} }, [ $el->[2], $elt->[2] ] );
                            push ( @{ $bank{$trio}{origins} }, $el->[1], $elt->[1] );
                          }
                          elsif ( $turn == 2 )
                          {
                            push ( @{ $bank{$trio}{orvals} }, [ $elt->[2], $el->[2] ] );
                            push ( @{ $bank{$trio}{origins} }, $elt->[1], $el->[1] );
                          }

                          if ( ( $ordist > 0 ) and ( $ordist ne "" ) and ( $dist ne "" ) and ( $strength ne "" ) )
                          {
                            push ( @{ $bank{$trio}{ordists} }, $ordist );
                            #push ( @{ $bank{$reversedtrio}{ordists} }, $ordist );
                            push ( @{ $bank{$trio}{dists} }, $dist );
                            #push ( @{ $bank{$reversedtrio}{dists} }, $dist );
                            push ( @{ $bank{$trio}{strengths} }, $strength );
                          }

                          if ( $turn == 1 )
                          {
                            $pos1 = $d11; #say $tee "WORKING \$pos1: " . dump( $pos1 );
                            $pos2 = $d21; #say $tee "WORKING \$pos2: " . dump( $pos2 );
                            $val1 = $el->[2]; #say $tee "WORKING \$val1: " . dump( $val1 );
                            $val2 = $elt->[2]; #say $tee "WORKING \$val2: " . dump( $val2 );
                          }
                          elsif ( $turn == 2 )
                          {
                            $pos1 = $d21; #say $tee "WORKING \$pos1: " . dump( $pos1 );
                            $pos2 = $d11; #say $tee "WORKING \$pos2: " . dump( $pos2 );
                            $val1 = $elt->[2]; #say $tee "WORKING \$val1: " . dump( $val1 );
                            $val2 = $el->[2]; #say $tee "WORKING \$val2: " . dump( $val2 );
                          }

                          my $diffpos = ( $pos1 - $pos2 ); #say $tee "WORKING \$diffpos: " . dump( $diffpos );
                          my $diffval = ( $val1 - $val2 ); #say $tee "WORKING \$diffval: " . dump( $diffval );
                          my $grad;
                          if ( ( $diffpos ne "" ) and ( $diffpos != 0 ) )
                          {
                            $grad = ( $diffval / $diffpos ); #say $tee "DEFINING \$grad: " . dump( $grad );
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
    }
    #_#say $tee " \%bank: " . dump( %bank );
    return ( \%bank, \%nears );
  }

  sub clean
  {
    my ( $bank_ref, $nfilter, $message, $recedes_ref ) = @_;
    my %bank = %{ $bank_ref };
    my $n2filter = ( 2 * $nfilter );
    my @recedes = @{ $recedes_ref };
    if ( scalar( @recedes ) > 0 )
    {
      say "RECEDE " . dump( @recedes ); #say "MESSAGE $message";
    }

    foreach my $trio ( keys ( %bank ) )
    {
      my @els = split( "-", $trio );
      my $first = $els[0];
      unless ( ( $message eq "principal" ) and ( $first ~~ @recedes ) )
      {
        my ( @grads, @ordists, @dists, @strengths );
        unless( ( $bank{$trio}{grad} eq "" ) or ( $bank{$trio}{ordists} eq "" )
          or ( $bank{$trio}{dists} eq "" ) or ( $bank{$trio}{strengths} eq "" ) )
        {
          push ( @grads, $bank{$trio}{grad} );
          @grads = map { $_ =~ s/ // } @grads;
          push ( @ordists, $bank{$trio}{ordists} );
          @ordists = map { $_ =~ s/ // } @ordists;
          push ( @dists, $bank{$trio}{dists} );
          @dists = map { $_ =~ s/ // } @dists;
          push ( @strengths, $bank{$trio}{strengths} );

          @grads = map { $b <=> $a } @grads;
          @grads = @grads[0..$n2filter];
          @ordists = map { $b <=> $a } @ordists;
          @ordists = @ordists[0..$n2filter];
          @dists = map { $b <=> $a } @dists;
          @dists = @dists[0..$n2filter];
          @strengths = map { $_ =~ s/ // } @strengths;
          @strengths = map { $b <=> $a } @strengths;
          @strengths = @strengths[0..$n2filter];

          $bank{$trio}{grad} = [ @grads ];
          $bank{$trio}{ordists} = [ @ordists ];
          $bank{$trio}{dists} = [ @dists ];
          $bank{$trio}{strengths} = [ @strengths ];
        }
      }
      #else
      #{
      #  say $tee "RECEDE $first";
      #}
    }
    return( \%bank );
  } #END FILLBANK

  unless( ( $fulldo eq "$tight" ) and ( $count > 0 ) )
  {
    say $tee "Entering gradients' \%bank.";
    my ( $bank_ref, $nears_ref ) = fillbank( \@arr__, $minimumcertain, $minreq_forgrad, $maxdist, $condweight, \%factlevels, $nfilter, \@arra, $first0, $last0, \%nears );
    %bank = %{ $bank_ref }; #say $tee "\%bank: " . dump( %bank );
    %nears = %{ $nears_ref };
    %bank = %{ clean( \%bank, $nfilter, "principal", \@recedes ) }; say $tee "BANK DONE."; #say $tee "CLEANED \%bank: " . dump( %bank ) ;
  }

###--###
  sub mixbank
  {
    my ( $bank_ref, $weldbank_ref, $parsws_ref ) = @_;
    my %bank = %{ $bank_ref };
    my %weldbank = %{ $weldbank_ref };
    my @parsws = @{ $parsws_ref };
    say $tee "Mixing for welding " . dump( @parsws );
    foreach my $trio ( keys %weldbank )
    {
      unless ( $trio eq "" )
      {
        my @splits = split( "-", $trio ); #say $tee "\@splits " . dump( @splits );
        my $num = $splits[0];
        if ( $num ~~ @parsws )
        {
          push ( @{ $bank{$trio}{orderedtrio} }, @{ $weldbank{$trio}{orderedtrio} } );
          push ( @{ $bank{$trio}{grad} }, @{ $weldbank{$trio}{grad} } );
          push ( @{ $bank{$trio}{grads} }, @{ $weldbank{$trio}{grads} } );
          push ( @{ $bank{$trio}{ordists} }, @{ $weldbank{$trio}{ordists} } );
          push ( @{ $bank{$trio}{strengths} }, @{ $weldbank{$trio}{strengths} } );
          push ( @{ $bank{$trio}{orvals} }, @{ $weldbank{$trio}{orvals} } );
          push ( @{ $bank{$trio}{origins} }, @{ $weldbank{$trio}{origins} } );
          push ( @{ $bank{$trio}{orstrings} }, @{ $weldbank{$trio}{orstrings} } );
          push ( @{ $bank{$trio}{orstring} }, @{ $weldbank{$trio}{orstring} } );
          say $tee "weld $num.";
        }
      }
    }
    return( \%bank );
  }

  unless ( ( scalar( @weldsprepared ) == 0 )
  #or ( $count > 0 )
  )
  { say $tee "Entering gradients' bank for welding.";
    my $co = 0;
    foreach my $weldref ( @weldaarrs )
    {
      my @parsws = @{ $parswelds[$co] }; say $tee "\@parsws: " . dump( @parsws );
      my @weldarr = @{ $weldref }; #_#say $tee "THIS \@weldarr: " . dump( @weldarr ) . " DONE THIS \@weldarr.";
      my @weldarr__;
      if ( ( $limit_checkdistgrades ne "" ) or ( $limit_checkdistpoints ne "" ) )
      {
        @weldarr__ = shuffle( @weldarr );
      }
      else
      {
        @weldarr__ = @weldarr;
      }

      my ( @weldarra, @weldarrah );
      if ( ( $limit_checkdistgrades ne "" ) and ( $limit_checkdistgrades > $checkstop ) )
      {
        @weldarrah = @weldarr__;
        @weldarra = @weldarrah[0..$limit_checkdistgrades];
      }
      else
      {
        @weldarra = @weldarr__;
      }

      my @weldarrb;
      if ( ( $limit_checkdistgrades ne "" ) and ( $limit_checkdistgrades > $checkstop ) )
      {
        @weldarrb = @weldarrah[0..$limit_checkdistpoints];
      }
      elsif ( ( $limit_checkdistpoints ne "" ) and ( $limit_checkdistpoints > $checkstop ) )
      {
        my @weldarrb_ = @weldarr__;
        @weldarrb = @weldarrb_[0..$limit_checkdistpoints];
      }
      else
      {
        @weldarrb = @weldarr__;
      }


      #foreach my $el ( @weldarr )
      #{
      #  if ( ( $weldnears{$el->[0]}{all}->[2] eq "" ) or ( ( $weldnears{$el->[0]}{all}->[3] < 1 ) and ( $weldnears{$el->[0]}{all}->[2] != $el->[2] ) ) )
      #  {
      #    $weldnears{$el->[0]}{all} = $el;
      #  }
      #}
      #say $tee " \%weldnears: " . dump( \%weldnears );

      #say $tee "FIRST0 $first0,  LAST0 $last0 ";
      #say $tee " \@weldarr__: " . dump( \@weldarr__ ) ;
      #say $tee " \%factlevels: " . dump( \%factlevels ) ;
      #say $tee " \@weldarra: " . dump( \@weldarra ) ;
      my ( $weldbank_ref, $weldnears_ref ) = fillbank( \@weldarr__, $minimumcertain, $minreq_forgrad, $maxdist, $condweight, \%factlevels, $nfilter, \@weldarra, $first0, $last0, \%nears );##%weldnears!!!!
      %weldbank = %{ $weldbank_ref }; #say $tee " \%weldbank: " . dump( \%weldbank ) ;
      %weldnears = %{ $weldnears_ref };

      %weldbank = %{ clean( \%weldbank, $nfilter, "weld" ) }; #say $tee "CLEANED \%weldbank: " . dump( \%weldbank ) ;

      %bank = %{ mixbank( \%bank, \%weldbank, \@parsws ) };
      #say $tee "COMPLETED \%bank:" . dump( \%bank ) . ": COMPLETED \%bank.";
      say $tee "KEYS \%bank: " . ( keys %bank );

      $co++;
    }
  }
###--###

  sub cyclearr
  {
    my ( $arr_r, $minreq_forinclusion, $minreq_forgrad, $bank_r, $factlevels, $nfilter, $arrb_r, $first0, $last0, $nears_ref ) = @_;
    my @arr = @{ $arr_r };
    my @arrb = @{ $arrb_r };
    my %bank = %{ $bank_r };
    my %factlevels = %{ $factlevels };
    my %nears = %{ $nears_ref };
    #say $tee "IN cyclearr ARR: " . dump( @arr );
    # %nfilter is not used here.

    my %wand;
    my $coun = 0;
    foreach my $el ( @arr )
    { #say $tee "\$el->[1]: " . dump( $el->[1] ); #say $tee "EL: " . dump( $el );
      my $key =  $el->[0] ; #say $tee "\$key: " . dump( $key );

      if ( $el->[2] eq "" )
      { #say $tee "TRYING \$el->[1]: " . dump( $el->[1] );

        my @neighbours;
        if ( scalar( @{ $nears{$el->[0]}{neighbours} } ) == 0 )
        {
          @neighbours = @{ isnear( $el->[0], $first0, $last0 ) };
          $nears{$el->[0]}{neighbours} = [ @neighbours ];
        }
        else
        {
          @neighbours = @{ $nears{$el->[0]}{neighbours} };
        }

        #foreach my $elt ( @arrb )
        foreach my $it ( @neighbours )
        { #say $tee "SO, ELT: " . dump( $elt ); #say $tee "IN WHICH, ELT0: " . dump( @{ $elt->[0] } );
          #if ( ( $elt->[0] ~~ @neighbours ) and ( $elt->[2] ne "" ) and ( $el->[3] >= $minreq_forinclusion ) )
          # ( any { $_ eq $elt->[0] } @neighbours )
          #if ( ( any { $_ eq $elt->[0] } @neighbours ) and ( $elt->[2] ne "" ) and ( $el->[3] >= $minreq_forinclusion ) )
          my $elt = $nears{$it}{all};
          #say $tee "FOUND \$elt: " . dump( $elt );
          if ( ( $elt->[2] ne "" ) and ( $el->[3] >= $minreq_forinclusion ) )
          {
            my @diff1 = diff( \@{ $el->[1] }, \@{ $elt->[1] } ); #say $tee "AND \@diff1: " . dump( @diff1 );

            if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= $minreq_forgrad->[2] ) )
            { #say $tee "AND \@diff1 IS 1: " . dump( @diff1 );
              #say "NOW IN.";
              my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } ); #say $tee "SO \@diff2: " . dump( @diff2 );

              my ( @da1, @da1par, @da2, @da2par );
              foreach my $el ( @diff1 )
              {
                my @elts = split( "-", $el );
                push( @da1, $elts[0] );
                push( @da1par, $elts[1] );
              }
              foreach my $el ( @diff2 )
              {
                my @elts = split( "-", $el );
                push( @da2, $elts[0] );
                push( @da2par, $elts[1] );
              }

              #my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
              #my @da1 = keys %h1;
              #my @da1par = values %h1; # $tee "\@da1par: " . dump( @da1par );
              #my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " .yes dump( %h2 );
              #my @da2 = keys %h2;
              #my @da2par = values %h2; #say $tee "\@da2par: " . dump( @da2par );
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
                        #if ( ( $grad ne "" ) and ( ${ $bank{$newtrio}{orstring} }[$cn] ~~ @neighbours ) )
                        if ( ( $grad ne "" ) and ( any { $_ eq ${ $bank{$newtrio}{orstring} }[$cn] } @neighbours ) )
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
                              my $diffpar = abs( $e - $ei ); #say $tee "335 \$diffpar: " . dump( $diffpar );
                              #if ( ( $diffpar >= $minreq_forgrad->[1] ) and ( $diffpar > 0 ) )
                             ###################if ( ( ${ $bank{$newtrio}{orstring} }[$cn] ~~ @neighbours ) ) and ( $diffpar <= $minreq_forgrad->[1] ) and ( $diffpar > 0 ) ) ############################HERE
                              if ( ( $diffpar <= $minreq_forgrad->[1] ) and ( $diffpar > 0 ) )
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

                        #unless ( ( $soughtinc eq "" ) or ( $totdist eq "" ) or ( $elt->[0] ~~ @{ $wand{$key}{origin} } ) )###################
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
                      }
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
    } #say $tee "MAGIC WAND. " . dump( %wand );
    return( \%wand, \%nears );
  }

  say $tee "GOING TO CREATE NEW POINTS.";
  my ( $wand_ref, $nears_ref ) = cyclearr( \@arr__, $minreq_forinclusion, $minreq_forgrad, \%bank, \%factlevels, $nfilter, \@arrb, $first0, $last0, \%nears ); say $tee "DONE."; #say $tee "\%wand OUT: " . dump( %wand );
  my %wand = %{ $wand_ref }; #say $tee "\%wand OUT: " . dump( %wand );
  say $tee "\nDONE.";
  %nears = %{ $nears_ref }; #say $tee "RE-UPDATED \%nears: " . dump( \%nears ) . "\nDONE.";

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

  if ( $fulldo eq "yes" )
  {
    %bank = ();
  }

  #say $tee "LIMBO_WEI: " . dump( @limbo_wei );
  return( \@limb0, \%bank, \%nears )
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

                my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } ); #say $tee "SO \@diff2: " . dump( @diff2 );

                my ( @da1, @da1par, @da2, @da2par );
                foreach my $el ( @diff1 )
                {
                  my @elts = split( "-", $el );
                  push( @da1, $elts[0] );
                  push( @da1par, $elts[1] );
                }
                foreach my $el ( @diff2 )
                {
                  my @elts = split( "-", $el );
                  push( @da2, $elts[0] );
                  push( @da2par, $elts[1] );
                }

                #my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
                #my @da1 = keys %h1;
                #my @da1par = values %h1; # $tee "\@da1par: " . dump( @da1par );
                #my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " .yes dump( %h2 );
                #my @da2 = keys %h2;
                #my @da2par = values %h2; #say $tee "\@da2par: " . dump( @da2par );
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

                my ( @da1, @da1par, @da2, @da2par );
                foreach my $el ( @diff1 )
                {
                  my @elts = split( "-", $el );
                  push( @da1, $elts[0] );
                  push( @da1par, $elts[1] );
                }
                foreach my $el ( @diff2 )
                {
                  my @elts = split( "-", $el );
                  push( @da2, $elts[0] );
                  push( @da2par, $elts[1] );
                }

                #my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
                #my @da1 = keys %h1;
                #my @da1par = values %h1; # $tee "\@da1par: " . dump( @da1par );
                #my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
                #my @da2 = keys %h2;
                #my @da2po_weiar = values %h2; #sa_refy $tee "\@da2par: " . dump( @da2par );
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
                    $co++;$nears_ref
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


                my ( @da1, @da1par, @da2, @da2par );
                foreach my $el ( @diff1 )
                {
                  my @elts = split( "-", $el );
                  push( @da1, $elts[0] );
                  push( @da1par, $elts[1] );
                }
                foreach my $el ( @diff2 )
                {
                  my @elts = split( "-", $el );
                  push( @da2, $elts[0] );
                  push( @da2par, $elts[1] );
                }

                #my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
                #my @da1 = keys %h1;
                #my @da1par = values %h1; # $tee "\@da1par: " . dump( @da1par );
                #my %h2fill = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
                #my @da2 = keys %h2;
                #my @da2par = values %h2; #say $tee "\@da2par: " . dump( @da2par );
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

                my ( @da1, @da1par, @da2, @da2par );
                foreach my $el ( @diff1 )
                {
                  my @elts = split( "-", $el );
                  push( @da1, $elts[0] );
                  push( @da1par, $elts[1] );
                }
                foreach my $el ( @diff2 )
                {
                  my @elts = split( "-", $el );
                  push( @da2, $elts[0] );
                  push( @da2par, $elts[1] );
                }

                #my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
                #my @da1 = keys %h1;
                #my @da1par = values %h1; # $tee "\@da1par: " . dump( @da1par );
                #my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
                #my @da2 = keys %h2;
                #my @da2par = values %h2; #say $tee "\@da2par: " . du$presence mp( @da2par );
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
  my @aarr = @{ $_[0] };
  my %hsh;
  foreach my $el ( @aarr )
  {
    foreach my $bit ( @{ $el->[1] } )
    {
      my ( $head, $tail ) = split( /-/ , $bit );
      $hsh{pairs}{$head} = $tail;
    }
  }
  return( \%hsh );
}


sub prepfactlev_delete
{
  my ( $aarr_r, $blockelts_r ) = @_;
  my @aarr = @{ $aarr_r };
  my @blockelts = @{ $blockelts_r };
  my %hsh;
  foreach my $el ( @aarr )
  {
    foreach my $bit ( @{ $el->[1] } )
    {
      my ( $head, $tail ) = split( /-/ , $bit );
      if ( $blockelts_r eq "" )
      {
        $hsh{pairs}{$head} = $tail;
      }
      else
      {
        #if ( $head ~~ @blockelts )
        if ( any { $_ eq $head } @blockelts )
        {
          $hsh{pairs}{$head} = $tail;
        }
      }
    }
  }
  return( %hsh );
}


sub interstart
{
  say "
This is Interlinear.
Name of a csv file (Unix path):
    ";
  my $sourcefile = <STDIN>;

  if ( not ( -e $sourcefile ) )
  {
    say "
    This csv file does not seem to be there.
    I will look for \"./sourcefile.csv\".
    Now name of a configuration file:
    ";
    my $confile = <STDIN>;

    if ( not ( -e $confile ) )
    {
      say "
      This configuration file does not seem to be there.
      I will look for \"./confinterlinear.pl\",
      or go with the defaults.
      Now hit ENTER to proceed.
      ";
      my $throwaway = <STDIN>;
      @arr = interlinear( $sourcefile, $confile );
    }
  }
}


########################################### END SUBS

my $optformat;
my @arr;

sub interlinear
{
  my ( $sourcef, $configf, $metafile, $blockelts_r, $reportf, $countblock ) = @_;
  #say $tee "ARRIVED IN INTERLINEAR \$configf $configf";
  #say $tee "ARRIVED IN INTERLINEAR \$sourcef $sourcef";
  #say $tee "ARRIVED IN INTERLINEAR \$metafile $metafile";
  #say $tee "ARRIVED IN INTERLINEAR \$blockelts_r ". dump( $blockelts_r );
  #say $tee "ARRIVED IN INTERLINEAR \$reportf $reportf";
  #say $tee "ARRIVED IN INTERLINEAR \$countblock $countblock";

  say "DOING";
  my ( %bank, %nears );

  if ( $reportf ne "" ){ $report = $reportf; } #say $tee "CHECK5 \$report: " . dump( $report );

  if ( $configf eq "" )
  {
    $configf = "./confinterlinear.pl";
  };

  if ( $configf ne "" )
  {
    $confile = $configf;
  }; #say $tee "CHECK5 \$confile: " . dump( $confile );

  if ( -e $confile )
  {
    require $confile; ############## TRULY FIX THIS!!!!!
  }
  else
  {



  }


  $tee = new IO::Tee(\*STDOUT, ">>$report"); # GLOBAL ZZZ

  #say $tee "ENTERED.";

  if ( $sourcef ne "" ){ $sourcefile = $sourcef; } #say $tee "CHECK5 \$sourcefile: " . dump( $sourcefile );

  if ( $metafile ne "" ){ $newfile = $metafile; } #say $tee "CHECK5 \$newfile: " . dump( $newfile );

  my @blockelts;
  if ( $blockelts_r ne "" ){ @blockelts = @{ $blockelts_r }; } #say $tee "CHECK5 \@blockelts: " . dump( @blockelts );

  my @mode = adjustmode( $maxloops, \@mode );
  say $tee "Opening $sourcefile";
  open( SOURCEFILE, "$sourcefile" ) or die;
  my @lines = <SOURCEFILE>; #say $tee "REALLY \@lines: " . dump( @lines );
  close SOURCEFILE;
  #print "THIS $tee";
  say $tee "Preparing the dataseries, IN INTERLINEAR: \$countblock $countblock";
  say "nfilter: $nfilter";
  my $checkstop;

  my $aarr_ref;
  ( $aarr_ref, $optformat ) = preparearr( @lines );

  my @aarr = @{ $aarr_ref }; #say $tee "REALLY \@aarr: " . dump( @aarr );

  say $tee "Checking factors and levels.";
  my %factlevels = %{ prepfactlev( \@aarr ) }; #say $tee "IN INTERLINEAR REALLY \%factlevels: " . dump( \%factlevels );
  say $tee "Done.";


  my ( $factlev_ref ) = tellstepsize( \%factlevels, $lvconversion );
  my %factlev = %{ $factlev_ref }; say $tee " \%factlev: " . dump( %factlev );
  say $tee "Understood step sizes.";

###--###
  my ( @weldaarrs );
  if ( scalar( @weldsprepared ) > 0 )
  {
    foreach my $weldsourcefile ( @weldsprepared )
    {
      open( WELDSOURCEFILE, "$weldsourcefile" ) or die;
      my @weldlines = <WELDSOURCEFILE>; #say $tee "REALLY \@lines: " . dump( @lines );
      close WELDSOURCEFILE;

      my ( $weldaarr_ref, $optformat ) = preparearr( @weldlines );

      my @weldaarr = @{ $weldaarr_ref }; #say $tee "REALLY \@weldaarr: " . dump( @weldaarr );
      push ( @weldaarrs, [ @weldaarr ] );
    }
  }

  my ( $maxdist, $first0, $last0 ) = calcmaxdist( \@aarr, \%factlev );
###--###

  #say $tee "\$first0: " . dump( $first0 );
  #say $tee "\$last0: " . dump( $last0 );
  #say $tee "DONE CALCMAXDIST: " . dump( $maxdist );

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

    #say $tee "COUNT: " . dump( $count + 1 );
    my $mode__ = $mode[$count] ;

    my ( @limbo_wei, @limbo_purelin, @limbo_near, @limbo, %wand );


    #if ( ( $mode__ eq "vault" ) or ( $mode__ eq "mix" ) )
    #{
    #  @limbo_vault = vault( \@arr, $relaxlimit, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count, \%factlev );
    #}
    #say $tee "OBTAINED limbo_vault: " . dump( @limbo_vault );
    #say $tee "THERE ARE " . scalar( @limbo_vault ) . " ITEMS IN THIS LOOP , NUMBER " . ( $count + 1 ). ", 1, FOR GLOBALLY WEIGHTED GRADIENT INTERPOLATION.";

    sub checkstop
    {
      my @arr = @_;
      my $t = 0;
      foreach my $e ( @arr )
      {
        if ( $e->[2] eq "" )
        {
          $t++;
        }
      }
      if ( $t == 0)
      {
        say $tee "EXITING. DONE.";
        printend( \@arr, $newfile, $optformat );
        last;
      }
      $checkstop = $t;
    }
    checkstop( @arr );


    foreach my $el ( @arr )
    {
      if ( ( $nears{$el->[0]}{all}->[2] eq "" ) or ( ( $nears{$el->[0]}{all}->[3] < 1 ) and ( $nears{$el->[0]}{all}->[2] != $el->[2] ) ) )
      {
        $nears{$el->[0]}{all} = $el;
      }
    }

    #if ( $count > 0 )
    #{
    #   say "NEARS: " . dump( \%nears );
    #}


    if ( ( $mode__ eq "wei" ) or ( $mode__ eq "mix" ) )
    {
      my ( $limbo_wei_ref, $bank_ref, $nears_ref ) = wei( \@arr, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count, \%factlev, $minreq_forgrad, $minreq_forinclusion, $minreq_forcalc, $minreq_formerge, $maxdist, $nfilter, $limit_checkdistgrades, $limit_checkdistpoints, \%bank, $fulldo, $first0, $last0, \%nears, $checkstop, \@weldsprepared, \@weldaarrs, \@parswelds, \@recedes );

      @limbo_wei = @{ $limbo_wei_ref };
      %bank = %{ $bank_ref };
      %nears = %{ $nears_ref }; say $tee "OBTAINED \%nears: " . dump( \%nears );

      say $tee "THERE ARE " . scalar( @limbo_wei ) . " ITEMS IN THIS LOOP , NUMBER " . ( $count + 1 ). ", 1, FOR WEIGHTED GRADIENT INTERPOLATION OF THE NEAREST NEIGHBOUR.";
    }
    say $tee "OBTAINED LIMBO_WEI: " . dump( @limbo_wei );

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

    #if ( $mode__ eq "mix" )printend( \@arr, $newfile, $optformat );
    #{
    #  my @limbo_prov = mixlimbo( \@limbo_wei, \@limbo_purelin, $presence, $linearprecedence, \@weights );
    #  @limbo = mixlimbo( \@limbo_prov, \@limbo_near, $presence, $linearprecedence, \@weights );
    #}

    #say $tee "OBTAINED LIMBO: " . dump( @limbo );
    say $tee "MIXING THE ARRAY UPDATES " . ( $count + 1 ) . " for $sourcefile";
    say $tee "THERE ARE " . scalar( @limbo ) . " ITEMS COMING OUT FROM THIS MIX " . ( $count + 1 );


    if ( ( scalar( @limbo ) == 0 ) )
    {
      #say $tee "ARR END: " . dump( @arr );
      say $tee "EXITING.";
      printend( \@arr, $newfile, $optformat );
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
{
  if ( $ARGV[0] eq "interstart" )
  {
    interstart;
  }
  elsif ( $ARGV[0] eq "." )
  {
    my @args = ( @ARGV[1..$#ARGV] );
    @arr = interlinear( @args );
  }
}


sub printend
{
  my ( $arr_r, $newfile, $optformat ) = @_;
  my @arr = @{ $arr_r };

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
}

if ( ( scalar( @arr ) > 0 ) and ( defined( $newfile ) ) and ( defined( $optformat ) ) )
{
  printend( \@arr, $newfile, $optformat );
}




#############################################################################

1;

__END__

=head1 NAME


Sim::OPT::Interlinear


=head1 SYNOPSIS


  # As a Perl function:
  re.#!/usr/bin/env perl
  use Sim::OPT::Interlinear
  Sim::OPT::Interlinear::interlinear( "./sourcefile.csv", "./configfile.pl", "./obtainedmetamodel.csv" );

  # or as a script, from the command line:
  perl ./Interlinear.pm  .  ./sourcefile.csv
  # (note the dot).

  # or, again, from the command line, for beginning with a dialogue question:
  interlinear interstart


=head1 DESCRIPTION


Interlinear is a program for computing the missing values in multivariate datasieries through a strategy entailing distance-weighting the nearest-neihbouring gradients between points in an n-dimensional space.
The program adopts a distance-weighted gradient-based strategy. The strategy weights the known gradients in a manner inversely proportional to the distance of their pivot points from the pivot points of the missing nearest-neighbouring gradients, then utilizes recursively the gradients neighbouring near each unknown point to define it, weighting the candidates by distance. In this strategy, the curvatures in the space are reconstructed by exploiting the fact that in this calculation a local sample of the near-neighbouring gradients is used, which vary for each point. The strategy in question is adopted in Interlinear since version 0.103. Before that version, the gradients were calculated on a global basis.
Besides the described strategy, a), the following metamodelling strategies are utilized by Interlinear:

b) pure linear interpolation (one may want to use this in some occasions: for example, on factorials);

c) pure nearest neighbour (a strategy of last resort. One may want to use it to unlock a computation which is based on data which are too sparse to proceed, or when nothing else works).

Strategy a) works for cases which are adjacent in the design space. For example, it cannot work with the gradient between a certain iteration 1 and the corresponding iteration 3. It can only work with the gradient between iterations 1 and 2, or 2 and 3.
For that reason, it does not work well with data evenly distributed in the design space, like those deriving from latin hypercube sampling, or a random sampling; and works well with data clustered in small patches, like those deriving from star (coordinate descent) sampling strategies.
To work well with a latin hypercube sampling, it is usually necessary to include a pass of strategy b) before calling strategy a). Then strategy a) will charge itself of reducing the gradient errors created by the initial pass of strategy b).

A configuration file should be prepared following the example in the "examples" folder in this distribution.
If the configuration file is incomplete or missing, the program will adopt its own defaults, exploiting the distance-weighted gradient-based strategy.
in the last column in the last column
The only variable that must mandatorily be specified in a configuration file is $sourcefile: the Unix path to the source file containining the dataseries. The source file has to be prepared by listing in each column the values (levels) of the parameters (factors, variables), putting the objective function valuesin the last column in the last column, at the rows in which they are present.

The parameter number is given by the position of the column (i.e. column 4 host parameter 4).

Here below is an example of multivatiate dataseries of 3 parameters assuming 3 levels each. The numbers preceding the objective function (which is in the last colum) are the indices of the multidimensional matrix (tensor).


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
The program converts this format into the one preferred by Sim::OPTS, which is the following:


1-1_2-1_3-1,9.234

1-1_2-2_3-2,4.500

1-1_2-3_3-3

1-2_2-1_3-1,7.534

1-2_2-2_3-2,0.000

1-2_2-3_3-3,0.550

1-3_2-1_3-1

1-3_2-2_3-2,0.670

1-3_2-3_3-3


After some computations, Interlinear will output a new dataseries with the missing values filled in.
This dataseries can be used by OPT for the optimization of one or more blocks. This can be useful, for example, to save computations in searches involving simulations, especially when the time required by each simulations is long, like it may happen with CFD simulations in building design.

The number of computations required for the creation of a metamodel in OPT increases exponentially with the number of instances in the metamodel. To make the increase linear, a limit has to be set for the size of the net of instances taken into account in the computations for gradients and for points. The variables in the configuration files controlling those limits are "$limit_checkgrades" and "$limit_checkpoints". By default they are both set to 10000. If a null value ("") is specified for them, no limit is assumed.

To call Interlinear as a Perl function (best strategy):
re.pl # open Perl shell
use Sim::OPT::Interlinear; # load Interlinear
Sim::OPT::Interlinear::interlinear( "./sourcefile.csv", "./configfile.pl", "./obtainedmetamodel.csv" );
"configfile.pl" is the configuration file. If that file is an empty file, Interlinear will assume its defaults.
"./sourcefile.csv" is the only information which is truly mandatory: the path to the csv dataseries to be completed.

To use Interlinear as a script from the command line:
./Interlinear.pm . "./sourcefile.csv" "./configfile.pl ";
(Note the dot within the line.) If "./sourcefile.csv" is not specified, the default file "./sourcefile.csv" will be sought.
If "./configfile.pl" is not specified, the program goes with the defaults.

Or to begin with a dialogue question:
./Interlinear.pm interstart;
.

=head2 EXPORT


interlinear, interstart.



=head1 AUTHOR


Gian Luca Brunetti (2018-19) E<lt>gianluca.brunetti@polimi.itE<gt>


=head1 COPYRIGHT AND LICENSE


Copyright (C) 2018-19 by Gian Luca Brunetti and Politecnico di Milano. This is free software. You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 or newer.


=cut
