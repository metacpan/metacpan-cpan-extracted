package NCAR::Test;

our $VERSION = '0.01';

use strict;
use base qw( Exporter );
our @EXPORT = qw( 
                  gendat bndary min max alog10 log10 
                  sign min max genara dfclrs labtop 
                  capsap shader drawcl
                );
use PDL;

sub gendat {
  my ( $DATA, $IDIM, $M, $N, $MLOW, $MHGH, $DLOW, $DHGH)  = @_; 
  my $CCNT = zeroes float, 3, 50;
  my $FOVM = 9./$M;
  my $FOVN = 9./$N;
  my $NLOW = max( 1, min( 25, $MLOW ) );
  my $NHGH = max( 1, min( 25, $MHGH ) );
  my $NCNT = $NLOW+$NHGH;

  
  for my $K ( 1 .. $NCNT ) {
    set( $CCNT, 0, $K - 1, 1.+($M-1.)*rand() );
    set( $CCNT, 1, $K - 1, 1.+($N-1.)*rand() );
    if( $K <= $NLOW ) {
      set( $CCNT, 2, $K - 1, -1 );
    } else {
      set( $CCNT, 2, $K - 1, +1 );
    }
  }
  my $DMIN=+1.E36;
  my $DMAX=-1.E36;
  
  
  for my $J ( 1 .. $N ) {
    for my $I ( 1 .. $M ) {
      set( $DATA, $I - 1, $J - 1, .5*($DLOW+$DHGH) );
      for my $K ( 1 .. $NCNT ) { 
         my $T1 = $FOVM * ( $I - at( $CCNT, 0, $K - 1 ) );
         my $T2 = $FOVN * ( $J - at( $CCNT, 1, $K - 1 ) );
         my $TEMP = - ( $T1 * $T1 + $T2 * $T2 ); 
         if( $TEMP >= -20 ) {
           set( $DATA, $I - 1, $J - 1, 
                at( $DATA, $I - 1, $J - 1 ) + 
                .5 * ( $DHGH - $DLOW ) * at( $CCNT, 2, $K - 1 ) * exp( $TEMP )
              );
         }
      }
      $DMIN = min( $DMIN, at( $DATA, $I - 1, $J - 1 ) );
      $DMAX = max( $DMAX, at( $DATA, $I - 1, $J - 1 ) );
    }
  }

  for my $J ( 1 .. $N ) {
    for my $I ( 1 .. $M ) {
      set( $DATA, $I - 1, $J - 1, 
           ( at( $DATA, $I - 1, $J - 1 ) - $DMIN ) /
           ( $DMAX - $DMIN ) * ( $DHGH - $DLOW ) + $DLOW );
    }
  }

}


sub capsap {
  my ( $LABL, $IAMA, $LAMA ) = @_;
#
# Compute and print the time required to draw the contour plot and how
# much space was used in the various arrays.
#
  print STDERR "PLOT TITLE WAS $LABL\n";
&NCAR::cpgeti( 'IWU - INTEGER WORKSPACE USAGE', my $IIWU );
&NCAR::cpgeti( 'RWU - REAL WORKSPACE USAGE', my $IRWU );
  print STDERR "INTEGER WORKSPACE USED $IIWU\n";
  print STDERR "   REAL WORKSPACE USED $IRWU\n";
  if( $LAMA != 0 ) {
    my $IAMU = $LAMA - ( at( $IAMA, 5 ) - at( $IAMA, 5 ) -1 );
    print STDERR "   AREA MAP SPACE USED $IAMU\n";
  }
#
# Done.
#
}

sub labtop {
  my ( $LABL, $SIZE ) = @_;
#
# Put a label just above the top of the plot.  The SET call is re-done
# to allow for the use of fractional coordinates, and the text extent
# capabilities of the package PLOTCHAR are used to determine the label
# position.
#
  my ( $XVPL, $XVPR, $YVPB, $YVPT, $XWDL, $XWDR, $YWDB, $YWDT, $LNLG );
  &NCAR::getset( $XVPL, $XVPR, $YVPB, $YVPT, $XWDL, $XWDR, $YWDB, $YWDT, $LNLG );
  my $SZFS=$SIZE*($XVPR-$XVPL);
  &NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::pcgeti( 'QU - QUALITY FLAG', my $IQUA );
&NCAR::pcseti( 'QU - QUALITY FLAG', 0 );
&NCAR::pcseti( 'TE - TEXT EXTENT COMPUTATION FLAG', 1 );
  &NCAR::plchhq (.5,.5,$LABL,$SZFS,360.,0.);
&NCAR::pcgetr( 'DB - DISTANCE TO BOTTOM OF STRING', my $DBOS );
  &NCAR::plchhq (.5*($XVPL+$XVPR),$YVPT+$SZFS+$DBOS,$LABL,$SZFS,0.,0.);
&NCAR::pcseti( 'QU - QUALITY FLAG', $IQUA );
  &NCAR::set ($XVPL,$XVPR,$YVPB,$YVPT,$XWDL,$XWDR,$YWDB,$YWDT,$LNLG);
#
# Done.
#
}



sub bndary {;
&NCAR::plotit(     0,     0, 0 );
&NCAR::plotit( 32767,     0, 1 );
&NCAR::plotit( 32767, 32767, 1 );
&NCAR::plotit(     0, 32767, 1 );
&NCAR::plotit(     0,     0, 1 );
};

sub alog10 {
  return exp( $_[0] * log( 10 ) );      
}

sub log10 {
  return log( $_[0] ) / log( 10 );      
}

sub sign {
  my $s = -1;
  ( $_[1] >= 0 ) && ( $s = +1 );
  return $s * abs( $_[0] );
}

