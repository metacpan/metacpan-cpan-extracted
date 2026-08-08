package Sim::OPT::Interlinear;
# NOTE: TO USE THE PROGRAM AS A SCRIPT, THE LINE ABOVE SHOULD BE DELETED.
# Interlinear is a program for filling a design space multivariate discrete dataseries # through a strategy entailing distance-weighting the nearest-neihbouring gradients.
# Interliner is distributed under a dual licence, open-source (GPL v3) and proprietary.
# Copyright Gian Luca Brunetti 2018-2025, gianluca.brunetti@gmail.com. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( interlinear, interstart prepfactlev tellstepsize );

use Math::Round;
use List::Util qw( min max reduce shuffle any );
use Sim::OPT::Stats qw(:all);
use List::Compare;
use Set::Intersection;
use List::MoreUtils qw(uniq);
use List::AllUtils qw(sum);
use Data::Dump qw(dump);
use feature 'say';
no strict;
no warnings;
use Switch::Back;

use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Sim;
use Sim::OPT::Report;
use Sim::OPT::Descend;
use Sim::OPT::Takechance;

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


# NOTE: TO USE THE PROGRAM AS A SCRIPT, THE ABOVE "use Sim::OPT..." lines should be deleted or commented.

$VERSION = '0.199';
$ABSTRACT = 'Interlinear is a program for building metamodels from incomplete multivariate discrete dataseries on the basis of nearest-neighbouring gradients weighted by distance.';

#######################################################################
# Interlinear
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
  my ( $factlevels_ref, $lvconv ) = @_;
  my %factlevels = %{ $factlevels_ref }; #say  "FACTLEVELS IN tellstepsize: " . dump( %factlevels ); say  "\$factlevels{pairs}: " . dump( $factlevels{pairs} );
  foreach my $fact ( sort {$a <=> $b} ( keys %{ $factlevels{pairs} } ) )
  { #say  "\$fact: " . dump( $fact );

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
      $stepsize = ( 1 / ( $factlevels{pairs}{$fact} - 1 ) ) * $lvconv; #say  "\$stepsize: " . dump( $stepsize );
    }
    else
    {
      $stepsize = 0; #say  "\$stepsize: " . dump( $stepsize );
    }
    $factlevels{stepsizes}{$fact} = $stepsize ;
  } #say  "FACTLEVELS1: " . dump( %factlevels );
  return( \%factlevels );
}


sub union
{
  my $aref = shift;
  my $bref = shift;
  my @aa = @$aref; #say  ""\@aa: " . dump( @aa );
  my @bb = @$bref; #say  "\@bb: " . dump( @bb );

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
  my @aa = @$aref;
  my @bb = @$bref;
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
  my @aa = @$aref;
  my @bb = @$bref;
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
  my $optformat = "y";
  my @arr;
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
    $optformat = "n";
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
  } #say  "ARR: " . dump( @arr );
  return( \@arr, $optformat );
}



sub pythagoras
{
  my ( $factbag_ref, $levbag_ref, $stepbag_ref ) = @_;
  my @factbag = @{ $factbag_ref };
  my @levbag = @{ $levbag_ref };
  my @stepbag = @{ $stepbag_ref };
  my $powdist;
  my $inc = 0;
  foreach ( @factbag )
  {
    my $step = $stepbag[$inc];
    my $difflevel = $levbag[$inc];
    $powdist = $powdist + ( ( $difflevel * $step ) ** 2 );
    $inc++;
  }
  my $dist = $powdist ** ( 1/2 );
  return ( $dist );
}


sub weightvals1
{
  my ( $elt1, $boxgrads_ref, $boxdists_ref, $boxors_ref, $minreq_forcalc, $factbag_ref, $levbag_ref, $stepbag_ref, $levstep, $elt2, $factlevels_ref, $maxdist, $elt3, $condweight ) = @_;
  my @boxgrads = @{ $boxgrads_ref };
  my @boxdists = @{ $boxdists_ref };
  my @boxors = @{ $boxors_ref };
  my @factbag = @{ $factbag_ref };
  my @levbag = @{ $levbag_ref };
  my @stepbag = @{ $stepbag_ref };
  my %factlevels = %{ $factlevels_ref };

  my @newboxdists;
  foreach my $or ( @boxors )
  {
    my $hsh_ref = calcdist( $elt1, $or, \%factlevels, $maxdist, $elt3, $condweight );
    my %hsh = %{ $hsh_ref };
    my $dist = $hsh{dist};
    push ( @newboxdists, $dist );
  }

  my @boxstrengths;
  foreach my $dist ( @newboxdists )
  {
    if ( ( $dist ne "" ) and ( $dist != 0 ) )
    {
      my $strength = ( 1 - $dist );
      push ( @boxstrengths, $strength );
    }
  }

  my $sum_strengths;

  $sum_strengths = sum( @boxstrengths );

  my $totdist;
  my $soughtgrad = 0;
  if ( not ( scalar( @boxgrads ) == 0 ) )
  {
    my $in = 0;
    foreach my $grad ( @boxgrads )
    {

      my $strength = $boxstrengths[$in];

      if ( ( $strength ne "" ) and ( $sum_strengths ne "" ) and ( $sum_strengths != 0 ))
      {
        $soughtgrad = ( $soughtgrad + ( $grad * ( $strength / $sum_strengths ) ) );
      }
      $in++;
    }
  }

  my ( $totdist, $totstrength );
  unless ( ( scalar( @levbag ) == 0 ) or ( scalar( @factbag ) == 0 ) or ( scalar( @stepbag ) == 0 ) )
  {
    my $rawtotdist = pythagoras( \@factbag, \@levbag, \@stepbag );
    $totdist = ( $rawtotdist / $maxdist );
  }

  if ( ( $totdist ne "" ) and ( $totdist != 0 ) )
  {
    $totstrength = ( 1 - $totdist );
  }

  # $soughtgrad is a slope (change per 1 level). To convert it into an increment,
  # multiply by the number of levels spanned between neighbour and target (|Δlevel|).
  if ( $levstep eq "" ) { $levstep = 1; }
  my $soughtinc = ( $soughtgrad * $levstep );

  if ( ( $soughtinc ne "" ) and ( $totdist ne "" ) and ( $totstrength ne "" ) and ( $totstrength >= $minreq_forcalc ) )
  {
    return ( $soughtinc, $totdist, $totstrength );
  }
}


sub weightvals_merge
{
  my ( $vals_ref, $strengths_ref, $minreq_formerge, $maxdist ) = @_;
  my @vals = @{ $vals_ref };
  my @strengths = @{ $strengths_ref };

  my ( $soughtval, $totstrength, $sum_strengths );
  my $strengthsnum = scalar( @strengths );
  if ( $strengthsnum > 0 )
  {
    $sum_strengths = sum( @strengths );
  }

  my $totstrength;
  my $value;
  my $soughtval = 0;
  if ( ( $sum_strengths ne "" ) and ( $sum_strengths > 0 ) )
  {
    my $in = 0;
    foreach my $val ( @vals )
    {
      my $strength = $strengths[$in];
      $soughtval = ( $soughtval + ( $val * ( $strength / $sum_strengths ) ) );
      $in++;
    }
    my $seedstrength = 1;

    my $inc = 0;
    foreach my $strength ( @strengths )
    {
      if ( not ( $strength == 1 ) )
      {
        $seedstrength = ( $seedstrength * $strength );
      }
      else
      {
        $seedstrength = 1;
        $value = $vals[$inc];
        last;
      }
      $inc++;
    }
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

  if ( ( $soughtval ne "" ) and ( $totstrength ne "" ) and ( $totstrength >= $minreq_formerge ) )
  {
    return ( $soughtval, $totstrength );
  }
}


sub calcdist
{
  my ( $el1, $elt1, $factlevels_ref, $maxdist, $el3, $elt3, $condweight ) = @_;
  my %factlevels = %{ $factlevels_ref };
  my @diff1 = diff( \@{ $el1 }, \@{ $elt1 } );
  my $dist;
  my ( @factbag, @levbag, @stepbag, @da1, @da1par, @da2, @da2par, @diff2 );

  if ( scalar( @diff1 ) > 0 )
  {
    @diff2 = diff( \@{ $elt1 } , \@{ $el1 } );

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

    my $c = 0;
    foreach my $e ( @da1par )
    {
      my $e = $da1par[$c];
      my $ei = $da2par[$c];
      my $fact = $da1[$c];
      my $diffpar = abs( $e - $ei );

      if ( ( $fact ne "" ) and ( $diffpar ne "" ) and ( $factlevels{stepsizes}{$fact} ne "" ) )
      {
        push ( @factbag, $fact );
        push ( @levbag, $diffpar );
        push ( @stepbag, $factlevels{stepsizes}{$fact} );
      }
      $c++;
    }
  }
  unless ( ( scalar( @levbag ) == 0 ) or ( scalar( @factbag ) == 0 ) or ( scalar( @stepbag ) == 0 ) )
  {
    my $ordist = scalar( @levbag );
    my $rawdist = pythagoras( \@factbag, \@levbag, \@stepbag );
    my ( $dist, $strength );

    if ( $maxdist ne "" )
    {
      $dist = ( $rawdist / $maxdist );
      $strength = ( 1 - $dist );
    }

    if ( ( $el3 ne "" ) and ( $elt3 ne "" ) and ( $condweight = "y") )
    {
      $strength = ( $strength * $el3 * $elt3 );
    }
    elsif ( ( $elt3 ne "" ) and ( $condweight = "y") )
    {
      $strength = ( $strength * $elt3 );
    }

    return( { dist => $dist, strength => $strength, ordist => $ordist, rawdist => $rawdist,
      diff1 => \@diff1, diff2 => \@diff2, da1 => \@da1, da2 => \@da2, da1par => \@da1par, da2par => \@da2par } );
  }
}


sub calcdistgrad
{
  my ( $el1, $elt1, $factlevels_ref, $minreq, $maxdist, $el3, $elt3, $condweight, $el, $elt ) = @_;
  my %factlevels = %{ $factlevels_ref };
  my @diff1 = diff( \@{ $el1 }, \@{ $elt1 } );
  my $dist;
  my ( @factbag, @levbag, @stepbag, @da1, @da1par, @da2, @da2par, @diff2 );
  if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= $minreq->[0] ) )
  {
    @diff2 = diff( \@{ $elt1 } , \@{ $el1 } );

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
          my $diffpar = abs( $lev1 - $lev2 );
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
    my $ordist = scalar( @levbag );
    my $rawdist = pythagoras( \@factbag, \@levbag, \@stepbag );
    my ( $dist, $strength );

    if ( $maxdist ne "" )
    {
      $dist = ( $rawdist / $maxdist );
      $strength = ( 1 - $dist );
    }

    if ( ( $el3 ne "" ) and ( $elt3 ne "" ) and ( $condweight = "y") )
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
  my $first = $arr[0];
  my $last = $arr[-1];
  my %hash = %{ calcdist( $first->[1], $last->[1], $factlevels_ref ) };

  say  "raw max distance: " . dump( $hash{rawdist} );
  return( $hash{rawdist}, $first->[0], $last->[0] );
}


