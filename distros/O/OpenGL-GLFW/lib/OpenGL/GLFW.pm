package OpenGL::GLFW;

use 5.010001;
use strict;
use warnings;

#
# Declare GLFW constants with the constant pragma for perl
#
use constant NULL => \0;
use constant GLFW_VERSION_MAJOR => 3;
use constant GLFW_VERSION_MINOR => 2;
use constant GLFW_VERSION_REVISION => 1;
use constant GLFW_TRUE => 1;
use constant GLFW_FALSE => 0;
use constant GLFW_RELEASE => 0;
use constant GLFW_PRESS => 1;
use constant GLFW_REPEAT => 2;
use constant GLFW_KEY_UNKNOWN => -1;
use constant GLFW_KEY_SPACE => 32;
use constant GLFW_KEY_APOSTROPHE => 39;
use constant GLFW_KEY_COMMA => 44;
use constant GLFW_KEY_MINUS => 45;
use constant GLFW_KEY_PERIOD => 46;
use constant GLFW_KEY_SLASH => 47;
use constant GLFW_KEY_0 => 48;
use constant GLFW_KEY_1 => 49;
use constant GLFW_KEY_2 => 50;
use constant GLFW_KEY_3 => 51;
use constant GLFW_KEY_4 => 52;
use constant GLFW_KEY_5 => 53;
use constant GLFW_KEY_6 => 54;
use constant GLFW_KEY_7 => 55;
use constant GLFW_KEY_8 => 56;
use constant GLFW_KEY_9 => 57;
use constant GLFW_KEY_SEMICOLON => 59;
use constant GLFW_KEY_EQUAL => 61;
use constant GLFW_KEY_A => 65;
use constant GLFW_KEY_B => 66;
use constant GLFW_KEY_C => 67;
use constant GLFW_KEY_D => 68;
use constant GLFW_KEY_E => 69;
use constant GLFW_KEY_F => 70;
use constant GLFW_KEY_G => 71;
use constant GLFW_KEY_H => 72;
use constant GLFW_KEY_I => 73;
use constant GLFW_KEY_J => 74;
use constant GLFW_KEY_K => 75;
use constant GLFW_KEY_L => 76;
use constant GLFW_KEY_M => 77;
use constant GLFW_KEY_N => 78;
use constant GLFW_KEY_O => 79;
use constant GLFW_KEY_P => 80;
use constant GLFW_KEY_Q => 81;
use constant GLFW_KEY_R => 82;
use constant GLFW_KEY_S => 83;
use constant GLFW_KEY_T => 84;
use constant GLFW_KEY_U => 85;
use constant GLFW_KEY_V => 86;
use constant GLFW_KEY_W => 87;
use constant GLFW_KEY_X => 88;
use constant GLFW_KEY_Y => 89;
use constant GLFW_KEY_Z => 90;
use constant GLFW_KEY_LEFT_BRACKET => 91;
use constant GLFW_KEY_BACKSLASH => 92;
use constant GLFW_KEY_RIGHT_BRACKET => 93;
use constant GLFW_KEY_GRAVE_ACCENT => 96;
use constant GLFW_KEY_WORLD_1 => 161;
use constant GLFW_KEY_WORLD_2 => 162;
use constant GLFW_KEY_ESCAPE => 256;
use constant GLFW_KEY_ENTER => 257;
use constant GLFW_KEY_TAB => 258;
use constant GLFW_KEY_BACKSPACE => 259;
use constant GLFW_KEY_INSERT => 260;
use constant GLFW_KEY_DELETE => 261;
use constant GLFW_KEY_RIGHT => 262;
use constant GLFW_KEY_LEFT => 263;
use constant GLFW_KEY_DOWN => 264;
use constant GLFW_KEY_UP => 265;
use constant GLFW_KEY_PAGE_UP => 266;
use constant GLFW_KEY_PAGE_DOWN => 267;
use constant GLFW_KEY_HOME => 268;
use constant GLFW_KEY_END => 269;
use constant GLFW_KEY_CAPS_LOCK => 280;
use constant GLFW_KEY_SCROLL_LOCK => 281;
use constant GLFW_KEY_NUM_LOCK => 282;
use constant GLFW_KEY_PRINT_SCREEN => 283;
use constant GLFW_KEY_PAUSE => 284;
use constant GLFW_KEY_F1 => 290;
use constant GLFW_KEY_F2 => 291;
use constant GLFW_KEY_F3 => 292;
use constant GLFW_KEY_F4 => 293;
use constant GLFW_KEY_F5 => 294;
use constant GLFW_KEY_F6 => 295;
use constant GLFW_KEY_F7 => 296;
use constant GLFW_KEY_F8 => 297;
use constant GLFW_KEY_F9 => 298;
use constant GLFW_KEY_F10 => 299;
use constant GLFW_KEY_F11 => 300;
use constant GLFW_KEY_F12 => 301;
use constant GLFW_KEY_F13 => 302;
use constant GLFW_KEY_F14 => 303;
use constant GLFW_KEY_F15 => 304;
use constant GLFW_KEY_F16 => 305;
use constant GLFW_KEY_F17 => 306;
use constant GLFW_KEY_F18 => 307;
use constant GLFW_KEY_F19 => 308;
use constant GLFW_KEY_F20 => 309;
use constant GLFW_KEY_F21 => 310;
use constant GLFW_KEY_F22 => 311;
use constant GLFW_KEY_F23 => 312;
use constant GLFW_KEY_F24 => 313;
use constant GLFW_KEY_F25 => 314;
use constant GLFW_KEY_KP_0 => 320;
use constant GLFW_KEY_KP_1 => 321;
use constant GLFW_KEY_KP_2 => 322;
use constant GLFW_KEY_KP_3 => 323;
use constant GLFW_KEY_KP_4 => 324;
use constant GLFW_KEY_KP_5 => 325;
use constant GLFW_KEY_KP_6 => 326;
use constant GLFW_KEY_KP_7 => 327;
use constant GLFW_KEY_KP_8 => 328;
use constant GLFW_KEY_KP_9 => 329;
use constant GLFW_KEY_KP_DECIMAL => 330;
use constant GLFW_KEY_KP_DIVIDE => 331;
use constant GLFW_KEY_KP_MULTIPLY => 332;
use constant GLFW_KEY_KP_SUBTRACT => 333;
use constant GLFW_KEY_KP_ADD => 334;
use constant GLFW_KEY_KP_ENTER => 335;
use constant GLFW_KEY_KP_EQUAL => 336;
use constant GLFW_KEY_LEFT_SHIFT => 340;
use constant GLFW_KEY_LEFT_CONTROL => 341;
use constant GLFW_KEY_LEFT_ALT => 342;
use constant GLFW_KEY_LEFT_SUPER => 343;
use constant GLFW_KEY_RIGHT_SHIFT => 344;
use constant GLFW_KEY_RIGHT_CONTROL => 345;
use constant GLFW_KEY_RIGHT_ALT => 346;
use constant GLFW_KEY_RIGHT_SUPER => 347;
use constant GLFW_KEY_MENU => 348;
use constant GLFW_KEY_LAST => GLFW_KEY_MENU;
use constant GLFW_MOD_SHIFT => 0x0001;
use constant GLFW_MOD_CONTROL => 0x0002;
use constant GLFW_MOD_ALT => 0x0004;
use constant GLFW_MOD_SUPER => 0x0008;
use constant GLFW_MOUSE_BUTTON_1 => 0;
use constant GLFW_MOUSE_BUTTON_2 => 1;
use constant GLFW_MOUSE_BUTTON_3 => 2;
use constant GLFW_MOUSE_BUTTON_4 => 3;
use constant GLFW_MOUSE_BUTTON_5 => 4;
use constant GLFW_MOUSE_BUTTON_6 => 5;
use constant GLFW_MOUSE_BUTTON_7 => 6;
use constant GLFW_MOUSE_BUTTON_8 => 7;
use constant GLFW_MOUSE_BUTTON_LAST => GLFW_MOUSE_BUTTON_8;
use constant GLFW_MOUSE_BUTTON_LEFT => GLFW_MOUSE_BUTTON_1;
use constant GLFW_MOUSE_BUTTON_RIGHT => GLFW_MOUSE_BUTTON_2;
use constant GLFW_MOUSE_BUTTON_MIDDLE => GLFW_MOUSE_BUTTON_3;
use constant GLFW_JOYSTICK_1 => 0;
use constant GLFW_JOYSTICK_2 => 1;
use constant GLFW_JOYSTICK_3 => 2;
use constant GLFW_JOYSTICK_4 => 3;
use constant GLFW_JOYSTICK_5 => 4;
use constant GLFW_JOYSTICK_6 => 5;
use constant GLFW_JOYSTICK_7 => 6;
use constant GLFW_JOYSTICK_8 => 7;
use constant GLFW_JOYSTICK_9 => 8;
use constant GLFW_JOYSTICK_10 => 9;
use constant GLFW_JOYSTICK_11 => 10;
use constant GLFW_JOYSTICK_12 => 11;
use constant GLFW_JOYSTICK_13 => 12;
use constant GLFW_JOYSTICK_14 => 13;
use constant GLFW_JOYSTICK_15 => 14;
use constant GLFW_JOYSTICK_16 => 15;
use constant GLFW_JOYSTICK_LAST => GLFW_JOYSTICK_16;
use constant GLFW_NOT_INITIALIZED => 0x00010001;
use constant GLFW_NO_CURRENT_CONTEXT => 0x00010002;
use constant GLFW_INVALID_ENUM => 0x00010003;
use constant GLFW_INVALID_VALUE => 0x00010004;
use constant GLFW_OUT_OF_MEMORY => 0x00010005;
use constant GLFW_API_UNAVAILABLE => 0x00010006;
use constant GLFW_VERSION_UNAVAILABLE => 0x00010007;
use constant GLFW_PLATFORM_ERROR => 0x00010008;
use constant GLFW_FORMAT_UNAVAILABLE => 0x00010009;
use constant GLFW_NO_WINDOW_CONTEXT => 0x0001000A;
use constant GLFW_FOCUSED => 0x00020001;
use constant GLFW_ICONIFIED => 0x00020002;
use constant GLFW_RESIZABLE => 0x00020003;
use constant GLFW_VISIBLE => 0x00020004;
use constant GLFW_DECORATED => 0x00020005;
use constant GLFW_AUTO_ICONIFY => 0x00020006;
use constant GLFW_FLOATING => 0x00020007;
use constant GLFW_MAXIMIZED => 0x00020008;
use constant GLFW_RED_BITS => 0x00021001;
use constant GLFW_GREEN_BITS => 0x00021002;
use constant GLFW_BLUE_BITS => 0x00021003;
use constant GLFW_ALPHA_BITS => 0x00021004;
use constant GLFW_DEPTH_BITS => 0x00021005;
use constant GLFW_STENCIL_BITS => 0x00021006;
use constant GLFW_ACCUM_RED_BITS => 0x00021007;
use constant GLFW_ACCUM_GREEN_BITS => 0x00021008;
use constant GLFW_ACCUM_BLUE_BITS => 0x00021009;
use constant GLFW_ACCUM_ALPHA_BITS => 0x0002100A;
use constant GLFW_AUX_BUFFERS => 0x0002100B;
use constant GLFW_STEREO => 0x0002100C;
use constant GLFW_SAMPLES => 0x0002100D;
use constant GLFW_SRGB_CAPABLE => 0x0002100E;
use constant GLFW_REFRESH_RATE => 0x0002100F;
use constant GLFW_DOUBLEBUFFER => 0x00021010;
use constant GLFW_CLIENT_API => 0x00022001;
use constant GLFW_CONTEXT_VERSION_MAJOR => 0x00022002;
use constant GLFW_CONTEXT_VERSION_MINOR => 0x00022003;
use constant GLFW_CONTEXT_REVISION => 0x00022004;
use constant GLFW_CONTEXT_ROBUSTNESS => 0x00022005;
use constant GLFW_OPENGL_FORWARD_COMPAT => 0x00022006;
use constant GLFW_OPENGL_DEBUG_CONTEXT => 0x00022007;
use constant GLFW_OPENGL_PROFILE => 0x00022008;
use constant GLFW_CONTEXT_RELEASE_BEHAVIOR => 0x00022009;
use constant GLFW_CONTEXT_NO_ERROR => 0x0002200A;
use constant GLFW_CONTEXT_CREATION_API => 0x0002200B;
use constant GLFW_NO_API => 0;
use constant GLFW_OPENGL_API => 0x00030001;
use constant GLFW_OPENGL_ES_API => 0x00030002;
use constant GLFW_NO_ROBUSTNESS => 0;
use constant GLFW_NO_RESET_NOTIFICATION => 0x00031001;
use constant GLFW_LOSE_CONTEXT_ON_RESET => 0x00031002;
use constant GLFW_OPENGL_ANY_PROFILE => 0;
use constant GLFW_OPENGL_CORE_PROFILE => 0x00032001;
use constant GLFW_OPENGL_COMPAT_PROFILE => 0x00032002;
use constant GLFW_CURSOR => 0x00033001;
use constant GLFW_STICKY_KEYS => 0x00033002;
use constant GLFW_STICKY_MOUSE_BUTTONS => 0x00033003;
use constant GLFW_CURSOR_NORMAL => 0x00034001;
use constant GLFW_CURSOR_HIDDEN => 0x00034002;
use constant GLFW_CURSOR_DISABLED => 0x00034003;
use constant GLFW_ANY_RELEASE_BEHAVIOR => 0;
use constant GLFW_RELEASE_BEHAVIOR_FLUSH => 0x00035001;
use constant GLFW_RELEASE_BEHAVIOR_NONE => 0x00035002;
use constant GLFW_NATIVE_CONTEXT_API => 0x00036001;
use constant GLFW_EGL_CONTEXT_API => 0x00036002;
use constant GLFW_ARROW_CURSOR => 0x00036001;
use constant GLFW_IBEAM_CURSOR => 0x00036002;
use constant GLFW_CROSSHAIR_CURSOR => 0x00036003;
use constant GLFW_HAND_CURSOR => 0x00036004;
use constant GLFW_HRESIZE_CURSOR => 0x00036005;
use constant GLFW_VRESIZE_CURSOR => 0x00036006;
use constant GLFW_CONNECTED => 0x00040001;
use constant GLFW_DISCONNECTED => 0x00040002;
use constant GLFW_DONT_CARE => -1;
use constant GLFW_TRANSPARENT_FRAMEBUFFER => 0x0002000A;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OpenGL::GLFW ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
        glfwCreateCursor
        glfwCreateStandardCursor
        glfwCreateWindow
        glfwDefaultWindowHints
        glfwDestroyCursor
        glfwDestroyWindow
        glfwExtensionSupported
        glfwFocusWindow
        glfwGetClipboardString
        glfwGetCurrentContext
        glfwGetCursorPos
        glfwGetFramebufferSize
        glfwGetGammaRamp
        glfwGetInputMode
        glfwGetJoystickAxes
        glfwGetJoystickButtons
        glfwGetJoystickName
        glfwGetKey
        glfwGetKeyName
        glfwGetMonitorName
        glfwGetMonitorPhysicalSize
        glfwGetMonitorPos
        glfwGetMonitorWorkarea
        glfwGetMonitors
        glfwGetMouseButton
        glfwGetPrimaryMonitor
        glfwGetRequiredInstanceExtensions
        glfwGetTime
        glfwGetTimerFrequency
        glfwGetTimerValue
        glfwGetVersion
        glfwGetVersionString
        glfwGetVideoMode
        glfwGetVideoModes
        glfwGetWindowAttrib
        glfwGetWindowFrameSize
        glfwGetWindowMonitor
        glfwGetWindowPos
        glfwGetWindowSize
        glfwGetWindowUserPointer
        glfwHideWindow
        glfwIconifyWindow
        glfwInit
        glfwJoystickPresent
        glfwMakeContextCurrent
        glfwMaximizeWindow
        glfwPollEvents
        glfwPostEmptyEvent
        glfwRestoreWindow
        glfwSetClipboardString
        glfwSetCursor
        glfwSetCursorPos
        glfwSetCharCallback
        glfwSetCharModsCallback
        glfwSetCursorEnterCallback
        glfwSetCursorPosCallback
        glfwSetDropCallback
        glfwSetErrorCallback
        glfwSetFramebufferSizeCallback
        glfwSetJoystickCallback
        glfwSetKeyCallback
        glfwSetMonitorCallback
        glfwSetMouseButtonCallback
        glfwSetScrollCallback
        glfwSetWindowCloseCallback
        glfwSetWindowFocusCallback
        glfwSetWindowIconifyCallback
        glfwSetWindowPosCallback
        glfwSetWindowRefreshCallback
        glfwSetWindowSizeCallback
        glfwSetGamma
        glfwSetGammaRamp
        glfwSetInputMode
        glfwSetTime
        glfwSetWindowAspectRatio
        glfwSetWindowIcon
        glfwSetWindowMonitor
        glfwSetWindowPos
        glfwSetWindowShouldClose
        glfwSetWindowSize
        glfwSetWindowSizeLimits
        glfwSetWindowTitle
        glfwSetWindowUserPointer
        glfwShowWindow
        glfwSwapBuffers
        glfwSwapInterval
        glfwTerminate
        glfwVulkanSupported
        glfwWaitEvents
        glfwWaitEventsTimeout
        glfwWindowHint
        glfwWindowShouldClose
        GLFW_VERSION_MAJOR
        GLFW_VERSION_MINOR
        GLFW_VERSION_REVISION
        GLFW_TRUE
        GLFW_FALSE
        GLFW_RELEASE
        GLFW_PRESS
        GLFW_REPEAT
        GLFW_KEY_UNKNOWN
        GLFW_KEY_SPACE
        GLFW_KEY_APOSTROPHE
        GLFW_KEY_COMMA
        GLFW_KEY_MINUS
        GLFW_KEY_PERIOD
        GLFW_KEY_SLASH
        GLFW_KEY_0
        GLFW_KEY_1
        GLFW_KEY_2
        GLFW_KEY_3
        GLFW_KEY_4
        GLFW_KEY_5
        GLFW_KEY_6
        GLFW_KEY_7
        GLFW_KEY_8
        GLFW_KEY_9
        GLFW_KEY_SEMICOLON
        GLFW_KEY_EQUAL
        GLFW_KEY_A
        GLFW_KEY_B
        GLFW_KEY_C
        GLFW_KEY_D
        GLFW_KEY_E
        GLFW_KEY_F
        GLFW_KEY_G
        GLFW_KEY_H
        GLFW_KEY_I
        GLFW_KEY_J
        GLFW_KEY_K
        GLFW_KEY_L
        GLFW_KEY_M
        GLFW_KEY_N
        GLFW_KEY_O
        GLFW_KEY_P
        GLFW_KEY_Q
        GLFW_KEY_R
        GLFW_KEY_S
        GLFW_KEY_T
        GLFW_KEY_U
        GLFW_KEY_V
        GLFW_KEY_W
        GLFW_KEY_X
        GLFW_KEY_Y
        GLFW_KEY_Z
        GLFW_KEY_LEFT_BRACKET
        GLFW_KEY_BACKSLASH
        GLFW_KEY_RIGHT_BRACKET
        GLFW_KEY_GRAVE_ACCENT
        GLFW_KEY_WORLD_1
        GLFW_KEY_WORLD_2
        GLFW_KEY_ESCAPE
        GLFW_KEY_ENTER
        GLFW_KEY_TAB
        GLFW_KEY_BACKSPACE
        GLFW_KEY_INSERT
        GLFW_KEY_DELETE
        GLFW_KEY_RIGHT
        GLFW_KEY_LEFT
        GLFW_KEY_DOWN
        GLFW_KEY_UP
        GLFW_KEY_PAGE_UP
        GLFW_KEY_PAGE_DOWN
        GLFW_KEY_HOME
        GLFW_KEY_END
        GLFW_KEY_CAPS_LOCK
        GLFW_KEY_SCROLL_LOCK
        GLFW_KEY_NUM_LOCK
        GLFW_KEY_PRINT_SCREEN
        GLFW_KEY_PAUSE
        GLFW_KEY_F1
        GLFW_KEY_F2
        GLFW_KEY_F3
        GLFW_KEY_F4
        GLFW_KEY_F5
        GLFW_KEY_F6
        GLFW_KEY_F7
        GLFW_KEY_F8
        GLFW_KEY_F9
        GLFW_KEY_F10
        GLFW_KEY_F11
        GLFW_KEY_F12
        GLFW_KEY_F13
        GLFW_KEY_F14
        GLFW_KEY_F15
        GLFW_KEY_F16
        GLFW_KEY_F17
        GLFW_KEY_F18
        GLFW_KEY_F19
        GLFW_KEY_F20
        GLFW_KEY_F21
        GLFW_KEY_F22
        GLFW_KEY_F23
        GLFW_KEY_F24
        GLFW_KEY_F25
        GLFW_KEY_KP_0
        GLFW_KEY_KP_1
        GLFW_KEY_KP_2
        GLFW_KEY_KP_3
        GLFW_KEY_KP_4
        GLFW_KEY_KP_5
        GLFW_KEY_KP_6
        GLFW_KEY_KP_7
        GLFW_KEY_KP_8
        GLFW_KEY_KP_9
        GLFW_KEY_KP_DECIMAL
        GLFW_KEY_KP_DIVIDE
        GLFW_KEY_KP_MULTIPLY
        GLFW_KEY_KP_SUBTRACT
        GLFW_KEY_KP_ADD
        GLFW_KEY_KP_ENTER
        GLFW_KEY_KP_EQUAL
        GLFW_KEY_LEFT_SHIFT
        GLFW_KEY_LEFT_CONTROL
        GLFW_KEY_LEFT_ALT
        GLFW_KEY_LEFT_SUPER
        GLFW_KEY_RIGHT_SHIFT
        GLFW_KEY_RIGHT_CONTROL
        GLFW_KEY_RIGHT_ALT
        GLFW_KEY_RIGHT_SUPER
        GLFW_KEY_MENU
        GLFW_KEY_LAST
        GLFW_MOD_SHIFT
        GLFW_MOD_CONTROL
        GLFW_MOD_ALT
        GLFW_MOD_SUPER
        GLFW_MOUSE_BUTTON_1
        GLFW_MOUSE_BUTTON_2
        GLFW_MOUSE_BUTTON_3
        GLFW_MOUSE_BUTTON_4
        GLFW_MOUSE_BUTTON_5
        GLFW_MOUSE_BUTTON_6
        GLFW_MOUSE_BUTTON_7
        GLFW_MOUSE_BUTTON_8
        GLFW_MOUSE_BUTTON_LAST
        GLFW_MOUSE_BUTTON_LEFT
        GLFW_MOUSE_BUTTON_RIGHT
        GLFW_MOUSE_BUTTON_MIDDLE
        GLFW_JOYSTICK_1
        GLFW_JOYSTICK_2
        GLFW_JOYSTICK_3
        GLFW_JOYSTICK_4
        GLFW_JOYSTICK_5
        GLFW_JOYSTICK_6
        GLFW_JOYSTICK_7
        GLFW_JOYSTICK_8
        GLFW_JOYSTICK_9
        GLFW_JOYSTICK_10
        GLFW_JOYSTICK_11
        GLFW_JOYSTICK_12
        GLFW_JOYSTICK_13
        GLFW_JOYSTICK_14
        GLFW_JOYSTICK_15
        GLFW_JOYSTICK_16
        GLFW_JOYSTICK_LAST
        GLFW_NOT_INITIALIZED
        GLFW_NO_CURRENT_CONTEXT
        GLFW_INVALID_ENUM
        GLFW_INVALID_VALUE
        GLFW_OUT_OF_MEMORY
        GLFW_API_UNAVAILABLE
        GLFW_VERSION_UNAVAILABLE
        GLFW_PLATFORM_ERROR
        GLFW_FORMAT_UNAVAILABLE
        GLFW_NO_WINDOW_CONTEXT
        GLFW_FOCUSED
        GLFW_ICONIFIED
        GLFW_RESIZABLE
        GLFW_VISIBLE
        GLFW_DECORATED
        GLFW_AUTO_ICONIFY
        GLFW_FLOATING
        GLFW_MAXIMIZED
        GLFW_RED_BITS
        GLFW_GREEN_BITS
        GLFW_BLUE_BITS
        GLFW_ALPHA_BITS
        GLFW_DEPTH_BITS
        GLFW_STENCIL_BITS
        GLFW_ACCUM_RED_BITS
        GLFW_ACCUM_GREEN_BITS
        GLFW_ACCUM_BLUE_BITS
        GLFW_ACCUM_ALPHA_BITS
        GLFW_AUX_BUFFERS
        GLFW_STEREO
        GLFW_SAMPLES
        GLFW_SRGB_CAPABLE
        GLFW_REFRESH_RATE
        GLFW_DOUBLEBUFFER
        GLFW_CLIENT_API
        GLFW_CONTEXT_VERSION_MAJOR
        GLFW_CONTEXT_VERSION_MINOR
        GLFW_CONTEXT_REVISION
        GLFW_CONTEXT_ROBUSTNESS
        GLFW_OPENGL_FORWARD_COMPAT
        GLFW_OPENGL_DEBUG_CONTEXT
        GLFW_OPENGL_PROFILE
        GLFW_CONTEXT_RELEASE_BEHAVIOR
        GLFW_CONTEXT_NO_ERROR
        GLFW_CONTEXT_CREATION_API
        GLFW_NO_API
        GLFW_OPENGL_API
        GLFW_OPENGL_ES_API
        GLFW_NO_ROBUSTNESS
        GLFW_NO_RESET_NOTIFICATION
        GLFW_LOSE_CONTEXT_ON_RESET
        GLFW_OPENGL_ANY_PROFILE
        GLFW_OPENGL_CORE_PROFILE
        GLFW_OPENGL_COMPAT_PROFILE
        GLFW_CURSOR
        GLFW_STICKY_KEYS
        GLFW_STICKY_MOUSE_BUTTONS
        GLFW_CURSOR_NORMAL
        GLFW_CURSOR_HIDDEN
        GLFW_CURSOR_DISABLED
        GLFW_ANY_RELEASE_BEHAVIOR
        GLFW_RELEASE_BEHAVIOR_FLUSH
        GLFW_RELEASE_BEHAVIOR_NONE
        GLFW_NATIVE_CONTEXT_API
        GLFW_EGL_CONTEXT_API
        GLFW_ARROW_CURSOR
        GLFW_IBEAM_CURSOR
        GLFW_CROSSHAIR_CURSOR
        GLFW_HAND_CURSOR
        GLFW_HRESIZE_CURSOR
        GLFW_VRESIZE_CURSOR
        GLFW_CONNECTED
        GLFW_DISCONNECTED
        GLFW_DONT_CARE
        GLFW_TRANSPARENT_FRAMEBUFFER
        glfwCreateWindowSurface
        glfwGetInstanceProcAddress
        glfwGetPhysicalDevicePresentationSupport
        glfwGetProcAddress
        glfwGetRequiredInstanceExtensions
        NULL
        ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION    = '0.0401';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;    # see L<perlmodstyle>

