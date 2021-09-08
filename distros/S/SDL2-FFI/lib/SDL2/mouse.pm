package SDL2::mouse 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::error;
    use SDL2::video;
    #
    package SDL2::Cursor 0.01 {
        use SDL2::Utils;
        our $TYPE = has();
    };
    #
    enum SDL_SystemCursor => [
        qw[
            SDL_SYSTEM_CURSOR_ARROW
            SDL_SYSTEM_CURSOR_IBEAM
            SDL_SYSTEM_CURSOR_WAIT
            SDL_SYSTEM_CURSOR_CROSSHAIR
            SDL_SYSTEM_CURSOR_WAITARROW
            SDL_SYSTEM_CURSOR_SIZENWSE
            SDL_SYSTEM_CURSOR_SIZENESW
            SDL_SYSTEM_CURSOR_SIZEWE
            SDL_SYSTEM_CURSOR_SIZENS
            SDL_SYSTEM_CURSOR_SIZEALL
            SDL_SYSTEM_CURSOR_NO
            SDL_SYSTEM_CURSOR_HAND
            SDL_NUM_SYSTEM_CURSORS
        ]
        ],
        SDL_MouseWheelDirection => [qw[SDL_MOUSEWHEEL_NORMAL SDL_MOUSEWHEEL_FLIPPED]];
    attach mouse => {
        SDL_GetMouseFocus         => [ [], 'SDL_Window' ],
        SDL_GetMouseState         => [ [ 'int*', 'int*' ], 'uint32' ],
        SDL_GetGlobalMouseState   => [ [ 'int*', 'int*' ], 'uint32' ],
        SDL_GetRelativeMouseState => [ [ 'int*', 'int*' ], 'uint32' ],
        SDL_WarpMouseInWindow     => [ [ 'SDL_Window', 'int', 'int' ] ],
        SDL_WarpMouseGlobal       => [ [ 'int', 'int' ] ],
        SDL_SetRelativeMouseMode  => [ ['SDL_bool'], 'int' ],
        SDL_CaptureMouse          => [ ['SDL_bool'] => 'int' ],
        SDL_GetRelativeMouseMode  => [ [], 'SDL_bool' ],
        SDL_CreateCursor => [ [ 'uint8[]', 'uint8[]', 'int', 'int', 'int', 'int' ], 'SDL_Cursor' ],
        SDL_CreateColorCursor  => [ [ 'SDL_Surface', 'int', 'int' ], 'SDL_Cursor' ],
        SDL_CreateSystemCursor => [ ['SDL_SystemCursor'],            'SDL_Cursor' ],
        SDL_SetCursor          => [ ['SDL_Cursor'] ],
        SDL_GetCursor          => [ [], 'SDL_Cursor' ],
        SDL_GetDefaultCursor   => [ [], 'SDL_Cursor' ],
        SDL_FreeCursor         => [ ['SDL_Cursor'] ],
        SDL_ShowCursor         => [ ['int'], 'int' ],
    };
    define mouse => [
        [ SDL_BUTTON        => sub ($X) { ( 1 << ( ($X) - 1 ) ) } ],
        [ SDL_BUTTON_LEFT   => 1 ],
        [ SDL_BUTTON_MIDDLE => 2 ],
        [ SDL_BUTTON_RIGHT  => 3 ],
        [ SDL_BUTTON_X1     => 4 ],
        [ SDL_BUTTON_X2     => 5 ],
        [ SDL_BUTTON_LMASK  => sub () { SDL2::FFI::SDL_BUTTON( SDL2::FFI::SDL_BUTTON_LEFT() ) } ],
        [ SDL_BUTTON_MMASK  => sub () { SDL2::FFI::SDL_BUTTON( SDL2::FFI::SDL_BUTTON_MIDDLE() ) } ],
        [ SDL_BUTTON_RMASK  => sub () { SDL2::FFI::SDL_BUTTON( SDL2::FFI::SDL_BUTTON_RIGHT() ) } ],
        [ SDL_BUTTON_X1MASK => sub () { SDL2::FFI::SDL_BUTTON( SDL2::FFI::SDL_BUTTON_X1() ) } ],
        [ SDL_BUTTON_X2MASK => sub () { SDL2::FFI::SDL_BUTTON( SDL2::FFI::SDL_BUTTON_X2() ) } ]
    ];

=encoding utf-8

=head1 NAME

