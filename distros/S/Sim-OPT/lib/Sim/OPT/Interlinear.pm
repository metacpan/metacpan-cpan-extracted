#package Sim::OPT::Interlinear;

# INTERLINEAR, v. 0.01
# Author: Gian Luca Brunetti, Politecnico di Milano. (gianluca.brunetti@polimi.it)
# Copyright reserved.  2018.
# GPL License 3.0 or newer.
# This is a program for filling a design space multivariate discrete dataseries
# by creatinng recursive and progressive relations of linear interpolation.
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

#use Sim::OPT;
#use Sim::OPT::Morph;
#use Sim::OPT::Sim;
#use Sim::OPT::Report;
#use Sim::OPT::Descend;
#use Sim::OPT::Takechance;
#use Sim::OPT::Parcoord3d;

our @ISA = qw( Exporter );
our @EXPORT = qw( interlinear, interstart );

$VERSION = '0.001';
$ABSTRACT = 'Interlinear is a program for building metamodels from sparse multivariate discrete dataseries.';

#######################################################################
# Interlinear
#######################################################################



my $sourcefile = "/home/luca/int/starcloud.csv";
my $newfile = $sourcefile . "_new.csv";
my $report = $newfile . "_report.txt";
my @mode = ( "linnea", "linnea", "mix" ); # #"linnea" is a hybrid between linear interpolation" and nearest neighbour
# my @mode = ( "lin" ); # #"lin" is linear interpolation.
#my @mode = ( "nea" ); # "nea" means "nearest neighbour"
#@mode = ( "linnea", "lin", "mix" ); # "mix" means sequentially mixed in each loop.
#my @mode = ( "linnea", "linnea", "nea" );
#my @mode = ( "mix", "linnea", "nea" );
my @weights = (  ); #my @weights = ( 0.7, 0.3 ); # THE FIRST IS THE WEIGHT FOR linear interpolation, THE SECOND FOR nearest neighbour.
# THEY ARE FRACTIONS OF 1 AND MUST GIVE 1 IN TOTAL. IF THE VALUES ARE UNSPECIFIED (IE. IF THE ARRAY IS EMPTY), THE VALUES ARE UNWEIGHTED.
my $linearprecedence = "no"; # PRECEDENCE TO LINEAR INTERPOLATES. IF "yes", THE VALUES DERIVED FROM LINEAR INTERPOLATION, WHERE PRESENT, WILL SUPERSEDE THE VALUES DERIVED FROM THE NEAREST NEIGHBUR STRATEGY. IF "no", THE OPPOSITE. IT CAN BE ACTIVE ONLY IF LOGARITHMIC IS OFF. IT WORKS WITH "LINEAR" AND "EXPONENTIAL"

my $relaxmethod = "logarithmic"; #"logarithmic", "linear" or "exponential". THE FARTHER NEIGHBOURS ARE WEIGHT LESS THAN THE NEAREST ONES: INDEED, LOGARITHMICALLY, LINEARLY OR EXPONENTIALLY. THE LOGARITHM BASE IS $relaxlimit OR $nearrelaxlimit, DEPENDING FROM THE CONTEXT. THE LINEAR MULTIPLICATOR OR THE EXPONENT IS DEFINED BY $overwerightnearest.
my $relaxlimit = 0; #THIS IS THE CEILING FOR THE RELAXATION OF THE RELATIONS OF LINEAR INTERPOLATION. For greatest precision: 0, or a negative number near 0. IF > = 0, THE PROGRAM INTERPOLATES ALSO NEAREST NEIGHBOURS. THE HIGHER THE NUMBER, THE FARTHER THE NEIGHBOURS.
my $overweightnearest = 1; #A NUMBER. IT IS MADE NULL BY THE $logarithmicrelax "yes". THE HIGHER THE NUMBER, THE GREATER THE OVERWEIGHT GIVEN TO THE NEAREST. IN THIS MANNER, THE OVERWEIGHT IS NOT LOGARITHMIC, LIKE IT WHERE OTHERWISE, BUT LINEAR. THIS SLOWS DOWN THE COMPUTATIONS. UNLESS THE OVERWEIGHT IS 1, WHICH MAKES THE OVERWEIGHTING NULL.
my $nearrelaxlimit = 0; #THIS IS THE CEILING FOR THE RELAXATION OF THE RELATIONS OF THE NEAREST NEIGHBOUR STRATEGY. For greatest precision: 0, or a negative number near 0. IF > = 0, THE PROGRAM INCREASES THE DISTANCE OF THE NEAREST NEIGHBOURS INCLUDED. THE HIGHER THE NUMBER, THE FARTHER THE NEIGHBOURS. ONE IS NOT LIKELY TO WANT TO USE THIS OPTION.
my $nearconcurrencies = 1; #Requested minimum number of concurrencies for the nearest neighbour method. Minimum value: 1. The more the requested concurrencies, the greatest the precision, the slowest the convergence.
my $parconcurrencies = 1; #Requested minimum number of concurrencies for the linear interpolations for each parameter of each instance. Minimum value: 1. The more the requested concurrencies, the greatest the precision, the slowest the convergence.
my $instconcurrencies = 1; #Requested minimum number of concurrencies for the linear interpolations for each instance. Minimum value: 1. The more the requested concurrencies, the greatest the precision, the slowest the convergence.