require XSLoader;
XSLoader::load('OpenGL::GLFW', $XS_VERSION);

# Preloaded methods go here.

## sub NULL { return \0 }

1;
__END__


=head1 NAME

OpenGL::GLFW - Perl bindings for the GLFW library

=head1 SYNOPSIS

  use OpenGL::GLFW qw(:all);
  use OpenGL::Modern qw(:all);  # for OpenGL


=head1 DESCRIPTION

L<OpenGL::GLFW> provides perl5 bindings to the GLFW
library for OpenGL applications development.  The
implementation is a direct translation of the
GLFW C interface to perl.  You can use the official
GLFW documentation at L<http://www.glfw.org/documentation.html>
for the specifics of the GLFW API.  The documentation
here is on the perl usages and calling conventions.

At the top level, we have the following correspondences
between these perl bindings and the C API:

=over 4

=item *

C<GLFWwindow>, C<GLFWmonitor>, and C<GLFWcursor> are
opaque data types and pointers to them are returned as
perl scalar references.

=item *

C<GLFWvidmode>, C<GLFWgammaramp>, and C<GLFWimage> types
are mapped to perl hashes and passed and returned as the
corresponding references.

The pointers to red, green, and blue channels of the
gamma ramp become strings of packed ushort values.

Similarly, the pointer to pixels in the images use
a packed string of C<4 x width x height> unsigned
char values per pixel as C<[R,G,B,A]> for pixels C<(0,0)>
through C<(width-1,height-1)>.