SDL2::mouse - SDL Mouse Event Handling

=head1 SYNOPSIS

    use SDL2 qw[:mouse];

=head1 DESCRIPTION

SDL2::keyboard

=head1 Functions

These may be imported by name or with the C<:mouse> tag.

=head2 C<SDL_GetMouseFocus( )>

Get the window which currently has mouse focus.

Returns the window with mouse focus.

=head2 C<SDL_GetMouseState( ... )>

Retrieve the current state of the mouse.

The current button state is returned as a button bitmask, which can be tested
using the C<SDL_BUTTON(X)> function (where C<X> is generally 1 for the left, 2
for middle, 3 for the right button), and C<x> and C<y> are set to the mouse
cursor position relative to the focus window. You can pass NULL for either C<x>
or C<y>.

Expected parameters include:

=over

=item C<x> - the x coordinate of the mouse cursor position relative to the focus window

=item C<y> - the y coordinate of the mouse cursor position relative to the focus window

=back

Returns a 32-bit button bitmask of the current button state.

=head2 C<SDL_GetGlobalMouseState( ... )>

Get the current state of the mouse in relation to the desktop.

This works similarly to L<< C<SDL_GetMouseState( ... )>|/C<SDL_GetMouseState(
... )> >>, but the coordinates will be reported relative to the top-left of the
desktop. This can be useful if you need to track the mouse outside of a
specific window and L<< C<SDL_CaptureMouse( ... )>|/C<SDL_CaptureMouse( ... )>
>> doesn't fit your needs. For example, it could be useful if you need to track
the mouse while dragging a window, where coordinates relative to a window might
not be in sync at all times.

Note: L<< C<SDL_GetMouseState( ... )>|/C<SDL_GetMouseState( ... )> >> returns
the mouse position as SDL understands it from the last pump of the event queue.
This function, however, queries the OS for the current mouse position, and as
such, might be a slightly less efficient function. Unless you know what you're
doing and have a good reason to use this function, you probably want L<<
C<SDL_GetMouseState( ... )>|/C<SDL_GetMouseState( ... )> >> instead.

Expected parameters include:

=over

=item C<x> - filled in with the current X coord relative to the desktop; can be C<undef>

=item C<y> - filled in with the current Y coord relative to the desktop; can be C<undef>

=back

Returns the current button state as a bitmask which can be tested using C<the
SDL_BUTTON( X )> macros.

=head2 C<SDL_GetRelativeMouseState( ... )>

Retrieve the relative state of the mouse.

The current button state is returned as a button bitmask, which can be tested
using the C<SDL_BUTTON( X )> functions (where C<X> is generally 1 for the left,
2 for middle, 3 for the right button), and C<x> and C<y> are set to the mouse
deltas since the last call to SDL_GetRelativeMouseState() or since event
initialization. You can pass C<undef> for either C<x> or C<y>.

Expected parameters include:

=over

=item C<x> - a pointer filled with the last recorded x coordinate of the mouse

=item C<y> - a pointer filled with the last recorded y coordinate of the mouse

=back

=head2 C<SDL_WarpMouseInWindow( ... )>

Move the mouse cursor to the given position within the window.

This function generates a mouse motion event.

Expected parameters include:

=over

=item C<window> - the window to move the mouse into, or C<undef> for the current mouse focus

=item C<x> - the x coordinate within the window

=item C<y> - the y coordinate within the window

=back

=head2 C<SDL_WarpMouseGlobal( ... )>

Move the mouse to the given position in global screen space.

This function generates a mouse motion event.

A failure of this function usually means that it is unsupported by a platform.

Expected parameters include:

=over

=item C<x> - the x coordinate

=item C<y> - the y coordinate

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SetRelativeMouseMode( ... )>

Set relative mouse mode.

While the mouse is in relative mode, the cursor is hidden, and the driver will
try to report continuous motion in the current window. Only relative motion
events will be delivered, the mouse position will not change.

This function will flush any pending mouse motion.

Expected parameters include:

=over

=item C<enabled> - C<SDL_TRUE> to enable relative mode, C<SDL_FALSE> to disable

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

If relative mode is not supported, this returns C<-1>.

=head2 C<SDL_CaptureMouse( ... )>

Capture the mouse and to track input outside an SDL window.

Capturing enables your app to obtain mouse events globally, instead of just
within your window. Not all video targets support this function. When capturing
is enabled, the current window will get all mouse events, but unlike relative
mode, no change is made to the cursor and it is not restrained to your window.

