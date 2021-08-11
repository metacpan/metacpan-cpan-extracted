#!/usr/bin/perl
use lib 'lib';

use PDL;
use PDL::NiceSlice;
use PDL::Graphics::Gnuplot qw(plot plot3d gpwin);

@windows = ();

use feature qw(say);

# data I use for 2D testing
my $x = sequence(21) - 10;

# data I use for 3D testing
my($th,$ph,$x_3d,$y_3d,$z_3d);
$th   = zeros(30)->xlinvals( 0,          3.14159*2)->transpose;
$ph   = zeros(30)->xlinvals( -3.14159/2, 3.14159/2);
$x_3d = (cos($ph)*cos($th))->flat->glue(0, (cos($ph)*cos($th))->transpose->flat);
$y_3d = (cos($ph)*sin($th))->flat->glue(0, (cos($ph)*sin($th))->transpose->flat);
$z_3d = (sin($ph)*$th->ones)->flat->glue(0,(sin($ph)*$th->ones)->transpose->flat);

$rv = rvals(21,21);
$zv = cos($rv) / (3 + $rv);

#################################
# Now the tests!
#################################

# first, some very basic stuff. Testing implicit domains, multiple curves in
# arguments, packed in ndarrays, etc

sub prompt {
    print $_[0]. "   (Press <RETURN> to continue)";
    $a=<>;
}

$w=gpwin(x11);


$w->plot($x**2);
prompt("A simple parabola");

$w->plot(-$x, $x**3);
prompt("A cubic");

$w->plot(-$x, $x**3,{},
     $x,  $x**2);
prompt("Parabola and cubic");

$w->plot(PDL::cat($x**2, $x**3));
prompt("Another way to plot a parabola and cubic");

$w->plot(-$x,
     PDL::cat($x**2, $x**3));
prompt("Yet another way");

push(@windows,$w);

# some more varied plotting, using the object-oriented interface
$w->options(globalwith => 'linespoints', xmin => -10);

$w->plot( title => 'Error bars and other things',
	  y2tics=>10,
	  {with => 'lines', 'lw' => 4},
	  legend => ['Parabola A','Parabola B','Parabola C'],
	  axes => 'x1y2',
	  PDL::cat($x, $x*2, $x*3), $x**2 - 300,

	  with => 'xyerrorbars',
	  axes=>'x1y1',
	  $x**2 * 10, $x**2/40, $x**2/2, # implicit domain

	  {with => 'line', legend => 'cubic', tuplesize => 2},
	  {legend => ['shifted cubic A','shifted cubic B']},
	  $x, PDL::cat($x**3, $x**3 - 100) );


prompt("Error bars and other things");

# a way to control the point size

$w->plot(cbmin => -600, cbmax => 600, title=>"Variable pointsize",
     {with => qw(points pointtype 7 pointsize variable)},
	 $x, $x/2, (10-abs($x))/2);
prompt("Variable pointsize");


################################
# some 3d stuff
################################
$w->reset;

# plot a gridded surface
$w->plot3d( 
    with=>'linespoints',
    xvals($zv), yvals($zv),
    $zv
    );
prompt("A gridded surface (feed in a 2-D column)\n  (Incidentally, if you're using the X11 or wxt device you can\n  change the view by dragging your mouse around the window)\n");

# Plot a collection of lines
$w->plot3d( 
    with=>'linespoints',
    cdim=>1,
    xvals($zv), yvals($zv),
    $zv
    );
prompt("A collection of lines (same data, treated as a collection of 1-D columns)");



# plot a sphere
$w->plot3d( j=>1, zrange=>[-1,1],yrange=>[-1,1],xrange=>[-1,1],
	    {with=>'linespoints'},
	    $x_3d, $y_3d, $z_3d,
      );
prompt("A sphere");



# sphere, ellipse together

$w->plot3d(
        j=>1,
        {legend => ['sphere', 'ellipsoid'],cd=>1},
        $x_3d->cat($x_3d*2),
        $y_3d->cat($y_3d*2), $z_3d );
prompt("A sphere and an ellipsoid");


# some paraboloids plotted on an implicit 2D domain
{
    my($xy,$z,$xy_half,$z_half);
    $xy = zeros(21,21)->ndcoords - pdl(10,10);
    $z = inner($xy, $xy);
    $xy_half = zeros(11,11)->ndcoords;
    $z_half = inner($xy_half, $xy_half);
    
    $w->plot3d(
	    globalwith => 'points', title  => 'gridded paraboloids',tuplesize=>1,
	    {legend => ['zplus','zminus']}, $z->cat(-$z),
	    {legend => 'zplus2'}, $z*2);
    prompt("Some paraboloids");
    $w->reset;
}

# 3d, variable color, variable pointsize
{
    my($pi,$theta,$z);
    $pi   = 3.14159;
    $theta = zeros(200)->xlinvals(0, 6*$pi);
    $z     = zeros(200)->xlinvals(0, 5);

 $w->plot3d( 
	     title => 'double helix',
	     
	     { with => 'linespoints', pointsize => 'variable', pointtype => 7, palette => 1, tuplesize => 5,
	       legend => ['spiral 1','spiral 2'],cdim=>1},
	     # 2 sets of x, y, z:
	     cos($theta)->cat(-cos($theta)),
	     sin($theta)->cat(-sin($theta)),
	     $z,
	     
	     # pointsize, color
	     0.5 + abs(cos($theta)), sin(2*$theta) );
    prompt("A double helix");
}

# implicit domain heat map
{
  my $xy;
  $xy = zeros(21,21)->ndcoords - pdl(10,10);

  $w->plot3d(
         title  => 'Paraboloid heat map',
         extracmds => 'set view 0,0',
         zrange => [-1,1],
         with => 'image', inner($xy, $xy));
  prompt("An image");
}


say STDERR 'I should complain about an invalid "with":';
say STDERR "=================================";
eval( <<'EOM' );
plot(with => 'bogusstyle', $x);
EOM
print STDERR $@ if $@;
say STDERR "=================================\n\n";


say STDERR 'PDL::Graphics::Gnuplot can detect I/O hangs. Here I ask for a delay, so I should detect this and quit after a few seconds:';
say STDERR "=================================";
eval( <<'EOM' );
  my $xy = zeros(21,21)->ndcoords - pdl(10,10);
  plot( extracmds => 'pause 10',
        sequence(5));
EOM
print STDERR $@ if $@;
say STDERR "=================================\n\n";
say STDERR "This concludes the gnuplot demo!  Enjoy using PDL::Graphics::Gnuplot!\n";

