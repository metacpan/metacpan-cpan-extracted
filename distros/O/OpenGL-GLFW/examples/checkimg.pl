#!/usr/bin/perl
#
use OpenGL::GLFW qw(:all);
use OpenGL::Modern qw(:all);
use OpenGL::Modern::Helpers qw(glGenBuffers_p glBufferData_p);

# #include "linmath.h"

#                   x     y    r    g    b
my @vertices = (  -0.6, -0.4, 1.0, 0.0, 0.0,
                   0.6, -0.4, 0.0, 1.0, 0.0,
                   0.0,  0.6, 0.0, 0.0, 1.0 );

my @vertex_shader_text = (
    "uniform mat4 MVP;\n",
    "attribute vec3 vCol;\n",
    "attribute vec2 vPos;\n",
    "varying vec3 color;\n",
    "void main()\n",
    "{\n",
    "    gl_Position = MVP * vec4(vPos, 0.0, 1.0);\n",
    "    color = vCol;\n",
    "}\n"
);

my @fragment_shader_text = (
    "varying vec3 color;\n",
    "void main()\n",
    "{\n",
    "    gl_FragColor = vec4(color, 1.0);\n",
    "}\n",
);

my $drop_callback = sub {
    my ($window, @paths) = @_;
    print "Dropped (@paths)\n";
};

my $cursorenter_callback = sub {
    my ($window, $entered) = @_;
    printf STDERR "CursorEnter callback: " . ($entered ? "entered" : "left") . " window\n";
};

my $cursorpos_callback = sub {
    my ($window, $xpos, $ypos) = @_;
    printf STDERR "CursorPos callback: cursor at ($xpos,$ypos)\n";
};

my $char_callback = sub {
    my ($window, $codepoint) = @_;
    printf STDERR "Char callback: got codepoint=$codepoint\n";
};

my $charmods_callback = sub {
    my ($window, $codepoint, $mods) = @_;
    printf STDERR "CharMods callback: got codepoint=$codepoint, mods=$mods\n";
};

my $error_callback = sub {
    my ($error, $description) = @_;
    printf STDERR "Error #%d from perl: %s\n", $error, $description;
};

my $framebuffersize_callback = sub {
   my ($window, $width, $height) = @_;
   printf STDERR "FrameBufferSize callback: (w,h) = ($width,$height)\n";
};

my $key_callback = sub {
    my ($window, $key, $scancode, $action, $mods) = @_;
    if ($key == GLFW_KEY_ESCAPE && $action == GLFW_PRESS) {
        glfwSetWindowShouldClose($window, GLFW_TRUE);
    }
};

my $mousebutton_callback = sub {
    my ($window,$button,$action,$mods) = @_;
    printf STDERR "MouseButton callback: button=$button, action=$action, mods=$mods\n";
};

my $scroll_callback = sub {
   my ($window, $xoffset, $yoffset) = @_;
   printf STDERR "Scroll callback: offset=($xoffset,$yoffset)\n";
};

my $windowclose_callback = sub {
   my ($window) = @_;
   printf STDERR "WindowClose callback: closed!\n";
};

my $windowfocus_callback = sub {
   my ($window,$focused) = @_;
   printf STDERR "WindowFocus callback: " . ($focused ? "is " : "is not ") . "focused\n";
};

my $windowiconify_callback = sub {
   my ($window,$iconified) = @_;
   printf STDERR "WindowIconify callback: " . ($iconified ? "is " : "is not ") . "iconified\n";
};

my $windowpos_callback = sub {
   my ($window,$xpos,$ypos) = @_;
   printf STDERR "WindowPos callback: ($xpos,$ypos)\n";
};

my $windowrefresh_callback = sub {
   my ($window) = @_;
   printf STDERR "WindowRefresh callback!\n";
};

my $windowsize_callback = sub {
   my ($window,$width,$height) = @_;
   printf STDERR "WindowSize callback: ($width,$height)\n";
};

my $joystick_callback = sub {
   my ($joy_id,$event) = @_;
   printf STDERR "Joystick callback: joy_id=$joy_id with event=$event\n";
};


# int main(void) {
#
my ($window);
my ($vertex_buffer, $vertex_shader, $fragment_shader, $program);
my ($mvp_location, $vpos_location, $vcol_location);

glfwSetErrorCallback($error_callback);

die "glfwInit failed, $!\n" if !glfwInit();

# glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
# glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

# TODO: implement NULL pointer (is 0 or undef enough?)
# $window = glfwCreateWindow(640, 480, "Simple example", NULL, NULL);
#
# $window = glfwCreateWindow(640, 480, "Simple example", \0, \0);
$window = glfwCreateWindow(640, 480, "Simple example", NULL, NULL);
unless (defined $window) {
    glfwTerminate();
    die "glfwCreateWindow failed, $!\n";
}

glfwSetKeyCallback($window, $key_callback);

# glfwSetCharCallback($window, $char_callback);

# glfwSetCharModsCallback($window, $charmods_callback);

# glfwSetCursorEnterCallback($window, $cursorenter_callback);

# glfwSetCursorPosCallback($window, $cursorpos_callback);

# glfwSetFramebufferSizeCallback($window, $framebuffersize_callback);

# glfwSetMouseButtonCallback($window, $mousebutton_callback);

