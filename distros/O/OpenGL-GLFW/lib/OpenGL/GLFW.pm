package OpenGL::GLFW;

use 5.010001;
use strict;
use warnings;

#
# Declare GLFW constants with the constant pragma for perl
#
use constant NULL => \0;
my %const_hash; BEGIN { %const_hash = (
  GLFW_VERSION_MAJOR => 3,
  GLFW_VERSION_MINOR => 4,
  GLFW_VERSION_REVISION => 0,
  GLFW_TRUE => 1,
  GLFW_FALSE => 0,
  GLFW_RELEASE => 0,
  GLFW_PRESS => 1,
  GLFW_REPEAT => 2,
  GLFW_HAT_CENTERED => 0,
  GLFW_HAT_UP => 1,
  GLFW_HAT_RIGHT => 2,
  GLFW_HAT_DOWN => 4,
  GLFW_HAT_LEFT => 8,
  GLFW_KEY_UNKNOWN => -1,
  GLFW_KEY_SPACE => 32,
  GLFW_KEY_APOSTROPHE => 39,
  GLFW_KEY_COMMA => 44,
  GLFW_KEY_MINUS => 45,
  GLFW_KEY_PERIOD => 46,
  GLFW_KEY_SLASH => 47,
  GLFW_KEY_0 => 48,
  GLFW_KEY_1 => 49,
  GLFW_KEY_2 => 50,
  GLFW_KEY_3 => 51,
  GLFW_KEY_4 => 52,
  GLFW_KEY_5 => 53,
  GLFW_KEY_6 => 54,
  GLFW_KEY_7 => 55,
  GLFW_KEY_8 => 56,
  GLFW_KEY_9 => 57,
  GLFW_KEY_SEMICOLON => 59,
  GLFW_KEY_EQUAL => 61,
  GLFW_KEY_A => 65,
  GLFW_KEY_B => 66,
  GLFW_KEY_C => 67,
  GLFW_KEY_D => 68,
  GLFW_KEY_E => 69,
  GLFW_KEY_F => 70,
  GLFW_KEY_G => 71,
  GLFW_KEY_H => 72,
  GLFW_KEY_I => 73,
  GLFW_KEY_J => 74,
  GLFW_KEY_K => 75,
  GLFW_KEY_L => 76,
  GLFW_KEY_M => 77,
  GLFW_KEY_N => 78,
  GLFW_KEY_O => 79,
  GLFW_KEY_P => 80,
  GLFW_KEY_Q => 81,
  GLFW_KEY_R => 82,
  GLFW_KEY_S => 83,
  GLFW_KEY_T => 84,
  GLFW_KEY_U => 85,
  GLFW_KEY_V => 86,
  GLFW_KEY_W => 87,
  GLFW_KEY_X => 88,
  GLFW_KEY_Y => 89,
  GLFW_KEY_Z => 90,
  GLFW_KEY_LEFT_BRACKET => 91,
  GLFW_KEY_BACKSLASH => 92,
  GLFW_KEY_RIGHT_BRACKET => 93,
  GLFW_KEY_GRAVE_ACCENT => 96,
  GLFW_KEY_WORLD_1 => 161,
  GLFW_KEY_WORLD_2 => 162,
  GLFW_KEY_ESCAPE => 256,
  GLFW_KEY_ENTER => 257,
  GLFW_KEY_TAB => 258,
  GLFW_KEY_BACKSPACE => 259,
  GLFW_KEY_INSERT => 260,
  GLFW_KEY_DELETE => 261,
  GLFW_KEY_RIGHT => 262,
  GLFW_KEY_LEFT => 263,
  GLFW_KEY_DOWN => 264,
  GLFW_KEY_UP => 265,
  GLFW_KEY_PAGE_UP => 266,
  GLFW_KEY_PAGE_DOWN => 267,
  GLFW_KEY_HOME => 268,
  GLFW_KEY_END => 269,
  GLFW_KEY_CAPS_LOCK => 280,
  GLFW_KEY_SCROLL_LOCK => 281,
  GLFW_KEY_NUM_LOCK => 282,
  GLFW_KEY_PRINT_SCREEN => 283,
  GLFW_KEY_PAUSE => 284,
  GLFW_KEY_F1 => 290,
  GLFW_KEY_F2 => 291,
  GLFW_KEY_F3 => 292,
  GLFW_KEY_F4 => 293,
  GLFW_KEY_F5 => 294,
  GLFW_KEY_F6 => 295,
  GLFW_KEY_F7 => 296,
  GLFW_KEY_F8 => 297,
  GLFW_KEY_F9 => 298,
  GLFW_KEY_F10 => 299,
  GLFW_KEY_F11 => 300,
  GLFW_KEY_F12 => 301,
  GLFW_KEY_F13 => 302,
  GLFW_KEY_F14 => 303,
  GLFW_KEY_F15 => 304,
  GLFW_KEY_F16 => 305,
  GLFW_KEY_F17 => 306,
  GLFW_KEY_F18 => 307,
  GLFW_KEY_F19 => 308,
  GLFW_KEY_F20 => 309,
  GLFW_KEY_F21 => 310,
  GLFW_KEY_F22 => 311,
  GLFW_KEY_F23 => 312,
  GLFW_KEY_F24 => 313,
  GLFW_KEY_F25 => 314,
  GLFW_KEY_KP_0 => 320,
  GLFW_KEY_KP_1 => 321,
  GLFW_KEY_KP_2 => 322,
  GLFW_KEY_KP_3 => 323,
  GLFW_KEY_KP_4 => 324,
  GLFW_KEY_KP_5 => 325,
  GLFW_KEY_KP_6 => 326,
  GLFW_KEY_KP_7 => 327,
  GLFW_KEY_KP_8 => 328,
  GLFW_KEY_KP_9 => 329,
  GLFW_KEY_KP_DECIMAL => 330,
  GLFW_KEY_KP_DIVIDE => 331,
  GLFW_KEY_KP_MULTIPLY => 332,
  GLFW_KEY_KP_SUBTRACT => 333,
  GLFW_KEY_KP_ADD => 334,
  GLFW_KEY_KP_ENTER => 335,
  GLFW_KEY_KP_EQUAL => 336,
  GLFW_KEY_LEFT_SHIFT => 340,
  GLFW_KEY_LEFT_CONTROL => 341,
  GLFW_KEY_LEFT_ALT => 342,
  GLFW_KEY_LEFT_SUPER => 343,
  GLFW_KEY_RIGHT_SHIFT => 344,
  GLFW_KEY_RIGHT_CONTROL => 345,
  GLFW_KEY_RIGHT_ALT => 346,
  GLFW_KEY_RIGHT_SUPER => 347,
  GLFW_KEY_MENU => 348,
  GLFW_MOD_SHIFT => 0x0001,
  GLFW_MOD_CONTROL => 0x0002,
  GLFW_MOD_ALT => 0x0004,
  GLFW_MOD_SUPER => 0x0008,
  GLFW_MOD_CAPS_LOCK => 0x0010,
  GLFW_MOD_NUM_LOCK => 0x0020,
  GLFW_MOUSE_BUTTON_1 => 0,
  GLFW_MOUSE_BUTTON_2 => 1,
  GLFW_MOUSE_BUTTON_3 => 2,
  GLFW_MOUSE_BUTTON_4 => 3,
  GLFW_MOUSE_BUTTON_5 => 4,
  GLFW_MOUSE_BUTTON_6 => 5,
  GLFW_MOUSE_BUTTON_7 => 6,
  GLFW_MOUSE_BUTTON_8 => 7,
  GLFW_JOYSTICK_1 => 0,
  GLFW_JOYSTICK_2 => 1,
  GLFW_JOYSTICK_3 => 2,
  GLFW_JOYSTICK_4 => 3,
  GLFW_JOYSTICK_5 => 4,
  GLFW_JOYSTICK_6 => 5,
  GLFW_JOYSTICK_7 => 6,
  GLFW_JOYSTICK_8 => 7,
  GLFW_JOYSTICK_9 => 8,
  GLFW_JOYSTICK_10 => 9,
  GLFW_JOYSTICK_11 => 10,
  GLFW_JOYSTICK_12 => 11,
  GLFW_JOYSTICK_13 => 12,
  GLFW_JOYSTICK_14 => 13,
  GLFW_JOYSTICK_15 => 14,
  GLFW_JOYSTICK_16 => 15,
  GLFW_GAMEPAD_BUTTON_A => 0,
  GLFW_GAMEPAD_BUTTON_B => 1,
  GLFW_GAMEPAD_BUTTON_X => 2,
  GLFW_GAMEPAD_BUTTON_Y => 3,
  GLFW_GAMEPAD_BUTTON_LEFT_BUMPER => 4,
  GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER => 5,
  GLFW_GAMEPAD_BUTTON_BACK => 6,
  GLFW_GAMEPAD_BUTTON_START => 7,
  GLFW_GAMEPAD_BUTTON_GUIDE => 8,
  GLFW_GAMEPAD_BUTTON_LEFT_THUMB => 9,
  GLFW_GAMEPAD_BUTTON_RIGHT_THUMB => 10,
  GLFW_GAMEPAD_BUTTON_DPAD_UP => 11,
  GLFW_GAMEPAD_BUTTON_DPAD_RIGHT => 12,
  GLFW_GAMEPAD_BUTTON_DPAD_DOWN => 13,
  GLFW_GAMEPAD_BUTTON_DPAD_LEFT => 14,
  GLFW_GAMEPAD_AXIS_LEFT_X => 0,
  GLFW_GAMEPAD_AXIS_LEFT_Y => 1,
  GLFW_GAMEPAD_AXIS_RIGHT_X => 2,
  GLFW_GAMEPAD_AXIS_RIGHT_Y => 3,
  GLFW_GAMEPAD_AXIS_LEFT_TRIGGER => 4,
  GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER => 5,
  GLFW_NO_ERROR => 0,
  GLFW_NOT_INITIALIZED => 0x00010001,
  GLFW_NO_CURRENT_CONTEXT => 0x00010002,
  GLFW_INVALID_ENUM => 0x00010003,
  GLFW_INVALID_VALUE => 0x00010004,
  GLFW_OUT_OF_MEMORY => 0x00010005,
  GLFW_API_UNAVAILABLE => 0x00010006,
  GLFW_VERSION_UNAVAILABLE => 0x00010007,
  GLFW_PLATFORM_ERROR => 0x00010008,
  GLFW_FORMAT_UNAVAILABLE => 0x00010009,
  GLFW_NO_WINDOW_CONTEXT => 0x0001000A,
  GLFW_CURSOR_UNAVAILABLE => 0x0001000B,
  GLFW_FEATURE_UNAVAILABLE => 0x0001000C,
  GLFW_FEATURE_UNIMPLEMENTED => 0x0001000D,
  GLFW_PLATFORM_UNAVAILABLE => 0x0001000E,
  GLFW_FOCUSED => 0x00020001,
  GLFW_ICONIFIED => 0x00020002,
  GLFW_RESIZABLE => 0x00020003,
  GLFW_VISIBLE => 0x00020004,
  GLFW_DECORATED => 0x00020005,
  GLFW_AUTO_ICONIFY => 0x00020006,
  GLFW_FLOATING => 0x00020007,
  GLFW_MAXIMIZED => 0x00020008,
  GLFW_CENTER_CURSOR => 0x00020009,
  GLFW_TRANSPARENT_FRAMEBUFFER => 0x0002000A,
  GLFW_HOVERED => 0x0002000B,
  GLFW_FOCUS_ON_SHOW => 0x0002000C,
  GLFW_MOUSE_PASSTHROUGH => 0x0002000D,
  GLFW_POSITION_X => 0x0002000E,
  GLFW_POSITION_Y => 0x0002000F,
  GLFW_RED_BITS => 0x00021001,
  GLFW_GREEN_BITS => 0x00021002,
  GLFW_BLUE_BITS => 0x00021003,
  GLFW_ALPHA_BITS => 0x00021004,
  GLFW_DEPTH_BITS => 0x00021005,
  GLFW_STENCIL_BITS => 0x00021006,
  GLFW_ACCUM_RED_BITS => 0x00021007,
  GLFW_ACCUM_GREEN_BITS => 0x00021008,
  GLFW_ACCUM_BLUE_BITS => 0x00021009,
  GLFW_ACCUM_ALPHA_BITS => 0x0002100A,
  GLFW_AUX_BUFFERS => 0x0002100B,
  GLFW_STEREO => 0x0002100C,
  GLFW_SAMPLES => 0x0002100D,
  GLFW_SRGB_CAPABLE => 0x0002100E,
  GLFW_REFRESH_RATE => 0x0002100F,
  GLFW_DOUBLEBUFFER => 0x00021010,
  GLFW_CLIENT_API => 0x00022001,
  GLFW_CONTEXT_VERSION_MAJOR => 0x00022002,
  GLFW_CONTEXT_VERSION_MINOR => 0x00022003,
  GLFW_CONTEXT_REVISION => 0x00022004,
  GLFW_CONTEXT_ROBUSTNESS => 0x00022005,
  GLFW_OPENGL_FORWARD_COMPAT => 0x00022006,
  GLFW_CONTEXT_DEBUG => 0x00022007,
  GLFW_OPENGL_PROFILE => 0x00022008,
  GLFW_CONTEXT_RELEASE_BEHAVIOR => 0x00022009,
  GLFW_CONTEXT_NO_ERROR => 0x0002200A,
  GLFW_CONTEXT_CREATION_API => 0x0002200B,
  GLFW_SCALE_TO_MONITOR => 0x0002200C,
  GLFW_SCALE_FRAMEBUFFER => 0x0002200D,
  GLFW_COCOA_RETINA_FRAMEBUFFER => 0x00023001,
  GLFW_COCOA_FRAME_NAME => 0x00023002,
  GLFW_COCOA_GRAPHICS_SWITCHING => 0x00023003,
  GLFW_X11_CLASS_NAME => 0x00024001,
  GLFW_X11_INSTANCE_NAME => 0x00024002,
  GLFW_WIN32_KEYBOARD_MENU => 0x00025001,
  GLFW_WIN32_SHOWDEFAULT => 0x00025002,
  GLFW_WAYLAND_APP_ID => 0x00026001,
  GLFW_NO_API => 0,
  GLFW_OPENGL_API => 0x00030001,
  GLFW_OPENGL_ES_API => 0x00030002,
  GLFW_NO_ROBUSTNESS => 0,
  GLFW_NO_RESET_NOTIFICATION => 0x00031001,
  GLFW_LOSE_CONTEXT_ON_RESET => 0x00031002,
  GLFW_OPENGL_ANY_PROFILE => 0,
  GLFW_OPENGL_CORE_PROFILE => 0x00032001,
  GLFW_OPENGL_COMPAT_PROFILE => 0x00032002,
  GLFW_CURSOR => 0x00033001,
  GLFW_STICKY_KEYS => 0x00033002,
  GLFW_STICKY_MOUSE_BUTTONS => 0x00033003,
  GLFW_LOCK_KEY_MODS => 0x00033004,
  GLFW_RAW_MOUSE_MOTION => 0x00033005,
  GLFW_CURSOR_NORMAL => 0x00034001,
  GLFW_CURSOR_HIDDEN => 0x00034002,
  GLFW_CURSOR_DISABLED => 0x00034003,
  GLFW_CURSOR_CAPTURED => 0x00034004,
  GLFW_ANY_RELEASE_BEHAVIOR => 0,
  GLFW_RELEASE_BEHAVIOR_FLUSH => 0x00035001,
  GLFW_RELEASE_BEHAVIOR_NONE => 0x00035002,
  GLFW_NATIVE_CONTEXT_API => 0x00036001,
  GLFW_EGL_CONTEXT_API => 0x00036002,
  GLFW_OSMESA_CONTEXT_API => 0x00036003,
  GLFW_ANGLE_PLATFORM_TYPE_NONE => 0x00037001,
  GLFW_ANGLE_PLATFORM_TYPE_OPENGL => 0x00037002,
  GLFW_ANGLE_PLATFORM_TYPE_OPENGLES => 0x00037003,
  GLFW_ANGLE_PLATFORM_TYPE_D3D9 => 0x00037004,
  GLFW_ANGLE_PLATFORM_TYPE_D3D11 => 0x00037005,
  GLFW_ANGLE_PLATFORM_TYPE_VULKAN => 0x00037007,
  GLFW_ANGLE_PLATFORM_TYPE_METAL => 0x00037008,
  GLFW_WAYLAND_PREFER_LIBDECOR => 0x00038001,
  GLFW_WAYLAND_DISABLE_LIBDECOR => 0x00038002,
  GLFW_ANY_POSITION => 0x80000000,
  GLFW_ARROW_CURSOR => 0x00036001,
  GLFW_IBEAM_CURSOR => 0x00036002,
  GLFW_CROSSHAIR_CURSOR => 0x00036003,
  GLFW_POINTING_HAND_CURSOR => 0x00036004,
  GLFW_RESIZE_EW_CURSOR => 0x00036005,
  GLFW_RESIZE_NS_CURSOR => 0x00036006,
  GLFW_RESIZE_NWSE_CURSOR => 0x00036007,
  GLFW_RESIZE_NESW_CURSOR => 0x00036008,
  GLFW_RESIZE_ALL_CURSOR => 0x00036009,
  GLFW_NOT_ALLOWED_CURSOR => 0x0003600A,
  GLFW_CONNECTED => 0x00040001,
  GLFW_DISCONNECTED => 0x00040002,
  GLFW_JOYSTICK_HAT_BUTTONS => 0x00050001,
  GLFW_ANGLE_PLATFORM_TYPE => 0x00050002,
  GLFW_PLATFORM => 0x00050003,
  GLFW_COCOA_CHDIR_RESOURCES => 0x00051001,
  GLFW_COCOA_MENUBAR => 0x00051002,
  GLFW_X11_XCB_VULKAN_SURFACE => 0x00052001,
  GLFW_WAYLAND_LIBDECOR => 0x00053001,
  GLFW_ANY_PLATFORM => 0x00060000,
  GLFW_PLATFORM_WIN32 => 0x00060001,
  GLFW_PLATFORM_COCOA => 0x00060002,
  GLFW_PLATFORM_WAYLAND => 0x00060003,
  GLFW_PLATFORM_X11 => 0x00060004,
  GLFW_PLATFORM_NULL => 0x00060005,
  GLFW_DONT_CARE => -1,
); }
use constant \%const_hash;
my %const_hash2; BEGIN { %const_hash2 = (
  GLFW_HAT_RIGHT_UP => (GLFW_HAT_RIGHT | GLFW_HAT_UP),
  GLFW_HAT_RIGHT_DOWN => (GLFW_HAT_RIGHT | GLFW_HAT_DOWN),
  GLFW_HAT_LEFT_UP => (GLFW_HAT_LEFT  | GLFW_HAT_UP),
  GLFW_HAT_LEFT_DOWN => (GLFW_HAT_LEFT  | GLFW_HAT_DOWN),
  GLFW_KEY_LAST => GLFW_KEY_MENU,
  GLFW_MOUSE_BUTTON_LAST => GLFW_MOUSE_BUTTON_8,
  GLFW_MOUSE_BUTTON_LEFT => GLFW_MOUSE_BUTTON_1,
  GLFW_MOUSE_BUTTON_RIGHT => GLFW_MOUSE_BUTTON_2,
  GLFW_MOUSE_BUTTON_MIDDLE => GLFW_MOUSE_BUTTON_3,
  GLFW_JOYSTICK_LAST => GLFW_JOYSTICK_16,
  GLFW_GAMEPAD_BUTTON_LAST => GLFW_GAMEPAD_BUTTON_DPAD_LEFT,
  GLFW_GAMEPAD_BUTTON_CROSS => GLFW_GAMEPAD_BUTTON_A,
  GLFW_GAMEPAD_BUTTON_CIRCLE => GLFW_GAMEPAD_BUTTON_B,
  GLFW_GAMEPAD_BUTTON_SQUARE => GLFW_GAMEPAD_BUTTON_X,
  GLFW_GAMEPAD_BUTTON_TRIANGLE => GLFW_GAMEPAD_BUTTON_Y,
  GLFW_GAMEPAD_AXIS_LAST => GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER,
  GLFW_OPENGL_DEBUG_CONTEXT => GLFW_CONTEXT_DEBUG,
  GLFW_HRESIZE_CURSOR => GLFW_RESIZE_EW_CURSOR,
  GLFW_VRESIZE_CURSOR => GLFW_RESIZE_NS_CURSOR,
  GLFW_HAND_CURSOR => GLFW_POINTING_HAND_CURSOR,
); }
use constant \%const_hash2;
%const_hash = (%const_hash, %const_hash2);

use Exporter 'import';

my @const = (qw(NULL), sort keys %const_hash);
my @functions = qw(
  glfwRequestWindowAttention
  glfwPlatformSupported
  glfwGetPlatform
  glfwGetError
  glfwInitHint
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
  glfwCreateWindowSurface
  glfwGetInstanceProcAddress
  glfwGetPhysicalDevicePresentationSupport
  glfwGetProcAddress
  glfwGetRequiredInstanceExtensions
);
our %EXPORT_TAGS = (
  constants => \@const,
  functions => \@functions,
  all => [ @const, @functions ],
);

our @EXPORT_OK = @{ $EXPORT_TAGS{all} };

our $VERSION    = '0.0403';
$VERSION =~ tr/_//d;
our $XS_VERSION = $VERSION;

require XSLoader;
XSLoader::load('OpenGL::GLFW', $XS_VERSION);

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