See the C<examples/checkimg.pl> for an example using the
Perl Data Language module, L<PDL>, to construct the the
C<GLFWimage> hash.

=item *

The glfwSetXxxCallback routines do not implement the
return value for the previous callback.  If you need
it, you'll need to track and save yourself.

=item *

Vulkan is not currently supported and C<glfwVulkanSupported>
always returns false.

=item *

Neither C<glfwGetProcAddress> nor C<glfwExtensionSupported>
are implemented.  Please use the L<OpenGL::Modern> or L<OpenGL>
modules instead.

=back


=head2 EXPORT

None by default.


=head1 PERL USAGE


=head2 Per-window callbacks

  glfwSetWindowPosCallback($window, $cbfun)
  $windowpos_cbfun = sub ($window, $xpos, $ypos) { ... }

  glfwSetWindowSizeCallback($window, $cbfun)
  $windowsize_cbfun = sub ($window, $width, $height) { ... }

  glfwSetWindowCloseCallback($window, $cbfun)
  $windowclose_cbfun = sub ($window) { ... }

  glfwSetWindowRefreshCallback($window, $cbfun)
  $windowrefresh_cbfun = sub ($window) { ... }

  glfwSetWindowFocusCallback($window, $cbfun)
  $windowfocus_cbfun = sub ($window, $focused) { ... }

  glfwSetWindowIconifyCallback($window, $cbfun)
  $windowiconify_cbfun = sub ($window, $iconified) { ... }

  glfwSetFramebufferSizeCallback($window, $cbfun)
  $framebuffersize_cbfun = sub ($window, $width, $height) { ... }

  glfwSetKeyCallback($window, $cbfun)
  $key_cbfun = sub ($window, $key, $scancode, $action, $mods) { ... }

  glfwSetCharCallback($window, $cbfun)
  $char_cbfun = sub ($window, $codepoint) { ... }

  glfwSetCharModsCallback($window, $cbfun)
  $charmods_cbfun = sub ($window, $codepoint, $mods) { ... }

  glfwSetMouseButtonCallback($window, $cbfun)
  $mousebutton_cbfun = sub ($window, $button, $action, $mods) { ... }

  glfwSetCursorPosCallback($window, $cbfun)
  $cursorpos_cbfun = sub ($window, $xpos, $ypos) { ... }

  glfwSetCursorEnterCallback($window, $cbfun)
  $cursorenter_cbfun = sub ($window, $entered) { ... }

  glfwSetScrollCallback($window, $cbfun)
  $scroll_cbfun = sub ($window, $xoffset, $yoffset) { ... }

  glfwSetDropCallback($window, $cbfun)
  $drop_cbfun = sub ($window, $count, @paths) { ... }