# glfwSetScrollCallback($window, $scroll_callback);

# glfwSetJoystickCallback($joystick_callback);

glfwSetWindowCloseCallback($window, $windowclose_callback);

# glfwSetWindowFocusCallback($window, $windowfocus_callback);

# glfwSetWindowIconifyCallback($window, $windowiconify_callback);

# Doesn't seem to change with using mouse to drag cygwin window
# glfwSetWindowPosCallback($window, $windowpos_callback);

# glfwSetWindowRefreshCallback($window, $windowrefresh_callback);

# glfwSetWindowSizeCallback($window, $windowsize_callback);

# TODO: It looks like you cant Drag-and-Drop between windows Explorer
# and cygwin X11 applications.  Need to test for linux and for win32
# native
#
# glfwSetDropCallback($window, $drop_callback);

glfwMakeContextCurrent($window);

die "glewInit failed, $!\n" if GLEW_OK != glewInit();

glfwSwapInterval(1);

#-----------------------------------------------------------
#  This is a test for window icons with different sizes
#  between 16x16, 32x32, and 48x48
#-----------------------------------------------------------

use PDL; # make things easy!
use PDL::NiceSlice;

my $icon16 = zeros(4,16,16);  # red
$icon16(0) .= 255;
$icon16(3) .= 255;
my $icon32 = zeros(4,32,32);  # green
$icon32(1) .= 255;
$icon32(3) .= 255;
my $icon48 = zeros(4,48,48);  # blue
$icon48(2) .= 255;
$icon48(3) .= 255;

$img16 = { width => $icon16->dim(0), height => $icon16->dim(1), pixels => pack('C*',$icon16->list) };
$img32 = { width => $icon32->dim(0), height => $icon32->dim(1), pixels => pack('C*',$icon32->list) };
$img48 = { width => $icon48->dim(0), height => $icon48->dim(1), pixels => pack('C*',$icon48->list) };

glfwSetWindowIcon($window,$img16,$img32,$img48);

#-----------------------------------------------------------
#  NOTE: OpenGL error checks have been omitted for brevity
#-----------------------------------------------------------

my $vertex_buffer = glGenBuffers_p(1);  # TODO
glBindBuffer(GL_ARRAY_BUFFER, $vertex_buffer);
# glBufferData_p(GL_ARRAY_BUFFER, sizeof(@vertices), @vertices, GL_STATIC_DRAW);  # TODO
glBufferData_p(GL_ARRAY_BUFFER, 4*scalar(@vertices), @vertices, GL_STATIC_DRAW);  # TODO

my $vertex_shader = glCreateShader(GL_VERTEX_SHADER);
glShaderSource_p($vertex_shader, @vertex_shader_text);  # TODO
glCompileShader($vertex_shader);

my $fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
glShaderSource_p($fragment_shader, @fragment_shader_text);  # TODO
glCompileShader($fragment_shader);

my $program = glCreateProgram();
glAttachShader($program, $vertex_shader);
glAttachShader($program, $fragment_shader);
glLinkProgram($program);

my $mvp_location  = glGetUniformLocation_c($program, "MVP");  # TODO change name to _p or no-suffix
my $vpos_location = glGetAttribLocation_c($program, "vPos");  # TODO change name to _p or no-suffix
my $vcol_location = glGetAttribLocation_c($program, "vCol");  # TODO change name to _p or no-suffix

glEnableVertexAttribArray($vpos_location);
#------------------------------------------------------------ stride, offset
glVertexAttribPointer_c($vpos_location, 2, GL_FLOAT, GL_FALSE, 4 * 5, 0     );
glEnableVertexAttribArray($vcol_location);
#------------------------------------------------------------ stride, offset
glVertexAttribPointer_c($vcol_location, 3, GL_FLOAT, GL_FALSE, 4 * 5, 4 * 2 );

while (!glfwWindowShouldClose($window))
{
    my ($width, $height);
    my ($angle, $c, $s, $cor, $sor);
    # mat4x4 $m, $p, $mvp;  # TODO

    my ($width, $height) = glfwGetFramebufferSize($window);
    my $ratio = $width / $height;

    glViewport(0, 0, $width, $height);
    glClear(GL_COLOR_BUFFER_BIT);

    # $m = mat4x4_identity();  # TODO
    # $m = mat4x4_rotate_Z($m, glfwGetTime());  # TODO
    $angle = glfwGetTime();
    $c = cos($angle);
    $cor = $c/$ratio;
    $s = sin($angle);
    $sor = $s/$ratio;

    # $p = mat4x4_ortho(-$ratio, $ratio, -1.0, 1.0, 1.0, -1.0);  # TODO
    # hardwired rotation and orthographic projection MVP matrix
    my $mvp = pack 'f[16]', $cor, $s, 0, 0, -$sor, $c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1;
    my $pointer_to_mvp_data = unpack 'Q', pack 'P', $mvp;

    glUseProgram($program);
    glUniformMatrix4fv_c($mvp_location, 1, GL_FALSE, $pointer_to_mvp_data);  # TODO
    glDrawArrays(GL_TRIANGLES, 0, 3);

    glfwSwapBuffers($window);
    glfwPollEvents();
}

glfwDestroyWindow($window);

glfwTerminate();
#
# }
