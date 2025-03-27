#========================================================================
# Simple multi-window example
# Copyright (c) Camilla Löwy <elmindreda@glfw.org>
#
# This software is provided 'as-is', without any express or implied
# warranty. In no event will the authors be held liable for any damages
# arising from the use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would
#    be appreciated but is not required.
#
# 2. Altered source versions must be plainly marked as such, and must not
#    be misrepresented as being the original software.
#
# 3. This notice may not be removed or altered from any source
#    distribution.
#
#========================================================================

use OpenGL::GLFW qw(:all);
use OpenGL::Modern qw(:all);
use OpenGL::Modern::Helpers qw(pack_GLfloat);

my $error_callback = sub {
    my ( $error, $description ) = @_;
    printf STDERR "Error #%d from perl: %s\n", $error, $description;
};

if ( !glfwInit() ) {
    die "Failed to initialize GLFW\n";
}

glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
glfwWindowHint(GLFW_DECORATED, GLFW_FALSE);

my $monitor = glfwGetPrimaryMonitor();

my ($xpos,$ypos,$width,$height) = glfwGetMonitorWorkarea($monitor);

my %window;
my @colors = (
    [ '0.95', '0.32', '0.11' ],
    [ '0.50', '0.80', '0.16' ],
    [ '0', '0.68', '0.94' ],
    [ '0.98', '0.74', '0.04' ]
    );

for (my $i = 0;  $i < 4;  $i++)
{
    my $size = $height / 5;

    glfwWindowHint(GLFW_FOCUS_ON_SHOW, GLFW_FALSE) if $i > 0;

    $windows{$i} = glfwCreateWindow($size,$size,"Multi-Window Example",NULL,NULL);

    if (!$windows{$i})
    {
	glfwSetErrorCallback( $error_callback );
	die "glfwInit failed, $!\n"
    }

    glfwSetWindowPos($windows{$i}, $xpos + $size * (1 + ($i & 1)), $ypos + $size * (1 + ($i >> 1)));
    glfwSetInputMode($windows{$i}, GLFW_STICKY_KEYS, GLFW_TRUE);

    glfwMakeContextCurrent($windows{$i});
    #gladLoadGL(glfwGetProcAddress);
    glClearColor( $colors[$i][0] , $colors[$i][1] , $colors[$i][2] , 1 );
}

for (my $i = 0;  $i < 4;  $i++) {
    glfwShowWindow($windows{$i});
}

for (;;)
{
    for (my $i = 0; $i < 4; $i++)
    {
	glfwMakeContextCurrent($windows{$i});
	glClear(GL_COLOR_BUFFER_BIT);
	glfwSwapBuffers($windows{$i});

	if (glfwWindowShouldClose($windows{$i}) ||
	    glfwGetKey($windows{$i}, GLFW_KEY_ESCAPE))
	{
	    glfwTerminate();
	    exit;
	}
    }

    glfwWaitEvents();
}
