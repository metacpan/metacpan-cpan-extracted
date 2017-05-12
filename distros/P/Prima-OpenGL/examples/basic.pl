use lib '../lib', '../blib/arch';
use strict;
use warnings;
use OpenGL;
use Prima qw(Application GLWidget);

my $window = Prima::MainWindow-> create;
$window-> insert( GLWidget => 
	pack    => { expand => 1, fill => 'both'},
	onPaint => sub {
		my $self = shift;
		glClearColor(0,0,1,1);
		glClear(GL_COLOR_BUFFER_BIT);
		glOrtho(-1,1,-1,1,-1,1);
		
		glColor3f(1,0,0);
		glBegin(GL_POLYGON);
			glVertex2f(-0.5,-0.5);
			glVertex2f(-0.5, 0.5);
			glVertex2f( 0.5, 0.5);
			glVertex2f( 0.5,-0.5);
		glEnd();
		glFlush();
	}
);

run Prima;