sub calcmaxdist_old
{
  my ( $arr_ref, $factlevels_ref) = @_;
  my $thislimit; # $limit is unused.
  my @arr = @{ $arr_ref };

  my @arrc;

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

  my @rawdists;
  foreach my $el ( @arrc )
  {
    foreach my $elt ( @arrc )
    {
      my $hash_ref = calcdist( $el->[1], $elt->[1], $factlevels_ref );
      my %hash = %{ $hash_ref };
      push ( @rawdists, $hash{rawdist} );
    }
  }
  my $maxdist = max( @rawdists );
  return( $maxdist );
}


sub isnear
{
  my ( $this, $first, $last ) = @_;
  my @bits = split( "_", $this );
  my @firstbits = split( "_", $first );
  my @lastbits = split( "_", $last );
  my @newels;

  my $c = 0;
  foreach my $bit ( @bits)
  {
    my @els = split( "-", $bit);
    my @firstels = split( "-", $firstbits[$c] );
    my @lastels = split( "-", $lastbits[$c] );

    if ( not( $firstels[1] > ( $els[1] - 1 ) ) )
    {
      my @newels1 = ( $els[0], ( $els[1] - 1 ) );
      my $newl = join( "-", @newels1 );
      push( @newels, $newl );
    }
    else
    {
      push( @newels, $bit );
    }

    if ( not( $lastels[1] < ( $els[1] + 1 ) ) )
    {
      my @newels2 = ( $els[0], ( $els[1] + 1 ) );
      my $newl = join( "-", @newels2 );
      push( @newels, $newl );
    }
    else
    {
      push( @newels, $bit );
    }
    $c++;
  }

  my ( @neighs, @neighbours );
  foreach my $newel ( @newels )
  {
    my @ns = split( "-", $newel );
    my $n = $ns[0] . "-";
    my $word = $this;
    $word =~ s/$n(\d+)/$newel/ ;
    push( @neighs, $word );
  }
  @neighs = uniq( @neighs );
  my @neighbours = sort { $a <=> $b } @neighs;
  return( \@neighbours );
}

sub isstar
{
    my ( $this, $first, $last ) = @_;
    my @bits      = split( "_", $this );
    my @firstbits = split( "_", $first );
    my @lastbits  = split( "_", $last );

    my @newels;
    foreach my $bit (@bits)
    {
        my @els      = split( "-", $bit );
        my @firstels = split( "-", $firstbits[$c] );
        my @lastels  = split( "-", $lastbits[$c] );

        my $insts = ( $lastels[1] - $firstels[1] );

        my $basis = $firstels[1];
        while ( $basis <= $lastels[1] )
        {
          my @newels1 = ( $els[0], $basis );
          my $newl = join( "-", @newels1 );
          push( @newels, $newl );
          $basis++;
        }
    }

    my ( @neighs_, @neighbours, @neighs );
    foreach my $newel (@newels) {
        my @ns   = split( "-", $newel );
        my $n    = $ns[0] . "-";
        my $word = $this;
        $word =~ s/$n(\d+)/$newel/;
        push( @neighs_, $word );
    }
    @neighs_ = uniq(@neighs_);

    foreach my $unit ( @neighs_ )
    {
      unless ( $unit eq "$first" )
      {
        push ( @neighs, $unit );
      }
    }

    my @neighbours = sort { $a <=> $b } @neighs;
    return ( \@neighbours );
}


