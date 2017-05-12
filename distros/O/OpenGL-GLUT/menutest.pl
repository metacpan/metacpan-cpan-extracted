use OpenGL::GLUT qw(:all);
use OpenGL::Modern qw(:all);

# NOTE: This example only demonstrates the GLUT menu functionality
#       A complete example would include the needed callbacks for rendering.

glutInit();

glutInitWindowPosition(10, 10);
glutInitWindowSize(200, 200);
glutInitDisplayMode(16);

$win = glutCreateWindow("test2");
glutSetWindow($win);

glutDisplayFunc(sub { print "Display!\n";
		      glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT ) } );
glutReshapeFunc(sub { print "Reshape!\n";
		      my ($width, $height) = @_;
		      glViewport(0, 0, $width, $height); } );
#glutIdleFunc(sub { print "Idle!\n" } );

glutCreateMenu(sub { print "Got menu ",@_,"\n" } );
glutAddMenuEntry("Hello", 1);
glutAttachMenu(GLUT_RIGHT_BUTTON);

glutMainLoop();
