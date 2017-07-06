use strict;
use warnings;
use OpenGL;
use Prima qw(Application GLWidget);

$::application-> insert( GLWidget => 
	size    => [400,400],
	layered => 1,
	onPaint => sub {
		glClearColor(0,0,0,0);
		glClear(GL_COLOR_BUFFER_BIT);
		glBegin(GL_TRIANGLES);
		glColor3f(1.0,0.0,0.0);
		glVertex3f( 0.0, 1.0, 0.0);
		glColor3f(0.0,1.0,0.0);
		glVertex3f(-1.0,-1.0, 0.0);
		glColor3f(0.0,0.0,1.0);
		glVertex3f( 1.0,-1.0, 0.0);
		glEnd();
	},
	onMouseDown => sub { exit },
);

run Prima;

