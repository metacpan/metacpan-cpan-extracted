#!/usr/bin/perl -w
use strict;
use blib;
use Numeric::LL_Array qw( access_d packId_d packId_star_d d0_1 d0_m1
			  d2d1_plus_assign d2d1_assign
			  dd2d2_sproduct d2d1_mult_assign );

die <<EOD unless @ARGV==3 or @ARGV==4;
Usage: $0 width+2 height+2 number_of_2x_relaxations [test]
  Runs Chebyshev_relaxation steps for Dirichlet problem for Poisson equation.
EOD

sub typeout ($$$) {
  my ($p, $w, $h) = @_;
  my @a = access_d $$p, 0, 2, [1, $w, $w, $h];
  print "@$_\n" for @a;
}

my ($w, $h, $steps, $test) = (shift, shift, shift, shift||0);	# 10 means: 8, plus 2 for boundary
my ($tile_w, $tile_h) = map int($_/2-1), $w, $h; # Will fill $tile x $tile zone

my $sec = pack packId_star_d, 0..$w+$h+10;

my ($eigth, $quarter, $half) = map pack(packId_d, $_), 0.125, 0.25, 0.5;
my $zero = my $p = pack packId_d, 0;
$p x= ($w * $h);		# Main Playground
my $tmp = $p;			# Temporary var
my $fmt = [1, $w, $w, $h];

d0_1 $p, $w+1, 2, [1, $tile_w, $w, $tile_h];
# typeout \$p, $w, $h;

d2d1_plus_assign $p, $p, $w+1, $w+2, 2,
  [1,$tile_w, $w, $tile_h], [1,$tile_w-1, $w, $tile_h];
d2d1_plus_assign $p, $p, $w+1, 2*$w+1, 2,
  [1,$tile_w, $w, $tile_h], [1,$tile_w, $w, $tile_h-1];

if (0) {	# On boundary, initialize to a linear function
  d2d1_assign $sec, $p, $w+$h, 0, 1,
    [-1,$w], [1,$w];
  d2d1_assign $sec, $p, $w+1, $w*($h-1), 1,
    [-1,$w], [1,$w];
  d2d1_assign $sec, $p, $w+$h, 0, 1,
    [-1,$w], [$w,$h];
  d2d1_assign $sec, $p, 1+$h, $h-1, 1,
    [-1,$w], [$w,$h];
}
typeout \$p, $w, $h if $w*$h < 1000;	# In a quadrant, initialize to x * y

sub Poisson_4__4 ($$$$) {	# Spectrum normalized 4 --> -4
  my ($s_r, $t_r, $w, $h) = @_;		# 2 references to playgrounds
  d2d1_assign $$s_r, $$t_r, 0, 0, 2,	# Exact copy
    [1,$w, $w, $h], [1,$w, $w, $h];
  # Add shift by (-1,1): take shift by (0,1), and add to shift by (1,0)
  d2d1_plus_assign $$t_r, $$t_r, $w, 1, 2,  # correct in $w-1 x $h-1 rectangle
    [1,$w-1, $w, $h-1], [1,$w-1, $w, $h-1]; # starting at (1,0)
  # Add shift by (1,1): take shift by (0,1), and add to shift by (1,0)
  d2d1_plus_assign $$t_r, $$t_r, $w+2, 1, 2,
    [1,$w-2, $w, $h-2], [1,$w-2, $w, $h-2];
}	# The result is $w-2 x $h-2 starting at offset (1,0)


sub Poisson_1_0 ($$$$) {	# Spectrum normalized 1 --> 0
  &Poisson_4__4;		# Second argument: temporary playground
  my ($t_r, $tmp_r, $w, $h) = @_;		# references to playgrounds
  dd2d2_sproduct($quarter, $$tmp_r, $$t_r, 0, 1, $w+1, 2,
		 [0,$w-2, 0, $h-2], [1,$w-2, $w, $h-2], [1,$w-2, $w, $h-2]);
  d2d1_mult_assign($half, $$t_r, 0, $w+1, 2,
		 [0,$w-2, 0, $h-2], [1,$w-2, $w, $h-2]);
}

