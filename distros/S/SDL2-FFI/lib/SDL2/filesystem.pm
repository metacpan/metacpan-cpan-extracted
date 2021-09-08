package SDL2::filesystem 0.01 {
    use SDL2::Utils;
    use SDL2::stdinc;
    use SDL2::error;
    #
    attach filesystem => {
        SDL_GetBasePath => [ [],                     'string' ],
        SDL_GetPrefPath => [ [ 'string', 'string' ], 'string' ]
    };

=encoding utf-8

=head1 NAME

SDL2::filesystem - Filesystem SDL API Functions

=head1 SYNOPSIS

    use SDL2 qw[:filesystem];

=head1 DESCRIPTION

SDL2::filesystem provides functions to deal with the filesystem.

=head1 Functions

These may be imported by name or with the C<:filesystem> tag.

=head2 C<SDL_GetBasePath( )>

Get the directory where the application was run from.

This is not necessarily a fast call, so you should call this once near startup
and save the string if you need it.

B<Mac OS X and iOS Specific Functionality>: If the application is in a ".app"
bundle, this function returns the Resource directory (e.g.
C<MyApp.app/Contents/Resources/>). This behaviour can be overridden by adding a
property to the Info.plist file. Adding a string key with the name
C<SDL_FILESYSTEM_BASE_DIR_TYPE> with a supported value will change the
behaviour.

Supported values for the C<SDL_FILESYSTEM_BASE_DIR_TYPE> property (Given an
application in C</Applications/SDLApp/MyApp.app>):

=over

=item C<resource>: bundle resource directory (the default). For example: C</Applications/SDLApp/MyApp.app/Contents/Resources>

=item C<bundle>: the Bundle directory. For example: C</Applications/SDLApp/MyApp.app/>

=item C<parent>: the containing directory of the bundle. For example: C</Applications/SDLApp/>

=back

The returned path is guaranteed to end with a path separator (C<\> on Windows,
C</> on most other platforms).

The pointer returned is owned by the caller. Please call SDL_free() on the
pointer when done with it.

Returns an absolute path in UTF-8 encoding to the application data directory.
C<undef> will be returned on error or when the platform doesn't implement this
functionality, call C<SDL_GetError( )> for more information.

=head2 C<( ... )>

Get the user-and-app-specific path where files can be written.

Get the "pref dir". This is meant to be where users can write personal files
(preferences and save games, etc) that are specific to your application. This
directory is unique per user, per application.

This function will decide the appropriate location in the native filesystem,
create the directory if necessary, and return a string of the absolute path to
the directory in UTF-8 encoding.

On Windows, the string might look like: C<C:\Users\bob\AppData\Roaming\My
Company\My Program Name\>

On Linux, the string might look like: C</home/bob/.local/share/My Program
Name/>

On Mac OS X, the string might look like: C</Users/bob/Library/Application
Support/My Program Name/>

You should assume the path returned by this function is the only safe place to
write files (and that L<< C<SDL_GetBasePath( )>|/C<SDL_GetBasePath( )> >>,
while it might be writable, or even the parent of the returned path, isn't
where you should be writing things).

Both the org and app strings may become part of a directory name, so please
follow these rules:

=over

=item - Try to use the same org string (_including case-sensitivity_) for all your applications that use this function.

=item - Always use a unique app string for each one, and make sure it never changes for an app once you've decided on it.

=item - Unicode characters are legal, as long as it's UTF-8 encoded, but...

=item - ...only use letters, numbers, and spaces. Avoid punctuation like "Game Name 2: Bad Guy's Revenge!" ... "Game Name 2" is sufficient.

=back

The returned path is guaranteed to end with a path separator (C<\> on Windows,
C</> on most other platforms).

The pointer returned is owned by the caller. Please call C<SDL_free( ... )> on
the pointer when done with it.

Expected parameters include:

=over

=item C<org> - the name of your organization

=item C<app> - the name of your application

=back

Returns a UTF-8 string of the user directory in platform-dependent notation.
C<undef> if there's a problem (creating directory failed, etc.).

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

iOS pref dir

=end stopwords

=cut

};
1;
