package SDL2::messagebox 0.01 {
    use SDL2::Utils;
    use SDL2::stdinc;
    use SDL2::video;
    enum
        SDL_MessageBoxFlags => [
        [ SDL_MESSAGEBOX_ERROR                 => 0x00000010 ],
        [ SDL_MESSAGEBOX_WARNING               => 0x00000020 ],
        [ SDL_MESSAGEBOX_INFORMATION           => 0x00000040 ],
        [ SDL_MESSAGEBOX_BUTTONS_LEFT_TO_RIGHT => 0x00000080 ],
        [ SDL_MESSAGEBOX_BUTTONS_RIGHT_TO_LEFT => 0x00000100 ]
        ],
        SDL_MessageBoxButtonFlags => [
        [ SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT => 0x00000001 ],
        [ SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT => 0x00000002 ]
        ];

    package SDL2::MessageBoxButtonData {
        use SDL2::Utils;
        our $TYPE = has
            flags    => 'uint32',
            buttonid => 'int',
            text     => 'opaque'    # 'string'
            ;
    };

    package SDL2::MessageBoxColor {
        use SDL2::Utils;
        our $TYPE = has
            r => 'uint8',
            g => 'uint8',
            b => 'uint8';
    };
    enum SDL_MessageBoxColorType => [
        qw[
            SDL_MESSAGEBOX_COLOR_BACKGROUND
            SDL_MESSAGEBOX_COLOR_TEXT
            SDL_MESSAGEBOX_COLOR_BUTTON_BORDER
            SDL_MESSAGEBOX_COLOR_BUTTON_BACKGROUND
            SDL_MESSAGEBOX_COLOR_BUTTON_SELECTED
            SDL_MESSAGEBOX_COLOR_MAX]
    ];

    package SDL2::MessageBoxColorScheme {
        use SDL2::Utils;
        our $TYPE = has colors => 'opaque'

            #'SDL_MessageBoxColor[' . SDL2::FFI::SDL_MESSAGEBOX_COLOR_MAX() . ']';
    };

    package SDL2::MessageBoxData {
        use SDL2::Utils;
        has
            flags       => 'uint32',
            window      => 'SDL_Window',
            title       => 'opaque',                      # string
            message     => 'opaque',                      # string
            numbuttons  => 'int',
            buttons     => 'SDL_MessageBoxButtonData',
            colorScheme => 'SDL_MessageBoxColorScheme';
    };
    attach messagebox => {
        SDL_ShowMessageBox       => [ [ 'SDL_MessageBoxData', 'int*' ], 'int' ],
        SDL_ShowSimpleMessageBox => [ [ 'uint32', 'string', 'string', 'SDL_Window' ], 'int' ]
    };

=encoding utf-8

=head1 NAME

SDL2::messagebox - Modal Message Box Support

=head1 SYNOPSIS

    use SDL2 qw[:messagebox];

=head1 DESCRIPTION

SDL2::messagebox provides functions to display modal message boxes.

=head1 Functions

These functions may be imported by name or with the C<:messagebox> tag.

=head2 C<SDL_ShowMessageBox( ... )>

Create a modal message box.

If your needs aren't complex, it might be easier to use L<<
C<SDL_ShowSimpleMessageBox( ... )>|/C<SDL_ShowSimpleMessageBox( ... )> >>.

This function should be called on the thread that created the parent window, or
on the main thread if the messagebox has no parent. It will block execution of
that thread until the user clicks a button or closes the messagebox.

This function may be called at any time, even before C<SDL_Init( ... )>. This
makes it useful for reporting errors like a failure to create a renderer or
OpenGL context.

On X11, SDL rolls its own dialog box with X11 primitives instead of a formal
toolkit like GTK+ or Qt.

Note that if C<SDL_Init( ... )> would fail because there isn't any available
video target, this function is likely to fail for the same reasons. If this is
a concern, check the return value from this function and fall back to writing
to stderr if you can.

Expected parameters include:

=over

=item C<messageboxdata> - the L<SDL2::MessageBoxData> structure with title, text and other options

=item C<buttonid> - the pointer to which user id of hit button should be copied

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_ShowSimpleMessageBox( ... )>

Display a simple modal message box.

If your needs aren't complex, this function is preferred over L<<
C<SDL_ShowMessageBox( ... )>|/C<SDL_ShowMessageBox( ... )> >>.

C<flags> may be any of the following:

=over

=item C<SDL_MESSAGEBOX_ERROR>: error dialog

=item C<SDL_MESSAGEBOX_WARNING>: warning dialog

=item C<SDL_MESSAGEBOX_INFORMATION>: informational dialog

=back

This function should be called on the thread that created the parent window, or
on the main thread if the messagebox has no parent. It will block execution of
that thread until the user clicks a button or closes the messagebox.

This function may be called at any time, even before C<SDL_Init( ... )>. This
makes it useful for reporting errors like a failure to create a renderer or
OpenGL context.

On X11, SDL rolls its own dialog box with X11 primitives instead of a formal
toolkit like GTK+ or Qt.

Note that if C<SDL_Init( ... )> would fail because there isn't any available
video target, this function is likely to fail for the same reasons. If this is
a concern, check the return value from this function and fall back to writing
to stderr if you can.

Expected parameters include:

=over

=item C<flags> - an C<SDL_MessageBoxFlags> value

=item C<title> - UTF-8 title text

=item C<message> - UTF-8 message text

=item C<window> - the parent window, or C<undef> for no parent

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head1 Defined Variables and Enumerations

Variables may be imported by name or with the C<:messagebox> tag. Enumerations
may be imported with their given tag.

=head2 C<SDL_MessageBoxFlags>

L<SDL2::MessageBox> flags. If supported will display warning icon, etc.

=over

=item C<SDL_MESSAGEBOX_ERROR> - error dialog

=item C<SDL_MESSAGEBOX_WARNING> - warning dialog

=item C<SDL_MESSAGEBOX_INFORMATION> - informational dialog

=item C<SDL_MESSAGEBOX_BUTTONS_LEFT_TO_RIGHT> - buttons placed left to right

=item C<SDL_MESSAGEBOX_BUTTONS_RIGHT_TO_LEFT> - buttons placed right to left

=back

=head2 C<SDL_MessageBoxButtonFlags>

Flags for L<SDL2::MessageBoxButtonData>.

=over

=item C<SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT> - Marks the default button when return is hit

=item C<SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT> - Marks the default button when escape is hit

=back

=head2 C<SDL_MessageBoxColorType>

=over

=item C<SDL_MESSAGEBOX_COLOR_BACKGROUND>

=item C<SDL_MESSAGEBOX_COLOR_TEXT>

=item C<SDL_MESSAGEBOX_COLOR_BUTTON_BORDER>

=item C<SDL_MESSAGEBOX_COLOR_BUTTON_BACKGROUND>

=item C<SDL_MESSAGEBOX_COLOR_BUTTON_SELECTED>

=item C<SDL_MESSAGEBOX_COLOR_MAX>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

messagebox

=end stopwords

=cut

};
1;
