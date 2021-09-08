package SDL2::gesture 0.01 {
    use SDL2::Utils;
    use SDL2::stdinc;
    use SDL2::error;
    use SDL2::video;
    use SDL2::touch;
    #
    ffi->type( 'sint64' => 'SDL_GestureID' );
    #
    attach gesture => {
        SDL_RecordGesture          => [ ['SDL_TouchID'],                  'int' ],
        SDL_SaveAllDollarTemplates => [ ['SDL_RWops'],                    'int' ],
        SDL_SaveDollarTemplate     => [ [ 'SDL_GestureID', 'SDL_RWops' ], 'int' ],
        SDL_LoadDollarTemplates    => [ [ 'SDL_TouchID', 'SDL_RWops' ],   'int' ]
    };

=encoding utf-8

=head1 NAME

SDL2::gesture - SDL Gesture Event Handling

=head1 SYNOPSIS

    use SDL2 qw[:gesture];

=head1 DESCRIPTION

SDL2::gesture provides functions that allow for simple and complex gesture
events. These functions may be imported by name or with the C<:gesture> tag.

=head1 Functions

These may be imported by name or with the C<:gesture> tag.

=head2 C<SDL_RecordGesture( ... )>

Begin recording a gesture on a specified touch device or all touch devices.

If the parameter C<touchId> is C<-1> (i.e., all devices), this function will
always return C<1>, regardless of whether there actually are any devices.

Expected parameters include:

=over

=item C<touchId> - the touch device id, or C<-1> for all touch devices

=back

Returns C<1> on success or C<0> if the specified device could not be found.

=head2 C<SDL_SaveAllDollarTemplates( ... )>

Save all currently loaded Dollar Gesture templates.

Expected parameters include:

=over

=item C<dst> - a L<SDL2::RWops> to save to

=back

Returns the number of saved templates on success or C<0> on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SaveDollarTemplate( ... )>

Save a currently loaded Dollar Gesture template.

Expected parameters include:

=over

=item C<gestureId> - a gesture id

=item C<dst> - a L<SDL2::RWops> to save to

=back

Returns C<1> on success or C<0> on failure; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_LoadDollarTemplates( ... )>

Load Dollar Gesture templates from a file.

Expected parameters include:

=over

=item C<touchId> - a touch id

=item C<src> - a L<SDL2::RWops> to load from

=back

Returns the number of loaded templates on success or a negative error code (or
C<0>) on failure; call C<SDL_GetError( )> for more information.

=head1 Defined Types

These are used internally.

=head2 C<SDL_GestureID>

A signed 64-bit integer.

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
