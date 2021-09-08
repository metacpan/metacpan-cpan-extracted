package SDL2::shape 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::pixels;
    use SDL2::rect;
    use SDL2::surface;
    use SDL2::video;
    #
    define shape => [
        [ SDL_NONSHAPEABLE_WINDOW    => -1 ],
        [ SDL_INVALID_SHAPE_ARGUMENT => -2 ],
        [ SDL_WINDOW_LACKS_SHAPE     => -3 ]
    ];
    attach shape => {
        SDL_CreateShapedWindow =>
            [ [ 'string', 'uint', 'uint', 'uint', 'uint', 'uint32' ], 'SDL_Window' ],
        SDL_IsShapedWindow => [ ['SDL_Window'], 'SDL_bool' ]
    };
    enum WindowShapeMode => [
        qw[ShapeModeDefault
            ShapeModeBinarizeAlpha
            ShapeModeReverseBinarizeAlpha
            ShapeModeColorKey]
    ];
    define shape => [
        [   SDL_SHAPEMODEALPHA => sub ($mode) {
                ( $mode == SDL2::FFI::ShapeModeDefault() ||
                        $mode == SDL2::FFI::ShapeModeBinarizeAlpha() ||
                        $mode == SDL2::FFI::ShapeModeReverseBinarizeAlpha() )
            }
        ],
    ];

    package SDL2::WindowShapeParams {
        use SDL2::Utils;
        use FFI::C::UnionDef;
        is 'Union';
        our $TYPE = has binarizationCutoff => 'uint8', colorKey => 'SDL_Color';
    };

    package SDL2::WindowShapeMode {
        use SDL2::Utils;
        our $TYPE = has
            mode       => 'WindowShapeMode',
            parameters => 'SDL_WindowShapeParams';
    };
    attach shape => {
        SDL_SetWindowShape => [ [ 'SDL_Window', 'SDL_Surface', 'SDL_WindowShapeMode' ], 'int' ],
        SDL_GetShapedWindowMode => [ [ 'SDL_Window', 'SDL_WindowShapeMode' ], 'int' ]
    };

=encoding utf-8

=head1 NAME

SDL2::shape - Functions for the Shaped Window API

=head1 SYNOPSIS

    use SDL2 qw[:shape];

=head1 DESCRIPTION

SDL2::shape exposes functions which allow you to create windows with custom
shapes.

=head1 Functions

These functions may be imported by name or with the C<:shape> tag.

=head2 C<SDL_CreateShapedWindow( ... )>

Create a window that can be shaped with the specified position, dimensions, and
flags.

Expected parameters include:

=over

=item C<title> - The title of the window, in UTF-8 encoding

=item C<x> - The x position of the window, C<SDL_WINDOWPOS_CENTERED>, or C<SDL_WINDOWPOS_UNDEFINED>

=item C<y> - The y position of the window, C<SDL_WINDOWPOS_CENTERED>, or C<DL_WINDOWPOS_UNDEFINED>.

=item C<w> - The width of the window.

=item C<h> - The height of the window.

=item C<flags>

The flags for the window, a mask of C<SDL_WINDOW_BORDERLESS> with any of the
following: C<SDL_WINDOW_OPENGL>, C<SDL_WINDOW_INPUT_GRABBED>,
C<DL_WINDOW_HIDDEN>, C<SDL_WINDOW_RESIZABLE>, C<SDL_WINDOW_MAXIMIZED>,
C<SDL_WINDOW_MINIMIZED>.

C<SDL_WINDOW_BORDERLESS> is always set, and C<SDL_WINDOW_FULLSCREEN> is always
unset.

=back

Returns the window created, or C<undef> if window creation failed.

=head2 C<SDL_IsShapedWindow( ... )>

Return whether the given window is a shaped window.

Expected parameters include:

=over

=item C<window> - the window to query for being shaped

=back

Returns C<SDL_TRUE> if the window is a window that can be shaped, C<SDL_FALSE>
if the window is unshaped or C<undef>.

=head2 C<SDL_SetWindowShape( ... )>

Set the shape and parameters of a shaped window.

Expected parameters include:

=over

=item C<window> - the shaped window whose parameters should be set

=item C<shape> - a surface encoding the desired shape for the window

=item C<shape_mode> - the parameters to set for the shaped window

=back

Returns C<0> on success, C<SDL_INVALID_SHAPE_ARGUMENT> on an invalid shape
argument, or C<SDL_NONSHAPEABLE_WINDOW> if the L<SDL2::Window> given does not
reference a valid shaped window.

=head2 C<SDL_GetShapedWindowMode( ... )>

Get the shape parameters of a shaped window.

Expected parameters include:

=over

=item C<window> - the shaped window whose parameters should be retrieved

=item C<shape_mode> - an empty shape-mode structure to fill, or C<undef> to check whether the window has a shape

=back

Returns C<0> if the window has a shape and, provided shape_mode was not
C<undef>, C<shape_mode> has been filled with the mode data,
C<SDL_NONSHAPEABLE_WINDOW> if the L<SDL2::Window> given is not a shaped window,
or C<SDL_WINDOW_LACKS_SHAPE> if the L<SDL2::Window> given is a shapeable window
currently lacking a shape.

=head1 Defined Variables and Enumerations

Variables may be imported by name or with the C<:shape> tag.

=over

=item C<SDL_NONSHAPEABLE_WINDOW>

=item  C<SDL_INVALID_SHAPE_ARGUMENT>

=item C<SDL_WINDOW_LACKS_SHAPE>

=back

=head2 C<WindowShapeMode>

An enum denoting the specific type of contents present in an
C<SDL_WindowShapeParams> union. These may be imported with the
C<:windowShapeMode> tag.

=over

=item C<ShapeModeDefault> - The default mode, a binarized alpha cutoff of 1

=item C<ShapeModeBinarizeAlpha> - A binarized alpha cutoff with a given integer value

=item C<ShapeModeReverseBinarizeAlpha> - A binarized alpha cutoff with a given integer value, but with the opposite comparison

=item C<ShapeModeColorKey> - A color key is applied.

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

binarized

=end stopwords

=cut

};
1;