# Need $w > 2, $h > 2
sub Poisson_1_r ($$$$$) {	# Spectrum normalized 1 --> ? so that $r |--> 0
  &Poisson_4__4;		# Second argument: temporary playground
  my ($t_r, $tmp_r, $w, $h, $r) = @_;		# references to playgrounds
  # Want a+b(4-8x) = 1 - x/r; so b = 1/8r; a = 1-4b = 1-1/(2r)
  my ($a, $b) = map pack(packId_d, $_), 1-1/(2*$r), 1/(8*$r);
  d2d1_mult_assign($a, $$t_r, 0, $w+1, 2,
		 [0,$w-2, 0, $h-2], [1,$w-2, $w, $h-2]);
  dd2d2_sproduct($b, $$tmp_r, $$t_r, 0, 1, $w+1, 2,
		 [0,$w-2, 0, $h-2], [1,$w-2, $w, $h-2], [1,$w-2, $w, $h-2]);
}

#   In the "checkerboard" [cb] patterns, we compess the rarified grid as this:
# *   *   *   *   *			* * * * *
#   *   *   *   *   *   ===>		* * * * *
# *   *   *   *   *			* * * * *
#   *   *   *   *   *   		* * * * *

# Need $w > 1, $h > 2
sub Poisson_4__4_cb ($$$$) {	# Spectrum normalized 4 --> -4
  my ($s_r, $t_r, $w, $h) = @_;		# references to playgrounds
  d2d1_assign $$s_r, $$t_r, 0, 0, 2,	# Exact copy
    [1,$w, $w, $h], [1,$w, $w, $h];
  #  off-diag terms of 5-point Laplace after compression:
  # at even rows: need add shift by (-1,-1), (0,-1), (-1,1), (0,1);
  # at odd  rows: need add shift by (0,-1),  (1,-1), (0,1),  (1,1);
  #   Instead we do: add shifts by (0,0), (1,0), (0,2), (1,2).
  # So at even rows: result is shifted by (-1,-1)
  #    at odd  rows: result is shifted by (0,-1)
  d2d1_plus_assign $$t_r, $$t_r, 1, 0, 2,	# Add shift by (1,0)
    [1,$w-1, $w, $h], [1,$w-1, $w, $h];
  d2d1_plus_assign $$t_r, $$t_r, 2*$w, 0, 2,	# Add shift by (0,2)
    [1,$w-1, $w, $h-2], [1,$w-1, $w, $h-2];
}  # The result is $w-1 x $h-2, but even and odd rows are shifted differently

# Need $w > 2, $h > 2
sub Poisson_1_r_cb ($$$$$) {	# Spectrum normalized 1 --> ? so that $r |--> 0
  &Poisson_4__4_cb;		# Second argument: temporary playground
  my ($t_r, $tmp_r, $w, $h, $r) = @_;		# references to playgrounds
  # Want a+b(4-8x) = 1 - x/r; so b = 1/8r; a = 1-4b = 1-1/(2r)
  my ($a, $b) = map pack(packId_d, $_), 1-1/(2*$r), 1/(8*$r);
  # When copying from $tmp_r, need to shift even/odd differently
  # (and multiply by `a' on non-boundary values only...)
  my $h2 = int(($h-3)/2);	# How many even rows to process: 2..$h-2
  if ($h2) {			# Copy from offset (0,1) to (1,2)
    d2d1_mult_assign($a, $$t_r, 0, 2*$w+1, 2,
		     [0,$w-1, 0, $h2], [1,$w-1, 2*$w, $h2]);
    dd2d2_sproduct($b, $$tmp_r, $$t_r, 0, $w, 2*$w+1, 2,
		   [0,$w-1, 0, $h2], [1,$w-1, 2*$w, $h2], [1,$w-1, 2*$w, $h2]);
  }
  $h2 = int(($h-1)/2);		# How many odd rows to process: 1..$h-2
  if ($h2) {			# Copy from offset (0,0) to (0,1)
    d2d1_mult_assign($a, $$t_r, 0, $w, 2,
		     [0,$w-1, 0, $h2], [1,$w-1, 2*$w, $h2]);
    dd2d2_sproduct($b, $$tmp_r, $$t_r, 0, 0, $w, 2,
		   [0,$w-1, 0, $h2], [1,$w-1, 2*$w, $h2], [1,$w-1, 2*$w, $h2]);
  }
} # Doesn't touch boundary: top, bottom, even rows on left, odd rows on right

sub norm ($$$$) {
  my ($p, $off, $d, $format) = @_;
  my $res = $zero;
  my $s_format = [@$format];
  $s_format->[2*$_] = 0 for 0..$d-1;
  dd2d2_sproduct $$p, $$p, $res, $off, $off, 0, $d, $format, $format, $s_format;
  sqrt unpack packId_d, $res;
}

