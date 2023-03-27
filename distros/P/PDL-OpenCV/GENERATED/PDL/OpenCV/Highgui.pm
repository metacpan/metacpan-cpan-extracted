#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::OpenCV::Highgui;

our @EXPORT_OK = qw( namedWindow destroyWindow destroyAllWindows startWindowThread waitKeyEx waitKey pollKey imshow resizeWindow resizeWindow2 moveWindow setWindowProperty setWindowTitle getWindowProperty getWindowImageRect selectROI selectROI2 selectROIs getTrackbarPos setTrackbarPos setTrackbarMax setTrackbarMin addText displayOverlay displayStatusBar WINDOW_NORMAL WINDOW_AUTOSIZE WINDOW_OPENGL WINDOW_FULLSCREEN WINDOW_FREERATIO WINDOW_KEEPRATIO WINDOW_GUI_EXPANDED WINDOW_GUI_NORMAL WND_PROP_FULLSCREEN WND_PROP_AUTOSIZE WND_PROP_ASPECT_RATIO WND_PROP_OPENGL WND_PROP_VISIBLE WND_PROP_TOPMOST WND_PROP_VSYNC EVENT_MOUSEMOVE EVENT_LBUTTONDOWN EVENT_RBUTTONDOWN EVENT_MBUTTONDOWN EVENT_LBUTTONUP EVENT_RBUTTONUP EVENT_MBUTTONUP EVENT_LBUTTONDBLCLK EVENT_RBUTTONDBLCLK EVENT_MBUTTONDBLCLK EVENT_MOUSEWHEEL EVENT_MOUSEHWHEEL EVENT_FLAG_LBUTTON EVENT_FLAG_RBUTTON EVENT_FLAG_MBUTTON EVENT_FLAG_CTRLKEY EVENT_FLAG_SHIFTKEY EVENT_FLAG_ALTKEY QT_FONT_LIGHT QT_FONT_NORMAL QT_FONT_DEMIBOLD QT_FONT_BOLD QT_FONT_BLACK QT_STYLE_NORMAL QT_STYLE_ITALIC QT_STYLE_OBLIQUE QT_PUSH_BUTTON QT_CHECKBOX QT_RADIOBOX QT_NEW_BUTTONBAR );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::OpenCV::Highgui ;






#line 364 "../genpp.pl"

=head1 NAME

PDL::OpenCV::Highgui - PDL bindings for OpenCV Highgui

=head1 SYNOPSIS

 use PDL::OpenCV::Highgui;

=cut

use strict;
use warnings;
use PDL::OpenCV; # get constants
#line 40 "Highgui.pm"






=head1 FUNCTIONS

=cut




#line 274 "../genpp.pl"

=head2 namedWindow

=for ref

Creates a window.

=for example

 namedWindow($winname); # with defaults
 namedWindow($winname,$flags);

The function namedWindow creates a window that can be used as a placeholder for images and
trackbars. Created windows are referred to by their names.
If a window with the same name already exists, the function does nothing.
You can call cv::destroyWindow or cv::destroyAllWindows to close the window and de-allocate any associated
memory usage. For a simple program, you do not really have to call these functions because all the
resources and windows of the application are closed automatically by the operating system upon exit.
@note
Qt backend supports additional flags:
-   **WINDOW_NORMAL or WINDOW_AUTOSIZE:** WINDOW_NORMAL enables you to resize the
window, whereas WINDOW_AUTOSIZE adjusts automatically the window size to fit the
displayed image (see imshow ), and you cannot change the window size manually.
-   **WINDOW_FREERATIO or WINDOW_KEEPRATIO:** WINDOW_FREERATIO adjusts the image
with no respect to its ratio, whereas WINDOW_KEEPRATIO keeps the image ratio.
-   **WINDOW_GUI_NORMAL or WINDOW_GUI_EXPANDED:** WINDOW_GUI_NORMAL is the old way to draw the window
without statusbar and toolbar, whereas WINDOW_GUI_EXPANDED is a new enhanced GUI.
By default, flags == WINDOW_AUTOSIZE | WINDOW_KEEPRATIO | WINDOW_GUI_EXPANDED

Parameters:

=over

=item winname

Name of the window in the window caption that may be used as a window identifier.

=item flags

Flags of the window. The supported flags are: (cv::WindowFlags)

=back


=cut
#line 100 "Highgui.pm"