=head2 Global callbacks

  glfwSetErrorCallback($cbfun)
  $error_cbfun = sub ($error, $description) { ... }

  glfwSetMonitorCallback($cbfun)
  $monitor_cbfun = sub ($monitor, $event) { ... }

  glfwSetJoystickCallback($cbfun)
  $joystick_cbfun = sub ($joy_id, $event) { ... }


=head2 Icons/Cursors/Images

  glfwSetWindowIcon($window, $image_hash, ...)

  $cursor = glfwCreateCursor($image_hash, $xhot, $yhot)

  $cursor = glfwCreateStandardCursor($shape)

  glfwDestroyCursor($cursor)

  glfwSetCursor($window, $cursor)

where

  $image_hash = {

    # The width, in pixels, of this image.
    width  => $width,

    # The height, in pixels, of this image.
    height => $height,

    # The pixel data of this image, arranged
    # left-to-right, top-to-bottom in a packed
    # string of unsigned char data.
    pixels => $pixels

  }


=head2 Monitors

  $monitor = glfwGetPrimaryMonitor()

  @monitors = glfwGetMonitors()

  $name = glfwGetMonitorName($monitor)

  ($widthMM, $heightMM) = glfwGetMonitorPhysicalSize($monitor)

  ($xpos, $ypos) = glfwGetMonitorPos($monitor)

  ($xpos, $ypos, $width, $height) = glfwGetMonitorWorkarea($monitor)