# When upscaling to cb, need to know both sizes; better have consistent API...
# Need $w > 2, $h > 1;	coefficient is 4
sub downscale_to_cb_4 ($$$$$$$) {	# Target must has place for 1 extra row
  my ($s_r, $t_r, $w, $h, $nw, $nh, $cut_left) = @_;	# refs to playgrounds
#  my ($nw, $nh) = (int(($w-1)/2), $h - 1); # new height; cut width aggressively
  my $x_off = (!($w%2) and $cut_left) ? 1 : 0;
  d2d1_assign $$s_r, $$t_r, $x_off+1, 0, 2, # Exact copy of even/odd cols (0 etc)
    [2,$nw, $w, $h], [1,$nw, $nw, $h];
  # Add to yourselves with offset 0,1
  d2d1_plus_assign $$t_r, $$t_r, $nw, 0, 2,	# Add shift by (1,0)
    [1,$nw, $nw, $nh], [1,$nw, $nw, $nh];
  # Now need to add to even rows (0..end) offset $x_off, to odd $x_off+2
  # Both repeated with the next row
  my $nh2 = int(($nh + 1)/2);	# Number of even new rows
# Can't += inside t_r with right shift from left to right - would read new values
  d2d1_plus_assign $$s_r, $$t_r, $x_off, 0, 2,	# $nh >= 1 always
    [2,$nw, 2*$w, $nh2], [1,$nw, 2*$nw, $nh2];
  d2d1_plus_assign $$s_r, $$t_r, $x_off+$w, 0, 2,
    [2,$nw, 2*$w, $nh2], [1,$nw, 2*$nw, $nh2];
  if ($nh2 = $nh - $nh2) {		# Number of odd old rows
	# Again, do from source: target has no values at extreme right...
    d2d1_plus_assign $$s_r, $$t_r, $x_off+$w+2, $nw, 2, # Exact copy of even/odd cols (0 etc)
      [2,$nw, 2*$w, $nh2], [1,$nw, 2*$nw, $nh2];
    d2d1_plus_assign $$s_r, $$t_r, $x_off+2*$w+2, $nw, 2, # Exact copy of even/odd cols (0 etc)
      [2,$nw, 2*$w, $nh2], [1,$nw, 2*$nw, $nh2];
  }
}

if ($test eq 'test-down-to-cb') {
  for my $W (4,5,6,7) {
    for my $H (4,5) {
      for my $OFF (0,1) {
        my $p2 = $p;
        my ($nw, $nh) = (int(($W-1)/2), $H - 1); # new height; cut width aggressively
        d0_m1 $p2, 0, 2, [1, $W, $W, $H];
        d2d1_assign $p, $p2, 1+$w, 1+$W, 2, [1,$W-2,$w,$H-2], [1,$W-2,$W,$H-2];
        d0_m1 $tmp, 0, 2, [1, $w, $w, $h];
        downscale_to_cb_4(\$p2, \$tmp, $W, $H, $nw, $nh, $OFF);
        print "--- ($nw x $nh) <== $W x $H, cut_left=$OFF\n";
        typeout \$p2, $W, $H;
        typeout \$tmp, $nw, $nh;
      }
    }
  }
  exit;
}

#  . . . . . . . . . . . .
#   *   *   *   *   *
#  . . . . . . . . . . . .
#     *   *   *   *   *
#  . . . . . . . . . . . .
#   *   *   *   *   *
#  . . . . . . . . . . . .