#line 275 "../genpp.pl"

*namedWindow = \&PDL::OpenCV::Highgui::namedWindow;
#line 107 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 destroyWindow

=for ref

Destroys the specified window.

=for example

 destroyWindow($winname);

The function destroyWindow destroys the window with the given name.

Parameters:

=over

=item winname

Name of the window to be destroyed.

=back


=cut
#line 137 "Highgui.pm"



#line 275 "../genpp.pl"

*destroyWindow = \&PDL::OpenCV::Highgui::destroyWindow;
#line 144 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 destroyAllWindows

=for ref

Destroys all of the HighGUI windows.

=for example

 destroyAllWindows;

The function destroyAllWindows destroys all of the opened HighGUI windows.

=cut
#line 163 "Highgui.pm"



#line 275 "../genpp.pl"

*destroyAllWindows = \&PDL::OpenCV::Highgui::destroyAllWindows;
#line 170 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 startWindowThread

=for ref

=for example

 $res = startWindowThread;


=cut
#line 186 "Highgui.pm"



#line 275 "../genpp.pl"

*startWindowThread = \&PDL::OpenCV::Highgui::startWindowThread;
#line 193 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 waitKeyEx

=for ref

Similar to #waitKey, but returns full key code.

=for example

 $res = waitKeyEx; # with defaults
 $res = waitKeyEx($delay);

@note
Key code is implementation specific and depends on used backend: QT/GTK/Win32/etc

=cut
#line 214 "Highgui.pm"



#line 275 "../genpp.pl"

*waitKeyEx = \&PDL::OpenCV::Highgui::waitKeyEx;
#line 221 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 waitKey

=for ref

Waits for a pressed key.

=for example

 $res = waitKey; # with defaults
 $res = waitKey($delay);

The function waitKey waits for a key event infinitely (when C<<< \texttt{delay}\leq 0 >>>) or for delay
milliseconds, when it is positive. Since the OS has a minimum time between switching threads, the
function will not wait exactly delay ms, it will wait at least delay ms, depending on what else is
running on your computer at that time. It returns the code of the pressed key or -1 if no key was
pressed before the specified time had elapsed. To check for a key press but not wait for it, use
#pollKey.
@note The functions #waitKey and #pollKey are the only methods in HighGUI that can fetch and handle
GUI events, so one of them needs to be called periodically for normal event processing unless
HighGUI is used within an environment that takes care of event processing.
@note The function only works if there is at least one HighGUI window created and the window is
active. If there are several HighGUI windows, any of them can be active.

Parameters:

=over

=item delay

Delay in milliseconds. 0 is the special value that means "forever".

=back


=cut
#line 262 "Highgui.pm"



#line 275 "../genpp.pl"

*waitKey = \&PDL::OpenCV::Highgui::waitKey;
#line 269 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 pollKey

=for ref

Polls for a pressed key.

=for example

 $res = pollKey;

The function pollKey polls for a key event without waiting. It returns the code of the pressed key
or -1 if no key was pressed since the last invocation. To wait until a key was pressed, use #waitKey.
@note The functions #waitKey and #pollKey are the only methods in HighGUI that can fetch and handle
GUI events, so one of them needs to be called periodically for normal event processing unless
HighGUI is used within an environment that takes care of event processing.
@note The function only works if there is at least one HighGUI window created and the window is
active. If there are several HighGUI windows, any of them can be active.

=cut
#line 294 "Highgui.pm"



#line 275 "../genpp.pl"

*pollKey = \&PDL::OpenCV::Highgui::pollKey;
#line 301 "Highgui.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 imshow

=for sig

  Signature: ([phys] mat(l2,c2,r2); StringWrapper* winname)

=for ref

Displays an image in the specified window.

=for example

 imshow($winname,$mat);

