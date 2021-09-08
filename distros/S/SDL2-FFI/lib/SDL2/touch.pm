package SDL2::touch 0.01 {
    use SDL2::Utils;
    use SDL2::stdinc;
    use SDL2::error;
    use SDL2::video;
    #
    ffi->type( 'sint64' => 'SDL_TouchID' );
    ffi->type( 'sint64' => 'SDL_FingerID' );
    #
    enum SDL_TouchDeviceType => [
        [ SDL_TOUCH_DEVICE_INVALID => -1 ], qw[SDL_TOUCH_DEVICE_DIRECT
            SDL_TOUCH_DEVICE_INDIRECT_ABSOLUTE
            SDL_TOUCH_DEVICE_INDIRECT_RELATIVE]
    ];
    #
    package SDL2::Finger {
        use SDL2::Utils;
        our $TYPE = has
            id       => 'SDL_FingerID',
            x        => 'float',
            y        => 'float',
            pressure => 'float';
    };
    #
    define touch => [
        [ SDL_TOUCH_MOUSEID => -1 ],    # unsigned 64bit int
        [ SDL_MOUSE_TOUCHID => -1 ]     # signed 64bit int
    ];
    #
    attach touch => {
        SDL_GetNumTouchDevices => [ [],                       'int' ],
        SDL_GetTouchDevice     => [ ['int'],                  'SDL_TouchID' ],
        SDL_GetTouchDeviceType => [ ['SDL_TouchID'],          'SDL_TouchDeviceType' ],
        SDL_GetNumTouchFingers => [ ['SDL_TouchID'],          'int' ],
        SDL_GetTouchFinger     => [ [ 'SDL_TouchID', 'int' ], 'SDL_Finger' ]
    };

=encoding utf-8

=head1 NAME

SDL2::touch - SDL Touch Event Handling

=head1 SYNOPSIS

    use SDL2 qw[:touch];

=head1 DESCRIPTION

SDL2::touch provides functions and defined values that allow for handling
simple touch events. These functions may be imported by name or with the
C<:touch> tag.

=head1 Functions

These may be imported by name or with the C<:touch> tag.

=head2 C<SDL_GetNumTouchDevices( )>

Get the number of registered touch devices.

On some platforms SDL first sees the touch device if it was actually used.
Therefore C<SDL_GetNumTouchDevices( )> may return C<0> although devices are
available. After using all devices at least once the number will be correct.

Returns the number of registered touch devices.

=head2 C<SDL_GetTouchDevice( ... )>

Get the touch ID with the given index.

Expected parameters include:

=over

=item C<index> - the touch device index

=back

Returns the touch ID with the given index on success or C<0> if the index is
invalid; call C<SDL_GetError( )> for more information.

=head2 C<SDL_GetTouchDeviceType( ... )>

Get the type of the given touch device.

Expected parameters include:

=over

=item C<touchID> - the touch ID to query

=back

Returns a C<SDL_TouchDeviceType>.

=head2 C<SDL_GetNumTouchFingers( ... )>

Get the number of active fingers for a given touch device.

Expected parameters include:

=over

=item C<touchID> - the ID of a touch device

=back

Returns the number of active fingers for a given touch device on success or
C<0> on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_GetTouchFinger( ... )>

Get the finger object for specified touch device ID and finger index.

The returned resource is owned by SDL and should not be deallocated.

Expected parameters include:

=over

=item C<touchID> - the ID of the requested touch device

=item C<index> - the index of the requested finger

=back

Returns a pointer to the L<SDL2::Finger> object or C<undef> if no object at the
given ID and index could be found.

=head1 Defined Types, Enumerations, and Values

These values may be imported by name or with the given tag.

=head2 C<SDL_TouchID>

Signed 64-bit integer.

=head2 C<SDL_FingerID>

Signed 64-bit integer.

=head2 C<SDL_TouchDeviceType>

Enumeration which may be imported with the C<:touchDeviceType> tag.

=over

=item C<SDL_TOUCH_DEVICE_INVALID>

=item C<SDL_TOUCH_DEVICE_DIRECT> - touch screen with window-relative coordinates

=item C<SDL_TOUCH_DEVICE_INDIRECT_ABSOLUTE> - trackpad with absolute device coordinates

=item C<SDL_TOUCH_DEVICE_INDIRECT_RELATIVE> - trackpad with screen cursor-relative coordinates

=back

=head2 C<SDL_TOUCH_MOUSEID>

Used as the device ID for mouse events simulated with touch input.

=head2 C<SDL_MOUSE_TOUCHID>

Used as the C<SDL_TouchID> for touch events simulated with mouse input.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

deallocated trackpad

=end stopwords

=cut

};
1;