# We do not change the boundary values (Dirichlet semantic)
# The remaining: interpolate between diagonally placed pairs
# ??? What to do with extra column/row?
sub upscale_from_cb_2 ($$$$$$$) {
  my ($s_r, $t_r, $nw, $nh, $w, $h, $cut_left) = @_;	# refs to playgrounds
# my ($nw, $nh) = (int(($w-1)/2), $h - 1); # new height; cut width aggressively
  my $x_off = (!($w%2) and $cut_left) ? 1 : 0;
  my $n_even_h = int(($nh+1)/2);
  my $n_even_h_down = int($nh/2); # Save to assign down
  my $n_odd_h = $nh - $n_even_h;
  my $n_odd_h_down = $n_odd_h - !($nh%2); # $nh even ==> last line is odd
  # It's safe to assign even rows down-right w.r.t. overwrite of right boundary
  d2d1_assign $$s_r, $$t_r, 0, $x_off+1+$w, 2,
    [1,$nw, 2*$nw, $n_even_h_down], [2,$nw, 2*$w, $n_even_h_down];
  # with down-left: left column is safe if $x_off
  d2d1_assign $$s_r, $$t_r, 1-$x_off, $w+2-$x_off, 2,
    [1,$nw-1+$x_off, 2*$nw, $n_even_h_down],
      [2,$nw-1+$x_off, 2*$w, $n_even_h_down];
  # Odd rows: safe to d-left; safe to d-right unless $x_off or $w is odd
  d2d1_assign $$s_r, $$t_r, $nw, $x_off+2*$w+1, 2,
    [1,$nw, 2*$nw, $n_odd_h_down], [2,$nw, 2*$w, $n_odd_h_down];
  my $unsafe_r = ($w%2 or $x_off);
  d2d1_assign $$s_r, $$t_r, $nw, $x_off+2*$w+2, 2,
    [1,$nw - $unsafe_r, 2*$nw, $n_odd_h_down], [2,$nw - $unsafe_r, 2*$w, $n_odd_h_down];
  d2d1_assign $$s_r, $$t_r, 2*$nw-1, 2*$w-2, 1,	# Up-right on right column
    [2*$nw, $n_odd_h], [2*$w, $n_odd_h] unless $unsafe_r;
  # Up-left: safe on 1st column of even rows (except 0)
  d2d1_assign $$s_r, $$t_r, 2*$nw, 2*$w+1, 1,
    [2*$nw, $n_even_h - 1], [2*$w, $n_even_h - 1] if $x_off;

  # Up-right: safe on even rows (except 0)
  d2d1_plus_assign $$s_r, $$t_r, 2*$nw, 2*$w+1+$x_off, 2,
    [1,$nw, 2*$nw, $n_even_h - 1], [2,$nw, 2*$w, $n_even_h - 1];
  # Up-right on odd rows: when safe on the last column, already done!
  d2d1_plus_assign $$s_r, $$t_r, $nw, $w+2+$x_off, 2,
    [1,$nw-1, 2*$nw, $n_odd_h], [2, $nw-1, 2*$w, $n_odd_h];
  # Up-left: already done (if safe) on 1st column of even rows
  d2d1_plus_assign $$s_r, $$t_r, 2*$nw+1, 2*$w+2+$x_off, 2,
    [1,$nw, 2*$nw, $n_even_h - 1], [2,$nw - 1, 2*$w, $n_even_h - 1];

  d2d1_plus_assign $$s_r, $$t_r, $nw, $w+1+$x_off, 2, # Uleft: safe on odd rows
    [1,$nw, 2*$nw, $n_odd_h], [2, $nw, 2*$w, $n_odd_h];
  # Now should be correct except on "extra" column
  unless ($w%2) {		# Even, hence have extra column
    my $to_s = $x_off ? 1 : $w - 2;
    my $from_s = $x_off ? 0 : $w - 1;
    # odd rows are approximated from below, even from above; Dirichlet semantic
  dd2d2_sproduct $half, $$t_r, $$t_r, 0, $w+$from_s, $w+$to_s, 2,	# Up-right on right column
    [0, $n_odd_h, 0, 2], [2*$w, $n_odd_h, -$w, 2], [2*$w, $n_odd_h, 0, 2];
  dd2d2_sproduct $half, $$t_r, $$t_r, 0, 2*$w+$from_s, 2*$w+$to_s, 2,	# Up-right on right column
    [0, $n_odd_h_down, 0, 2], [2*$w, $n_odd_h_down,  $w, 2], [2*$w, $n_odd_h_down, 0, 2];
  }
}

if ($test eq 'test-up-from-cb') {
  for my $W (4,5,6,7) {
    for my $H (4,5) {
      for my $OFF (0,1) {
        my $p2 = $p;
        my ($nw, $nh) = (int(($W-1)/2), $H - 1); # new height; cut width aggressively
        d2d1_assign $p, $p2, 1+$w, 0, 2, [1,$nw,$w,$nh], [1,$nw,$nw,$nh];
        d0_m1 $tmp, 0, 2, [1, $w, $w, $h];
        upscale_from_cb_2(\$p2, \$tmp, $nw, $nh, $W, $H, $OFF);
        print "--- ($nw x $nh) ==> $W x $H, cut_left=$OFF\n";
        typeout \$tmp, $W, $H;
      }
    }
  }
  exit;
}

#Poisson_1_r_cb \$p, \$tmp, $w, $h, 1;
#typeout \$p, $w, $h;

#d0_m1 $tmp, 0, 2, [1, int(($w-1)/2) x 2, $h-1];
#downscale_to_cb_4 \$p, \$tmp, $w, $h, 0;
#typeout \$tmp, int(($w-1)/2), $h-1;