The function imshow displays an image in the specified window. If the window was created with the
cv::WINDOW_AUTOSIZE flag, the image is shown with its original size, however it is still limited by the screen resolution.
Otherwise, the image is scaled to fit the window. The function may scale the image, depending on its depth:
-   If the image is 8-bit unsigned, it is displayed as is.
-   If the image is 16-bit unsigned, the pixels are divided by 256. That is, the
value range [0,255*256] is mapped to [0,255].
-   If the image is 32-bit or 64-bit floating-point, the pixel values are multiplied by 255. That is, the
value range [0,1] is mapped to [0,255].
-   32-bit integer images are not processed anymore due to ambiguouty of required transform.
Convert to 8-bit unsigned matrix using a custom preprocessing specific to image's context.
If window was created with OpenGL support, cv::imshow also support ogl::Buffer , ogl::Texture2D and
cuda::GpuMat as input.
If the window was not created before this function, it is assumed creating a window with cv::WINDOW_AUTOSIZE.
If you need to show an image that is bigger than the screen resolution, you will need to call namedWindow("", WINDOW_NORMAL) before the imshow.
@note This function should be followed by a call to cv::waitKey or cv::pollKey to perform GUI
housekeeping tasks that are necessary to actually show the given image and make the window respond
to mouse and keyboard events. Otherwise, it won't display the image and the window might lock up.
For example, **waitKey(0)** will display the window infinitely until any keypress (it is suitable
for image display). **waitKey(25)** will display a frame and wait approximately 25 ms for a key
press (suitable for displaying a video frame-by-frame). To remove the window, use cv::destroyWindow.
@note
[__Windows Backend Only__] Pressing Ctrl+C will copy the image to the clipboard.
[__Windows Backend Only__] Pressing Ctrl+S will show a dialog to save the image.

Parameters:

=over

=item winname

Name of the window.

=item mat

Image to be shown.

=back


=for bad

imshow ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 369 "Highgui.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Highgui::imshow {
  barf "Usage: PDL::OpenCV::Highgui::imshow(\$winname,\$mat)\n" if @_ < 2;
  my ($winname,$mat) = @_;
    
  PDL::OpenCV::Highgui::_imshow_int($mat,$winname);
  
}
#line 382 "Highgui.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*imshow = \&PDL::OpenCV::Highgui::imshow;
#line 389 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 resizeWindow

=for ref

Resizes the window to the specified size

=for example

 resizeWindow($winname,$width,$height);

@note
-   The specified window size is for the image area. Toolbars are not counted.
-   Only windows created without cv::WINDOW_AUTOSIZE flag can be resized.

Parameters:

=over

=item winname

Window name.

=item width

The new window width.

=item height

The new window height.

=back


=cut
#line 429 "Highgui.pm"



#line 275 "../genpp.pl"

*resizeWindow = \&PDL::OpenCV::Highgui::resizeWindow;
#line 436 "Highgui.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 resizeWindow2

=for sig

  Signature: (indx [phys] size(n2=2); StringWrapper* winname)

=for ref

=for example

 resizeWindow2($winname,$size);

@overload

Parameters:

=over

=item winname

Window name.

=item size

The new window size.

=back


=for bad

resizeWindow2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 480 "Highgui.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Highgui::resizeWindow2 {
  barf "Usage: PDL::OpenCV::Highgui::resizeWindow2(\$winname,\$size)\n" if @_ < 2;
  my ($winname,$size) = @_;
    
  PDL::OpenCV::Highgui::_resizeWindow2_int($size,$winname);
  
}
#line 493 "Highgui.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*resizeWindow2 = \&PDL::OpenCV::Highgui::resizeWindow2;
#line 500 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 moveWindow

=for ref

Moves the window to the specified position

=for example

 moveWindow($winname,$x,$y);

Parameters:

=over

=item winname

Name of the window.

=item x

The new x-coordinate of the window.

=item y

The new y-coordinate of the window.

=back


=cut
#line 536 "Highgui.pm"



#line 275 "../genpp.pl"

*moveWindow = \&PDL::OpenCV::Highgui::moveWindow;
#line 543 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 setWindowProperty

=for ref

Changes parameters of a window dynamically.

=for example

 setWindowProperty($winname,$prop_id,$prop_value);

The function setWindowProperty enables changing properties of a window.

Parameters:

=over

=item winname

Name of the window.

=item prop_id

Window property to edit. The supported operation flags are: (cv::WindowPropertyFlags)

=item prop_value

New value of the window property. The supported flags are: (cv::WindowFlags)

=back


=cut
#line 581 "Highgui.pm"



#line 275 "../genpp.pl"

*setWindowProperty = \&PDL::OpenCV::Highgui::setWindowProperty;
#line 588 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 setWindowTitle

=for ref

Updates window title

=for example

 setWindowTitle($winname,$title);

Parameters:

=over

=item winname

Name of the window.

=item title

New title.

=back