This function may also deny mouse input to other windows--both those in your
application and others on the system--so you should use this function
sparingly, and in small bursts. For example, you might want to track the mouse
while the user is dragging something, until the user releases a mouse button.
It is not recommended that you capture the mouse for long periods of time, such
as the entire time your app is running. For that, you should probably use L<<
C<SDL_SetRelativeMouseMode( ... )>|/C<SDL_SetRelativeMouseMode( ... )> >> or
C<SDL_SetWindowGrab( ... )>, depending on your goals.

While captured, mouse events still report coordinates relative to the current
(foreground) window, but those coordinates may be outside the bounds of the
window (including negative values). Capturing is only allowed for the
foreground window. If the window loses focus while capturing, the capture will
be disabled automatically.

While capturing is enabled, the current window will have the
C<SDL_WINDOW_MOUSE_CAPTURE> flag set.

Expected parameters include:

=over

=item C<enabled> - C<SDL_TRUE> to enable capturing, C<SDL_FALSE> to disable.

=back

Returns C<0> on success or C<-1> if not supported; call C<SDL_GetError( )> for
more information.

=head2 C<SDL_GetRelativeMouseMode( )>

Query whether relative mouse mode is enabled.

Returns C<SDL_TRUE> if relative mode is enabled or C<SDL_FALSE> otherwise.

=head2 C<SDL_CreateCursor( ... )>

Create a cursor using the specified bitmap data and mask (in MSB format).

C<mask> has to be in MSB (Most Significant Bit) format.

The cursor width (C<w>) must be a multiple of 8 bits.

The cursor is created in black and white according to the following:

=over

=item - data=0, mask=1: white

=item - data=1, mask=1: black

=item - data=0, mask=1: transparent

=item - data=1, mask=0: inverted color if possible, black if not.

=back

Cursors created with this function must be freed with L<< C<SDL_FreeCursor( ...
)>|/C<SDL_FreeCursor( ... )> >>.

If you want to have a color cursor, or create your cursor from an
L<SDL2::Surface>, you should use L<< C<SDL_CreateColorCursor( ...
)>|/C<SDL_CreateColorCursor( ... )> >>. Alternately, you can hide the cursor
and draw your own as part of your game's rendering, but it will be bound to the
framerate.

Also, since SDL 2.0.0, L<< C<SDL_CreateSystemCursor( ...
)>|/C<SDL_CreateSystemCursor( ... )> >> is available, which provides twelve
readily available system cursors to pick from.

Expected parameters include:

=over

=item C<data> - the color value for each pixel of the cursor

=item C<mask> - the mask value for each pixel of the cursor

=item C<w> - the width of the cursor

=item C<h> - the height of the cursor

=item C<hot_x> - the X-axis location of the upper left corner of the cursor relative to the actual mouse position

=item C<hot_y> - the Y-axis location of the upper left corner of the cursor relative to the actual mouse position

=back

Returns a new cursor with the specified parameters on success or C<undef> on
failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_CreateColorCursor( ... )>

Create a color cursor.

Expected parameters include:

=over

=item C<surface> - an L<SDL2::Surface> structure representing the cursor image

=item C<hot_x> - the x position of the cursor hot spot

=item C<hot_y> - the y position of the cursor hot spot

=back

Returns the new cursor on success or NULL on failure; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_CreateSystemCursor( ... )>

Create a system cursor.

Expected parameters include:

=over

=item C<id> - an L<< C<SDL_SystemCursor>|/C<SDL_SystemCursor> >> enum value

=back

Returns a cursor on success or NULL on failure; call C<SDL_GetError( )> for
more information.

=head2 C<SDL_SetCursor( ... )>

Set the active cursor.

This function sets the currently active cursor to the specified one. If the
cursor is currently visible, the change will be immediately represented on the
display. C<SDL_SetCursor( undef )> can be used to force cursor redraw, if this
is desired for any reason.

Expected parameters include:

=over

=item C<cursor> - a cursor to make active

=back

=head2 C<SDL_GetCursor( )>

Get the active cursor.

This function returns a pointer to the current cursor which is owned by the
library. It is not necessary to free the cursor with L<< C<SDL_FreeCursor( ...
)>|/C<SDL_FreeCursor( ... )> >>.