# *   *   *   *   *		... "o"s are with cut-bottom ($cut_top == 0)
#   * o * o * o * o *
# * . *   *   *   *		starting at ".": cut-top
#   * o * o * o * o *

# Need $w > 1, $h > 2		($nw, $nh are for sparser grid)
sub downscale_from_cb_4 ($$$$$$$) {	# Target must has place for 1 extra row
  my ($s_r, $t_r, $w, $h, $nw, $nh, $cut_top) = @_;	# refs to playgrounds
#  my ($nh, $nw) = (int(($h-1)/2), $w - 1); # new height; cut height aggressively
  my $ini_off = (!($h%2) and $cut_top) ? $w : 1;	# pre-old (1,1) or (2,0)
  my $move_dl = (!($h%2) and $cut_top) ? $w : $w-1;
  d2d1_assign $$s_r, $$t_r, $ini_off, 0, 2, # Exact copy of even/odd cols (0 etc)
    [1,$nw, 2*$w, $nh], [1,$nw, $nw, $nh];
  d2d1_plus_assign $$s_r, $$t_r, $ini_off+$move_dl, 0, 2,
    [1,$nw, 2*$w, $nh], [1,$nw, $nw, $nh];
  d2d1_plus_assign $$s_r, $$t_r, $ini_off+$move_dl+1, 0, 2,
    [1,$nw, 2*$w, $nh], [1,$nw, $nw, $nh];
  d2d1_plus_assign $$s_r, $$t_r, $ini_off+2*$w, 0, 2,
    [1,$nw, 2*$w, $nh], [1,$nw, $nw, $nh];
}

if ($test eq 'test-down-from-cb') {
  for my $W (4,5) {
    for my $H (4,5,6,7) {
      for my $OFF (0,1) {
        my $p2 = $p;
        my ($nh, $nw) = (int(($H-1)/2), $W - 1); # cut height aggressively
        d0_m1 $p2, 0, 2, [1, $W, $W, $H];
        d2d1_assign $p, $p2, 1+$w, 1+$W, 2, [1,$W-2,$w,$H-2], [1,$W-2,$W,$H-2];
        d0_m1 $tmp, 0, 2, [1, $w, $w, $h];
        downscale_from_cb_4(\$p2, \$tmp, $W, $H, $nw, $nh, $OFF);
        print "--- ($nw x $nh) <== $W x $H, cut_top=$OFF\n";
        typeout \$p2, $W, $H;
        typeout \$tmp, $nw, $nh;
      }
    }
  }
  exit;
}

# The semantic of propagation of boundary condition: interpret b f + c f' = d
# as f(c/b) = d/b; this can be recalculated into different grids.
# ==> Neumann condition (b=0) is invariant w.r.t. translations of the grid...

# *   *   *   *   *		... this is with cut-bottom ($cut_top == 0)
#   * o * o * o * o *		- how to calculate on the leftmost?
# *   *   *   *   *
#   *   *   *   *   *		- $h even, and cut-bottom

# Assume that the semantic of extension is of Dirichlet condition:
# We already know the values at boundary, so do not want to assign them
# Thus on the second *-column, we take interpolation between one "o"-
# and two "*"-values