=cut
#line 620 "Highgui.pm"



#line 275 "../genpp.pl"

*setWindowTitle = \&PDL::OpenCV::Highgui::setWindowTitle;
#line 627 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 getWindowProperty

=for ref

Provides parameters of a window.

=for example

 $res = getWindowProperty($winname,$prop_id);

The function getWindowProperty returns properties of a window.

Parameters:

=over

=item winname

Name of the window.

=item prop_id

Window property to retrieve. The following operation flags are available: (cv::WindowPropertyFlags)

=back

See also:
setWindowProperty


=cut
#line 664 "Highgui.pm"



#line 275 "../genpp.pl"

*getWindowProperty = \&PDL::OpenCV::Highgui::getWindowProperty;
#line 671 "Highgui.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 getWindowImageRect

=for sig

  Signature: (indx [o,phys] res(n2=4); StringWrapper* winname)

=for ref

Provides rectangle of image in the window.

=for example

 $res = getWindowImageRect($winname);

The function getWindowImageRect returns the client screen coordinates, width and height of the image rendering area.

Parameters:

=over

=item winname

Name of the window.

=back

See also:
resizeWindow moveWindow


=for bad

getWindowImageRect ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 716 "Highgui.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Highgui::getWindowImageRect {
  barf "Usage: PDL::OpenCV::Highgui::getWindowImageRect(\$winname)\n" if @_ < 1;
  my ($winname) = @_;
  my ($res);
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Highgui::_getWindowImageRect_int($res,$winname);
  !wantarray ? $res : ($res)
}
#line 730 "Highgui.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*getWindowImageRect = \&PDL::OpenCV::Highgui::getWindowImageRect;
#line 737 "Highgui.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 selectROI

=for sig

  Signature: ([phys] img(l2,c2,r2); byte [phys] showCrosshair(); byte [phys] fromCenter(); indx [o,phys] res(n5=4); StringWrapper* windowName)

=for ref

Allows users to select a ROI on the given image.

=for example

 $res = selectROI($windowName,$img); # with defaults
 $res = selectROI($windowName,$img,$showCrosshair,$fromCenter);

The function creates a window and allows users to select a ROI using the mouse.
Controls: use `space` or `enter` to finish selection, use key `c` to cancel selection (function will return the zero cv::Rect).
@note The function sets it's own mouse callback for specified window using cv::setMouseCallback(windowName, ...).
After finish of work an empty callback will be set for the used window.

Parameters:

=over

=item windowName

name of the window where selection process will be shown.

=item img

image to select a ROI.

=item showCrosshair

if true crosshair of selection rectangle will be shown.

=item fromCenter

if true center of selection will match initial mouse position. In opposite case a corner of
selection rectangle will correspont to the initial mouse position.

=back

Returns: selected ROI or empty rect if selection canceled.


=for bad

selectROI ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 798 "Highgui.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Highgui::selectROI {
  barf "Usage: PDL::OpenCV::Highgui::selectROI(\$windowName,\$img,\$showCrosshair,\$fromCenter)\n" if @_ < 2;
  my ($windowName,$img,$showCrosshair,$fromCenter) = @_;
  my ($res);
  $showCrosshair = 1 if !defined $showCrosshair;
  $fromCenter = 0 if !defined $fromCenter;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Highgui::_selectROI_int($img,$showCrosshair,$fromCenter,$res,$windowName);
  !wantarray ? $res : ($res)
}
#line 814 "Highgui.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*selectROI = \&PDL::OpenCV::Highgui::selectROI;
#line 821 "Highgui.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 selectROI2

=for sig

  Signature: ([phys] img(l1,c1,r1); byte [phys] showCrosshair(); byte [phys] fromCenter(); indx [o,phys] res(n4=4))

=for ref

=for example

 $res = selectROI2($img); # with defaults
 $res = selectROI2($img,$showCrosshair,$fromCenter);

@overload

=for bad

selectROI2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 851 "Highgui.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Highgui::selectROI2 {
  barf "Usage: PDL::OpenCV::Highgui::selectROI2(\$img,\$showCrosshair,\$fromCenter)\n" if @_ < 1;
  my ($img,$showCrosshair,$fromCenter) = @_;
  my ($res);
  $showCrosshair = 1 if !defined $showCrosshair;
  $fromCenter = 0 if !defined $fromCenter;
  $res = PDL->null if !defined $res;
  PDL::OpenCV::Highgui::_selectROI2_int($img,$showCrosshair,$fromCenter,$res);
  !wantarray ? $res : ($res)
}
#line 867 "Highgui.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*selectROI2 = \&PDL::OpenCV::Highgui::selectROI2;
#line 874 "Highgui.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 selectROIs

