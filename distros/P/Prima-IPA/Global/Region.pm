# $Id$
use strict;

package Prima::IPA::Region;

use constant DATA   => 0;
use constant LEFT   => 1;
use constant BOTTOM => 2;
use constant WIDTH  => 3;
use constant HEIGHT => 4;

sub contour2region
{
   my $cont = $_[0];
   my $i;
   my $cnt = scalar @$cont;
   warn("contour2region: too few points in contour\n"), return ([],0) if $cnt < 4;

   if ( $$cont[0] == $$cont[-2] && $$cont[1] == $$cont[-1]) {
      $cnt -= 2;
      pop @$cont;
      pop @$cont;
   }

   # filter horizontal vertexes 
   my @pp = ( $$cont[0], $$cont[1]);
   # zis:  /--/  trans: \--/
   # trans hlines must contain odd number of points, zis - even
   my ( @zis, @trans);

   my $ldir=0;
   my $dir=0;
   my $last;
   my @temp;

   #defining the last slope direction
   for ( $i=$cnt-2; $i >= 0; $i-=2) {
      my ( $x, $y) = ( $$cont[$i], $$cont[$i+1]);
      if ( $pp[1] == $y) {
         push @temp, $x, $y;
         @pp = ($x, $y);
      } else {
         $dir = ( $pp[1] < $y) ? -1 : 1;
         last;
      }
   }
   $last = $i;
   $ldir = $dir;

   @pp = ( $$cont[0], $$cont[1]);

   for ( $i=2; $i <= $last; $i+=2) {
      my ( $x, $y) = ( $$cont[$i], $$cont[$i+1]);
      if ( $pp[1] == $y) {
         push @temp, @pp;
      } else {
         my $nd = ( $pp[1] < $y) ? 1 : -1;
         push @temp, @pp if scalar(@temp) || $nd != $dir;
         push @{( $nd == $dir) ? \@trans : \@zis}, [@temp] if scalar @temp;
         @temp = ();
         $dir = $nd;
      }
      @pp = ($x, $y);
   }

   $i = ( $last + 2 >= $cnt) ? 0 : $last + 2;
   push @temp, @pp if scalar(@temp) || $dir != $ldir;
   push @{( $dir == $ldir) ? \@trans : \@zis}, [@temp] if scalar @temp;
   push @$_, $$_[0], $$_[1] for @trans; # make even

   # filling y-hash
   my %y;
   for ( $i=0; $i < $cnt; $i+=2) {
      push @{$y{$$cont[$i+1]}}, $$cont[$i];
   }
   for ( @trans, @zis) {
      my ( $a, $c) = ( $_, scalar @$_);
      for ( $i = 0; $i < $c; $i+=2) {
         push @{$y{$$a[$i+1]}}, $$a[$i];
      }
   }

   my @rgn;
   my $min = 100000000;
   for ( sort {$a <=> $b} keys %y) {
      $min = $_ if $min > $_;
      my @s = sort { $a <=> $b} @{$y{$_}};
      my ( $i, $c) = ( 0, scalar @s);
      my @ret = @s[0,1];
      for ( $i = 2; $i < $c; $i+=2) {
         if ( $ret[-1]+1 >= $s[$i]) {
            $ret[-1] = $s[$i+1];
         } else {
            push @ret, @s[$i, $i+1];  
         }
      }
      warn ("contour2region: $_ inconsistency (even points in contour)\n") if $c % 2;
      push @rgn, \@ret;
   }
   return calc_extents([ \@rgn, 0, $min, 0, 0]); 
}

sub scanlines2region
{
   my $sc = $_[0];
   my $c = int(scalar ( @$sc) / 3) * 3;
   my $i;
   my %y;
   for ( $i = 0; $i < $c; $i+=3) {
      push @{$y{$$sc[$i+2]}}, $$sc[$i], $$sc[$i+1];
   }
   my @rgn;
   my $min = 100000000;
   for ( sort { $a <=> $b } keys %y) {
      $min = $_ if $min > $_;
      push @rgn, [ sort { $a <=> $b } @{$y{$_}}];
      my $z = $rgn[-1];
   }
   return calc_extents([ \@rgn, 0, $min, 0, 0]); 
}

sub draw
{
   my ( $drawable, $region, $dx, $dy) = @_;
   my $i;
   $dx = 0 unless $dx;
   $dy = 0 unless $dy;
   $dy += $$region[2];
   for ( @{$$region[0]}) {
      my ( $a, $c) = ( $_, scalar @$_);
      for ( $i = 0; $i < $c; $i += 2) {
         $drawable-> line( $$a[$i]+$dx, $dy, $$a[$i+1]+$dx, $dy);
      }
      $dy++;
   }
}