=head2 Gamma Settings

  glfwSetGamma($monitor, $gamma)

  $gammaramp_hash = glfwGetGammaRamp($monitor)

  glfwSetGammaRamp($monitor, $gammaramp_hash)

where

  $gammaramp_hash = {

    # An array of values describing the
    # response of the red channel as a
    # string of packed unsigned short data.
    red => $red,

    # An array of values describing the
    # response of the green channel as a
    # string of packed unsigned short data.
    green => $green,

    # An array of values describing the
    # response of the blue channel as a
    # string of packed unsigned short data.
    blue => $blue,

    # The number of elements in each array.
    size => $size

  }

=head2 Video Mode

  $vidmode_hash = glfwGetVideoMode($monitor)

  @vidmodes = glfwGetVideoModes($monitor);  # elements are vid mode hashes

where

  $vidmode_hash = {

    # The width, in screen coordinates, of the video mode.
    width => $width,

    # The height, in screen coordinates, of the video mode.
    height => $height,

    # The bit depth of the red channel of the video mode.
    redBits => $redBits,

    # The bit depth of the green channel of the video mode.
    greenBits => $greenBits,

    # The bit depth of the blue channel of the video mode.
    blueBits => $blueBitsm,

    # The refresh rate, in Hz, of the video mode.
    refreshRate => $refreshRate

  }