#######################################################################

$tee = new IO::Tee(\*STDOUT, ">$report");

#sub _mean_ { return @_ ? sum(@_) / @_ : 0 }

sub union
{
  my $aref = shift;
  my $bref = shift;
  my @aa = @$aref; #say $tee ""\@aa: " . dump( @aa );
  my @bb = @$bref; #say $tee "\@bb: " . dump( @bb );

  my @union = uniq( @aa, @bb );
  return @union;
}

sub diff_old1
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


sub diff_old2
{
  my $aref = shift;
  my $bref = shift;
  my @aa = @$aref; #say $tee "\@aa: " . dump( @aa );
  my @bb = @$bref; #say $tee "\@bb: " . dump( @bb );
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


sub linear
{
  my ( $arr_ref, $arrcopy_ref, $relaxlimit, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count ) = @_;
  my @arr = @{ $arr_ref };
  my %arrcopy = %{ $arrcopy_ref };
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

              }
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
                my @da2par = values %h2; #sa_refy $tee "\@da2par: " . dump( @da2par );
                #say $tee "\$el->[2]: " . dump( $el->[2] );

                if ( $relaxmethod eq "linear" )
                {
                  my $indinc = ( $overweightnearest - $index );
                }
                elsif ( $relaxmethod eq "exponential" )
                {
                  my $indinc = ( ( $overweightnearest - $index ) * ( $overweightnearest - $index ) );
                }

                my $count = 0;
                foreach my $d10 ( @da1 )
                { #say $tee "\$d10: " . dump( $d10 );
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
                      }_mean_
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
          my $val2 = $array[i+1]->[4];
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
                my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
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
        $spell{$ke} = $magic{$ke}{$dee}->[0] ;#DDD
      }
    }
  }

  #say $tee "MAGIC: " . dump(%magic);
  #say $tee "WAND: " . dump(%wand);
  #say $tee "SPELL: " . dump(%spell);


  foreach my $ke ( sort {$a <=> $b} ( keys %wand ) )
  {
    my $eltnum = scalar( keys %{ $wand{$ke} } );
    unless ( $eltnum <= ( $instconcurrencies - 1 ) )
    {
      my $avg = mean( values( %{ $wand{$ke} } ) ); #say $tee "\$avg: " .  dump( $avg );
      push ( @limbo1, [ $spell{$ke}[0], $spell{$ke}[1] , $avg ] ); #say $tee "\$avg: $avg"; say $tee "\${ \$magic{\$ke}{\$dee} }->[1] : ${ $magic{$ke}{$dee} }->[1] ";
    }
  }
  return( @limbo1 )
} #####END SUB LINEAR