=for sig

  Signature: ([phys] img(l2,c2,r2); indx [o,phys] boundingBoxes(n3=4,n3d0); byte [phys] showCrosshair(); byte [phys] fromCenter(); StringWrapper* windowName)

=for ref

Allows users to select multiple ROIs on the given image. NO BROADCASTING.

=for example

 $boundingBoxes = selectROIs($windowName,$img); # with defaults
 $boundingBoxes = selectROIs($windowName,$img,$showCrosshair,$fromCenter);

The function creates a window and allows users to select multiple ROIs using the mouse.
Controls: use `space` or `enter` to finish current selection and start a new one,
use `esc` to terminate multiple ROI selection process.
@note The function sets it's own mouse callback for specified window using cv::setMouseCallback(windowName, ...).
After finish of work an empty callback will be set for the used window.

Parameters:

=over

=item windowName

name of the window where selection process will be shown.

=item img

image to select a ROI.

=item boundingBoxes

selected ROIs.

=item showCrosshair

if true crosshair of selection rectangle will be shown.

=item fromCenter

if true center of selection will match initial mouse position. In opposite case a corner of
selection rectangle will correspont to the initial mouse position.

=back


=for bad

selectROIs ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 938 "Highgui.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Highgui::selectROIs {
  barf "Usage: PDL::OpenCV::Highgui::selectROIs(\$windowName,\$img,\$showCrosshair,\$fromCenter)\n" if @_ < 2;
  my ($windowName,$img,$showCrosshair,$fromCenter) = @_;
  my ($boundingBoxes);
  $boundingBoxes = PDL->null if !defined $boundingBoxes;
  $showCrosshair = 1 if !defined $showCrosshair;
  $fromCenter = 0 if !defined $fromCenter;
  PDL::OpenCV::Highgui::_selectROIs_int($img,$boundingBoxes,$showCrosshair,$fromCenter,$windowName);
  !wantarray ? $boundingBoxes : ($boundingBoxes)
}
#line 954 "Highgui.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*selectROIs = \&PDL::OpenCV::Highgui::selectROIs;
#line 961 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 getTrackbarPos

=for ref

Returns the trackbar position.

=for example

 $res = getTrackbarPos($trackbarname,$winname);

The function returns the current position of the specified trackbar.
@note
[__Qt Backend Only__] winname can be empty if the trackbar is attached to the control
panel.

Parameters:

=over

=item trackbarname

Name of the trackbar.

=item winname

Name of the window that is the parent of the trackbar.

=back


=cut
#line 998 "Highgui.pm"



#line 275 "../genpp.pl"

*getTrackbarPos = \&PDL::OpenCV::Highgui::getTrackbarPos;
#line 1005 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 setTrackbarPos

=for ref

Sets the trackbar position.

=for example

 setTrackbarPos($trackbarname,$winname,$pos);

The function sets the position of the specified trackbar in the specified window.
@note
[__Qt Backend Only__] winname can be empty if the trackbar is attached to the control
panel.

Parameters:

=over

=item trackbarname

Name of the trackbar.

=item winname

Name of the window that is the parent of trackbar.

=item pos

New position.

=back


=cut
#line 1046 "Highgui.pm"



#line 275 "../genpp.pl"

*setTrackbarPos = \&PDL::OpenCV::Highgui::setTrackbarPos;
#line 1053 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 setTrackbarMax

=for ref

Sets the trackbar maximum position.

=for example

 setTrackbarMax($trackbarname,$winname,$maxval);

The function sets the maximum position of the specified trackbar in the specified window.
@note
[__Qt Backend Only__] winname can be empty if the trackbar is attached to the control
panel.

Parameters:

=over

=item trackbarname

Name of the trackbar.

=item winname

Name of the window that is the parent of trackbar.

=item maxval

New maximum position.

=back


=cut
#line 1094 "Highgui.pm"



#line 275 "../genpp.pl"

*setTrackbarMax = \&PDL::OpenCV::Highgui::setTrackbarMax;
#line 1101 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 setTrackbarMin

