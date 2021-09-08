package SDL2::misc {
    use strictures 2;
    use SDL2::Utils;
    #
    use SDL2::stdinc;
    #
    attach misc => { SDL_OpenURL => [ ['string'], 'int' ] };

=encoding utf-8

=head1 NAME

SDL2::misc - SDL API functions that don't fit elsewhere

=head1 SYNOPSIS

    use SDL2 qw[:misc];
    SDL_OpenURL( 'https://github.com/' );

=head1 DESCRIPTION

SDL2::misc contains functions that don't fit anywhere else.

=head1 Functions

These may be imported by name or with the C<:misc> tag.

=head2 C<SDL_OpenURL( ... )>

Open a URL/URI in the browser or other appropriate external application.

Open a URL in a separate, system-provided application. How this works will vary
wildly depending on the platform. This will likely launch what makes sense to
handle a specific URL's protocol (a web browser for C<http://>, etc), but it
might also be able to launch file managers for directories and other things.

What happens when you open a URL varies wildly as well: your game window may
lose focus (and may or may not lose focus if your game was fullscreen or
grabbing input at the time). On mobile devices, your app will likely move to
the background or your process might be paused. Any given platform may or may
not handle a given URL.

If this is unimplemented (or simply unavailable) for a platform, this will fail
with an error. A successful result does not mean the URL loaded, just that we
launched _something_ to handle it (or at least believe we did).

All this to say: this function can be useful, but you should definitely test it
on every platform you target.

Expected parameters include:

=over

=item C<url> - a valid URL/URI to open. Use C<file:///full/path/to/file> for local files, if supported.

=back

Returns C<0> on success, or C<-1> on error; call C<SDL_GetError( )> for more
information.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

fullscreen non-fullscreen high-dpi borderless resizable draggable taskbar
tooltip popup subwindow macOS iOS NSHighResolutionCapable videomode screensaver
wgl lifespan vsync glX framebuffer framerate

=end stopwords

=cut

};
1;