sub min {
return $_[0] <= $_[1] ? $_[0] : $_[1];
}

sub max {
return $_[0] >= $_[1] ? $_[0] : $_[1];
}


sub genara {
  my ( $a, $b, $id, $jd ) = @_;
  my $pi =  3.14159;
  my $twopi = 2. * $pi;
  my $eps = $pi / 6.;

  my $nn = int( ( $id + $jd ) / 10 );
  my $aa = 1.;
  my $di = $id - 4;
  my $dj = $jd - 4;
  while( 1 ) {
    for( my $k = 1; $k <= $nn; $k++ ) {
      my $ii = int( 3. + $di * rand() );
      my $jj = int( 3. + $dj * rand() );
      for( my $j = 1; $j <= $jd; $j++ ) {
        my $je = abs( $j - $jj );
        for( my $i = 1; $i <= $id; $i++ ) {
          my $ie = abs( $i - $ii );
          my $ee = max( $ie, $je );
          $a->[ $i - 1 ][ $j - 1 ] = ( $a->[ $i - 1 ][ $j - 1 ] || 0 ) 
                                     + $aa * exp( $ee * log( .8 ) );
        }
      }
    }
    
    last if( $aa != 1. );
    $aa = -1.;
  }

  for( my $j = 1; $j <= $jd; $j++ ) {
     my $jm1 = max( 1, $j - 1 );
     my $jp1 = min( $jd, $j + 1 );
     for( my $i = 1; $i <= $id; $i++ ) {
       my $im1 = max( 1, $i - 1 );
       my $ip1 = min( $id, $i + 1 );
       $b->[ $i - 1 ][ $j - 1 ] = 
       ( 4. * $a->[ $i - 1 ][ $j - 1 ] + 2. * 
         ( $a->[ $i - 1 ][ $jm1 - 1 ] + $a->[ $im1 - 1 ][ $j - 1 ] +
           $a->[ $ip1 - 1 ][ $j - 1 ] + $a->[ $i - 1 ][ $jp1 - 1 ] 
         ) +
         $a->[ $im1 - 1 ][ $jm1 - 1 ] + $a->[ $ip1 - 1 ][ $jm1 - 1 ] +
         $a->[ $im1 - 1 ][ $jp1 - 1 ] + $a->[ $ip1 - 1 ][ $jp1 - 1 ] 
       ) / 16.;
     }
  }
}

sub dfclrs {
  my ( $iwkid ) = @_;
  my $nclrs = 16;
  my @rgbv = ( 
     [  0.00 , 0.00 , 0.00 ],
     [  1.00 , 1.00 , 1.00 ],
     [  0.70 , 0.70 , 0.70 ],
     [  0.75 , 0.50 , 1.00 ],
     [  0.50 , 0.00 , 1.00 ],
     [  0.00 , 0.00 , 1.00 ],
     [  0.00 , 0.50 , 1.00 ],
     [  0.00 , 1.00 , 1.00 ],
     [  0.00 , 1.00 , 0.60 ],
     [  0.00 , 1.00 , 0.00 ],
     [  0.70 , 1.00 , 0.00 ],
     [  1.00 , 1.00 , 0.00 ],
     [  1.00 , 0.75 , 0.00 ],
     [  1.00 , 0.38 , 0.38 ],
     [  1.00 , 0.00 , 0.38 ],
     [  1.00 , 0.00 , 0.00 ],
  );
  for( my $i = 1; $i <= $nclrs; $i++ ) {
    &NCAR::gscr( $iwkid, $i - 1, @{ $rgbv[$i-1] } ); 
  }
}


sub drawcl {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
#
# This version of DRAWCL draws the polyline defined by the points
# ((XCS(I),YCS(I)),I=1,NCS) if and only if none of the area identifiers
# for the area containing the polyline are negative.  The dash package
# routine CURVED is called to do the drawing.
#
#
# Turn on drawing.
#
  my $IDR=1;
#
# If any area identifier is negative, turn off drawing.
#
  for my $I ( 1 .. $NAI ) {
    if( at( $IAI, $I - 1 ) < 0 ) {
      $IDR = 0;
    }
  }
#
# If drawing is turned on, draw the polyline.
#
  if( $IDR != 0 ) {
    &NCAR::curved( $XCS,$YCS,$NCS);
  }
#
# Done.
}


sub shader {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
#
# This version of SHADER shades the polygon whose edge is defined by
# the points ((XCS(I),YCS(I)),I=1,NCS) if and only, relative to edge
# group 3, its area identifier is a 1.  The package SOFTFILL is used
# to do the shading.
#
#
# Define workspaces for the shading routine.
#
  my $DST = zeroes float, 1100;
  my $IND = zeroes long, 1200;
#
# Turn off shading.
#
  my $ISH=0;
#
# If the area identifier for group 3 is a 1, turn on shading.
#

  for my $I ( 1 .. $NAI ) {
    if( ( at( $IAG, $I - 1 ) == 3 ) && ( at( $IAI, $I - 1 ) == 3 ) ) { 
      $ISH=1;
    }
  }
#
# If shading is turned on, shade the area.  The last point of the
# edge is redundant and may be omitted.
#
  if( $ISH != 0 ) {
&NCAR::sfseti( 'ANGLE', 45 );
&NCAR::sfsetr( 'SPACING', .006 );
    &NCAR::sfwrld ($XCS,$YCS,$NCS-1,$DST,1100,$IND,1200);
&NCAR::sfseti( 'ANGLE', 135 );
    &NCAR::sfnorm ($XCS,$YCS,$NCS-1,$DST,1100,$IND,1200);
  }
#
# Done.
#
}


1;