sub nearest
{
  my ( $arr_ref, $arrcopy_ref, $nearrelaxlimit, $relaxmethod, $overweightnearest, $nearconcurrencies, $count ) = @_;
  my @arr = @{ $arr_ref };
  my %arrcopy = %{ $arrcopy_ref };
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

          if ( $relaxmethod eq "logarithmic" )
          {
            my $index = 0;
            while ( $index <= $nearrelaxlimit )
            {
              if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) <= ( 1 + $nearrelaxlimit ) ) )
              { #say $tee "AND \@diff1 IS 1: " . dump( @diff1 );
                my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } ); #say $tee "SO \@diff2: " . dump( @diff2 );

                my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
                my @da1 = keys %h1;
                my @da1par = values %h1; #say $tee "\@da1par: " . dump( @da1par );
                my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
                my @da2 = keys %h2;
                my @da2par = values %h2; #say $tee "\@da2par: " . dump( @da2par );
                #say $tee "\$el->[2]: " . dump( $el->[2] );

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
          elsif ( ( $relaxmethod eq "linear" ) or ( $relaxmethod eq "exponential" ) )
          {
            my $index = 0;
            while ( $index <= $nearrelaxlimit )
            {
              if ( ( scalar( @diff1 ) > 0 ) and ( scalar( @diff1 ) == ( 1 + $nearelaxlimit ) ) )
              { #say $tee "AND \@diff1 IS 1: " . dump( @diff1 );#SAME CONTENT AS THE PREVIOUS WHILE HERE BELOW
                my @diff2 = diff( \@{ $elt->[1] } , \@{ $el->[1] } ); #say $tee "SO \@diff2: " . dump( @diff2 );

                my @d1 = split( /-/ , $diff1[0] ); #say $tee "THEN \@d1: " . dump( @d1 );
                my @d2 = split( /-/ , $diff2[0] ); #say $tee "THEN \@d2: " . dump( @d2 );
                #say $tee "SAYYY \$el->[1]: " . dump( $el->[1] );my %h1 = map { split( /-/ , $_ ) } @diff1; #say $tee "THEN \%h1: " . dump( %h1 );
                my @da1 = keys %h1;
                my @da1par = values %h1; # $tee "\@da1par: " . dump( @da1par );
                my %h2 = map { split( /-/ , $_ ) } @diff2; #say $tee "THEN \%h2: " . dump( %h2 );
                my @da2 = keys %h2;
                my @da2par = values %h2; #say $tee "\@da2par: " . dump( @da2par );
                #say $tee "SAYYY \$el->[1]: " . dump( $el->[1] );

                if ( $relaxmethod eq "linear" )
                {
                  my $indilinneanc = ( $overweightnearest - $index );
                }
                elsif ( $relaxmethod eq "exponential" )
                {
                  my $indinc = ( ( $overweightnearest - $index ) * ( $overweightnearest - $index ) );
                }

                my $count = 0;
                foreach my $d10 ( @da1 )
                { #say $tee "\$d10: " . dump( $d10 );
                  my $d11 = $da1par[$count]; #say $tee "\$d11: " . dump( $d11 );
                  my $co = 0;
                  foreach my $d20 ( @da2 )
                  { #say $tee "\$d20: " . dump( $d20 );
                    my $d21 = $da2par[$co]; #say $tee "\$d21: " . dump( $d21 );
                    while ( $indinc > 0 )
                    {
                      if ( ( $d10 eq $d20 ) ) #### if ( ( $d10 eq $d20 ) and ( $d11 ne $d21 ) ) ###  THE SECOND CONDITION COULD BE LOGICALLY REDUNDANT. CHECK. ####
                      {
                        push( @bag, $elt->[2] ); #say $tee "PUSHING " . $elt->[1] . " IN BAG"; #key, array, factornum missing, factornum gotten, value
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

      if ( not ( scalar( @bag ) <= ( $nearconcurrencies - 1 ) ) )
      { #say $tee "\@bag: " . dump( @bag );
        my $bagmean = mean( @bag ); #say $tee "\$bagmean: $bagmean";
        unless ( scalar( @bag ) == 0 )
        {
          push ( @limbo2, [ $el->[0], $el->[1], $bagmean ] ); #say $tee "PUSHIN \$bagmean $bagmean in \@limbo2 ";
        }
      }
    }
  }
  return( @limbo2 );
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
  foreach my $line ( @lines )
  {
    chomp( $line );
    my @row = split( /,/ , $line );
    my @pars = split( /_/ , $row[0] );
    if ( $row[1] eq undef )
    {
      push ( @arr, [ $row[0], [ @pars ] ] );
    }
    else
    {
      push ( @arr, [ $row[0], [ @pars ], $row[1],  ] );
    }
  } #say $tee "ARR: " . dump( @arr );
  my %arrcopy;
  foreach my $el ( @arr )
  {
    $arrcopy{$el->[0]} = $el;
  }
  return( \@arr, \%arrcopy );
}


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
      {
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
  interlinear( $configfile, $sourcefile );
}



########################################### END SUBS


sub interlinear
{
  my ( $configf, $sourcef ) = @_;
  if ( $sourcef ne "" ){ $sourcefile = $sourcef; }
  if ( $configf ne "" ){ $configfile = $configf; }

  my $maxloops= 1000;
  my @mode = adjustmode( $maxloops, \@mode );
  open( SOURCEFILE, "$sourcefile" ) or die;
  my @lines = <SOURCEFILE>;
  close SOURCEFILE;

  my ( $arr_ref, $arrcopy_ref ) = preparearr( @lines );
  my @arr = @{ $arr_ref };
  my %arrcopy = %{ $arrcopy_ref };

  my $count = 0;
  while ( $count < $maxloops )
  {

    say $tee "COUNT: " . dump( $count + 1 );
    my $mode__ = $mode[$count] ;
    my ( @limbo1, @limbo2, @limbo );

    if ( ( $mode__ eq "linnea" ) or ( $mode__ eq "mix" ) )
    {
      @limbo1 = linear( \@arr, \%arrcopy, $relaxlimit, $relaxmethod, $overweightnearest, $parconcurrencies, $instconcurrencies, $count );
    }
    #say $tee "OBTAINED LIMBO1: " . dump( @limbo1 );
    say $tee "THERE ARE " . scalar( @limbo1 ) . " ITEMS IN THIS LOOP , NUMBER " . ( $count + 1 ). ", 1, FOR LINEAR INTERPOLATION.";

    if ( ( $mode__ eq "nea" ) or ( $mode__ eq "mix" ) )
    {
      @limbo2 = nearest( @arr, \%arrcopy, $nearrelaxlimit, $relaxmethod, $overweightnearest, $nearconcurrencies, $count );
    }
    #say $tee "MAGIC: " . dump( %magic );
    say $tee "OBTAINED LIMBO2: " . dump( @limbo2 );
    say $tee "THERE ARE " . scalar( @limbo2 ) . " ITEMS IN THIS LOOP, NUMBER " . ( $count + 1 ) . ", 2, FOR THE NEAREST NEIGHBOUR STRATEGY.";

    my %limbo1copy;
    foreach my $el ( @limbo1 )
    {
      $limbo1copy{$el->[0]} = $el;
    }

    my @limbo = mixlimbo( \@limbo1, \@limbo2, $presence, $linearprecedence, \@weights );

    #say $tee "OBTAINED LIMBO: " . dump( @limbo );
    say $tee "MIXING THE ARRAY UPDATES " . ( $count + 1 ) . " for $sourcefile";
    say $tee "THERE ARE " . scalar( @limbo ) . " ITEMS COMING OUT FROM THIS MIX " . ( $count + 1 );

    if ( scalar( @limbo ) == 0 )
    {
      last;
    }

    foreach my $el ( @limbo )
    { #say $tee "EL AGAIN: " . dump( $el );
      my $elt = $arrcopy{$el->[0]};
      if ( $el->[0] eq $elt->[0] )
      {
        unless ( $el->[2] eq "" )
        {
          push ( @{ $elt }, $el->[2] );
        }
      }$configf
    }
    #say $tee " ARR: " . dump( @arr );
    say $tee "INSERTING THE ARRAY UPDATES " . ( $count + 1 ) . " for $sourcefile";
    $count++;
  }
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
    interlinear;
  }
  else
  {
    interlinear( @ARGV );
  }
}

open( NEWFILE, ">$newfile" ) or die;
foreach my $entry ( @arr )
{
  my $coun = 0;
  my $number = scalar( @{ $entry->[1] } );
  foreach my $item ( @{ $entry->[1] } )
  {
    if ( not ( $coun == $number ) )
    {
      print NEWFILE "$item,";
    }
    else
    {
      print NEWFILE "$item";
    }
    $coun++;
  }
  print NEWFILE "$entry->[2]\n";
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

  Or from the command line:
  interlinear .
  (note the dot), to use the file as a script and include the location of the source file directly in the configuration file.

  Or from the command line:
  interlinear interstart
  to begin with a dialogue question.

=head1 DESCRIPTION

Interlinear is a program for computing the missing values in multivariate data series pre-prepared in csv format.


Presently the program adopts a mix of nearest-neighbour strategy and hybrid linear interpolation for filling the missing values.

A configuration file for the program should be prepared following the example in the "examples" folder in this distribution.

If the configuration file is incomplete or missing, the program adopts its own defaults; which presently include a sequence of loops constituted by three passes of pure linear interpolation and one of the nearest neighbor strategy.

The operations entailed are linear but the results of their interplay  are not.

The operations can be weighted and the strategies can be intermixed.

The source cvs file has currently to be prepared in the format liked by Sim::OPT.

For example, a multivatiate dataseries with missing entries, like the one shown below (in which the numbers relative to the factors are put into the odd colums and the numbers relative to the levels are put in the even columns, and in which the last column is kept for the objective function)...


1,1,2,1,3,1,1.234

1,1,2,2,3,2,1.500

1,1,2,3,3,3

1,2,2,1,3,1,1.534

1,2,2,2,3,2,0.000

1,2,2,3,3,0.550

1,3,2,1,3,1

1,3,2,2,3,2,0.670

1,3,2,3,3,3


...should be edited in the following manner:


1-1_2-1_3-1,9.234

1-1_2-2_3-2,4.500

1-1_2-3_3-3

1-2_2-1_3-1,7.534

1-2_2-2_3-2,0.000

1-2_2-3_3-3,0.550

1-3_2-1_3-1

1-3_2-2_3-2,0.670

1-3_2-3_3-3


After some computations, the program will output a new dataseries, with the missing values filled in.


=head2 EXPORT

interlinear, interstart.

=head1 SEE ALSO

An example of configuration file can be found in the "examples" folder in this distribution.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2017 by Gian Luca Brunetti and Politecnico di Milano. This is free software. You can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 or newer.

=cut
