package SDL2::quit 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    #
    define quit => [
        [   SDL_QuitRequested => sub () {
                SDL2::FFI::SDL_PumpEvents(), (
                    SDL2::FFI::SDL_PeepEvents(
                        undef,                    0,
                        SDL2::FFI::SDL_PEEKEVENT, SDL2::FFI::SDL_QUIT,
                        SDL2::FFI::SDL_QUIT
                    ) > 0
                    );
            }
        ]
    ];

=encoding utf-8

=head1 NAME

SDL2::quit - SDL Quit Event Handling

=head1 SYNOPSIS

    use SDL2 qw[:quit];

=head1 DESCRIPTION

An C<SDL_QUIT> event is generated when the user tries to close the application
window.

If it is ignored or filtered out, the window will remain open. If it is not
ignored or filtered, it is queued normally and the window is allowed to close. 
When the window is closed, screen updates will complete, but have no effect.

C<SDL_Init( ... )> installs signal handlers for C<SIGINT> (keyboard interrupt)
and C<SIGTERM> (system termination request), if handlers do not already exist,
that generate C<SDL_QUIT> events as well. There is no way to determine the
cause of an C<SDL_QUIT> event, but setting a signal handler in your application
will override the default generation of quit events for that signal.

=head1 Functions

The following function may be imported with the C<:quit> tag.

=head2 C<SDL_QuitRequested( )>

Use this function to see whether an C<SDL_QUIT> event is queued.

Returns C<SDL_TRUE> if C<SDL_QUIT> is queued or C<SDL_FALSE> otherwise.

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
