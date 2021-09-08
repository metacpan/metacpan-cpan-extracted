package SDL2::error 0.01 {
    use strictures 2;
    use experimental 'signatures';
    use SDL2::Utils;
    #
    enum SDL_errorcode => [
        qw[
            SDL_ENOMEM
            SDL_EFREAD
            SDL_EFWRITE
            SDL_EFSEEK
            SDL_UNSUPPORTED
            SDL_LASTERROR
        ]
    ];
    attach error => {
        SDL_SetError => [
            ['string'] => 'int' =>
                sub ( $inner, $fmt, @params ) { $inner->( sprintf( $fmt, @params ) ); }
        ],
        SDL_GetError    => [ [] => 'string' ],
        SDL_GetErrorMsg => [
            [ 'string', 'int' ] => 'string' => sub ( $inner, $errstr, $maxlen = length $errstr ) {
                $_[1] = ' ' x $maxlen if !defined $_[1] || length $errstr != $maxlen;
                $inner->( $_[1], $maxlen );
            }
        ],
        SDL_ClearError => [ [] => 'void' ],
        SDL_Error      => [ ['SDL_errorcode'], 'int' ]
    };

=encoding utf-8

=head1 NAME

SDL2::error - Simple Error Message Routines for SDL

=head1 SYNOPSIS

    use SDL2 qw[:error];

=head1 DESCRIPTION

Functions in this import tag provide simple error message routines for SDL.
C<SDL_GetError( )>|/C<SDL_GetError( )> >> can be called for almost all SDL
functions to determine what problems are occurring. Check the wiki page of each
specific SDL function to see whether L<< C<SDL_GetError( )>|/C<SDL_GetError( )>
>> is meaningful for them or not. These functions may be imported with the
C<:error> tag.

=head1 Functions

The SDL error messages are in English.

=head2 C<SDL_SetError( ... )>

Set the SDL error message for the current thread.

Calling this function will replace any previous error message that was set.

This function always returns C<-1>, since SDL frequently uses C<-1> to signify
an failing result, leading to this idiom:

	if ($error_code) {
		return SDL_SetError( 'This operation has failed: %d', $error_code );
	}

Expected parameters:

=over

=item C<fmt>

a C<printf( )>-style message format string

=item C<@params>

additional parameters matching % tokens in the C<fmt> string, if any

=back

=head2 C<SDL_GetError( )>

Retrieve a message about the last error that occurred on the current thread.

	warn SDL_GetError( );

It is possible for multiple errors to occur before calling C<SDL_GetError( )>.
Only the last error is returned.

The message is only applicable when an SDL function has signaled an error. You
must check the return values of SDL function calls to determine when to
appropriately call C<SDL_GetError( )>. You should B<not> use the results of
C<SDL_GetError( )> to decide if an error has occurred! Sometimes SDL will set
an error string even when reporting success.

SDL will B<not> clear the error string for successful API calls. You B<must>
check return values for failure cases before you can assume the error string
applies.

Error strings are set per-thread, so an error set in a different thread will
not interfere with the current thread's operation.

The returned string is internally allocated and must not be freed by the
application.

Returns a message with information about the specific error that occurred, or
an empty string if there hasn't been an error message set since the last call
to L<< C<SDL_ClearError( )>|/C<SDL_ClearError( )> >>. The message is only
applicable when an SDL function has signaled an error. You must check the
return values of SDL function calls to determine when to appropriately call
C<SDL_GetError( )>.

=head2 C<SDL_GetErrorMsg( ... )>

Get the last error message that was set for the current thread.

	my $x;
	warn SDL_GetErrorMsg($x, 300);

This allows the caller to copy the error string into a provided buffer, but
otherwise operates exactly the same as L<< C<SDL_GetError( )>|/C<SDL_GetError(
)> >>.

=over

=item C<errstr>

A buffer to fill with the last error message that was set for the current
thread

=item C<maxlen>

The size of the buffer pointed to by the errstr parameter

=back

Returns the pointer passed in as the C<errstr> parameter.

=head2 C<SDL_ClearError( )>

Clear any previous error message for this thread.

    SDL_ClearError( );

=head2 C<SDL_Error( ... )>

Set the current error to a member of the L<<
C<<SDL_errorcode>|SDL2::Enum/C<:errorcode> >> enum.

    SDL_Error( SDL_EFWRITE );

Unconditionally returns C<-1>.

=head1 Enumerations

These are defined for your use!

=head2 C<SDL_errorcode>

These values may be imported with the C<:errorcode> tag.

=over

=item C<SDL_ENOMEM> - Out of memory

=item C<SDL_EFREAD> - Error reading file

=item C<SDL_EFWRITE> - Error writing file

=item C<SDL_EFSEEK> - Error seeking in file

=item C<SDL_UNSUPPORTED>

=item C<SDL_LASTERROR>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

errstr

=end stopwords

=cut

};
1;
