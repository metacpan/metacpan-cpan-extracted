package OpenGL::GLX;

=head1 NAME

OpenGL::GLX - module encapsulating GLX functions

=cut

use strict;
use warnings;

use Exporter 'import';
require DynaLoader;

our $VERSION = '0.7003';
our @ISA = qw(DynaLoader);

our @const_common = qw(
   GLX_ACCUM_ALPHA_SIZE
   GLX_ACCUM_BLUE_SIZE
   GLX_ACCUM_GREEN_SIZE
   GLX_ACCUM_RED_SIZE
   GLX_ALPHA_SIZE
   GLX_AUX_BUFFERS
   GLX_BLUE_SIZE
   GLX_BUFFER_SIZE
   GLX_DEPTH_SIZE
   GLX_DOUBLEBUFFER
   GLX_GREEN_SIZE
   GLX_LEVEL
   GLX_RED_SIZE
   GLX_RGBA
   GLX_STENCIL_SIZE
   GLX_STEREO
   GLX_USE_GL
);
our @const_old_functions = qw(
   AlreadyGrabbed
   AnyModifier
   AsyncBoth
   AsyncKeyboard
   AsyncPointer
   Button1
   Button1Mask
   Button1MotionMask
   Button2
   Button2Mask
   Button2MotionMask
   Button3
   Button3Mask
   Button3MotionMask
   Button4
   Button4Mask
   Button4MotionMask
   Button5
   Button5Mask
   Button5MotionMask
   ButtonMotionMask
   ButtonPress
   ButtonPressMask
   ButtonRelease
   ButtonReleaseMask
   CirculateNotify
   CirculateRequest
   ClientMessage
   ColormapChangeMask
   ColormapInstalled
   ColormapNotify
   ColormapUninstalled
   ConfigureNotify
   ConfigureRequest
   ControlMapIndex
   ControlMask
   CreateNotify
   DestroyNotify
   DirectColor
   EnterNotify
   EnterWindowMask
   Expose
   ExposureMask
   FamilyChaos
   FamilyDECnet
   FamilyInternet
   FocusChangeMask
   FocusIn
   FocusOut
   GrabFrozen
   GrabInvalidTime
   GrabModeAsync
   GrabModeSync
   GrabNotViewable
   GrabSuccess
   GraphicsExpose
   GravityNotify
   GrayScale
   KeyPress
   KeyPressMask
   KeyRelease
   KeyReleaseMask
   KeymapNotify
   KeymapStateMask
   LASTEvent
   LeaveNotify
   LeaveWindowMask
   LockMapIndex
   LockMask
   MapNotify
   MapRequest
   MappingNotify
   Mod1MapIndex
   Mod1Mask
   Mod2MapIndex
   Mod2Mask
   Mod3MapIndex
   Mod3Mask
   Mod4MapIndex
   Mod4Mask
   Mod5MapIndex
   Mod5Mask
   MotionNotify
   NoEventMask
   NoExpose
   NotifyAncestor
   NotifyDetailNone
   NotifyGrab
   NotifyHint
   NotifyInferior
   NotifyNonlinear
   NotifyNonlinearVirtual
   NotifyNormal
   NotifyPointer
   NotifyPointerRoot
   NotifyUngrab
   NotifyVirtual
   NotifyWhileGrabbed
   OwnerGrabButtonMask
   PlaceOnBottom
   PlaceOnTop
   PointerMotionHintMask
   PointerMotionMask
   PropertyChangeMask
   PropertyDelete
   PropertyNewValue
   PropertyNotify
   PseudoColor
   ReparentNotify
   ReplayKeyboard
   ReplayPointer
   ResizeRedirectMask
   ResizeRequest
   SelectionClear
   SelectionNotify
   SelectionRequest
   ShiftMapIndex
   ShiftMask
   StaticColor
   StaticGray
   StructureNotifyMask
   SubstructureNotifyMask
   SubstructureRedirectMask
   SyncBoth
   SyncKeyboard
   SyncPointer
   TrueColor
   UnmapNotify
   VisibilityChangeMask
   VisibilityFullyObscured
   VisibilityNotify
   VisibilityPartiallyObscured
   VisibilityUnobscured
   X_PROTOCOL
   X_PROTOCOL_REVISION
);
our @const = (@const_common, qw(
   GLX_X_VISUAL_TYPE_EXT
   GLX_TRANSPARENT_TYPE_EXT
   GLX_TRANSPARENT_INDEX_VALUE_EXT
   GLX_TRANSPARENT_RED_VALUE_EXT
   GLX_TRANSPARENT_GREEN_VALUE_EXT
   GLX_TRANSPARENT_BLUE_VALUE_EXT
   GLX_TRANSPARENT_ALPHA_VALUE_EXT
), @const_old_functions);

our @func = qw(
   glXSwapBuffers
   XPending
   glpXNextEvent
   glpXQueryPointer
);

our @EXPORT_OK = (@const, @func, qw(_have_glp _have_glx glpcOpenWindow __had_dbuffer_hack glpReadTex));
our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
  constants => \@const,
  glxconstants => \@const,
  functions => \@func,
  glxfunctions => \@func,
);

__PACKAGE__->bootstrap;

1;
