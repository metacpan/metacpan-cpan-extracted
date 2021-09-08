package SDL2::log 0.01 {
    use strictures 2;
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    #
    define log           => [ [ SDL_MAX_LOG_MESSAGE => 4096 ] ];
    enum SDL_LogCategory => [
        qw[
            SDL_LOG_CATEGORY_APPLICATION
            SDL_LOG_CATEGORY_ERROR
            SDL_LOG_CATEGORY_ASSERT
            SDL_LOG_CATEGORY_SYSTEM
            SDL_LOG_CATEGORY_AUDIO
            SDL_LOG_CATEGORY_VIDEO
            SDL_LOG_CATEGORY_RENDER
            SDL_LOG_CATEGORY_INPUT
            SDL_LOG_CATEGORY_TEST
            SDL_LOG_CATEGORY_RESERVED1
            SDL_LOG_CATEGORY_RESERVED2
            SDL_LOG_CATEGORY_RESERVED3
            SDL_LOG_CATEGORY_RESERVED4
            SDL_LOG_CATEGORY_RESERVED5
            SDL_LOG_CATEGORY_RESERVED6
            SDL_LOG_CATEGORY_RESERVED7
            SDL_LOG_CATEGORY_RESERVED8
            SDL_LOG_CATEGORY_RESERVED9
            SDL_LOG_CATEGORY_RESERVED10
            SDL_LOG_CATEGORY_CUSTOM]
        ],
        SDL_LogPriority => [
        [ SDL_LOG_PRIORITY_VERBOSE => 1 ], qw[SDL_LOG_PRIORITY_DEBUG
            SDL_LOG_PRIORITY_INFO
            SDL_LOG_PRIORITY_WARN
            SDL_LOG_PRIORITY_ERROR
            SDL_LOG_PRIORITY_CRITICAL
            SDL_NUM_LOG_PRIORITIES]
        ];
    attach log => {
        SDL_LogSetAllPriority  => [ ['SDL_LogPriority'] ],
        SDL_LogSetPriority     => [ [ 'int', 'SDL_LogPriority' ] ],
        SDL_LogGetPriority     => [ ['int'], 'SDL_LogPriority' ],
        SDL_LogResetPriorities => [ [] ],
    };
    ffi->type( '(opaque,int,int,string)->void' => 'SDL_LogOutputFunction' );
    define log => [
        [   SDL_Log => sub ( $format, @args ) {
                my @types = SDL2::Utils::_tokenize_out( $format, 0 );
                ffi->function( SDL_Log => ['string'] => [@types] )->call( $format, @args );
            }
        ],
        [   SDL_LogVerbose => sub ( $category, $format, @args ) {
                my @types = SDL2::Utils::_tokenize_out( $format, 0 );
                ffi->function( SDL_LogVerbose => [ 'int', 'string' ] => [@types] )
                    ->call( $category, $format, @args );
            }
        ],
        [   SDL_LogDebug => sub ( $category, $format, @args ) {
                my @types = SDL2::Utils::_tokenize_out( $format, 0 );
                ffi->function( SDL_LogDebug => [ 'int', 'string' ] => [@types] )
                    ->call( $category, $format, @args );
            }
        ],
        [   SDL_LogInfo => sub ( $category, $format, @args ) {
                my @types = SDL2::Utils::_tokenize_out( $format, 0 );
                ffi->function( SDL_LogInfo => [ 'int', 'string' ] => [@types] )
                    ->call( $category, $format, @args );
            }
        ],
        [   SDL_LogWarn => sub ( $category, $format, @args ) {
                my @types = SDL2::Utils::_tokenize_out( $format, 0 );
                ffi->function( SDL_LogWarn => [ 'int', 'string' ] => [@types] )
                    ->call( $category, $format, @args );
            }
        ],
        [   SDL_LogError => sub ( $category, $format, @args ) {
                my @types = SDL2::Utils::_tokenize_out( $format, 0 );
                ffi->function( SDL_LogError => [ 'int', 'string' ] => [@types] )
                    ->call( $category, $format, @args );
            }
        ],
        [   SDL_LogCritical => sub ( $category, $format, @args ) {
                my @types = SDL2::Utils::_tokenize_out( $format, 0 );
                ffi->function( SDL_LogCritical => [ 'int', 'string' ] => [@types] )
                    ->call( $category, $format, @args );
            }
        ],
        [   SDL_LogMessage => sub ( $category, $priority, $format, @args ) {
                my @types = SDL2::Utils::_tokenize_out( $format, 0 );
                ffi->function(
                    SDL_LogMessage => [ 'int', 'SDL_LogPriority', 'string' ] => [@types] )
                    ->call( $category, $priority, $format, @args );
            }
        ],
        [   SDL_LogMessageV =>
                sub ( $category, $priority, $format, @args ) { SDL2::FFI::SDL_LogMessage(@_) }
        ],
    ];
    attach log => {
        SDL_LogGetOutputFunction => [
            [ 'opaque*', 'opaque*' ] => sub ( $inner, $callback, $userdata ) {
                $inner->( $callback, $userdata );
                $$callback = ffi->function( $$callback => [ 'opaque', 'int', 'int', 'string' ] )
                    ;    # Unwrap it
            }
        ],
        SDL_LogSetOutputFunction => [
            [ 'SDL_LogOutputFunction', 'opaque' ] => sub ( $inner, $callback, $userdata = () ) {
                my $closure = ffi->closure(
                    sub ( $ud, $cat, $pri, $msg ) { $callback->( $userdata, $cat, $pri, $msg ) } );
                $closure->sticky;
                $inner->( $closure, $userdata );
            }
        ]
    };

=encoding utf-8

=head1 NAME

SDL2::log - Simple Log Messages with Categories and Priorities

=head1 SYNOPSIS

    use SDL2 qw[:log];

=head1 DESCRIPTION

By default, logs are quiet but if you're debugging SDL you might want:

    SDL_LogSetAllPriority( SDL_LOG_PRIORITY_WARN );

Here's where the messages go on different platforms:

=over

=item Windows: debug output stream

=item Android: log output

=item Others: standard error output (stderr)

=back

=head1 Functions

These functions may be imported by name or with the C<:log> tag.

=head2 C<SDL_LogSetAllPriority( ... )>

Set the priority of all log categories.

Expected parameters include:

=over

=item C<priority> - the C<SDL_LogPriority> to assign

=back

=head2 C<SDL_LogSetPriority( ... )>

Set the priority of a particular log category.

Expected parameters include:

=over

=item C<category> - the category to assign a priority to

=item C<priority> - the C<SDL_LogPriority> to assign

=back

=head2 C<SDL_LogGetPriority( ... )>

Get the priority of a particular log category.

Expected parameters include:

=over

=item C<category> - the category to query

=back

Returns the C<SDL_LogPriority> for the requested category.

=head2 C<SDL_LogResetPriorities( )>

Reset all priorities to default.

This is called by C<SDL_Quit( )>.

=head2 C<SDL_Log( ... )>

Log a message with C<SDL_LOG_CATEGORY_APPLICATION> and
C<SDL_LOG_PRIORITY_INFO>.

Expected parameters include:

=over

=item C<fmt> - a C<printf( ... )> style message format string

=item C<...> - additional parameters matching C<%> tokens in the C<fmt> string, if any

=back

=head2 C<SDL_LogVerbose( ... )>

Log a message with C<SDL_LOG_PRIORITY_VERBOSE>.

Expected parameters include:

=over

=item C<category> - the category of the message

=item C<fmt> - a C<printf( ... )> style message format string

=item C<...> - additional parameters matching C<%> tokens in the C<fmt> string, if any

=back

=head2 C<SDL_LogDebug( ... )>

Log a message with C<SDL_LOG_PRIORITY_DEBUG>.

Expected parameters include:

=over

=item C<category> - the category of the message

=item C<fmt> - a C<printf( ... )> style message format string

=item C<...> - additional parameters matching C<%> tokens in the C<fmt> string, if any

=back

=head2 C<SDL_LogInfo( ... )>

Log a message with C<SDL_LOG_PRIORITY_INFO>.

Expected parameters include:

=over

=item C<category> - the category of the message

=item C<fmt> - a C<printf( ... )> style message format string

=item C<...> - additional parameters matching C<%> tokens in the C<fmt> string, if any

=back

=head2 C<SDL_LogWarn( ... )>

Log a message with C<SDL_LOG_PRIORITY_WARN>.

Expected parameters include:

=over

=item C<category> - the category of the message

=item C<fmt> - a C<printf( ... )> style message format string

=item C<...> - additional parameters matching C<%> tokens in the C<fmt> string, if any

=back

=head2 C<SDL_LogError( ... )>

Log a message with C<SDL_LOG_PRIORITY_ERROR>.

Expected parameters include:

=over

=item C<category> - the category of the message

=item C<fmt> - a C<printf( ... )> style message format string

=item C<...> - additional parameters matching C<%> tokens in the C<fmt> string, if any

=back

=head2 C<SDL_LogCritical( ... )>

Log a message with C<SDL_LOG_PRIORITY_CRITICAL>.

Expected parameters include:

=over

=item C<category> - the category of the message

=item C<fmt> - a C<printf( ... )> style message format string

=item C<...> - additional parameters matching C<%> tokens in the C<fmt> string, if any

=back

=head2 C<SDL_LogMessage( ... )>

Log a message with the specified category and priority.

Expected parameters include:

=over

=item C<category> - the category of the message

=item C<priority> - the priority of the message

=item C<fmt> - a C<printf( ... )> style message format string

=item C<...> - additional parameters matching C<%> tokens in the C<fmt> string, if any

=back

=head2 C<SDL_LogMessageV( ... )>

Expected parameters include:

=over

=item C<category> - the category of the message

=item C<priority> - the priority of the message

=item C<fmt> - a C<printf( ... )> style message format string

=item C<...> - additional parameters matching C<%> tokens in the C<fmt> string, if any

=back

=head2 C<SDL_LogGetOutputFunction( ... )>

Get the current log output function.

Expected parameters include:

=over

=item C<callback> - pointer which will be filled in with the current log callback

=item C<userdata> - a pointer which will be filled in with the pointer that is passed to C<callback>

=back

=head2 C<SDL_LogSetOutputFunction( ... )>

Replace the default log output function with one of your own.

Expected parameters include:

=over

=item C<callback> - an C<SDL_LogOutputFunction> to call instead of the default

=item C<userdata> - a pointer that is passed to C<callback>

=back

=head2 Defined Values and Enumerations

These might be imported with the given tag, by name, or with the <:log> tag.

=head2 C<SDL_MAX_LOG_MESSAGE>

The maximum size of a log message.

Messages longer than the maximum size will be truncated.

=head2 C<SDL_LogCategory>

The predefined log categories

By default the application category is enabled at the INFO level, the assert
category is enabled at the WARN level, test is enabled at the VERBOSE level and
all other categories are enabled at the C<CRITICAL> level.

=over

=item C<SDL_LOG_CATEGORY_APPLICATION>

=item C<SDL_LOG_CATEGORY_ERROR>

=item C<SDL_LOG_CATEGORY_ASSERT>

=item C<SDL_LOG_CATEGORY_SYSTEM>

=item C<SDL_LOG_CATEGORY_AUDIO>

=item C<SDL_LOG_CATEGORY_VIDEO>

=item C<SDL_LOG_CATEGORY_RENDER>

=item C<SDL_LOG_CATEGORY_INPUT>

=item C<SDL_LOG_CATEGORY_TEST>

=item C<SDL_LOG_CATEGORY_RESERVED1> - These are reserved for future SDL library use

=item C<SDL_LOG_CATEGORY_RESERVED2>

=item C<SDL_LOG_CATEGORY_RESERVED3>

=item C<SDL_LOG_CATEGORY_RESERVED4>

=item C<SDL_LOG_CATEGORY_RESERVED5>

=item C<SDL_LOG_CATEGORY_RESERVED6>

=item C<SDL_LOG_CATEGORY_RESERVED7>

=item C<SDL_LOG_CATEGORY_RESERVED8>

=item C<SDL_LOG_CATEGORY_RESERVED9>

=item C<SDL_LOG_CATEGORY_RESERVED10>

=item C<SDL_LOG_CATEGORY_CUSTOM>

Beyond this point is reserved for application use, e.g.

       enum {
           MYAPP_CATEGORY_AWESOME1 = SDL_LOG_CATEGORY_CUSTOM,
           MYAPP_CATEGORY_AWESOME2,
           MYAPP_CATEGORY_AWESOME3,
           ...
       };

=back

=head2 C<SDL_LogPriority>

The predefined log priorities.

=over

=item C<SDL_LOG_PRIORITY_VERBOSE>

=item C<SDL_LOG_PRIORITY_DEBUG>

=item C<SDL_LOG_PRIORITY_INFO>

=item C<SDL_LOG_PRIORITY_WARN>

=item C<SDL_LOG_PRIORITY_ERROR>

=item C<SDL_LOG_PRIORITY_CRITICAL>

=item C<SDL_NUM_LOG_PRIORITIES>

=back

=head2 C<SDL_LogOutputFunction>

The prototype for the log output callback function.

This function is called by SDL when there is new text to be logged.

Parameters to expect include:

=over

=item C<userdata> - what was passed as C<userdata> to L<< C<SDL_LogSetOutputFunction( ... )>|/C<SDL_LogSetOutputFunction( ... )> >>

=item C<category> - the category of the message

=item C<priority> - the priority of the message

=item C<message> - the message being output

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
