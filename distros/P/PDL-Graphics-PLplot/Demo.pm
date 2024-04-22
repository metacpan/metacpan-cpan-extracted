package PDL::Demos::PLplot;
use PDL::Graphics::PLplot;

sub info {('plplot', 'PLplot graphics output')}

sub init {'
use PDL::Graphics::PLplot;
use Data::Dumper;
'}
my @demo = (
[comment => q|
  Welcome to this tour of the PDL's PLplot interface.

  This tour will introduce the PDL's PLplot plotting module and show
  what this powerful package can provide in terms of plotting, though it is
  not designed to give a full tour of PLplot.
|],

[act => q|
  # ensure the module is loaded
  use PDL::Graphics::PLplot;
  # PLplot uses "devices". This installation of PLplot supports these:
  $devs = plgDevs();
  print Dumper($devs);
|],

[act => q[
  ($dev) = grep $devs->{$_}, qw(qtwidget wxwidgets xcairo xwin wingcc);
  die "No suitable GUI device found" if !$dev;
  print "We'll use '$dev'\n";
  # Initialise the window
  $w = PDL::Graphics::PLplot->new( DEV=>$dev, PAGESIZE=>[600,400] );
  plspause(0);
  # set up colourmap for first 2 demos
  $i = pdl [0.0,1.0]; # left/right boundary
  ($h, $l, $s) = (pdl(240, 0), pdl(0.6, 0.6), pdl(0.8, 0.8));
  plscmap1n(256);
  plscmap1l(0, $i, $h, $l, $s, pdl []);
]],

[act => q[
  # plot data of example 8
  ($XPTS, $YPTS) = (35, 45);
  ($indexxmin, $indexxmax) = (0, $XPTS);
  # parameters of ellipse (in x, y index coordinates) that limits the data.
  # x0, y0 correspond to the exact floating point centre of the index range.
  ($x0, $y0) = (0.5 * ( $XPTS - 1 ), 0.5 * ( $YPTS - 1 ));
  ($a, $b) = (0.9 * $x0, 0.7 * $y0);
  ($x, $y) = map +(sequence($_) - int($_ / 2)) / int($_ / 2), $XPTS, $YPTS;
  ($xx, $yy) = ($x->dummy(1,$YPTS), $y->dummy(0,$XPTS));
  $r = sqrt ($xx * $xx + $yy * $yy);
  $z = exp (-$r * $r) * cos (2.0 * PI * $r);
  $z->inplace->setnonfinitetobad;
  $z->inplace->setbadtoval(-5); # -MAXFLOAT would mess-up up the scale
  ($zmin, $zmax) = (min($z), max($z));
  $square_root = sqrt(1. - hclip( (( sequence($XPTS) - $x0 ) / $a) ** 2, 1 ));
  # Add 0.5 to find nearest integer and therefore preserve symmetry
  # with regard to lower and upper bound of y range.
  $indexymin = lclip( 0.5 + $y0 - $b * $square_root, 0 )->indx;
  # indexymax calculated with the convention that it is 1
  # greater than highest valid index.
  $indexymax = hclip( 1 + ( 0.5 + $y0 + $b * $square_root ), $YPTS )->indx;
  $zlimited = zeroes ($XPTS, $YPTS);
  for my $i ( $indexxmin..$indexxmax-1 ) {
    my $j = [ $indexymin->at($i), $indexymax->at($i) ];
    $zlimited->index($i)->slice($j) .= $z->index($i)->slice($j);
  }
  $nlevel = 10;
  $step = ($zmax - $zmin) / ($nlevel + 1);
  $clevel = $zmin + $step + $step * sequence($nlevel);
  # display the plot of example 8
  pllightsource(1., 1., 1.);
  pladv(0);
  plvpor(0.0, 1.0, 0.0, 0.9);
  plwind(-1.0, 1.0, -0.9, 1.1);
  plcol0(3);
  plmtex(1.0, 0.5, 0.5, "t", "#frPLplot Example 8 - Alt=60, Az=30");
  plcol0(1);
  plw3d(1.0, 1.0, 1.0, -1.0, 1.0, -1.0, 1.0, $zmin, $zmax, 60.0, 30.0);
  plbox3 (0.0, 0, 0.0, 0, 0.0, 0,
    "bnstu", "x axis", "bnstu", "y axis", "bcdmnstuv", "z axis");
  plcol0 (2);
  plsurf3d($x, $y, $z, MAG_COLOR | FACETED, pdl []);
  plflush();
]],

[act => q[
  # plot data of example 11
  ($XPTS, $YPTS) = (35, 46);
  ($x, $y) = map 3*(sequence($_) - int($_ / 2)) / int($_ / 2), $XPTS, $YPTS;
  ($xx, $yy) = ($x->dummy(1,$YPTS), $y->dummy(0,$XPTS));
  $z =
    3. * (1.-$xx)*(1.-$xx) * exp(-($xx*$xx) - ($yy+1.)*($yy+1.)) -
    10. * ($xx/5. - pow($xx,3.) - pow($yy,5.)) * exp(-$xx*$xx-$yy*$yy) -
    1./3. * exp(-($xx+1)*($xx+1) - ($yy*$yy));
  ($zmin, $zmax) = (min($z), max($z));
  $nlevel = 10;
  $step = ($zmax - $zmin) / ($nlevel + 1);
  $clevel = $zmin + $step + $step * sequence($nlevel);
  # display the plot of example 11
  pladv(0);
  plcol0(1);
  plvpor(0.0, 1.0, 0.0, 0.9);
  plwind (-1.0, 1.0, -1.0, 1.5);
  plw3d (1.0, 1.0, 1.2, -3.0, 3.0, -3.0, 3.0, $zmin, $zmax, 17.0, 115.0);
  plbox3 (0.0, 0, 0.0, 0, 0.0, 4,
          "bnstu", "x axis", "bnstu", "y axis", "bcdmnstuv", "z axis");
  plcol0(2);
  plmeshc($x, $y, $z, DRAW_LINEXY | MAG_COLOR | BASE_CONT, $clevel);
  plcol0(3);
  plmtex(1.0, 0.5, 0.5, "t", "#frPLplot Example 11 - Alt=17, Az=115, Opt=3");
  plflush();
]],

[act => q[
  # plot data of example 22.4
  $arrow2_x = pdl [-0.5, 0.3, 0.3, 0.5, 0.3,  0.3];
  $arrow2_y = pdl [0.0,  0.0, 0.2, 0.0, -0.2, 0.0];
  plsvect($arrow2_x, $arrow2_y, 1);
  ($nx, $ny, $nc, $nseg) = (20, 20, 11, 20);
  ($dx, $dy) = (1.0, 1.0);
  ($xmin, $xmax) = (-$nx / 2 * $dx, $nx / 2 * $dx);
  ($ymin, $ymax) = (-$ny / 2 * $dy, $ny / 2 * $dy);
  $x = ((sequence($nx)-int($nx/2)+0.5)*$dx)->dummy(1,$ny);
  $y = ((sequence($ny)-int($ny/2)+0.5)*$dy)->dummy(0,$nx);
  $cgrid2 = plAlloc2dGrid($x, $y);
  $Q = 2.0;
  $b = $ymax/4.0*(3-cos(PI*$x/$xmax));
  $dbdx = $ymax/4.0*sin(PI*$x/$xmax)*PI/$xmax*$y/$b;
  $u = $Q*$ymax/$b;
  $v = zeroes($nx, $ny);
  $clev = (sequence($nc) * $Q / ($nc - 1)) + $Q;
  # display the plot of example 22.4
  plstransform( sub {
    my ($x, $y, $xmax) = @_;
    return ($x, $y / 4.0 * ( 3 - cos( PI * $x / $xmax ) ));
  }, $xmax );
  plenv($xmin, $xmax, $ymin, $ymax, 0, 0);
  pllab("(x)", "(y)", "#frPLplot Example 22 - constriction with plstransform");
  plcol0( 2 );
  plshades( $u,
      $xmin + $dx / 2, $xmax - $dx / 2, $ymin + $dy / 2, $ymax - $dy / 2,
      $clev, 0.0, 1, 1.0, 0, 0, 0, 0 );
  plvect($u,$v,-1.0,\&pltr2,$cgrid2);
  # Plot edges using plpath (which accounts for coordinate transformation) rather than plline
  plpath( $nseg, $xmin, $ymax, $xmax, $ymax );
  plpath( $nseg, $xmin, $ymin, $xmax, $ymin );
  plcol0( 1 );
  plstransform( undef, undef );
  plflush();
  plFree2dGrid($cgrid2);
]],

[act => q[
  # plot data of example 22.5
  $nper = 100;
  $nlevel = 10;
  $rmax = $nr = $ntheta = 20;
  ($eps, $q1, $q2) = (2, 1, -1);
  ($d1, $d2) = ($rmax / 4, $rmax / 4);
  ($q1i, $d1i) = (- $q1 * $rmax / $d1, $rmax * $rmax / $d1);
  ($q2i, $d2i) = (- $q2 * $rmax / $d2, $rmax * $rmax / $d2);
  $r = (0.5 + sequence ($nr))->dummy (1, $ntheta);
  $theta = (2 * PI / ($ntheta - 1) *
               (0.5 + sequence ($ntheta)))->dummy (0, $nr);
  ($x, $y) = ($r * cos ($theta), $r * sin ($theta));
  ($div1, $div1i) =
    map sqrt(($x - $_) ** 2 + ($y - $_) ** 2 + $eps * $eps), $d1, $d1i;
  ($div2, $div2i) =
    map sqrt(($x - $_) ** 2 + ($y + $_) ** 2 + $eps * $eps), $d2, $d2i;
  $z = $q1 / $div1 + $q1i / $div1i + $q2 / $div2 + $q2i / $div2i;
  $u = -$q1 * ($x - $d1) / ($div1**3) - $q1i * ($x - $d1i) / ($div1i ** 3)
          -$q2 * ($x - $d2) / ($div2**3) - $q2i * ($x - $d2i) / ($div2i ** 3);
  $v = -$q1 * ($y - $d1) / ($div1**3) - $q1i * ($y - $d1i) / ($div1i ** 3)
          -$q2 * ($y + $d2) / ($div2**3) - $q2i * ($y + $d2i) / ($div2i ** 3);
  ($xmin, $xmax, $ymin, $ymax, $zmin, $zmax) = map minmax($_), $x, $y, $z;
  # Plot contours of the potential
  $dz = ($zmax - $zmin) / $nlevel;
  $clevel = $zmin + (sequence ($nlevel) + 0.5) * $dz;
  # the perimeter of the cylinder
  $theta = (2 * PI / ($nper - 1)) * sequence ($nper);
  ($px, $py) = ($rmax * cos ($theta), $rmax * sin ($theta));
  # display the plot of example 22.5
  plenv ($xmin, $xmax, $ymin, $ymax, 0, 0);
  pllab ("(x)", "(y)",
         "#frPLplot Example 22 - potential gradient vector plot");
  plcol0 (3);
  pllsty (2);
  my $cgrid2 = plAlloc2dGrid ($x, $y);
  plcont ($z, 1, $nr, 1, $ntheta, $clevel, \&pltr2, $cgrid2);
  pllsty (1);
  plcol0 (1);
  # Plot the vectors of the gradient of the potential
  plcol0 (2);
  plvect ($u, $v, 25.0, \&pltr2, $cgrid2);
  plcol0 (1);
  plline ($px , $py); # Plot the cylinder
  plflush();
  plFree2dGrid($cgrid2);
]],

[actnw => q|
  # close the window--we're done!
  $w->close;
  undef $w;

  # These are just a few of the amazing demos of PLplot. See their homepage at
  #      https://plplot.sourceforge.net/examples.php
|],
);

sub demo { @demo }

1;

=head1 NAME

PDL::Demos::PLplot - demonstrate PDL::Graphics::PLplot capabilities

=head1 SYNOPSIS

  pdl> demo plplot

=cut