=head2 Windows and Interaction

  $monitor = glfwGetWindowMonitor($window); # monitor of full screen window or undef?

  $window = glfwCreateWindow($width, $height, $title, $monitor or NULL, $share_window or NULL)

  glfwSetWindowMonitor($window, $monitor, $xpos, $ypos, $width, $height, $refreshRate)

  $window = glfwGetCurrentContext()

  $value = glfwGetInputMode($window, $mode)

  $pressed = glfwGetKey($window, $key)

  $pressed = glfwGetMouseButton($window, $button)

  $value = glfwGetWindowAttrib($window, $attrib)

  $value = glfwWindowShouldClose($window)

  glfwDestroyWindow($window)

  glfwFocusWindow($window)

  $string = glfwGetClipboardString($window)

  ($xpos, $ypos) = glfwGetCursorPos($window)

  ($width, $height) = glfwGetFramebufferSize($window)

  ($left, $top, $right, $bottom) = glfwGetWindowFrameSize($window)

  ($xpos, $ypos) = glfwGetWindowPos($window)

  ($width, $height) = glfwGetWindowSize($window)

  glfwHideWindow($window)

  glfwIconifyWindow($window)

  glfwMakeContextCurrent($window)

  glfwMaximizeWindow($window)

  glfwRestoreWindow($window)

  glfwSetClipboardString($window, $string)

  glfwSetCursorPos($window, $xpos, $ypos)

  glfwSetInputMode($window, $mode, $value)

  glfwSetWindowAspectRatio($window, $numer, $denom)

  glfwSetWindowPos($window, $xpos, $ypos)

  glfwSetWindowShouldClose($window, $value)

  glfwSetWindowSize($window, $width, $height)

  glfwSetWindowSizeLimits($window, $minwidth, $minheight, $maxwidth, $maxheight)

  glfwSetWindowTitle($window, $title)

  glfwSetWindowUserPointer($window, $ref)

  glfwShowWindow($window)

  glfwSwapBuffers($window)

  $ref = glfwGetWindowUserPointer($window)

  glfwDefaultWindowHints()

  ($major, $minor, $rev) = glfwGetVersion()

  glfwPollEvents()

  glfwPostEmptyEvent()

  glfwSetTime($time)

  glfwSwapInterval($interval)

  glfwTerminate()

  glfwWaitEvents()

  glfwWaitEventsTimeout($timeout)

  glfwWindowHint($hint, $value)

  $name = glfwGetJoystickName($joy)

  $name = glfwGetKeyName($key, $scancode)

  $version = glfwGetVersionString()

  @axes = glfwGetJoystickAxes($joy)

  @buttons = glfwGetJoystickButtons($joy)

  $status = glfwInit()

  $ispresent = glfwJoystickPresent($joy)

  $time = glfwGetTime()

  $frequency = glfwGetTimerFrequency()

  $timervalue = glfwGetTimerValue()

  $supported = glfwVulkanSupported()


=head2 GLFW OpenGL Extension checks are not implemented

  glfwExtensionSupported

  glfwGetProcAddress


=head2 Vulkan not implemented

  glfwGetRequiredInstanceExtensions

  glfwGetInstanceProcAddress

  glfwGetPhysicalDevicePresentationSupport

  glfwCreateWindowSurface


=head1 SEE ALSO

See the L<OpenGL::Modern> module for the perl bindings
for modern OpenGL APIs and the original perl L<OpenGL>
module bindings for OpenGL 1.x-2 with and some extensions.

Please use the Perl OpenGL mailing list at
L<sf.net|https://sourceforge.net/p/pogl/mailman/?source=navbar>
ask questions, provide feedback or to discuss L<OpenGL::GLFW>.

Perl OpenGL IRC is at #pogl on irc.perl.org and may also be
used for GLFW topics.


=head1 AUTHOR

Chris Marshall, E<lt>chm@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Chris Marshall, E<lt>chm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
