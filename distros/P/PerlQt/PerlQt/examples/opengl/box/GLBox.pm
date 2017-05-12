package GLBox;

use OpenGL qw(:all);

use strict;

use Qt;
use Qt::isa qw(Qt::GLWidget);
use Qt::slots 
    setXRotation => ['int'],
    setYRotation => ['int'],
    setZRotation => ['int'];
use Qt::attributes qw(
    xRot
    yRot
    zRot
    scale
    object
    list
);

sub NEW {
    shift->SUPER::NEW(@_);
    xRot = yRot = zRot = 0.0;
    scale = 1.25;
    object = undef;
}

sub paintGL
{
    glClear( GL_COLOR_BUFFER_BIT );
    glClear( GL_DEPTH_BUFFER_BIT );

    glLoadIdentity();
    glTranslatef( 0.0, 0.0, -10.0 );
    glScalef( scale, scale, scale );

    glRotatef( xRot, 1.0, 0.0, 0.0 );
    glRotatef( yRot, 0.0, 1.0, 0.0 );
    glRotatef( zRot, 0.0, 0.0, 1.0 );

    glCallList( object );
}

sub initializeGL
{
    qglClearColor( &black );             # Let OpenGL clear to black
    object = makeObject();              # Generate an OpenGL display list
    glShadeModel( GL_FLAT );
    glEnable( GL_DEPTH_TEST );
}

#  Set up the OpenGL view port, matrix mode, etc.

sub resizeGL
{
    my $w = shift;
    my $h = shift;
    glViewport( 0, 0, $w, $h );
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    glFrustum( -1.0, 1.0, -1.0, 1.0, 5.0, 15.0 );
    glMatrixMode( GL_MODELVIEW );
}

#  Generate an OpenGL display list for the object to be shown, i.e. the box

sub makeObject
{
    my $list = glGenLists( 1 );

    glNewList( $list, GL_COMPILE );

    qglColor( &darkGreen );                # Shorthand for glColor3f or glIndex

    glLineWidth( 2.0 );

    glBegin( GL_QUADS );
    glVertex3f(  1.0,  0.5, -0.4 );
    glVertex3f(  1.0, -0.5, -0.4 );
    glVertex3f( -1.0, -0.5, -0.4 );
    glVertex3f( -1.0,  0.5, -0.4 );
    glEnd();

    qglColor( &blue );

    glBegin( GL_QUADS );
    glVertex3f(  1.0,  0.5, 0.4 );
    glVertex3f(  1.0, -0.5, 0.4 );
    glVertex3f( -1.0, -0.5, 0.4 );
    glVertex3f( -1.0,  0.5, 0.4 );
    glEnd();

    qglColor( &darkRed );

    glBegin( GL_QUAD_STRIP );
    glVertex3f(  1.0,  0.5, -0.4 );   glVertex3f(  1.0,  0.5, 0.4 );
    glVertex3f(  1.0, -0.5, -0.4 );   glVertex3f(  1.0, -0.5, 0.4 );
    qglColor( &yellow );
    glVertex3f( -1.0, -0.5, -0.4 );   glVertex3f( -1.0, -0.5, 0.4 );
    qglColor( &green );
    glVertex3f( -1.0,  0.5, -0.4 );   glVertex3f( -1.0,  0.5, 0.4 );
    qglColor( &lightGray );
    glVertex3f(  1.0,  0.5, -0.4 );   glVertex3f(  1.0,  0.5, 0.4 );
    glEnd();

    glEndList();

    return $list;
}



#  Set the rotation angle of the object to \e degrees around the X axis.

sub setXRotation
{
    my $deg = shift;
    xRot = $deg % 360;
    updateGL();
}


#  Set the rotation angle of the object to \e degrees around the Y axis.

sub setYRotation
{
    my $deg = shift;
    yRot = $deg % 360;
    updateGL();
}


#  Set the rotation angle of the object to \e degrees around the Z axis.

sub setZRotation
{
    my $deg = shift;
    zRot = $deg % 360;
    updateGL();
}

sub DESTROY
{
#    makeCurrent();
    glDeleteLists( object, 1 );
}

1;