Returns the active cursor or C<undef> if there is no mouse.

=head2 C<SDL_GetDefaultCursor( )>

Get the default cursor.

Returns the default cursor on success or C<undef> on failure.

=head2 C<SDL_FreeCursor( ... )>

Free a previously-created cursor.

Use this function to free cursor resources created with L<< C<SDL_CreateCursor(
... )>|/C<SDL_CreateCursor( ... )> >>, L<< C<SDL_CreateColorCursor( ...
)>|/C<SDL_CreateColorCursor( ... )> >> or L<< C<SDL_CreateSystemCursor( ...
)>|/C<SDL_CreateSystemCursor( ... )> >>.

Expected parameters include:

=over

=item C<cursor> - the cursor to free

=back

=head2 C<SDL_ShowCursor( ... )>

Toggle whether or not the cursor is shown.

The cursor starts off displayed but can be turned off. Passing C<SDL_ENABLE>
displays the cursor and passing C<SDL_DISABLE> hides it.

The current state of the mouse cursor can be queried by passing C<SDL_QUERY>;
either C<SDL_DISABLE> or C<SDL_ENABLE> will be returned.

Expected parameters include:

=over

=item C<toggle> - C<SDL_ENABLE> to show the cursor, C<SDL_DISABLE> to hide it, C<SDL_QUERY> to query the current state without changing it

=back

Returns C<SDL_ENABLE> if the cursor is shown, or C<SDL_DISABLE> if the cursor
is hidden, or a negative error code on failure; call C<SDL_GetError( )> for
more information.

=head1 Defined values and Enumerations

These may be imported with their given tags or C<:mouse>.

=head2 C<SDL_SystemCursor>

Cursor types for L<< C<SDL_CreateSystemCursor( ...
)>|/C<SDL_CreateSystemCursor( ... )> >>. They may be imported with the
C<:systemCursor> tag.

=over

=item C<SDL_SYSTEM_CURSOR_ARROW> - Arrow

=item C<SDL_SYSTEM_CURSOR_IBEAM> - I-beam

=item C<SDL_SYSTEM_CURSOR_WAIT> - Wait

=item C<SDL_SYSTEM_CURSOR_CROSSHAIR> - Crosshair

=item C<SDL_SYSTEM_CURSOR_WAITARROW> - Small wait cursor (or Wait if not available)

=item C<SDL_SYSTEM_CURSOR_SIZENWSE> - Double arrow pointing northwest and southeast

=item C<SDL_SYSTEM_CURSOR_SIZENESW> - Double arrow pointing northeast and southwest

=item C<SDL_SYSTEM_CURSOR_SIZEWE> - Double arrow pointing west and east

=item C<SDL_SYSTEM_CURSOR_SIZENS> - Double arrow pointing north and south

=item C<SDL_SYSTEM_CURSOR_SIZEALL> - Four pointed arrow pointing north, south, east, and west

=item C<SDL_SYSTEM_CURSOR_NO> - Slashed circle or crossbones

=item C<SDL_SYSTEM_CURSOR_HAND> - Hand

=item C<SDL_NUM_SYSTEM_CURSORS>

=back

=head2 C<SDL_MouseWheelDirection>

Scroll direction types for the Scroll event. These may be imported with the
C<:mouseWheelDirection> tag.

=over

=item C<SDL_MOUSEWHEEL_NORMAL> - The scroll direction is normal

=item C<SDL_MOUSEWHEEL_FLIPPED> - The scroll direction is flipped / natural

=back

=head2 Button Masks

These functions return values which can be used as a mask when testing buttons
in buttonstate.

=over

=item - Button 1:  Left mouse button

=item - Button 2:  Middle mouse button

=item - Button 3:  Right mouse button

=back

=over

=item C<SDL_BUTTON( ... )> - expects one of the following values

=item C<SDL_BUTTON_LEFT>

=item C<SDL_BUTTON_MIDDLE>

=item C<SDL_BUTTON_RIGHT>

=item C<SDL_BUTTON_X1>

=item C<SDL_BUTTON_X2>

=item C<SDL_BUTTON_LMASK>

=item C<SDL_BUTTON_MMASK>

=item C<SDL_BUTTON_RMASK>

=item C<SDL_BUTTON_X1MASK>

=item C<SDL_BUTTON_X2MASK>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

bitmask coord bitmap framerate buttonstate

=end stopwords

=cut

};
1;