sub wei
{
  my ( $arr_ref, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count,
    $factlevels_ref, $minreq_forgrad, $minreq_forinclusion, $minreq_forcalc, $minreq_formerge, $maxdist, $nfiltergrads, $limit_checkdistgrads, $limit_checkdistpoints, $bank_ref, $fulldo, $first0, $last0, $nears_ref, $checkstop,
    $weldsprepared_ref, $weldaarrs_ref, $parswelds_ref, $recedes_ref, $nfilterpoints, $limitgrads, $limitpoints, $modality_ref ) = @_;
  my @arr = @{ $arr_ref };

  my @modality = @{ $modality_ref };
  my %factlevels = %{ $factlevels_ref };
  my %bank = %{ $bank_ref };
  my %nears = %{ $nears_ref };

  my %weldnears;

###--###
  my @weldsprepared = @{ $weldsprepared_ref };
  my @weldaarrs = @{ $weldaarrs_ref };
  my @parswelds = @{ $parswelds_ref };
  my @recedes = @{ $recedes_ref };
###--###



  my @arr__;
  if ( ( $limit_checkdistgrads ne "" ) or ( $limit_checkdistpoints ne "" ) )
  {
    @arr__ = shuffle( @arr );
  }
  else
  {
    @arr__ = @arr;
  }

  my ( @arra, @arrah );
  if ( ( $limit_checkdistgrads ne "" ) and ( $limit_checkdistgrads > $checkstop ) )
  {
    @arra = @arr__[0..$limit_checkdistgrads];
  }
  else
  {
    @arra = @arr__;
  }

  my @arrb;
  if ( ( $limit_checkdistpoints ne "" ) and ( $limit_checkdistpoints > $checkstop ) )
  {
    my @arrb_ = @arr__;
    @arrb = @arrb_[0..$limit_checkdistpoints];
  }
  else
  {
    @arrb = @arr__;
  }


  sub fillbank
  {
    my ( $arr_r, $minimumcertain, $minreq_forgrad, $maxdist, $condweight, $factlevels_r, $nfiltergrads,
    $arra_r, $first0, $last0, $nears_ref, $limitgrads, $limitpoints, $modality_ref ) = @_;
    my @arr = @{ $arr_r };
    my @arra = @{ $arra_r };
    my %factlevels = %{ $factlevels_r };
    my %nears = %{ $nears_ref };
    my @modality = @{ $modality_ref };

    my @neighbours;
    my %bank;

    my @newneighbours;
    if ( "flat" ~~ @modality )
    {
      foreach my $e ( @arra )
      {
        push ( @newneighbours, $e->[0] );
      }
    }

    foreach my $el ( @arr )
    {
      if ( ( $el->[2] ne "" ) and ( $el->[3] >= $minimumcertain ) )
      {
        unless ( "bankflat" ~~ @modality )
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
        }
        else
        {
          @neighbours = @newneighbours;
        }


        #foreach my $elt ( @arra )
        foreach my $it ( @neighbours )
        {
          my $elt = $nears{$it}{all};
          if ( ( $elt->[2] ne "" ) and ( $elt->[0] ne $el->[0] ) and ( $el->[3] >= $minimumcertain ) )
          {

            my ( $res_ref ) = calcdistgrad( $el->[1], $elt->[1], \%factlevels, $minreq_forgrad, $maxdist, $el->[3], $elt->[3], $condweight, $el, $elt );

            my %d;
            my ( @diff1, @diff2, @da1, @da2, @da1par, @da2par );
            my ( $ordist, $dist, $strength );

            unless ( !keys %{ $res_ref } )
            {
              %d = %{ $res_ref };
              my @diff1 = @{$d{diff1}};
              @diff2 = @{$d{diff2}};
              @da1 = @{$d{da1}};
              @da2 = @{$d{da2}};
              @da1par = @{$d{da1par}};
              @da2par = @{$d{da2par}};
              $ordist = $d{ordist};
              $dist = $d{dist};
              $strength = $d{strength};
            }

            unless ( !keys %{ $res_ref } and ( $ordist > 0 ) and ( $ordist ne "" ) )
            {
              {
                my $count = 0;
                foreach my $d10 ( @da1 )
                {
                  my $d11 = $da1par[$count];
                  my $co = 0;
                  foreach my $d20 ( @da2 )
                  {
                    if ( $d10 == $d20 )
                    {
                      my $stepsize = $factlevels{stepsizes}{$d20};
                      my $d21 = $da2par[$co];

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
                        $orderedtrio = join( "-", $d10, $orderedpair ); ;



                        unless ( ( $trio eq "" ) or ( any { $_ eq $el[0] } @{ $bank{$trio}{orstring} } ) )
                        {
                          my $avgstrength;
                          my $benchmark;
                          if ( $nfiltergrads ne "" )
                          {
                            if ( scalar( @{ $bank{$trio}{strengths} } ) > $nfiltergrads )
                            {
                              $benchmark = ${ $bank{$trio}{strengths} }[$nfiltergrads]; #say "BENCHMARK1: $benchmark.";
                              $avgstrength = mean( @{ $bank{$trio}{strengths} } );
                            }
                            else
                            {
                              $benchmark = 1;
                            }
                          }

                          if ( ( ( $nfiltergrads ne "" ) and ( $avgstrength > $benchmark ) )
                            or ( ( $limitgrads ne "" ) and ( scalar( @{ $bank{$trio}{strengths} } ) > $limitgrads ) ) )
                          {
                            next;
                          }



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
                            push ( @{ $bank{$trio}{dists} }, $dist );
                            push ( @{ $bank{$trio}{strengths} }, $strength );
                          }

                          if ( $turn == 1 )
                          {
                            $pos1 = $d11;
                            $pos2 = $d21;
                            $val1 = $el->[2];
                            $val2 = $elt->[2];
                          }
                          elsif ( $turn == 2 )
                          {
                            $pos1 = $d21;
                            $pos2 = $d11;
                            $val1 = $elt->[2];
                            $val2 = $el->[2];
                          }

                          my $diffpos = ( $pos1 - $pos2 );
                          my $diffval = ( $val1 - $val2 );
                          my $grad;
                          if ( ( $diffpos ne "" ) and ( $diffpos != 0 ) )
                          {
                            $grad = ( $diffval / $diffpos );
                          }

                          if ( $grad ne "" )
                          {
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
    return ( \%bank, \%nears );
  }

  sub clean
  {
    my ( $bank_ref, $nfiltergrads, $message, $recedes_ref ) = @_;
    my %bank = %{ $bank_ref };
    my @recedes = @{ $recedes_ref };
    if ( scalar( @recedes ) > 0 )
    {
      say "RECEDE " . dump( @recedes );
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
    }
    return( \%bank );
  } #END FILLBANK

  unless( ( $fulldo eq "$tight" ) and ( $count > 0 ) )
  {
    say  "Entering gradients' \%bank.";
    my ( $bank_ref, $nears_ref ) = fillbank( \@arr__, $minimumcertain, $minreq_forgrad, $maxdist, $condweight, \%factlevels,
    $nfiltergrads, \@arra, $first0, $last0, \%nears, $limitgrads, $limitpoints, \@modality );
    %bank = %{ $bank_ref };
    %nears = %{ $nears_ref };
    %bank = %{ clean( \%bank, $nfiltergrads, "principal", \@recedes ) }; say  "BANK DONE.";
  }

###--###
  sub mixbank
  {
    my ( $bank_ref, $weldbank_ref, $parsws_ref ) = @_;
    my %bank = %{ $bank_ref };
    my %weldbank = %{ $weldbank_ref };
    my @parsws = @{ $parsws_ref };
    say  "Mixing for welding " . dump( @parsws );
    foreach my $trio ( keys %weldbank )
    {
      unless ( $trio eq "" )
      {
        my @splits = split( "-", $trio );
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
          say  "weld $num.";
        }
      }
    }
    return( \%bank );
  }

  unless ( ( scalar( @weldsprepared ) == 0 )
  #or ( $count > 0 )
  )
  { say  "Entering gradients' bank for welding.";
    my $co = 0;
    foreach my $weldref ( @weldaarrs )
    {
      my @parsws = @{ $parswelds[$co] }; #say  "\@parsws: " . dump( @parsws );
      my @weldarr = @{ $weldref };
      my @weldarr__;
      if ( ( $limit_checkdistgrads ne "" ) or ( $limit_checkdistpoints ne "" ) )
      {
        @weldarr__ = shuffle( @weldarr );
      }
      else
      {
        @weldarr__ = @weldarr;
      }

      my ( @weldarra, @weldarrah );
      if ( ( $limit_checkdistgrads ne "" ) and ( $limit_checkdistgrads > $checkstop ) )
      {
        @weldarrah = @weldarr__;
        @weldarra = @weldarrah[0..$limit_checkdistgrads];
      }
      else
      {
        @weldarra = @weldarr__;
      }

      my @weldarrb;
      if ( ( $limit_checkdistgrads ne "" ) and ( $limit_checkdistgrads > $checkstop ) )
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

      my ( $weldbank_ref, $weldnears_ref ) = fillbank( \@weldarr__, $minimumcertain, $minreq_forgrad, $maxdist, $condweight, \%factlevels, $nfiltergrads, \@weldarra, $first0, $last0, \%nears, $limitgrads, $limitpoints );
      %weldbank = %{ $weldbank_ref };
      %weldnears = %{ $weldnears_ref };

      %weldbank = %{ clean( \%weldbank, $nfiltergrads, "weld" ) };

      %bank = %{ mixbank( \%bank, \%weldbank, \@parsws ) };
      #say  "KEYS \%bank: " . ( keys %bank );

      $co++;
    }
  }
###--###

  sub cyclearr
  {
    say "IN CYCLEARR";
    my ( $arr_r, $minreq_forinclusion, $minreq_forgrad, $bank_r, $factlevels, $nfilterpoints, $arrb_r, $first0, $last0,
    $nears_ref, $limitgrads, $limitpoints, $modality_ref ) = @_;
    my @arr = @{ $arr_r };
    my @arrb = @{ $arrb_r };
    my %bank = %{ $bank_r };
    my %factlevels = %{ $factlevels };
    my %nears = %{ $nears_ref };
    my @modality = @{ $modality_ref };

    my $minreq = $minreq_forgrad->[0];
    my ( @toinspects, @theseneighbours, @otherneighbours );

    my %wand;
    my $coun = 0;

    my @newneighbours;
    if ( "flat" ~~ @modality )
    {
      foreach my $e ( @arrb )
      {
        push ( @newneighbours, $e->[0] );
      }
    }

    foreach my $el ( @arr )
    {
      my $key =  $el->[0] ;

      if ( $el->[2] eq "" )
      {
        my @neighbours;

        unless ( "flat" ~~ @modality )
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
        }
        else
        {
          @neighbours = @newneighbours;
        }

        #foreach my $elt ( @arrb )
        foreach my $it ( @neighbours )
        {
          my $elt = $nears{$it}{all};
          if ( ( $elt->[2] ne "" ) and ( $el->[3] >= $minreq_forinclusion ) )
          {
            my @diff1 = diff( \@{ $el->[1] }, \@{ $elt->[1] } );

            if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= $minreq_forgrad->[2] ) ) ###DDD!!! TAKE CARE, IT WAS: if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= $minreq_forgrad->[2] ) )
            {
              my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } );

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

              my $soughtval;
              my $count = 0;
              foreach my $d10 ( @da1 )
              {
                my $d11 = $da1par[$count];
                my $co = 0;
                foreach my $d20 ( @da2 )
                {
                  if ( $d20 ne "" )
                  {
                    my $d20 = $da2[$co];
                    my $d21 = $da2par[$co];
                    if ( ( $d10 eq $d20 ) )
                    {
                      my $levstep = abs( $d11 - $d21 );
                      my $newpair = join( "-", ( $d11, $d21 ) );

                      my $newtrio = join( "-", $d10, $newpair );

                      my ( @boxgrads, @boxdists, @boxors );
                      my $cn = 0;
                      foreach my $grad ( @{ $bank{$newtrio}{grads} } )
                      {
                        if ( ( $grad ne "" ) and ( any { $_ eq ${ $bank{$newtrio}{orstring} }[$cn] } @neighbours ) )
                        {
                          push ( @boxgrads, $grad );
                          my $ordist = $bank{$newtrio}{ordists}[$cn];
                          push ( @boxdists, $ordist );
                          my $origin = $bank{$newtrio}{origins}[$cn];
                          push ( @boxors, $origin );
                        }
                        $cn++;
                      }

                      my ( @factbag, @levbag, @stepbag );
                      my $c = 0;
                      foreach my $e ( @da1par )
                      {
                        if ( $e ne "" )
                        {
                          my $fact = $da1[$c];

                          my $i = 0;
                          foreach my $ei ( @da2par )
                          {
                            if ( $da1[$c] == $da2[$i] )
                            {
                              my $diffpar = abs( $e - $ei );
                             ###################if ( ( ${ $bank{$newtrio}{orstring} }[$cn] ~~ @neighbours ) ) and ( $diffpar <= $minreq_forgrad->[1] ) and ( $diffpar > 0 ) ) ############################HERE
                              if ( ( $diffpar <= $minreq_forgrad->[1] ) and ( $diffpar > 0 ) ) ###DDD!!! TAKE CARE, IT WAS: if ( ( $diffpar <= $minreq_forgrad->[1] ) and ( $diffpar > 0 ) )
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

                      my ( $soughtinc, $totdist, $totstrength );

                      unless ( ( scalar( @boxgrads ) == 0 ) and ( scalar( @boxdists ) == 0 ) and ( scalar( @boxors ) == 0 ) )
                      { #say  "CHEKK \$el->[3]: " . dump( $el->[3] );
                        ( $soughtinc, $totdist, $totstrength ) = weightvals1( $elt->[1], \@boxgrads, \@boxdists, \@boxors, $minreq_forcalc, \@factbag, \@levbag, \@stepbag, $levstep, $elt->[2], \%factlevels, $maxdist, $elt->[3], $condweight );

                        unless ( ( $soughtinc eq "" ) or ( $totdist eq "" ) )
                        {
                          #my $benchmark;
                          #if ( $nfilterpoints ne "" )
                          #{
                          #  if ( scalar( @{ $wand{$key}{strength} } ) > $nfilterpoints )
                          #  {
                          #    $benchmark = ${ $wand{$key}{strength} }[$nfilterpoints]; #say "BENCHMARK1: $benchmark.";
                          #  }
                          #  else
                          #  {
                          #    $benchmark = 0;
                          #  }
                          #}

                          #if ( ( ( $nfilterpoints ne "" ) and ( $strength > $benchmark ) )
                          #  or ( ( $limitpoints ne "" ) and ( scalar( @{ $wand{$key}{strength} } ) > $limitpoints ) ) )
                          #{
                          #  next;
                          #}

                          my $soughtval = ( $elt->[2] + $soughtinc );
                          push ( @{ $wand{$key}{vals} }, $soughtval );
                          push ( @{ $wand{$key}{dists} }, $totdist );

                          push ( @{ $wand{$key}{strength} }, $totstrength );
                          push ( @{ $wand{$key}{origin} }, $elt->[0] );
                          $wand{$key}{name} = $key;
                          $wand{$key}{bulk} = [ @{ $elt->[1] } ] ;
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
    }
    return( \%wand, \%nears );
  }#END SUB CYCLEARR

  my ( %wand, @limb0 );

  say  "GOING TO CREATE NEW POINTS.";

  sub cyclearr_ancient
  {
    my %wand;
    my $coun = 0;
    foreach my $el ( @arr )
    {
      my $key =  $el->[0] ;
      if ( $el->[2] eq "" )
      {
        foreach my $elt ( @arr )
        {
          if ( ( $elt->[2] ne "" ) and ( $el->[3] >= $minreq_forinclusion ) )
          {
            my @diff1 = diff( \@{ $el->[1] }, \@{ $elt->[1] } );

            if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= $minreq_forgrad->[2] ) )
            {
              my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } );
              my %h1 = map { split( /-/ , $_ ) } @diff1;
              my @da1 = keys %h1;
              my @da1par = values %h1;
              my %h2 = map { split( /-/ , $_ ) } @diff2;
              my @da2 = keys %h2;
              my @da2par = values %h2;

              my $soughtval;
              my $count = 0;
              foreach my $d10 ( @da1 )
              {
                my $d11 = $da1par[$count];
                my $co = 0;
                foreach my $d20 ( @da2 )
                {
                  if ( $d20 ne "" )
                  {
                    my $d20 = $da2[$co];
                    my $d21 = $da2par[$co];
                    if ( ( $d10 eq $d20 ) )
                    {
                      my $levstep = abs( $d11 - $d21 );
                      my $newpair = join( "-", ( $d11, $d21 ) );

                      my $newtrio = join( "-", $d10, $newpair );

                      my ( @boxgrads, @boxdists, @boxors );
                      my $cn = 0;
                      foreach my $grad ( @{ $bank{$newtrio}{grads} } )
                      {
                        if ( $grad ne "" )
                        {
                          push ( @boxgrads, $grad );
                          my $ordist = $bank{$newtrio}{ordists}[$cn];
                          push ( @boxdists, $ordist );
                          my $origin = $bank{$newtrio}{origins}[$cn];
                          push ( @boxors, $origin );
                        }
                        $cn++;
                      }

                      my ( @factbag, @levbag, @stepbag );
                      my $c = 0;
                      foreach my $e ( @da1par )
                      {
                        if ( $e ne "" )
                        {
                          my $fact = $da1[$c];

                          my $i = 0;
                          foreach my $ei ( @da2par )
                          {
                            if ( $da1[$c] == $da2[$i] )
                            {
                              my $diffpar = abs( $e - $ei );
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

                      my ( $soughtinc, $totdist, $totstrength );

                      unless ( ( scalar( @boxgrads ) == 0 ) and ( scalar( @boxdists ) == 0 ) and ( scalar( @boxors ) == 0 ) )
                      {
                        ( $soughtinc, $totdist, $totstrength ) = weightvals1( $elt->[1], \@boxgrads, \@boxdists, \@boxors, $minreq_forcalc, \@factbag, \@levbag, \@stepbag, $levstep, $elt->[2], \%factlevels, $maxdist, $elt->[3], $condweight );

                        unless ( ( $soughtinc eq "" ) or ( $totdist eq "" ) )
                        {
                          my $soughtval = ( $elt->[2] + $soughtinc );
                          push ( @{ $wand{$key}{vals} }, $soughtval );
                          push ( @{ $wand{$key}{dists} }, $totdist );

                          push ( @{ $wand{$key}{strength} }, $totstrength );
                          push ( @{ $wand{$key}{origin} }, $elt->[0] );
                          $wand{$key}{name} = $key;
                          $wand{$key}{bulk} = [ @{ $elt->[1] } ] ;
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
    }
    return( \%wand );
  }


  my $wand_ref = cyclearr;
  my %wand = %{ $wand_ref };

  my ( $wand_ref, $nears_ref );

  if ( not ( "simple" ~~ @modality ) )
  {
    ( $wand_ref, $nears_ref ) = cyclearr( \@arr__, $minreq_forinclusion, $minreq_forgrad, \%bank, \%factlevels, $nfiltergrads,
      \@arrb, $first0, $last0, \%nears, $limitgrads, $limitpoints, \@modality );
  }
  else
  {
    $wand_ref = cyclearr_ancient;
  }

  %wand = %{ $wand_ref };
  #say  "\nDONE.";
  %nears = %{ $nears_ref };

  @limb0;
  foreach my $ke ( keys %wand )
  {
    my ( $soughtval, $totstrength ) = weightvals_merge( \@{ $wand{$ke}{vals} }, \@{ $wand{$ke}{strength} }, $minreq_formerge, $maxdist );

    if ( ( $soughtval ne "" ) and ( $totstrength ne "" ) )
    {
      push ( @limb0, [ $wand{$ke}{name}, $wand{$ke}{bulk}, $soughtval, $totstrength ] );
    }
  }

  if ( $fulldo eq "y" )
  {
    %bank = ();
  }
  return( \@limb0, \%bank, \%nears )
} ##### END SUB wei



sub purelin
{
  my ( $arr_refillf, $relaxlimit, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count, $factlevels_ref, $maxdist ) = @_;
  my @arr = @{ $arr_ref };
  my ( @linneabagbox );
  my ( %magic, %wand, %spell );
  foreach my $el ( @arr )
  {
    my $key =  $el->[0] ;
    if ( $el->[2] eq "" )
    {
      foreach my $elt ( @arr )
      {
        if ( not ( $elt->[2] eq "" ) )
        {
          my @diff1 = diff( \@{ $el->[1] }, \@{ $elt->[1] } );

          if ( $relaxmethod eq "logarithmic" )
          {
            my $index = 0;
            while ( $index <= $relaxlimit )
            {
              if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= ( 1 + $relaxlimit ) ) )
              {

                my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } );

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

                my $count = 0;
                foreach my $d10 ( @da1 )
                {
                  my $d11 = $da1par[$count];
                  my $co = 0;
                  foreach my $d20 ( @da2 )
                  {
                    my $d21 = $da2par[$co];
                    if ( ( $d10 eq $d20 ) )
                    {
                      push ( @{ $magic{$key}{$d10} }, [ $el->[0], $el->[1], $d11, $d21, $elt->[2] ] );
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
              {
                my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } );

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
                {
                  my $d11 = $da1par[$count];
                  my $co = 0;
                  foreach my $d20 ( @da2 )
                  {
                    my $d21 = $da2par[$co];
                    while ( $indinc > 0 )
                    {
                      if ( ( $d10 eq $d20 ) )
                      {
                        push ( @{ $magic{$key}{$d10} }, [ $el->[0], $el->[1], $d11, $d21, $elt->[2] ] );
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

  foreach my $ke ( sort {$a <=> $b} ( keys %magic ) )
  {
    foreach my $dee ( sort {$a <=> $b} ( keys %{ $magic{$ke} } ) )
    {
      my @array = @{ $magic{$ke}{$dee} };
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
              {
                my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } );


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

                my $count = 0;
                foreach my $d10 ( @da1 )
                {
                  my $d11 = $da1par[$count];
                  my $co = 0;
                  foreach my $lineard20 ( @da2 )
                  {
                    my $d21 = $da2par[$co];
                    if ( ( $d10 eq $d20 ) )
                    {
                      push ( @{ $magic{$key}{$d10} }, [ $el->[0], $el->[1], $d11, $d21, $elt->[2] ] );
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
              {
                my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } );

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

                my $count = 0;
                foreach my $d10 ( @da1 )
                {
                  my $d11 = $da1par[$count];
                  my $co = 0;
                  foreach my $d20 ( @da2 )
                  {
                    my $d21 = $da2par[$co];
                    if ( ( $d10 eq $d20 ) )
                    {
                      push ( @{ $magic{$key}{$d10} }, [ $el->[0], $el->[1], $d11, $d21, $elt->[2] ] );
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
            my $avgval = ( ( $val1 + $val2 ) / 2 );
            my $avgpos = ( ( $pos1 + $pos2 ) / 2);
            my $distp = ( $posor - $avgpos );
            my $change = ( $distp * $unit );
            my $soughtval = ( $avgval + $change );
            push( @bag, $soughtval );
          }
          $i++;
        }

        unless ( scalar( @bag ) <= ( $parconcurrencies - 1 ) )
        {
          unless ( scalar( @bag ) == 0 )
          {
            $bagmean = mean( @bag );
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

  my @limb0;
  foreach my $ke ( sort {$a <=> $b} ( keys %wand ) )
  {
    my $eltnum = scalar( keys %{ $wand{$ke} } );
    unless ( $eltnum <= ( $instconcurrencies - 1 ) )
    {
      my $avg = mean( values( %{ $wand{$ke} } ) );
      push ( @limb0, [ $spell{$ke}[0], $spell{$ke}[1] , $avg ] );
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
  {
    if ( $el->[2] eq "" )
    {

      my @bag;
      foreach my $elt ( @arr )
      {
        if ( not ( $elt->[2] eq "" ) )
        {
          my @diff1 = diff( \@{ $el->[1] }, \@{ $elt->[1] } );

          my $index = 0;
          while ( $index <= $nearrelaxlimit )
          {
            if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= ( 1 + $nearrelaxlimit ) ) )
            {
              my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } );

              my ( $da1_ref, $da1par_ref, $da2_ref, $da2par_ref ) = setvalues( \@diff1, \@diff2 );
              my @da1 = @{ $da1_ref };
              my @da2 = @{ $da2_ref };

              my $count = 0;
              foreach my $d10 ( @da1 )
              {
                my $d11 = $da1par[$count];
                my $co = 0;
                foreach my $d20 ( @da2 )
                {
                  my $d21 = $da2par[$co];
                  if ( ( $d10 eq $d20 ) )
                  {
                    push( @bag, $elt->[2] );
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
      {
        my $bagmean = mean( @bag );
        unless ( scalar( @bag ) == 0 )
        {
          push ( @limb0, [ $el->[0], $el->[1], $bagmean ] );
        }
      }
    }
  }
  return( @limb0 );
}############ END SUB near


sub mixlimbo
{
  my ( $limbo1_ref, $limbo2_ref, $presence, $linearprecedence, $weights_ref ) = @_;
  my @limbo1 = @{ $limbo1_ref };
  my @limbo2 = @{ $limbo2_ref };
  my @weights = @{ $weights_ref };
  my @limbo = @limbo1 ;
  foreach my $el ( @limbo2 )
  {
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
      if ( not ( $linearprecedence eq "n" ) )
      {unless ( $pos1 == $pos2 )
          {
            my $diffp = ( $pos1 - $pos2 );
            my $diffval = ( $val1 - $val2 );
            my $unit = ( $diffval / $diffp );
            my $halfunit = ( $unit / 2 );
            my $halfdiffval = ( $diffval / 2 );
            my $avgval = ( ( $val1 + $val2 ) / 2 );
            my $avgpos = ( ( $pos1 + $pos2 ) / 2);
            my $distp = ( $posor - $avgpos );
            my $change = ( $distp * $unit );
            my $soughtval = ( $avgval + $change );
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
  my ( $sourcefile, $configf, $metafile, $blockelts_r, $reportf, $countblock, 
      $dowhat_r, $dirfiles_r, $lines_r ) = @_;

  my @lines = @$lines_r; say "!!!!! IN INTERLINEAR, RECEIVED LINES " . dump( [lines] );
  my %dowhat = %$dowhat_r;
  my %dirfiles = %$dirfiles_r;
  my $precomputed = $dirfiles{precomputed};
  $sourcefile = $precomputed;

  my ( %bank, %nears );

  if ( $reportf ne "" ){ $report = $reportf; }

  if ( $configf eq "" )
  {
    $configf = "./confinterlinear.pl";
  };

  if ( $configf ne "" )
  {
    $confile = $configf;
  };




  ########## AN EXAMPLE OF SETTINGS TO BE PUT IN A CONFIGURATION FILE FOLLOWS.
  if ( $dowhat{maxloops} )
  {
    $maxloops = $dowhat{maxloops};
  }
  else 
  {
    $maxloops= 1000;
  }
  

  my $newfile = $sourcefile . "_meta.csv";

  my @mode;
  if ( $dowhat{mode} )
  {
    push( @mode, $dowhat{mode} );
  }
  else 
  {
    push( @mode, "wei" );
  } # #"wei" is weighted gradient linear interpolation of the nearest neighbours.
  #my @mode = ( "near" ); # "nea" means "nearest neighbour"
  #@mode = ( ""mix" ); # "mix" means sequentially mixed in each loop.
  #my @mode = ( "wei", "near", "near", "purelin" ); # a sequence

  my @weights;
  if ( $dowhat{weights} )
  {
    @weights = $dowhat{weights};
  }
  else 
  {
    @weights = (  );
  } #my @weights = ( 0.7, 0.3 ); # THE FIRST IS THE WEIGHT FOR linear interpolation, THE SECOND FOR nearest neighbour.
  # THEY ARE FRACTIONS OF 1 AND MUST GIVE 1 IN TOTAL. IF THE VALUES ARE UNSPECIFIED (IE. IF THE ARRAY IS EMPTY), THE VALUES ARE UNWEIGHTED.
  
  my $linearprecedence;
  if ( $dowhat{linearprecedence} )
  {
   $linearprecedence = $dowhat{linearprecedence};
  }
  else 
  {
    $linearprecedence = "n";
  }  # PRECEDENCE TO LINEAR INTERPOLATES. IF "y", THE VALUES DERIVED FROM LINEAR INTERPOLATION, WHERE PRESENT, WILL SUPERSEDE THE VALUES DERIVED FROM THE NEAREST NEIGHBUR STRATEGY. IF "n", THE OPPOSITE. IT CAN BE ACTIVE ONLY IF LOGARITHMIC IS OFF. IT WORKS WITH "LINEAR" AND "EXPONENTIAL"

  my $relaxmethod;
  if ( $dowhat{relaxmethod} )
  {
   $relaxmethod = $dowhat{relaxmethod};
  }
  else 
  {
    $relaxmethod = "logarithmic";
  } #It is relative to the "linnear" method. Options: "logarithmic", "linear" or "exponential". THE FARTHER NEIGHBOURS ARE WEIGHT LESS THAN THE NEAREST ONES: INDEED, LOGARITHMICALLY, LINEARLY OR EXPONENTIALLY. THE LOGARITHM BASE IS $relaxlimit OR $nearrelaxlimit, DEPENDING FROM THE CONTEXT. THE LINEAR MULTIPLICATOR OR THE EXPONENT IS DEFINED BY $overwerightnearest.
  
  my $relaxlimit;
  if ( $dowhat{relaxlimit} )
  {
   $relaxlimit = $dowhat{relaxlimit};
  }
  else 
  {
    $relaxlimit = 1; 
  } #THIS IS THE CEILING FOR THE RELAXATION OF THE RELATIONS OF PURE LINEAR INTERPOLATION. For greatest precision: 0, or a negative number near 0. IF > = 0, THE PROGRAM INTERPOLATES ALSO NEAREST NEIGHBOURS. THE HIGHER THE NUMBER, THE FARTHER THE NEIGHBOURS.
  
  my $overweightnearest;
  if ( $dowhat{overweightnearest} )
  {
   $overweightnearest = $dowhat{overweightnearest};
  }
  else 
  {
    $overweightnearest = 1; 
  } #A NUMBER. IT IS MADE NULL BY THE $logarithmicrelax "y". THE HIGHER THE NUMBER, THE GREATER THE OVERWEIGHT GIVEN TO THE NEAREST. IN THIS MANNER, THE OVERWEIGHT IS NOT LOGARITHMIC, LIKE IT WHERE OTHERWISE, BUT LINEAR. THIS SLOWS DOWN THE COMPUTATIONS. UNLESS THE OVERWEIGHT IS 1, WHICH MAKES THE OVERWEIGHTING NULL.
  
  my $nearrelaxlimit;
  if ( $dowhat{nearrelaxlimit} )
  {
   $nearrelaxlimit = $dowhat{nearrelaxlimit};
  }
  else 
  {
    $nearrelaxlimit = 0; 
  } #THIS IS THE CEILING FOR THE RELAXATION OF THE RELATIONS OF THE NEAREST NEIGHBOUR STRATEGY. For greatest precision: 0, or a negative number near 0. IF > = 0, THE PROGRAM INCREASES THE DISTANCE OF THE NEAREST NEIGHBOURS INCLUDED. THE HIGHER THE NUMBER, THE FARTHER THE NEIGHBOURS. ONE IS NOT LIKELY TO WANT TO USE THIS OPTION.
  
  my $nearconcurrencies;
  if ( $dowhat{nearconcurrencies} )
  {
   $nearconcurrencies = $dowhat{nearconcurrencies};
  }
  else 
  {
    $nearconcurrencies = 1;
  } #Requested minimum number of concurrencies for the nearest neighbour method. Minimum value: 1. The more the requested concurrencies, the greatest the precision, the slowest the convergence.
  
  my $parconcurrencies;
  if ( $dowhat{parconcurrencies} )
  {
   $parconcurrencies = $dowhat{parconcurrencies};
  }
  else 
  {
    $parconcurrencies = 1;
  } #Requested minimum number of concurrencies for the linear interpolations for each parameter of each instance. Minimum value: 1. The more the requested concurrencies, the greatest the precision, the slowest the convergence.
  
  my $instconcurrencies;
  if ( $dowhat{instconcurrencies} )
  {
   $instconcurrencies = $dowhat{instconcurrencies};
  }
  else 
  {
    $instconcurrencies = 1; 
  } #Requested minimum number of concurrencies for the linear interpolations for each instance. Minimum value: 1. The more the requested concurrencies, the greatest the precision, the slowest the convergence.
  
  # my %factlevels = ( pairs => { 1=>3, 2=>3, 3=>3, 4=>3, 5=>3 } ); #The keys are the factor numbers and the values are the number of levels in the data series. OBSOLETE.
  
  my $minreq_forgrad;
  if ( $dowhat{minreq_forgrad} )
  {
   $minreq_forgrad = $dowhat{minreq_forgrad};
  }
  else 
  {
    $minreq_forgrad = [1, 1, 1 ];
  } #THESE VALUES SPECIFY THE NUMBER OF PARAMETER DIFFERENCES (INTEGER NUMBERS) TELLING HOW WELL-ROOTED IN SIMULATED REALITY (I.E, NEAR FROM IT) A POINT MUST BE TO SELECT IT FOR CALCULATING THE GRADIENTS FOR THE METAMODEL. THEY ARE INTEGERS STARTING FROM 1 OR GREATER.
  # THE FIRST VALUE IS RELATIVE TO THE FACTORS AND TELLS HOW RELAXED A SEARCH IS.
  # THE SECOND VALUE IS RELATIVE TO THE LEVELS. ONE MAY WANT TO KEEP IT TO 1: THE GRADIENTS ARE CALCULATED USING ONLY ADJACENT INSTANCES.
  # ONE MAY WANT TO KEEP IT TO 1: THE GRADIENTS ARE CALCULATED USING ONLY ADJACENT INSTANCES.
  # THE THIRD VALUE HOW DIFFERENT (FAR, IN TERMS OF PARAMETER DIFFERENCES) MAY AN INSTANCE BE TO BE CALCULATED THROUGH THE GRADIENT IN QUESTION.
  # ONE MAY WANT TO SET TO THE NUMBER OF PARAMETERS.
  # A LARGE NUMBER, WEAK ENTRY BARRIER. NEVER LESS THAN 1.
  
  my $minreq_forinclusion;
  if ( $dowhat{minreq_forinclusion} )
  {
   $minreq_forinclusion = $dowhat{minreq_forinclusion};
  }
  else 
  {
    $minreq_forinclusion = 0; 
  } # THIS VALUE SPECIFIES A STRENGTH VALUE (LEVEL OF RELIABILITY) TELLING HOW WELL-ROOTED IN SIMULATED REALITY A DERIVED POINT (META-POINT) MUST BE FOR INCLUDING IT IN THE SET OF POINTS USED FOR THE METAMODEL.If 0, no entry barrier.
  
  my $minreq_forcalc;
  if ( $dowhat{minreq_forcalc} )
  {
   $minreq_forcalc = $dowhat{minreq_forcalc};
  }
  else 
  {
    $minreq_forcalc = 0;
  } # THIS VALUE SPECIFIES A STRENGTH VALUE (LEVEL OF RELIABILITY) TELLING HOW WELL-ROOTED IN SIMULATED REALITY A DERIVED POINT MUST BE FOR INCLUDING IT IN THE CALCULATIONS FOR CREATING NEW META-POINTS.  A VALUE BETWEEN 1 (JUST SIMULATED POINT) AND 0. If 0, no entry barrier.
  
  my $minreq_formerge;
  if ( $dowhat{minreq_formerge} )
  {
   $minreq_formerge = $dowhat{minreq_formerge};
  }
  else 
  {
    $minreq_formerge = 0;
  } # THIS VALUE SPECIFIES A STRENGTH VALUE (LEVEL OF RELIABILITY) TELLING HOW WELL-ROOTED IN SIMULATED REALITY A DERIVED POINT MUST BE FOR MERGING IT IN THE CALCULATIONS FOR MERGING IT IN THE METAMODEL. A VALUE BETWEEN 1 (JUST SIMULATED POINT) AND 0 (SIMULATED POINTS AND "META"POINTS WITH THE SAME RIGHT ) MUST BE SPECIFIED. If 0, no entry barrier.
  
  my $minimumcertain;
  if ( $dowhat{minimumcertain} )
  {
   $minimumcertain = $dowhat{minimumcertain};
  }
  else 
  {
    $minimumcertain = 0; 
  } # WHAT IS THE MINIMUM LEVEL OF STRENGTH (LEVEL OF RELIABILITY) REQUIRED TO USE A DATUM TO BUILD UPON IT. IT DEPENDS ON THE DISTANCE FROM THE ORIGINS OF THE DATUM. THE LONGER THE DISTANCE, THE SMALLER THE STRENGTH (WHICH IS INDEED INVERSELY PROPORTIONAL). A STENGTH VALUE OF 1 IS OF A SIMULATED DATUM, NOT OF A DERIVED DATUM. If 0, no entry barrier.
  
  my $minimumhold;
  if ( $dowhat{minimumhold} )
  {
   $minimumhold = $dowhat{minimumhold};
  }
  else 
  {
    $minimumhold = 1; 
  } # WHAT IS THE MINIMUM LEVEL OF STRENGTH (LEVEL OF RELIABILITY) REQUIRED FOR NOT AVERAGING A DATUM WITH ANOTHER, DERIVED DATUM. USUALLY IT HAS TO BE KEPT EQUAL TO $minimimcertain.  If 1, ONLY THE MODEL DATA ARE NOT SUBSTITUTABLE IN THE METAMODEL.
  
  my $minimumhold;
  if ( $dowhat{condweight} )
  {
    $condweight = $dowhat{condweight};
  }
  else 
  {
    $condweight = "y"; 
  } # THIS CONDITIONS TELLS IF THE STRENGTH (LEVEL OF RELIABILITY) OF THE GRADIENTS HAS TO BE CUMULATIVELY TAKEN INTO ACCOUNT IN THE WEIGHTING CALCULATIONS.
  
  my $nfiltergrads;
  if ( $dowhat{nfiltergrads} )
  {
    $nfiltergrads = $dowhat{nfiltergrads};
  }
  else 
  {
    $nfiltergrads = "";
  }  # DO NOT USE. do not take into account the gradients which in the ranking of strengths are below a certain position. If unspecified: inactive.
  
  my $limit_checkdistgrads;
  if ( $dowhat{limit_checkdistgrads} )
  {
    $limit_checkdistgrads = $dowhat{limit_checkdistgrads};
  }
  else 
  {
    $limit_checkdistgrads = ""; 
  } # LIMIT OF RELATIONS TAKEN INTO ACCOUNT IN CALCULATING THE NET OF GRADIENTS. IF NULL, NO BARRIER. AS A NUMBER, 1/5 OR 1/10 OF THE TOTAL INSTANCES SHOULD BE A GOOD PLACE TO START AS A COMPROMISE BETWEEN SPEED AND RELIABILITY.
  
  my $limit_checkdistpoints;
  if ( $dowhat{limit_checkdistpoints} )
  {
    $limit_checkdistpoints = $dowhat{limit_checkdistpoints};
  }
  else 
  {
    $limit_checkdistpoints = ""; 
  } # DO NOT USE. LIMIT OF RELATIONS TAKEN INTO ACCOUNT IN CALCULATING THE NET OF POINTS. IF NULL, NO BARRIER. 10000 IS A GOOD COMPROMISE BETWEEN SPEED AND RELIABILITY.
  
  my $fulldo;
  if ( $dowhat{fulldo} )
  {
    $fulldo = $dowhat{fulldo};
  }
  else 
  {
    $fulldo = "n"; 
  } # TO SEARCH FOR MAXIMUM PRECISION AT THE EXPENSES OF SPEED. "y" MAKES THE GRADIENTS BE RECALCULATED AT EACH COMPUTATION CYCLE.
  
  my $lvconversion;
  if ( $dowhat{lvconversion} )
  {
    $lvconversion = $dowhat{lvconversion};
  }
  else 
  {
    $lvconversion = "";
  }
  
  my $limitgrads;
  if ( $dowhat{limitgrads} )
  {
    $limitgrads = $dowhat{limitgrads};
  }
  else 
  {
    $limitgrads = "";
  }

  #@weldsprepared = ( "/home/luca/ffexpexps_full/minmissionsprep.csv" );
  #@parswelds = ( [ 1, 4 ] );
  #@recedes = ( 1, 4 );
  ############# END OF THE EXAMPLE SETTINGS TO BE PUT IN A CONFIGURATION FILE.

  if ( -e $confile )
  {
    #eval $confile; ############## TRULY FIX THIS!!!!!
    require $confile; ############## TRULY FIX THIS!!!!!
    #if ( $newfile eq "" ) { die };
  }
  elsif ( -e "./confinterlinear.pl" )
  {
    require "./confinterlinear.pl";
  }

  if ( $sourcef ne "" ){ $sourcefile = $sourcef; }

  if ( $metafile ne "" ){ $newfile = $metafile; }

  my @blockelts;
  if ( $blockelts_r ne "" ){ @blockelts = @{ $blockelts_r }; }

  @mode = adjustmode( $maxloops, \@mode );

  
  if ( @lines)
  {
    say "!!!!! IN INTERLINEAR HAD \@lines ";
  }
  elsif ( ref($sourcefile) eq 'ARRAY' ) 
  {
      say "Reading from memory (Array Reference)...";
      @lines = @$sourcefile; 
  } 
  else 
  {
      say  "Opening $sourcefile";
      open( SOURCEFILE, "$sourcefile" ) or die;
      @lines = <SOURCEFILE>;
      close SOURCEFILE;
  }
  chomp @lines; 
  say "LINES! " . dump ( @lines );
  
  
  say  "Preparing the dataseries, IN INTERLINEAR: \$countblock $countblock";
  #say "nfiltergrads: $nfiltergrads";
  #say "limit_checkdistgrads: $limit_checkdistgrads";
  #say "limit_checkdistpoints: $limit_checkdistpoints";
  #say "\$limitgrads: $limitgrads";
  my $checkstop;

  my $aarr_ref;
  ( $aarr_ref, $optformat ) = preparearr( @lines );

  my @aarr = @{ $aarr_ref };

  say  "Checking factors and levels.";
  my %factlevels = %{ prepfactlev( \@aarr ) };
  say  "Done.";


  my ( $factlev_ref ) = tellstepsize( \%factlevels, $lvconversion );
  my %factlev = %{ $factlev_ref }; #say  " \%factlev: " . dump( %factlev );
  say  "Understood step sizes.";

###--###
  my ( @weldaarrs );
  if ( scalar( @weldsprepared ) > 0 )
  {
    foreach my $weldsourcefile ( @weldsprepared )
    {
      open( WELDSOURCEFILE, "$weldsourcefile" ) or die;
      my @weldlines = <WELDSOURCEFILE>;
      close WELDSOURCEFILE;

      my ( $weldaarr_ref, $optformat ) = preparearr( @weldlines );

      my @weldaarr = @{ $weldaarr_ref };
      push ( @weldaarrs, [ @weldaarr ] );
    }
  }

  my ( $maxdist, $first0, $last0 ) = calcmaxdist( \@aarr, \%factlev );
###--###

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

    my $mode__ = $mode[$count] ;

    my ( @limbo_wei, @limbo_purelin, @limbo_near, @limbo, %wand );

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
        say  "EXITING. DONE.";
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
      my ( $limbo_wei_ref, $bank_ref, $nears_ref ) = wei( \@arr, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies,
      $count, \%factlev, $minreq_forgrad, $minreq_forinclusion, $minreq_forcalc, $minreq_formerge, $maxdist, $nfiltergrads,
      $limit_checkdistgrads, $limit_checkdistpoints, \%bank, $fulldo, $first0, $last0, \%nears, $checkstop, \@weldsprepared,
      \@weldaarrs, \@parswelds, \@recedes, $nfilterpoints, $limitgrads, $limitpoints, \@modality );

      @limbo_wei = @{ $limbo_wei_ref };
      %bank = %{ $bank_ref };
      %nears = %{ $nears_ref };

      say  "THERE ARE " . scalar( @limbo_wei ) . " ITEMS IN THIS LOOP , NUMBER " . ( $count + 1 ). ", 1, FOR WEIGHTED GRADIENT INTERPOLATION OF THE NEAREST NEIGHBOUR.";
    }
    #say  "OBTAINED LIMBO_WEI: " . dump( @limbo_wei );

    if ( ( $mode__ eq "purelin" ) or ( $mode__ eq "mix" ) )
    {
      @limbo_purelin = purelin( \@arr, $relaxlimit, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count, \%factlev, $maxdist );
      say  "THERE ARE " . scalar( @limbo_purelin ) . " ITEMS IN THIS LOOP , NUMBER " . ( $count + 1 ). ", 1, FOR PURE LINEAR INTERPOLATION.";
    }
    #say  "OBTAINED LIMBO_PURELIN: " . dump( @limbo_purelin );

    if ( ( $mode__ eq "near" ) or ( $mode__ eq "mix" ) )
    {
      @limbo_near = near( @arr, $nearrelaxlimit, $relaxmethod, $overweightnearest, $nearconcurrencies, $count, \%factlev, $maxdist );
      say  "THERE ARE " . scalar( @limbo_near ) . " ITEMS IN THIS LOOP, NUMBER " . ( $count + 1 ) . ", 2, FOR THE NEAREST NEIGHBOUR STRATEGY.";
    }
    #say  "MAGIC: " . dump( %magic );
    #say  "OBTAINED LIMBO_NEAR: " . dump( @limbo_near );


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

    #say  "OBTAINED LIMBO: " . dump( @limbo );
    say  "MIXING THE ARRAY UPDATES " . ( $count + 1 ) . " for $sourcefile";
    say  "THERE ARE " . scalar( @limbo ) . " ITEMS COMING OUT FROM THIS MIX " . ( $count + 1 );


    if ( ( scalar( @limbo ) == 0 ) )
    {
      #say  "ARR END: " . dump( @arr );
      say  "EXITING.";
      printend( \@arr, $newfile, $optformat );
      last;
    }

    foreach my $el ( @limbo )
    {
      foreach $elt ( @arr )
      {
        if ( $el->[0] eq $elt->[0] )
        {
          if ( $elt ->[2] eq "" )
          {
              push ( @{ $elt }, $el->[2], $el->[3] );
          }
          else
          {
            {
              my ( $soughtval, $totstrength ) = weightvals_merge( [ $elt->[2], $el->[2] ], [ $elt->[3], $el->[3] ], $minreq_formerge, $maxdist  );
              if ( ( $soughtval ne "" ) and ( $totstrength ne "" ) )
              {
                pop @{ $elt };
                pop @{ $elt };
                push ( @{ $elt }, $soughtval, $totstrength );
              }
            }
          }
        }
      }
    }
    
    @arr2 = @arr ;
    say  "INSERTING THE ARRAY UPDATES " . ( $count + 1 ) . " for $sourcefile";
    $count++;
  }

  my @newarr;
  foreach my $lin ( @arr )
  {
    my @elts = @$lin;
    my $bit = join( ",", ( $elts[0], $elts[-2] ) );
    push( @newarr, $bit );
  }
  return( \@arr, \@newarr );
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
    if ( $optformat eq "y" )
    {
      print NEWFILE "$entry->[0],$entry->[2]\n";
    }
    elsif ( $optformat eq "n" )
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
  Sim::OPT::Interlinear::interlinear( "./sourcefile.csv", "./confiinterlinear.pl", "./obtainedmetamodel.csv" );

  # or as a script, from the command line:
  perl ./Interlinear.pm  .  ./sourcefile.csv
  # (note the dot).

  # or, again, from the command line, for beginning with a dialogue question:
  interlinear interstart


=head1 DESCRIPTION


Interlinear is a program for metamodelling the missing instance values in multivariate datasieries by distance-weighting the nearest-neihbouring gradients between points.
The strategy weights the known gradients in a manner inversely proportional to the distance between the points they are taken from to the missing nearest-neighbouring points they are going to be used for. It is a zero-order instance-based method. In it, the space curvatures are reconstructed by utilizing a local sample of the near-neighbouring gradients. The method has been presented in the following publication: L<Gian Luca Brunetti (2020). “Increasing the efficiency of simulation-based design explorations via metamodelling”. Journal of Building Performance Simulation, 13:1, pp. 79-99. DOI: 10.1080/19401493.2019.1707875|http://doi.org/10.1080/19401493.2019.1707875>, where is has been named Distance-Weighted Gradient Network (DWGN), and has been shown capable of outperforming the Kriging method, the MARS method, and polynomial methods.
The DWGN is active by default when calling Intelinear. Another version of the procedure, in which the derived points are calculated on a global rather than a local basis, allowing faster computations, but entailing less accurate results, can be activated by setting @modality = ( "simple" ) in the configuration file.
Besides strategies the DWGN and the DWGN-simple, two alternative metamodelling strategies can be utilized in Interlinear: pure linear interpolation (one may want to use this just in some occasions: for example, on factorials), and pure nearest neighbour (a strategy of last resort: one may want to use a pass of it to unlock a computation which is based on data which are too sparse to proceed, or when nothing else works).

The DWGN and the DWGN-simple work preferentially on the basis of group of samples that are adjacent in the design space. For example, it does not like to work with only the gradients between a certain iteration 1 and the corresponding iteration 3. It likes to work with the gradient between iterations 1 and 2, or 2 and 3. For that reason, it does not work well with data evenly distributed in the design space, like those deriving from latin hypercube sampling, or a random sampling; and works well with data clustered in small patches, like those deriving from star sampling strategies, or from coordinate descent, or block coordinate descent, or overlapping block coordinate descent.
To work well with a latin hypercube sampling, it may be necessary to include a pass of pure linear interpolation or pure nearest neighbour before calling the DWGN. Then the DWGN will charge itself of reducing the errors created by that initial pass. As an alternative, in the DWGN, the third element of the variable $minreq_forgrad in the configuration file (which is, by default, "confinterlinear.pl") may be set to more than 1: for example $minreq_forgrad = [1, 1, 2]. This makes not only the nearest-neighbouring samples be taken into account in the calculations, but also the 2nd-nearest, or the nth-nearest.

A configuration file should be prepared following the example in the "examples" folder in this distribution.
If the configuration file is incomplete or missing, the program will adopt its own defaults, exploiting the distance-weighted gradient-based strategy a1.
The only variable that must mandatorily be specified in a configuration file is $sourcefile: the Unix path to the source file containining the dataseries. The source file has to be prepared by listing in each column the values (levels) of the parameters (factors, variables), putting the objective function valuesin the last column in the last column, at the rows in which they are present.

The parameter number is given by the position of the column (i.e. column 4 host parameter 4).

Here below is an example of multivatiate dataseries of 3 parameters assuming 3 levels each. The numbers preceding the objective function (which is in the last colum) are the indices of the multidimensional matrix (tensor).


1,1,1,1,1.234

1,2,3,2,1.500

1,3,3,3

2,1,3,1,1.534

2,2,3,2,0.000

2,3,3,1,0.550

3,1,3,1

3,2,3,2,0.670

3,3,3,3


The program converts this format into the one preferred by Sim::OPT, which is the following:


1-1_2-1_3-1,9.234

1-1_2-2_3-2,4.500

1-1_2-3_3-3

1-2_2-1_3-1,7.534

1-2_2-2_3-2,0.000

1-2_2-3_3-3,0.550

1-3_2-1_3-1

1-3_2-2_3-2,0.670

1-3_2-3_3-3


(((Note that the parameter listings cannot be incomplete if Interlinear is to be involved without involving Sim::OPT. Just the objective function entries can be incomplete. The following series, for example, is a version of the series above, incomplete as regards the parameter listings:

1-1_2-1_3-1,9.234

1-1_2-2_3-2,4.500

1-2_2-1_3-1,7.534

1-2_2-2_3-2,0.000

1-2_2-3_3-3,0.550

1-3_2-2_3-2,0.670

How to involve Sim::OPT is dealt with at the end of this document.)))


After some computations, Interlinear will output a new dataseries with the missing values filled in.
This dataseries can be used by OPT for the optimization of one or more blocks. This can be useful, for example, to save computations in searches involving simulations, especially when the time required by each simulations is long, like it may happen with CFD simulations in building design.

The number of computations required for the creation of a metamodel in OPT increases exponentially with the number of instances in the metamodel. To reduce the exponential, a limit has to be set for the size of the net of instances taken into account in the computations for gradients and for points. The variables in the configuration files controlling those limits are "$nfiltergrads", a limit with adaptive effects (putting a ceiling to the number of originary gradients utilized to derive the points), as well as "$limit_checkdistgrads" and "$limit_checkdistpoints" (putting a limit to the number of derived gradients and points from which the calculations are further propagated at each computation pass). By default they are unspecified. If they are unspecified (i.e. a null value ("") is specified for them), no limit is assumed. "$nfiltergrads" may be set to the double of the square root of the number of instances of a problem space. "$limit_checkdistgrads" and "$limit_checkdistpoints" may be set to a part of the total number of instances, for example that number divided by 1/5, or 1/10. "$limit_checkdistgrads" and "$limit_checkdistpoints" may be given the same value. An example of configuration file with more information in the comments is embedded in this source code, where it sets the defaults.

By utilizing the metamodelling procedure at point (a), Interlinear can also weld two related problem space models together, provided that they share the same parametric structure. This welding is not a mere merge. It is a neighbour-by-neighbour action, much wholler and, yes, cooler. The procedure has been presented in the following publication: L<Gian Luca Brunetti (2020). “Grafting of design-space models onto models of different scope or resolution”. Journal of Building Performance Simulation, 13:3, pp. 227-246. DOI: 10.1080/19401493.2019.1707875
|http://doi.org/10.1080/19401493.2020.1712477>. The action of procedure is controlled by the following settings in the configuration file:
1) @weldsprepared = ( "/home/luca/ffexpexps_full/minmissionsprep.csv" ); #The path to the second dataseries.
2) @parswelds = ( [ 1, 4 ] ); #The parameter numbers of which the welding action has to take place.
3) @recedes = ( 1, 4 ); #This signals with respect to which parameters the first dataseries gives way to the second. (Otherwise, the obtained points would be averaged one-to-one with those of first dataseries. Usually you do not want that.)

To call Interlinear as a Perl function (best strategy):
re.pl # open Perl shell
use Sim::OPT::Interlinear; # load Interlinear
Sim::OPT::Interlinear::interlinear( "./sourcefile.csv", "./confinterlinear.pl", "./obtainedmetamodel.csv" );
"confinterlinear.pl" is the configuration file. If that file is an empty file, Interlinear will assume the default file names above.
"./sourcefile.csv" is the only information which is truly mandatory: the path to the csv dataseries to be completed.
If is not specified,

To use Interlinear as a script from the command line:
perl ./Interlinear.pm . "./sourcefile.csv" "./confinterlinear.pl ";
(Note the dot within the line.) Again, if "./sourcefile.csv" is not specified, the default file "./sourcefile.csv" will be sought.

Or to begin with a dialogue question:
./Interlinear.pm interstart;
.


=head1 FILE OUTPUT NAMES

Interlinear’s internal defaults are:

  sourcefile              ("")         # overridden by caller
  newfile                 ($sourcefile . "_meta.csv")
  report                  ($newfile . "_tofile.txt")

These are normally set by the caller (e.g., Descend) and do not typically need
to be overridden in %dowhat.



This module is dual-licensed, open-source and proprietary. The open-source distribution is available on CPAN (https://metacpan.org/dist/Sim-OPT ). A proprietary distribution, including additional modules (OPTcue), is available from the author’s website (https://sites.google.com/view/bioclimatic-design/home/software ).

=head2 EXPORT


interlinear, interstart.



=head1 AUTHOR


Gian Luca Brunetti (2018-24) E<lt>gianluca.brunetti@polimi.itE<gt>


=head1 COPYRIGHT AND LICENSE


Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is GPL. By consequence, this is free software.  You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.


=cut
