# Purpose: Simple demo of per-pixel lighting with GLSL and OpenGL::Shader

# Copyright (c) 2007, Geoff Broadwell; this script is released
# as open source and may be distributed and modified under the terms
# of either the Artistic License or the GNU General Public License,
# in the same manner as Perl itself.  These licenses should have been
# distributed to you as part of your Perl distribution, and can be
# read using `perldoc perlartistic` and `perldoc perlgpl` respectively.

# (hacked for Prima::OpenGL by dk)

use strict;
use warnings;
use OpenGL ':all';
use OpenGL::Shader;
use Time::HiRes qw(time);
use Prima qw(Application OpenGL GLWidget);

my ($window, $gl_widget, $teapot, $shader);

sub init
{
	glutInit;

	glMaterialfv_p(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, 1, .7, .7, 1);
	glMaterialfv_p(GL_FRONT_AND_BACK, GL_SPECULAR,	  1,  1,  1, 1);
	glMaterialf   (GL_FRONT_AND_BACK, GL_SHININESS,	  50  );
	
	glFrontFace(GL_CW);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glEnable(GL_AUTO_NORMAL);
	glEnable(GL_NORMALIZE);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity;
	glOrtho(0, 16, 0, 16, -10, 10);
	glMatrixMode(GL_MODELVIEW);

	# freeglut dirty workaround
	my $g = glutCreateWindow('');
	glutDisplayFunc(sub {});
	glutReshapeFunc(sub {});
	$gl_widget->gl_select;

	$teapot = glGenLists(1);
	glNewList($teapot, GL_COMPILE);
	glutSolidTeapot(4);
	glEndList;

	glutHideWindow();
	glutMainLoopEvent();
	glutDestroyWindow($g);
	$gl_widget->gl_select;

	$shader = new OpenGL::Shader('GLSL');
	unless ($shader) {
		warn "This program requires support for GLSL shaders.\n" ;
		return;
	}

	my $fragment = fragment_shader();
	my $vertex   = vertex_shader();
	my $info     = $shader->Load($fragment, $vertex);
	print $info if $info;

	$shader->Enable;
}

sub cb_draw 
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glLoadIdentity;
	glTranslatef(0, 0, -3);
	glPushMatrix();
	glTranslatef( 8, 8, 0);

	my $slow_time = time / 5;
	my $frac_time = $slow_time - int $slow_time;
	my $angle  = $frac_time * 360;
	glRotatef($angle, 0, 1, 0);

	glCallList($teapot);
	glPopMatrix();
	glFlush();
}

$window = Prima::MainWindow->create( 
	size => [300,300],
	text => 'OpenGL::Shader example',
	menuItems => [
		['~Options' => [
			['*shader' => '~Shader' => 'Space' => kb::Space => sub {
				$gl_widget-> gl_select;
				shift->menu->toggle(shift) ? $shader->Enable : $shader->Disable
			} ]],
		],
	],
);

$gl_widget = $window->insert( GLWidget =>
	selectable => 1,
	gl_config  => {depth_bits => 1},
	growMode   => gm::Client,
	rect       => [0, 0, $window->size],
	onPaint	   => \&cb_draw,
);

$gl_widget->gl_select;
init;
$window->menu->disable('shader') unless $shader;

$window->insert( Timer => 
	timeout => 100,
	onTick	=> sub { $gl_widget->repaint },
)->start;

run Prima;

sub vertex_shader {
	return <<'VERTEX';

varying vec3 Normal;
varying vec3 Position;

void main(void) {
	gl_Position = ftransform();
	Position = vec3(gl_ModelViewMatrix * gl_Vertex);
	Normal	 = gl_NormalMatrix * gl_Normal;
}

VERTEX
}

sub fragment_shader {
	return <<'FRAGMENT';

varying vec3 Position;
varying vec3 Normal;

void main(void) {
	vec3 normal    = normalize(Normal);
	vec3 reflected = normalize(reflect(Position, normal));
	vec3 light_dir = normalize(vec3(gl_LightSource[0].position) - Position);

	float diffuse  = max  (dot(light_dir, normal   ), 0.0);
	float spec     = clamp(dot(light_dir, reflected), 0.0, 1.0);
	spec = pow  (spec, gl_FrontMaterial.shininess);

	gl_FragColor  = gl_FrontLightModelProduct.sceneColor
		 + gl_FrontLightProduct[0].ambient
		 + diffuse * gl_FrontLightProduct[0].diffuse
		 + spec    * gl_FrontLightProduct[0].specular;
}

FRAGMENT
}