# 		($nw, $nh are for sparser grid)
sub upscale_to_cb_2 ($$$$$$$) {
  my ($s_r, $t_r, $nw, $nh, $w, $h, $cut_top) = @_;	# refs to playgrounds
  my ($off_u, $off_l, $off_r, $off_d);		# up/left/right/down
  my ($keep_u, $keep_l, $keep_r, $keep_d); # ?moving-to-X overwrites boundary?
  if (!($h%2) and $cut_top) {
    ($off_u, $off_l, $off_r, $off_d, $keep_u) = ($w, 2*$w, 2*$w+1, 3*$w, 0);
  } else {
    ($off_u, $off_l, $off_r, $off_d, $keep_u) = (1, $w, $w+1, 2*$w+1, 1);
  }				# even and cut-bottom: "empty" row on bottom
  ($keep_l, $keep_r, $keep_d) = (!$keep_u, $keep_u, ($h%2) || $cut_top);

  if ($nh - $keep_d) {
    d2d1_assign $$s_r, $$t_r, 0, $off_d, 2,
      [1, $nw, $nw, $nh - $keep_d], [1, $nw, 2*$w, $nh - $keep_d];
  }
  d2d1_plus_assign $$s_r, $$t_r, $nw, $off_u + 2*$w, 2,
    [1, $nw, $nw, $nh - 1], [1,$nw, 2*$w, $nh - 1] if $nh > 1;
  unless ($keep_u) {
    d2d1_assign $$s_r, $$t_r, 0, $off_u, 1, [1, $nw], [1,$nw];
    # Now calculate contribution of Dirichlet data
    dd2d2_sproduct $half, $$t_r, $$t_r, 0, 0, $off_u, 1,
      [0,$nw], [1,$nw], [1,$nw];
    dd2d2_sproduct $half, $$t_r, $$t_r, 0, 1, $off_u, 1,
      [0,$nw], [1,$nw], [1,$nw];
  }
  unless ($keep_d) {    # Calculate contribution of Dirichlet data
    dd2d2_sproduct $half, $$t_r, $$t_r, 0, ($h-1)*$w, ($h-2)*$w + 1, 1,
      [0,$nw], [1,$nw], [1,$nw];
    dd2d2_sproduct $half, $$t_r, $$t_r, 0, ($h-1)*$w + 1, ($h-2)*$w + 1, 1,
      [0,$nw], [1,$nw], [1,$nw];
  }

  if ($nw - $keep_r) {
    d2d1_assign $$s_r, $$t_r, 0, $off_r, 2,
      [1, $nw - $keep_r, $nw, $nh], [1, $nw - $keep_r, 2*$w, $nh];
  }
  d2d1_plus_assign $$s_r, $$t_r, 1, $off_l + 1, 2,
    [1, $nw - 1, $nw, $nh], [1, $nw - 1, 2*$w, $nh] if $nw > 1;
  unless ($keep_l) {
    d2d1_assign $$s_r, $$t_r, 0, $off_l, 1, [$nw, $nh], [2*$w, $nh];
    # Now calculate contribution of Dirichlet data
    dd2d2_sproduct $half, $$t_r, $$t_r, 0, 0, $off_l, 1,
      [0,$nh], [2*$w, $nh], [2*$w, $nh];
    dd2d2_sproduct $half, $$t_r, $$t_r, 0, 2*$w, $off_l, 1,
      [0,$nh], [2*$w, $nh], [2*$w, $nh];
  }
  unless ($keep_r) {    # Calculate contribution of Dirichlet data
    dd2d2_sproduct $half, $$t_r, $$t_r, 0, 2*$w-1, 3*$w-1, 1,
      [0,$nh], [2*$w, $nh], [2*$w, $nh];
    dd2d2_sproduct $half, $$t_r, $$t_r, 0, 4*$w-1, 3*$w-1, 1,
      [0,$nh], [2*$w, $nh], [2*$w, $nh];
  }
}

if ($test eq 'test-up-to-cb') {
  for my $W (4,5) {
    for my $H (5,6,7,8) {
      for my $OFF (0,1) {
        my $p2 = $p;
        my ($nh, $nw) = (int(($H-1)/2), $W - 1); # cut height aggressively
        d2d1_assign $p, $p2, 1+$w, 0, 2, [1,$nw,$w,$nh], [1,$nw,$nw,$nh];
        d0_m1 $tmp, 0, 2, [1, $W, $W, $H];
        upscale_to_cb_2(\$p2, \$tmp, $nw, $nh, $W, $H, $OFF);
        print "--- ($nw x $nh) ==> $W x $H, cut_top=$OFF\n";
        typeout \$p2, $nw, $nh;
        typeout \$tmp, $W, $H;
      }
    }
  }
  exit;
}

#downscale_from_cb_4 \$p, \$tmp, $w, $h, 0;
#typeout \$tmp, $w-1, int(($h-1)/2);

sub permute3 ($);
sub permute3 ($) {	# known to behave well (is mixing) for 3^n
  my $n = shift;
  return [0..$n-1] if $n <= 2;
  my $n1 = int($n/3);
  my $p = permute3($n1);
  my $r = [];
  for my $k (0 .. $n1-1) {
    my $pk = $p->[$k];
    push @$r, $pk, 2*$n1 - 1 - $pk, $n - 1 - $pk;
  }
  my $n2 = $n % 3;     # $n2 elements 2 $n1 , etc not included; tackle at end
  push @$r, 2*$n1..(2*$n1+$n2-1);
  $r
}		# Experiments show it is good for "many" n

# my $p5 = permute3(5); print "<<@$p5>>\n";
# my $p16 = permute3(16); print "<<@$p16>>\n";

# Min wavenumber is 1/2(W-1), 1/2(H-1), max is (1,0).
# So min normalized eigenvalue is (2-cos(pi/(w-1))-cos(pi/(h-1)))/4
# approx. pi^2/8*(1/($w-1)^2 + 1/($h-1)^2)