=for ref

Sets the trackbar minimum position.

=for example

 setTrackbarMin($trackbarname,$winname,$minval);

The function sets the minimum position of the specified trackbar in the specified window.
@note
[__Qt Backend Only__] winname can be empty if the trackbar is attached to the control
panel.

Parameters:

=over

=item trackbarname

Name of the trackbar.

=item winname

Name of the window that is the parent of trackbar.

=item minval

New minimum position.

=back


=cut
#line 1142 "Highgui.pm"



#line 275 "../genpp.pl"

*setTrackbarMin = \&PDL::OpenCV::Highgui::setTrackbarMin;
#line 1149 "Highgui.pm"



#line 958 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 addText

=for sig

  Signature: ([phys] img(l1,c1,r1); indx [phys] org(n3=2); int [phys] pointSize(); double [phys] color(n6=4); int [phys] weight(); int [phys] style(); int [phys] spacing(); StringWrapper* text; StringWrapper* nameFont)

=for ref

Draws a text on the image.

=for example

 addText($img,$text,$org,$nameFont); # with defaults
 addText($img,$text,$org,$nameFont,$pointSize,$color,$weight,$style,$spacing);

Parameters:

=over

=item img

8-bit 3-channel image where the text should be drawn.

=item text

Text to write on an image.

=item org

Point(x,y) where the text should start on an image.

=item nameFont

Name of the font. The name should match the name of a system font (such as
*Times*). If the font is not found, a default one is used.

=item pointSize

Size of the font. If not specified, equal zero or negative, the point size of the
font is set to a system-dependent default value. Generally, this is 12 points.

=item color

Color of the font in BGRA where A = 255 is fully transparent.

=item weight

Font weight. Available operation flags are : cv::QtFontWeights You can also specify a positive integer for better control.

=item style

Font style. Available operation flags are : cv::QtFontStyles

=item spacing

Spacing between characters. It can be negative or positive.

=back


=for bad

addText ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1224 "Highgui.pm"



#line 959 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::OpenCV::Highgui::addText {
  barf "Usage: PDL::OpenCV::Highgui::addText(\$img,\$text,\$org,\$nameFont,\$pointSize,\$color,\$weight,\$style,\$spacing)\n" if @_ < 4;
  my ($img,$text,$org,$nameFont,$pointSize,$color,$weight,$style,$spacing) = @_;
    $pointSize = -1 if !defined $pointSize;
  $color = [0,0,0,0] if !defined $color;
  $weight = QT_FONT_NORMAL() if !defined $weight;
  $style = QT_STYLE_NORMAL() if !defined $style;
  $spacing = 0 if !defined $spacing;
  PDL::OpenCV::Highgui::_addText_int($img,$org,$pointSize,$color,$weight,$style,$spacing,$text,$nameFont);
  
}
#line 1241 "Highgui.pm"



#line 960 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*addText = \&PDL::OpenCV::Highgui::addText;
#line 1248 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 displayOverlay

=for ref

Displays a text on a window image as an overlay for a specified duration.

=for example

 displayOverlay($winname,$text); # with defaults
 displayOverlay($winname,$text,$delayms);

The function displayOverlay displays useful information/tips on top of the window for a certain
amount of time *delayms*. The function does not modify the image, displayed in the window, that is,
after the specified delay the original content of the window is restored.

Parameters:

=over

=item winname

Name of the window.

=item text

Overlay text to write on a window image.

=item delayms

The period (in milliseconds), during which the overlay text is displayed. If this
function is called before the previous overlay text timed out, the timer is restarted and the text
is updated. If this value is zero, the text never disappears.

=back


=cut
#line 1291 "Highgui.pm"



#line 275 "../genpp.pl"

*displayOverlay = \&PDL::OpenCV::Highgui::displayOverlay;
#line 1298 "Highgui.pm"



#line 274 "../genpp.pl"

=head2 displayStatusBar

=for ref

Displays a text on the window statusbar during the specified period of time.

=for example

 displayStatusBar($winname,$text); # with defaults
 displayStatusBar($winname,$text,$delayms);

The function displayStatusBar displays useful information/tips on top of the window for a certain
amount of time *delayms* . This information is displayed on the window statusbar (the window must be
created with the CV_GUI_EXPANDED flags).

Parameters:

=over

=item winname

Name of the window.

