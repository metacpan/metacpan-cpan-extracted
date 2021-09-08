package SDL2::keyboard 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::error;
    use SDL2::keycode;
    use SDL2::video;
    #
    package SDL2::Keysym {
        use SDL2::Utils;
        has
            scancode => 'SDL_Scancode',
            sym      => 'SDL_Keycode',
            mod      => 'uint16',
            unused   => 'uint32';
    };
    #
    attach keyboard => {
        SDL_GetKeyboardFocus => [ [], 'SDL_Window' ],
        SDL_GetKeyboardState => [                       # Make this nicer for returning lists
            ['int*'],
            'uint8[' . SDL2::FFI::SDL_NUM_SCANCODES() . ']' => sub ( $inner, $numkeys = () ) {
                my $retval = $inner->($numkeys);
                wantarray ? @$retval : $retval;
            }
        ],
        SDL_GetModState              => [ [], 'SDL_Keymod' ],
        SDL_SetModState              => [ ['SDL_Keymod'] ],
        SDL_GetKeyFromScancode       => [ ['SDL_Scancode'], 'SDL_Keycode' ],
        SDL_GetScancodeFromKey       => [ ['SDL_Keycode'],  'SDL_Scancode' ],
        SDL_GetScancodeName          => [ ['SDL_Scancode'], 'string' ],
        SDL_GetScancodeFromName      => [ ['string'],       'SDL_Scancode' ],
        SDL_GetKeyName               => [ ['SDL_Keycode'],  'string' ],
        SDL_GetKeyFromName           => [ ['string'],       'SDL_Keycode' ],
        SDL_StartTextInput           => [ [] ],
        SDL_IsTextInputActive        => [ [], 'SDL_bool' ],
        SDL_StopTextInput            => [ [] ],
        SDL_SetTextInputRect         => [ ['SDL_Rect'] ],
        SDL_HasScreenKeyboardSupport => [ [],             'SDL_bool' ],
        SDL_IsScreenKeyboardShown    => [ ['SDL_Window'], 'SDL_bool' ]
    };

=encoding utf-8

=head1 NAME

SDL2::keyboard - SDL Keyboard Event Handling

=head1 SYNOPSIS

    use SDL2 qw[:keyboard];

=head1 DESCRIPTION

SDL2::keyboard

=head1 Functions

=head2 C<SDL_GetKeyboardFocus( )>

Query the window which currently has keyboard focus.

Returns the window with keyboard focus.

=head2 C<SDL_GetKeyboardState( ... )>

Get a snapshot of the current state of the keyboard.

    my @state = SDL_GetKeyboardState(undef);
    if ( $state[SDL_SCANCODE_RETURN] ) {
        printf("<RETURN> is pressed.\n");
    }
    elsif ( $state[SDL_SCANCODE_RIGHT] && $state[SDL_SCANCODE_UP] ) {
        printf("Right and Up Keys Pressed.\n");
    }

A array element with a value of C<1> means that the key is pressed and a value
of C<0> means that it is not. Indexes into this array are obtained by using L<<
C<SDL_Scancode>|SDL2::scancode/C<SDL_Scancode> >> values.

Use C<SDL_PumpEvents( )> to update the state array.

This function gives you the current state after all events have been processed,
so if a key or button has been pressed and released before you process events,
then the pressed state will never show up in the C<SDL_GetKeyboardState( )>
calls.

Note: This function doesn't take into account whether shift has been pressed or
not.

Expected parameters include:

=over

=item C<numkeys> - if non-NULL, receives the length of the returned array

=back

Returns a pointer to an array of key states.

=head2 C<SDL_GetModState( )>

Get the current key modifier state for the keyboard.

Returns an OR'd combination of the modifier keys for the keyboard. See L<<
C<SDL_Keymod>|SDL2::keycode/C<SDL_Keymod> >> for details.

=head2 C<SDL_SetModState( ... )>

Set the current key modifier state for the keyboard.

The inverse of L<< C<SDL_GetModState( )>|/C<SDL_GetModState( )> >>,
C<SDL_SetModState( ... )> allows you to impose modifier key states on your
application. Simply pass your desired modifier states into C<modstate>. This
value may be a bitwise, OR'd combination of L<<
C<SDL_Keymod>|SDL2::keycode/C<SDL_Keymod> >> values.

This does not change the keyboard state, only the key modifier flags that SDL
reports.

Expected parameters include:

=over

=item C<modstate> - the desired L<< C<SDL_Keymod>|SDL2::keycode/C<SDL_Keymod> >> for the keyboard

=back

=head2 C<SDL_GetKeyFromScancode( ... )>

Get the key code corresponding to the given scancode according to the current
keyboard layout.

See L<< C<SDL_Keycode>|SDL2::keycode/C<SDL_Keycode> >> for details.

Expected parameters include:

