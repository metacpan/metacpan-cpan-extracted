#!/usr/bin/env perl
use strict;
use warnings;
use OpenGL::Simple qw(:all);
use OpenGL::Simple::GLUT qw(:all);
use OpenGL::Simple::Viewer;
use Data::Dumper;

# 
# Draw a Sierpinski gasket, by playing the Chaos Game and plotting the
# resulting points.
#
# You can play the Chaos Game on paper, as follows: choose three points,
# the "fixed points", forming a triangle. Number the points 1, 2, and 3.
# Plot another point, randomly, inside the triangle. Then roll a die: if
# it's larger than 3, subtract 3 so that you have a number N between 1 and
# three. Plot another point, half way between the last point you
# coloured, and fixed point number N. Repeat as long as you like.
#
# This will eventually produce a 2D "Sierpinski gasket" fractal; the
# following code plays the same game in 3D using the points on a
# tetrahedron. It also colours the points according to how close they
# are to the different fixed points. The more points you plot, the more
# clearly visisble the structure will be.
#
# For a large number of points, it can get quite slow to make a big
# bunch of OpenGL calls every time you want to replot the gasket from a
# different angle. So, we open a "display list", and store all of the
# OpenGL commands to plot the gasket inside the list. All you have to do
# to render a Sierpinski gasket after that is instruct OpenGL to call
# the list, using glCallList().
#

glutInit;

my $displaylist;
my $npoints = shift @ARGV || 2500; # Number of points to draw.

my $v = new OpenGL::Simple::Viewer(

        title => 'The Sierpinski Gasket',
        screenx => 512,
        screeny => 512,

        initialize_gl => sub { 
                glClearColor(0,0,0,1);  # Black background

                glDisable(GL_TEXTURE_2D);
                glEnable(GL_COLOR_MATERIAL);

                glPointSize(2.0);          # Plot nice big points..

                glEnable(GL_POINT_SMOOTH); # ..but round them off instead of
                glEnable(GL_BLEND);        # drawing big squares at each point
                glEnable(GL_DEPTH_TEST);

                # Set up display list, and record all the
                # points on the gasket.

                $displaylist = glGenLists(1);

                $|=1; print "Generating gasket with $npoints points... ";

                glNewList($displaylist,GL_COMPILE);
                        glBegin(GL_POINTS);
                        draw_gasket();
                        glEnd();
                glEndList();

                print "done.\n";
        },

        draw_geometry => sub { glCallList($displaylist); },

);

glutMainLoop;

exit;

sub draw_gasket {

        my $scale = 3.0;

        # Generate the vertices of a tetrahedron.
	# See http://mathworld.wolfram.com/Tetrahedron.html 

	my $xx = $scale / sqrt(3.0);
	my $r  = $scale * sqrt(6.0)/12.0;
	my $rr = $scale * 0.25 * sqrt(6.0);
	my $d  = $scale * sqrt(3.0)/6.0;

        # @fixp holds tetrahedron vertex coordinates, the
        # fixed points.

        my @fixp = (
                [$xx,		 0.0,		-$r],
                [-$d,		 0.5*$scale,	-$r],
                [-$d,		-0.5*$scale,	-$r],
                [0.0,	         0.0 ,		$rr]
        );

	my @col = (                     # Colours of fixed points
		[ 1.0, 0.0, 0.0 ],
		[ 0.0, 1.0, 0.0 ],
		[ 0.0, 0.0, 1.0 ],
		[ 1.0, 0.0, 1.0 ]
	);

        # Plot the corners

        for (0..3) {
                glColor(@{$col[$_]});
                glVertex(@{$fixp[$_]});
        }


        my ($x,$y,$z) = @{$fixp[0]};     # Moving point
        my ($cr,$cb,$cg) = @{$col[0]};   # Colour of moving point

        # Play the Chaos Game.
 
        for (1..$npoints) {
                my $j = int(rand(4)); # 0 <= $j <= 3

                # Move half way between previous point and a random
                # fixed point, in both real space and colour space.
 
		$x += 0.5 * ( $fixp[$j]->[0] - $x );
		$y += 0.5 * ( $fixp[$j]->[1] - $y );
		$z += 0.5 * ( $fixp[$j]->[2] - $z );

		$cr+= 0.5 * ( $col[$j]->[0] - $cr );
		$cg+= 0.5 * ( $col[$j]->[1] - $cg );
		$cb+= 0.5 * ( $col[$j]->[2] - $cb );

		glColor($cr,$cg,$cb);
                glVertex($x,$y,$z);
	}
}