sub area
{
   my $region = $_[0];
   my $i;
   my $area = 0;
   for ( @{$$region[0]}) {
      my ( $a, $c) = ( $_, scalar @$_);
      for ( $i = 0; $i < $c; $i += 2) {
         $area += $$a[$i+1] - $$a[$i] + 1;
      }
   }
   return $area;
}

sub plot
{
   my ( $image, $region, $dx, $dy, $color) = @_;
   my $i;
   $dx = 0 unless $dx;
   $dy = 0 unless $dy;
   $color = 0xffffff unless defined $color;
   $dy += $$region[2];
   my @triplets;
   for ( @{$$region[0]}) {
      my ( $a, $c) = ( $_, scalar @$_);
      for ( $i = 0; $i < $c; $i += 2) {
         push @triplets, $$a[$i]+$dx, $$a[$i+1]+$dx, $dy;
      }
      $dy++;
   }
   Prima::IPA::Global::hlines( $image, 0, 0, \@triplets, $color);
}

sub outline
{
   my ( $drawable, $region, $dx, $dy) = @_;
   my $i;
   $dx = 0 unless $dx;
   $dy = 0 unless $dy;
   $dy += $$region[2];
   for ( @{$$region[0]}) {
      my ( $a, $c) = ( $_, scalar @$_);
      for ( $i = 0; $i < $c; $i += 2) {
         $drawable-> line( $$a[$i]+$dx, $dy, $$a[$i]+$dx, $dy);
         $drawable-> line( $$a[$i+1]+$dx, $dy, $$a[$i+1]+$dx, $dy);
      }
      $dy++;
   }
}

sub combine
{
   my ( $src_rgn, $dst_rgn, $rop) = @_;
   
   if ( defined $rop) {
      if ( $rop eq 'and') {
         $rop = 0;
      } elsif ( $rop eq 'or') {
         $rop = 1;
      } elsif ( $rop eq 'xor') {
         $rop = 2;
      } else {
         warn "combine_regions: unsupported rop '$rop'\n";
         return [], 0;
      }
   } else {
      $rop = 0;
   }

   if ( $rop == 0) { # fast 'and' check
      if ( $$src_rgn[BOTTOM] + $$src_rgn[HEIGHT] < $$dst_rgn[BOTTOM] ||
           $$src_rgn[LEFT]   + $$src_rgn[WIDTH]  < $$dst_rgn[LEFT]   ||
           $$src_rgn[BOTTOM] > $$dst_rgn[BOTTOM] + $$dst_rgn[HEIGHT] ||
           $$src_rgn[LEFT]   > $$dst_rgn[LEFT]   + $$dst_rgn[WIDTH]) {
           return [[], 0,0,0,0];
      }
   }

   my ( $src, $src_offs, $dst, $dst_offs) = ( $$src_rgn[DATA], $$src_rgn[BOTTOM], $$dst_rgn[DATA], $$dst_rgn[BOTTOM]);

   my $miny = ( $src_offs < $dst_offs) ? $src_offs : $dst_offs;
   my ( $csrc, $cdst) = ( scalar @$src, scalar @$dst);
   my ( $ysrc, $ydst) = ( $csrc + $src_offs, $cdst + $dst_offs);
   my $maxy = ( $ysrc > $ydst) ? $ysrc : $ydst;
   my $i;
   my @rx;
   my ( $srcix, $dstix) = ( 0,0);
   for ( $i = $miny; $i < $maxy; $i++) {
      if ( $i >= $src_offs && $i < $ysrc) {
         if ( $i >= $dst_offs && $i < $ydst) {
            my ( $i, $x, $c, %a1, %a2);
            $c = scalar @{$x = $$src[$srcix]};
            for ( $i = 0; $i < $c; $i+=2) {
               $a1{$_} = 1 for $$x[$i] .. $$x[$i+1];
            }
            $c = scalar @{$x = $$dst[$dstix]};
            for ( $i = 0; $i < $c; $i+=2) {
               $a2{$_} = 1 for $$x[$i] .. $$x[$i+1];
            }
            my @ret;
            if ( $rop == 0) { # and
               for ( keys %a1) {
                  push @ret, $_ if exists $a2{$_};
               }
            } elsif ( $rop == 1)  { # or
               @ret = (keys(%a1), keys(%a2));
            } else { # xor
               for ( keys %a1) { push @ret, $_ unless exists $a2{$_}; }
               for ( keys %a2) { push @ret, $_ unless exists $a1{$_}; }
            }
            $c = scalar @ret;
            @ret = sort { $a <=> $b} @ret;
            if ( $c = scalar @ret) {
               my @rle = ( $ret[0], $ret[0]);
               for ( $i = 1; $i < $c; $i++) {
                  if ( $rle[-1] + 1 == $ret[$i]) {
                     $rle[-1] = $ret[$i];
                  } elsif ( $ret[$i] > $rle[-1]) {
                     push @rle, $ret[$i], $ret[$i];
                  }
               }
               push @rx, \@rle;
            } else {
               push @rx, [];
            }
            $dstix++;
         } else {
            push @rx, $rop ? $$src[$srcix] : [];
         }
         $srcix++;
      } elsif ( $i >= $dst_offs && $i < $ydst) {
         push @rx, $rop ? $$dst[$dstix] : [];
         $dstix++;
      } else {
         push @rx, [];
      }
   }

   $dst = scalar @rx;
   my $found;
   # trimming
   for ( $i = $dst-1; $i >= 0; $i--) {
      last if scalar @{$rx[$i]};
      $found = $i; 
   }
   if ( defined $found) {
      $found ? splice( @rx, $found-1) : (@rx=());
      $dst = scalar @rx;
   }
   $found = undef;
   for ( $i = 0; $i < $dst; $i++) {
      last if scalar @{$rx[$i]};
      $found = $i; 
   }
   if ( defined $found) {
      splice( @rx, 0, $found+1);
      $miny += $found+1;
   }
   
   return calc_extents([ \@rx, 0, $miny, 0, 0]);
}