# Chebyshev poly Tn takes value 2 at cosh(1.32/n), approx 1 + 1.32^2/2n^2;
# so one can get below 1/2 on the interval [1.74/4n^2, 1].  So if the minimal
# eigenvalue is a, n=1.32/2sqrt(a) is good.
# One gets sqrt(2)/pi (w-1)(h-1)/sqrt((w-1)^2 + (h-1)^2).

my $pi = 4*atan2(1,1);
# Asymptotic approximation; later we overwrite this (it is too optimistic!):
# one should use 2-2cos x instead of x^2

# Minimizing the guarantied error of well-permuted Chebyshev: one
# step error is n, with decrease 1/cosh(n eps) from the previous step.
# This leads to minimization of x/(1-1/cosh(x)), which is at x0=1.5055344, with
# cosh(x0) = 2.36423.

# The speed of convergence is governed by log(cosh(X))/X, which increases to 1.
# At x0 it is about 57%...

sub Chebyshev_roots ($) {	# With decrease 2
  my $min_eigen = shift;
  my $N = 1 + int(1.32/2/sqrt($min_eigen));
  my $P = permute3($N);
  my $d = $pi/$N;
  print "N=$N,   eigen=$min_eigen..1;    <<@$P>>\n" if $test eq 'test-perm';

  $_ = cos(($_ + 0.5)*$d)	  for @$P; # map to zeros of Tn, in [-1,1]
  $_ = 1-(1-$min_eigen)*(1+$_)/2  for @$P; # map -1 to 1, 1 to $min_eigen
  $P
}

sub min_eigen ($$$) {	# of Laplace with Dirichlet; max is normalized to 1
  my ($w, $h, $is_cb, $c) = (shift, shift, shift, 1);
  $c = 2 if $is_cb;
  my ($x,$y) = ($pi/($c*$w-1), $pi/($h-1));
  $c/4*(2 - cos($x) - cos($y));
}

sub relax_Chebyshev ($$$$$$$) {
  my ($p, $tmp, $w, $h, $P, $is_cb, $steps) = @_;
  if ($is_cb) {
    for my $iter (1..$steps) {
      for my $zero (@$P) {
	Poisson_1_r_cb $p, $tmp, $w, $h, $zero;
      }
    }
  } else {
    for my $iter (1..$steps) {
      for my $zero (@$P) {
	Poisson_1_r $p, $tmp, $w, $h, $zero;
      }
    }
  }
}

my $min_eigen_nocb    = $pi**2/8 * (1/($w-1)**2   + 1/($h-1)**2);
my $min_eigen         = $pi**2/4 * (1/(2*$w-1)**2 + 1/($h-1)**2);
my $P = Chebyshev_roots($min_eigen);
my $N = @$P;

print "N=$N,   eigen=$min_eigen..1;    <<@$P>>\n" if $test eq 'test-perm';

my $expect = 1 + $min_eigen * 2/(1-$min_eigen); # Rescale back to [-1,1]
# a+1/a = 2 $expect; or a = $expect + sqrt($expect^2 - 1)
$expect = $N*log($expect + sqrt($expect**2 - 1));	# $N * inv cosh
$expect = (exp($expect) + exp(-$expect))/2;	# cosh

