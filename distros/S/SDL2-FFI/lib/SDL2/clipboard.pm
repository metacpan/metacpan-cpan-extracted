package SDL2::clipboard 0.01 {
    use SDL2::Utils;
    attach clipboard => {
        SDL_SetClipboardText => [ ['string'], 'int' ],
        SDL_GetClipboardText => [ [],         'string' ],
        SDL_HasClipboardText => [ [],         'SDL_bool' ]
    };

=encoding utf-8

=head1 NAME

SDL2::clipboard - UTF-8 Friendly Clipboard Functions

=head1 SYNOPSIS

    use SDL2 qw[:clipboard];

=head1 DESCRIPTION

Basic clipboard handling.

=head1 Functions

These functions expose the clipboard. SDL's video subsystem must be initialized
to get or modify clipboard text.

=head2 C<SDL_SetClipboardText( ... )>

Put UTF-8 text into the clipboard.

    SDL_SetClipboardText( 'Hello, world!' );

Expected parameters include:

=over

=item C<text> - the text to store in the clipboard

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetClipboardText( )>

Get UTF-8 text from the clipboard, which must be freed with C<SDL_free( )>.

    my $clipboard = SDL_GetClipboardText( );

This functions returns NULL if there was not enough memory left for a copy of
the clipboard's content.

Returns the clipboard text on success or NULL on failure; call C<SDL_GetError(
)> for more information. Caller must call C<SDL_free( )> on the returned
pointer when done with it.

=head2 C<SDL_HasClipboardText( )>

Query whether the clipboard exists and contains a non-empty text string.

    if ( SDL_HasClipboardText( ) ) {
        ...
    }

Returns C<SDL_TRUE> if the clipboard has text, or C<SDL_FALSE> if it does not.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

=end stopwords

=cut

};
1;
