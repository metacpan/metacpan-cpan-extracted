package SDL2::loadso 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::error;
    #
    attach loadso => {
        SDL_LoadObject   => [ ['string'], 'opaque' ],
        SDL_LoadFunction => [
            [ 'opaque', 'string' ],
            'opaque',
            sub ( $inner, $handle, $name, $params = (), $retval = () ) {
                my $fn = $inner->( $handle, $name );
                $fn && $params ? SDL2::Utils::ffi->function( $fn, $params, $retval ) : $fn;
            }
        ],
        SDL_UnloadObject => [ ['opaque'] ]
    };

=encoding utf-8

=head1 NAME

SDL2::loadso - Dynamically Load a Shared Object

=head1 SYNOPSIS

    use SDL2 qw[:loadso];

=head1 DESCRIPTION

System dependent library loading routines.

Some things to keep in mind:

=over

=item

These functions only work on C function names.  Other languages may have name
mangling and intrinsic language support that varies from compiler to compiler.

=item

Make sure you declare your function pointers with the same calling convention
as the actual library function.  Your code will crash mysteriously if you do
not do this.

=item

Avoid namespace collisions.  If you load a symbol from the library, it is not
defined whether or not it goes into the global symbol namespace for the
application.  If it does and it conflicts with symbols in your code or other
shared libraries, you will not get the results you expect. :)

=back

=head1 Functions

These functions may be imported by name or with the C<:loadso> tag.

=head2 C<SDL_LoadObject( ... )>

Dynamically load a shared object.

Expected parameters include:

=over

=item C<sofile> - a system-dependent name of the object file

=back

Returns an opaque pointer to the object handle or C<undef> if there was an
error; call C<SDL_GetError( )> for more information.

=head2 C<SDL_LoadFunction( ... )>

Look up the address of the named function in a shared object.

This function pointer is no longer valid after calling L<< C<SDL_UnloadObject(
... )>|/C<SDL_UnloadObject( ... )> >>.

This function can only look up C function names. Other languages may have name
mangling and intrinsic language support that varies from compiler to compiler.

Make sure you declare your function pointers with the same calling convention
as the actual library function. Your code will crash mysteriously if you do not
do this.

If the requested function doesn't exist, C<undef> is returned.

Expected parameters include:

=over

=item C<handle> - a valid shared object handle returned by L<< C<SDL_LoadObject( ... )>|/C<SDL_LoadObject( ... )> >>

=item C<name> - the name of the function to look up

=item C<arguments> - optional L<FFI::Platypus>-friendly argument list

=item C<retval> - optional L<FFI::Platypus>-friendly return value

=back

Returns a pointer to the function or C<undef> if there was an error; call
C<SDL_GetError( )> for more information.

Note: We break from the upstream API by automatically wrapping the function
pointer if provided with an argument list.

=head2 C<SDL_UnloadObject( ... )>

Unload a shared object from memory.

Expected parameters include:

=over

=item C<handle> - a valid shared object handle returned by L<< C<SDL_LoadObject( ... )>|/C<SDL_LoadObject( ... )> >>

=back

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
