package SDL2::metal 0.01 {
    use SDL2::Utils;
    #
    use SDL2::video;

    package SDL2::MetalView {
        use SDL2::Utils;
        our $TYPE = has();
    };
    attach metal => {
        SDL_Metal_CreateView      => [ ['SDL_Window'], 'SDL_MetalView' ],
        SDL_Metal_DestroyView     => [ ['SDL_MetalView'] ],
        SDL_Metal_GetLayer        => [ ['SDL_MetalView'], 'opaque' ],
        SDL_Metal_GetDrawableSize => [ [ 'SDL_Window', 'int', 'int' ] ]
    };

=encoding utf-8

=head1 NAME

SDL2::metal - Metal Laysers and Views on SDL Windows

=head1 SYNOPSIS

    use SDL2 qw[:metal];

=head1 DESCRIPTION

This package contains functions to creating Metal layers and views on SDL
windows.

=head1 Functions

These functions may be imported by name or with the C<:metal> tag.

=head2 C<SDL_Metal_CreateView( ... )>

Create a CAMetalLayer-backed NSView/UIView and attach it to the specified
window.

On macOS, this does *not* associate a MTLDevice with the CAMetalLayer on its
own. It is up to user code to do that.

Expected parameters include:

=over

=item C<window> - L<SDL2::Window> from which the drawable size should be queried

=back

The returned handle can be cast directly to a NSView or UIView. To access the
backing CAMetalLayer, call L<< C<SDL_Metal_GetLayer( ...
)>|C<SDL_Metal_GetLayer( ... )> >>.

Note: window must be created with the C<SDL_WINDOW_METAL> flag.

=head2 C<SDL_Metal_DestroyView( ... )>

Destroy an existing L<SDL2::MetalView> object.

This should be called before C<SDL_DestroyWindow( ... )>, if L<<
C<SDL_Metal_CreateView( ... )>|/C<SDL_Metal_CreateView( ... )> >> was called
after C<SDL_CreateWindow( ... )>.

Expected parameters include:

=over

=item C<view> - L<SDL2::MetalView> to destroy

=back

=head2 C<SDL_Metal_GetLayer( ... )>

Get a pointer to the backing CAMetalLayer for the given view.

Expected parameters include:

=over

=item C<view> - L<SDL2::MetalView> to query

=back

Returns an opaque pointer.

=head2 C<SDL_Metal_GetDrawableSize( ... )>

Get the size of a window's underlying drawable in pixels (for use with setting
viewport, scissor & etc).

Expected parameters include:

=over

=item C<window> - L<SDL2::Window> from which the drawable size should be queried

=item C<w> - pointer to variable for storing the width in pixels, may be C<undef>

=item C<h> - Pointer to variable for storing the height in pixels, may be <undef>

=back

This may differ from C<SDL_GetWindowSize( ... )> if we're rendering to a
high-DPI drawable, i.e. the window was created with C<SDL_WINDOW_ALLOW_HIGHDPI>
on a platform with high-DPI support (Apple calls this "Retina"), and not
disabled by the C<SDL_HINT_VIDEO_HIGHDPI_DISABLED> hint.

Note: On macOS high-DPI support must be enabled for an application by setting
NSHighResolutionCapable to true in its Info.plist.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

MTLDevice

=end stopwords

=cut

};
1;