=item text

Text to write on the window statusbar.

=item delayms

Duration (in milliseconds) to display the text. If this function is called before
the previous text timed out, the timer is restarted and the text is updated. If this value is
zero, the text never disappears.

=back


=cut
#line 1341 "Highgui.pm"



#line 275 "../genpp.pl"

*displayStatusBar = \&PDL::OpenCV::Highgui::displayStatusBar;
#line 1348 "Highgui.pm"



#line 441 "../genpp.pl"

=head1 CONSTANTS

=over

=item PDL::OpenCV::Highgui::WINDOW_NORMAL()

=item PDL::OpenCV::Highgui::WINDOW_AUTOSIZE()

=item PDL::OpenCV::Highgui::WINDOW_OPENGL()

=item PDL::OpenCV::Highgui::WINDOW_FULLSCREEN()

=item PDL::OpenCV::Highgui::WINDOW_FREERATIO()

=item PDL::OpenCV::Highgui::WINDOW_KEEPRATIO()

=item PDL::OpenCV::Highgui::WINDOW_GUI_EXPANDED()

=item PDL::OpenCV::Highgui::WINDOW_GUI_NORMAL()

=item PDL::OpenCV::Highgui::WND_PROP_FULLSCREEN()

=item PDL::OpenCV::Highgui::WND_PROP_AUTOSIZE()

=item PDL::OpenCV::Highgui::WND_PROP_ASPECT_RATIO()

=item PDL::OpenCV::Highgui::WND_PROP_OPENGL()

=item PDL::OpenCV::Highgui::WND_PROP_VISIBLE()

=item PDL::OpenCV::Highgui::WND_PROP_TOPMOST()

=item PDL::OpenCV::Highgui::WND_PROP_VSYNC()

=item PDL::OpenCV::Highgui::EVENT_MOUSEMOVE()

=item PDL::OpenCV::Highgui::EVENT_LBUTTONDOWN()

=item PDL::OpenCV::Highgui::EVENT_RBUTTONDOWN()

=item PDL::OpenCV::Highgui::EVENT_MBUTTONDOWN()

=item PDL::OpenCV::Highgui::EVENT_LBUTTONUP()

=item PDL::OpenCV::Highgui::EVENT_RBUTTONUP()

=item PDL::OpenCV::Highgui::EVENT_MBUTTONUP()

=item PDL::OpenCV::Highgui::EVENT_LBUTTONDBLCLK()

=item PDL::OpenCV::Highgui::EVENT_RBUTTONDBLCLK()

=item PDL::OpenCV::Highgui::EVENT_MBUTTONDBLCLK()

=item PDL::OpenCV::Highgui::EVENT_MOUSEWHEEL()

=item PDL::OpenCV::Highgui::EVENT_MOUSEHWHEEL()

=item PDL::OpenCV::Highgui::EVENT_FLAG_LBUTTON()

=item PDL::OpenCV::Highgui::EVENT_FLAG_RBUTTON()

=item PDL::OpenCV::Highgui::EVENT_FLAG_MBUTTON()

=item PDL::OpenCV::Highgui::EVENT_FLAG_CTRLKEY()

=item PDL::OpenCV::Highgui::EVENT_FLAG_SHIFTKEY()

=item PDL::OpenCV::Highgui::EVENT_FLAG_ALTKEY()

=item PDL::OpenCV::Highgui::QT_FONT_LIGHT()

=item PDL::OpenCV::Highgui::QT_FONT_NORMAL()

=item PDL::OpenCV::Highgui::QT_FONT_DEMIBOLD()

=item PDL::OpenCV::Highgui::QT_FONT_BOLD()

=item PDL::OpenCV::Highgui::QT_FONT_BLACK()

=item PDL::OpenCV::Highgui::QT_STYLE_NORMAL()

=item PDL::OpenCV::Highgui::QT_STYLE_ITALIC()

=item PDL::OpenCV::Highgui::QT_STYLE_OBLIQUE()

=item PDL::OpenCV::Highgui::QT_PUSH_BUTTON()

=item PDL::OpenCV::Highgui::QT_CHECKBOX()

=item PDL::OpenCV::Highgui::QT_RADIOBOX()

=item PDL::OpenCV::Highgui::QT_NEW_BUTTONBAR()


=back

=cut
#line 1452 "Highgui.pm"






# Exit with OK status

1;