=over

=item C<scancode> - the desired L<< C<SDL_Scancode>|SDL2::scancode/C<SDL_Scancode> >> to query

=back

Returns the L<< C<SDL_Keycode>|SDL2::keycode/C<SDL_Keycode> >> that corresponds
to the given L<< C<SDL_Scancode>|SDL2::scancode/C<SDL_Scancode> >>.

=head2 C<SDL_GetScancodeFromKey( ... )>

Get the scancode corresponding to the given key code according to the current
keyboard layout.

See L<< C<SDL_Scancode>|SDL2::scancode/C<SDL_Scancode> >> for details.

Expected parameters include:

=over

=item C<key> - the desired L<< C<SDL_Keycode>|SDL2::keycode/C<SDL_Keycode> >> to query

=back

Returns the L<< C<SDL_Scancode>|SDL2::scancode/C<SDL_Scancode> >> that
corresponds to the given L<< C<SDL_Keycode>|SDL2::keycode/C<SDL_Keycode> >>.

=head2 C<SDL_GetScancodeName( ... )>

Get a human-readable name for a scancode.

See L<< C<SDL_Scancode>|SDL2::scancode/C<SDL_Scancode> >> for details.

B<Warning>: The returned name is by design not stable across platforms, e.g.
the name for C<SDL_SCANCODE_LGUI> is "Left GUI" under Linux but "Left Windows"
under Microsoft Windows, and some scancodes like C<SDL_SCANCODE_NONUSBACKSLASH>
don't have any name at all. There are even scancodes that share names, e.g.
C<SDL_SCANCODE_RETURN> and C<SDL_SCANCODE_RETURN2> (both called "Return"). This
function is therefore unsuitable for creating a stable cross-platform two-way
mapping between strings and scancodes.

Expected parameters include:

=over

=item C<scancode> the desired L<< C<SDL_Scancode>|SDL2::scancode/C<SDL_Scancode> >> to query

=back

Returns the name for the scancode. If the scancode doesn't have a name this
function returns an empty string (C<"">).

=head2 C<SDL_GetScancodeFromName( ... )>

Get a scancode from a human-readable name.

Expected parameters include:

=over

=item C<name> - the human-readable scancode name

=back

Returns the L<< C<SDL_Scancode>|SDL2::scancode/C<SDL_Scancode> >> , or
C<SDL_SCANCODE_UNKNOWN> if the name wasn't recognized; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_GetKeyName( ... )>

Get a human-readable name for a key.

See L<< C<SDL_Scancode>|SDL2::scancode/C<SDL_Scancode> >> and L<<
C<SDL_Keycode>|SDL2::keycode/C<SDL_Keycode> >> for details.

Expected parameters include:

=over

=item C<key> - the desired SDL_Keycode to query

=back

Returns a pointer to a UTF-8 string that stays valid at least until the next
call to this function. If you need it around any longer, you must copy it. If
the key doesn't have a name, this function returns an empty string (C<"">).

=head2 C<SDL_GetKeyFromName( ... )>

Get a key code from a human-readable name.

Expected parameters include:

=over

=item C<name> - the human-readable key name

=back

Returns key code, or C<SDLK_UNKNOWN> if the name wasn't recognized; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_StartTextInput( )>

Start accepting Unicode text input events.

This function will start accepting Unicode text input events in the focused SDL
window, and start emitting C<SDL_TextInputEvent> (C<SDL_TEXTINPUT>) and
C<SDL_TextEditingEvent> (C<SDL_TEXTEDITING>) events. Please use this function
in pair with L<< C<SDL_StopTextInput( )>|/C<SDL_StopTextInput( )> >>.

On some platforms using this function activates the screen keyboard.

=head2 C<SDL_IsTextInputActive( )>

Check whether or not Unicode text input events are enabled.

Returns C<SDL_TRUE> if text input events are enabled else C<SDL_FALSE>.

=head2 C<SDL_StopTextInput( )>

Stop receiving any text input events.

=head2 C<SDL_SetTextInputRect( )>

Set the rectangle used to type Unicode text inputs.

Expected parameters include:

=over

=item C<rect> - the L<SDL2::Rect> structure representing the rectangle to receive text (ignored if C<undef>)

=back

=head2 C<SDL_HasScreenKeyboardSupport( )>

Check whether the platform has screen keyboard support.

Returns C<SDL_TRUE> if the platform has some screen keyboard support or
C<SDL_FALSE> if not.

=head2 C<SDL_IsScreenKeyboardShown( ... )>

Check whether the screen keyboard is shown for given window.

Expected parameters include:

=over

=item C<window> - the window for which screen keyboard should be queried

=back

Returns C<SDL_TRUE> if screen keyboard is shown or C<SDL_FALSE> if not.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

bitwise scancodes scancode

=end stopwords

=cut

};
1;