my $do_cb = ($test =~ s/-cb//);
if ($test eq 'test-relax') {
  print "expected relaxation = $expect\nzeros <<@$P>>\n";

  # Just in case, calculate actual eigenvalues of Dirichlet problem
  my($min, $max, $relax, $relax1) = (1e100, 0, 1e100, 1e100);
  for my $hor (1.. ($do_cb ? 2 : 1)*$w-2) {
    for my $vert (1..$h-2) {
      my $eigen;
      if ($do_cb) {		# XXXX Not all of these are distinct 
        $eigen = 1 - cos($pi*$hor/(2*$w-1)) * cos($pi*$vert/($h-1));
        $eigen /= 2;		# Normalize to 1 at Nyquist
      } else {
        $eigen = 1 - cos($pi*$hor/($w-1)) - cos($pi*$vert/($h-1));
        $eigen /= 4;		# Normalize to 1 at Nyquist
      }
      $min = $eigen  if $eigen < $min;
      $max = $eigen  if $eigen > $max;
      my $val = 1;
      $val *= 1 - $eigen/$P->[$_] for 0..$N-1;
      $relax = 1/$val  if $val > 1/$relax;
      $relax1 = 1/$val  if $val > 1/$relax1 and $hor * $vert > 1;
    }
  }
  my $relax_error = $relax/$expect;
  print "eigenvalues min .. max = $min .. $max; relaxation = $relax\n";
  print "relaxation_error (better be 1 or more) = $relax_error\n";
  print "relaxation above (1,1) mode = $relax1\n";
  $expect = $relax;
}

my $pre = my $prev = norm(\$p, 0, 2, [1,$w, $w, $h]);
if ($test eq 'test-relax') {
  # k-th root of n-th Chebyshev polynomial is cos (k-1/2) pi/n
  # rescaling from [-1,1] to [0,1], get 0.5 - 0.5*cos (k-1/2) pi/n
  for my $iter (1..$steps) {
    for my $zero (@$P) {
      Poisson_1_r_cb \$p, \$tmp, $w, $h, $zero;
    }
    my $n = norm(\$p, 0, 2, [1,$w, $w, $h]);
    my @relax = map $expect/$_, ($prev/$n, ($pre/$n)**(1/(1+$iter)));
    print "post-$iter: norm=$n\n";
    print "post-$iter: loc/glob relax (rel to expect, must be 1 or less): @relax\n";
    $prev = $n;
  }
}
# typeout \$p, $w, $h;

if ($test eq 'test-2-grid') {
  my ($nh, $nw);
  if ($do_cb) {
    ($nh, $nw) = (int(($h-1)/2), $w - 1); # cut height aggressively
  } else {
    ($nw, $nh) = (int(($w-1)/2), $h - 1); # cut width aggressively
  }
  my $tmp1 = $tmp;			# XXX Can be smaller
  my $min_eigen_subgrid = min_eigen($nw, $nh, !$do_cb);
  my $ZEROS = Chebyshev_roots($min_eigen_subgrid);
  my $sub_steps = 8;			# Decrease 256 times
  my $OFF = 0;
  $prev = $pre;
  print "pre: norm=$pre\n";
  for my $iter (1..$steps) {
    if ($do_cb) {
      Poisson_1_r_cb \$p, \$tmp, $w, $h, 1;	# Apply 1-L
      downscale_from_cb_4(\$p, \$tmp1, $w, $h, $nw, $nh, $OFF);
      relax_Chebyshev(\$tmp1, \$tmp, $nw, $nh, $ZEROS, !$do_cb, $sub_steps);
      d2d1_mult_assign $quarter, $tmp1, 0, 0, 2, [0,-1,0,-1], [1, $nw, $nw, $nh];
      upscale_to_cb_2(\$tmp1, \$p, $nw, $nh, $w, $h, $OFF);
      d2d1_mult_assign $half, $p, 0, $w+1, 2, [0,-1,0,-1], [1, $w-2, $w, $h-2];
    } else {
      Poisson_1_r \$p, \$tmp, $w, $h, 1;	# Apply 1-L
#      Poisson_1_r \$p, \$tmp, $w, $h, 0.4;
#      Poisson_1_r \$p, \$tmp, $w, $h, 0.7;
      downscale_to_cb_4(\$p, \$tmp1, $w, $h, $nw, $nh, $OFF);
#  typeout \$tmp1, $w, $h if $w*$h <= 200;
  typeout \$tmp1, $nw, $nh if $nw*$nh <= 200 and $iter == 10;
      relax_Chebyshev(\$tmp1, \$tmp, $nw, $nh, $ZEROS, !$do_cb, $sub_steps);
  typeout \$tmp1, $nw, $nh if $nw*$nh <= 200 and $iter == 10;
      d2d1_mult_assign $quarter, $tmp1, 0, 0, 2, [0,-1,0,-1], [1, $nw, $nw, $nh];
      upscale_from_cb_2(\$tmp1, \$p, $nw, $nh, $w, $h, $OFF);
      d2d1_mult_assign $half, $p, 0, $w+1, 2, [0,-1,0,-1], [1, $w-2, $w, $h-2];
#      Poisson_1_r \$p, \$tmp, $w, $h, 0.4;
#      Poisson_1_r \$p, \$tmp, $w, $h, 0.7;
    }
    my $n = norm(\$p, 0, 2, [1,$w, $w, $h]);
    my $r = $n/$prev;
    $prev = $n;
    print "post-$iter: norm=$n, ratio = $r\n";
  }
  typeout \$p, $w, $h if $w*$h <= 200;
}

# Laplace makes sense starting from w,h>=3 in usual case, and w>=2, h>=3 in cb