sub calc_extents
{
   my ( $rgn, $x, $y, $w, $h) = @{$_[0]};
   $h = scalar @$rgn;
   return [[], 0, 0, 0, 0] unless $h;
   
   my $i;
   my $x2;
   for ( @$rgn) {
      my ( $a, $c) = ( $_, scalar @$_);
      $x2 = $x = $$a[0] if !defined $x2 && $c;
      for ( $i = 0; $i < $c; $i += 2) {
         $x  = $$a[$i]   if $x  > $$a[$i];
         $x2 = $$a[$i+1] if $x2 < $$a[$i+1];
      }
   }
   return [[], 0, 0, 0, 0] unless defined $x2;
   return [ $rgn, $x, $y, $x2 - $x + 1, $h];
}

# shallow copy
sub alias { [@{$_[0]}]; }

# deep copy
sub copy
{
   my ( $rgn, $x, $y, $w, $h) = @{$_[0]};
   my @cp;
   for ( @$rgn) { push @cp, [ @$_]; }
   return [ \@cp, $x, $y, $w, $h];
}

# relative offset
sub move
{
   my ( $rgn, $dx, $dy) = @_;
   $rgn->[LEFT]   += $dx;
   $rgn->[BOTTOM] += $dy;
   if ( $dx != 0) {
      for ( @{$$rgn[0]}) { $_ += $dx for @$_; }
   }
   return $rgn;
}

1;

__END__

=pod

=head1 NAME

Prima::IPA::Region - region data structures

=head1 DESCRIPTION

A contour is a 8-connected point set that is returned by
Prima::IPA::Global::identify_contours function. A region is a set of horizontal lines,
describing an 2D area. The contour2region function converts contour output of
C<Prima::IPA::Global::identify_contours> and C<Prima::IPA::Global::identify_scanlines> to a
region and returns the region array and its starting y-position.  The contour
has to contain no less that 2 unique points.  The ultimate requirement is that
all points have to be 8-connected and the contour contains no holes.

Example: 

          3.3                3.3-3.3
      2.2     4.2   ->    2.2-------4.2
  1.1 2.1 3.1 4.1      1.1----------4.1

      contour                region

The module provides various manipluation routines for these regions.


=head1 API

=over

=item contour2region CONTOUR

Converts output of C<Prima::IPA::Global::identify_contours> to a region. 

=item scanlines2region CONTOUR

Converts output of C<Prima::IPA::Global::identify_scanlines> to a region. 

=item draw DRAWABLE, REGION, OFFSET_X, OFFSET_Y

Plots REGION onto DRAWABLE with OFFSET_X and OFFSET_Y

=item plot DRAWABLE, REGION, OFFSET_X, OFFSET_Y

Same as C<draw> but optimized for speed, and DRAWABLE must be an image.

=item outline DRAWABLE, REGION, OFFSET_X, OFFSET_Y

Draws outline of REGION onto DRAWABLE with OFFSET_X and OFFSET_Y

=item combine REGION_1, REGION_2, OP = 'and'

Combines two regions, REGION_1 and REGION_2, with logic operation,
which can be one of 'and', 'or', and 'xor' strings, and returns the 
result.

=item calc_extents REGION

Recalculates extensions of REGION and returns adjusted L<alias> of REGION.

=item alias REGION

Returns shallow copy of REGION

=item copy REGION

Returns deep copy of REGION

=item move REGION, OFFSET_X, OFFSET_Y

Shifts REGION by OFFSET_X and OFFSET_Y

=item area REGION

Returns area occupied by a region

=back

=head1 SEE ALSO

L<Prima::IPA::Global/identify_contours>, L<Prima::IPA::Global/identify_scanlines>

=cut
