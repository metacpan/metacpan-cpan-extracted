package SDL2::assert {
    use strict;
    use warnings;
    use experimental 'signatures';
    use SDL2::Utils;
    use Try::Tiny;
    #
    enum SDL_AssertState => [
        qw[ SDL_ASSERTION_RETRY
            SDL_ASSERTION_BREAK
            SDL_ASSERTION_ABORT
            SDL_ASSERTION_IGNORE
            SDL_ASSERTION_ALWAYS_IGNORE
        ]
    ];

    package SDL2::AssertData {
        use SDL2::Utils;
        has
            always_ignore => 'int',
            trigger_count => 'uint',
            _condition    => 'opaque',    # string
            _filename     => 'opaque',    # string
            linenum       => 'int',
            _function     => 'opaque',    # string
            _next         => 'opaque';    # const struct SDL_AssertData *next
        ffi->attach_cast( '_cast' => 'opaque' => 'SDL_AssertData' );

        sub next {                        # TODO: Broken.
            my ($self) = @_;
            defined $self->_next ? _cast( $self->_next ) : undef;
        }

        sub condition {
            defined $_[1] ? $_[0]->_condition( ffi->cast( 'string', 'opaque', $_[1] ) ) :
                ffi->cast( 'opaque', 'string', $_[0]->_condition );
        }

        sub filename {
            ffi->cast( 'opaque', 'string', $_[0]->_filename );
        }

        sub function {
            ffi->cast( 'opaque', 'string', $_[0]->_function );
        }
    };
    ffi->type( '(int,opaque)->int' => 'SDL_AssertionHandler' );
    attach assert => {
        SDL_ReportAssertion =>
            [ [ 'SDL_AssertData', 'string', 'string', 'int' ], 'SDL_AssertState' ],
        SDL_SetAssertionHandler => [
            [ 'SDL_AssertionHandler', 'opaque' ] => sub {
                my ( $inner, $handler, $userdata ) = @_;
                my $ref = ffi->closure( sub { $handler->( shift, $userdata ) } );
                $inner->( $ref, $userdata );
            }
        ],
        SDL_GetDefaultAssertionHandler => [ [],          'SDL_AssertionHandler' ],
        SDL_GetAssertionHandler        => [ ['opaque*'], 'SDL_AssertionHandler' ],
        SDL_GetAssertionReport         => [ [],          'SDL_AssertData' ]       # SDL_AssertData[]
    };
    define assert => [
        [ SDL_disabled_assert => sub ( $code, $condition = () ) {1} ],

        # the do {} while(0) avoids dangling else problems:
        #    if (x) SDL_assert(y); else blah();
        #       ... without the do/while, the "else" could attach to this macro's "if".
        #   We try to handle just the minimum we need here in a macro...the loop,
        #   the static vars, and break points. The heavy lifting is handled in
        #   SDL_ReportAssertion(), in SDL_assert.c.
        #
        [   SDL_enabled_assert => sub ( $code, $condition = () ) {
                my $index = 0;
                ++$index while scalar caller($index) eq __PACKAGE__;
                my ( $package, $filename, $line, $subroutine ) = caller($index);
                $subroutine = '' if $subroutine =~ m[^SDL2::FFI::__ANON__];
                do {
                    if ( ref $code eq 'CODE' ) {
                        while ( !eval { &{$code}; } ) {
                            if ( !defined $condition ) {
                                try {
                                    require B::Deparse;
                                    $condition = B::Deparse->new(qw[-d -si8T])->coderef2text($code);
                                }
                                catch {
                                    $condition
                                        = 'code display non-functional on this version of Perl, sorry'
                                }
                            }
                            CORE::state $sdl_assert_data //= SDL2::AssertData->new(
                                {   condition =>

                                        #SDL2::Utils::ffi->cast( 'string', 'opaque', $condition ),
                                        $condition
                                }
                            );
                            my $sdl_assert_state
                                = SDL_ReportAssertion( $sdl_assert_data, $subroutine, $filename,
                                $line );
                            if ( $sdl_assert_state == SDL_ASSERTION_RETRY() ) {
                                next;    # go again.
                            }
                            elsif ( $sdl_assert_state == SDL_ASSERTION_BREAK() ) {

                              #SDL_TriggerBreakpoint();
                              # https://perldoc.perl.org/perldebug#Debugging-Compile-Time-Statements
                              # https://perlmaven.com/add-debugger-breakpoint-to-your-code
                                $DB::trace = 1;
                                return $DB::single = 1;
                            }
                            last;    # not retrying.
                        }
                    }
                    else {
                        while ( !$code ) {
                            CORE::state $sdl_assert_data //= SDL2::AssertData->new(
                                {   condition =>

                                        #SDL2::Utils::ffi->cast( 'string', 'opaque', $condition ),
                                        $condition
                                }
                            );
                            my $sdl_assert_state
                                = SDL_ReportAssertion( $sdl_assert_data, $subroutine, $filename,
                                $line );
                            if ( $sdl_assert_state == SDL_ASSERTION_RETRY() ) {
                                next;    # go again.
                            }
                            elsif ( $sdl_assert_state == SDL_ASSERTION_BREAK() ) {

                              #SDL_TriggerBreakpoint();
                              # https://perldoc.perl.org/perldebug#Debugging-Compile-Time-Statements
                              # https://perlmaven.com/add-debugger-breakpoint-to-your-code
                                $DB::trace = 1;
                                return $DB::single = 1;
                            }
                            last;    # not retrying.
                        }
                    }
                } while (0);
            }
        ],

        # TODO: enable these with a parameter passed to FFI import?
        # Enable various levels of assertions.
        [ SDL_assert_always => sub ($condition) { SDL_enabled_assert($condition) } ], (
            SDL2::FFI::SDL_ASSERT_LEVEL() == 0 ? (    # assertions disabled
                [ SDL_assert          => *SDL_disabled_assert ],
                [ SDL_assert_release  => *SDL_disabled_assert ],
                [ SDL_assert_paranoid => *SDL_disabled_assert ]
                ) :
                SDL2::FFI::SDL_ASSERT_LEVEL() == 1 ? (    # release
                [ SDL_assert          => *SDL_disabled_assert ],
                [ SDL_assert_release  => *SDL_enabled_assert ],
                [ SDL_assert_paranoid => *SDL_disabled_assert ]
                ) :
                SDL2::FFI::SDL_ASSERT_LEVEL() == 2 ? (    # normal
                [ SDL_assert          => *SDL_enabled_assert ],
                [ SDL_assert_release  => *SDL_enabled_assert ],
                [ SDL_assert_paranoid => *SDL_disabled_assert ]
                ) :
                SDL2::FFI::SDL_ASSERT_LEVEL() == 3 ? (    # paranoid
                [ SDL_assert          => *SDL_enabled_assert ],
                [ SDL_assert_release  => *SDL_enabled_assert ],
                [ SDL_assert_paranoid => *SDL_enabled_assert ]
                ) :
                ()
        )
    ];

=encoding utf-8

=head1 NAME

SDL2::assert - SDL Assertion Functions

=head1 SYNOPSIS

    use SDL2::FFI qw[:assert];
	SDL_assert( 1 == 1 );
	my $test = 'nope';
	SDL_assert(
        sub {
            warn 'testing';
            my $retval = $test eq "blah";
            $test = "blah";
            $retval;
        }
    );

=head1 DESCRIPTION

SDL2::assert implements an assertion system. Failures even cause the perl
debugger to halt if enabled.

=head1 Functions

These may be imported by name or with the C<:assert> tag.

=head2 C<SDL_ReportAssertion( ... )>

Never call this directly. Use L<< C<SDL_assert( ... )>|/C<SDL_assert( ... )>
>>, L<< C<SDL_assert_release( ... )>|/C<SDL_assert_release( ... )> >>, L<<
C<SDL_assert_paranoid( ... )>|/C<SDL_assert_paranoid( ... )> >>, and L<<
C<SDL_assert_always( ... )>|/C<SDL_assert_always( ... )> >>.

=head2 C<SDL_SetAssertionHandler( ... )>

Set an application-defined assertion handler.

	SDL_SetAssertionHandler( sub { ... } );

This function allows an application to show its own assertion UI and/or force
the response to an assertion failure. If the application doesn't provide this,
SDL will try to do the right thing, popping up a system-specific GUI dialog,
and probably minimizing any fullscreen windows.

This callback may fire from any thread, but it runs wrapped in a mutex, so it
will only fire from one thread at a time.

This callback is NOT reset to SDL's internal handler upon C<SDL_Quit( )>!

Expected parameters include:

=over

=item C<handler> - the L<< C<SDL_AssertionHandler>|/SDL_AssertionHandler >> function to call when an assertion fails or undef for the default handler

=back

=head2 C<SDL_GetDefaultAssertionHandler( )>

Get the default assertion handler.

This returns the function pointer that is called by default when an assertion
is triggered. This is an internal function provided by SDL, that is used for
assertions when L<< C<SDL_SetAssertionHandler( ...
)>|/C<SDL_SetAssertionHandler( ... )> >> hasn't been used to provide a
different function.

Returns the default C<SDL_AssertionHandler> that is called when an assert
triggers.

=head2 C<SDL_GetAssertionHandler( ... )>

Get the current assertion handler.

This returns the function pointer that is called when an assertion is
triggered. This is either the value last passed to L<<
C<SDL_SetAssertionHandler( ... )>|/C<SDL_SetAssertionHandler( ... )> >>, or if
no application-specified function is set, is equivalent to calling L<<
C<SDL_GetDefaultAssertionHandler( )>|/C<SDL_GetDefaultAssertionHandler( )> >>.

The parameter C<puserdata> is a pointer to a C<void*>, which will store the
"userdata" pointer that was passed to L<< C<SDL_SetAssertionHandler( ...
)>|/C<SDL_SetAssertionHandler( ... )> >>. This value will always be NULL for
the default handler. If you don't care about this data, it is safe to pass a
NULL pointer to this function to ignore it.

Expected parameters include:

=over

=item C<puserdata> pointer which is filled with the "userdata" pointer that was passed to L<< C<SDL_SetAssertionHandler( ... )>|/C<SDL_SetAssertionHandler( ... )> >>

=back

Returns the C<SDL_AssertionHandler> that is called when an assert triggers.

=head2 C<SDL_GetAssertionReport( )>

Get a list of all assertion failures.

This function gets all assertions triggered since the last call to L<<
C<SDL_ResetAssertionReport( )>|/C<SDL_ResetAssertionReport( )> >>, or the start
of the program.

The proper way to examine this data looks something like this:

    my $item = SDL_GetAssertionReport();
    while ($item) {
        printf( " ==> '%s', %s (%s:%d), triggered %u times, always ignore: %s.\n\n",
            $item->condition,     $item->function, $item->filename, $item->linenum,
            $item->trigger_count, $item->always_ignore ? 'yes' : 'no' );
        $item = $item->next;
    }

Returns a list of all failed assertions or NULL if the list is empty. This
memory should not be modified or freed by the application.

=head2 C<SDL_ResetAssertionReport( )>

Clear the list of all assertion failures.

	SDL_ResetAssertionReport( );

This function will clear the list of all assertions triggered up to that point.
Immediately following this call, L<< C<SDL_GetAssertionReport(
)>|/C<SDL_GetAssertionReport( )> >> will return no items. In addition, any
previously-triggered assertions will be reset to a C<trigger_count> of zero,
and their C<always_ignore> state will be false.


=head2 C<SDL_assert( ... )>

Use this macro to create an assertion for debugging.

	SDL_assert(1 == 0);  # triggers an assertion.
	SDL_assert(1 == 1);  # does NOT trigger an assertion

This function is enabled only when the C<SDL_ASSERT_LEVEL> is set to C<2> or
C<3>, otherwise it is disabled.

Expected parameters include:

=over

=item C<condition> - the expression to check

=back

=head2 C<SDL_assert_release( ... )>

Use this function to create an assertion for release builds.

	SDL_assert_release( time > -f __FILE__ );

Expected parameters include:

=over

=item C<condition> - the expression to check

=back

This function is enabled by default. It can be disabled by setting the
C<SDL_ASSERT_LEVEL> to C<0>.

=head2 C<SDL_assert_paranoid( ... )>

Use this function to create an assertion for detailed checking.

	SDL_assert_paranoid( 5 == 10 );

This function is disabled by default. It is available for use only when the
C<SDL_ASSERT_LEVEL> is set to C<3>.

Expected parameters include:

=over

=item C<condition> - the expression to check

=back

=head2 C<SDL_assert_always( ... )>

Use this function to create an assertion regardless of the current
C<SDL_ASSERT_LEVEL>.

	SDL_assert_always( 5 == 10 );

Expected parameters include:

=over

=item C<condition> - the expression to check

=back

=head1 Types

=head2 C<SDL_AssertionHandler>

A callback that fires when an SDL assertion fails.

This function should expect the following parameters:

=over

=item C<data> - a pointer to the L<SDL2::AssertData> structure corresponding to the current assertion

=item C<userdata> - what was passed as C<userdata> to C<SDL_SetAssertionHandler( )>

=back

You should return an L<< assert state|/C<:assertState> >> value indicating how
to handle the failure.

=head1 Defines and Enum

Defines and Enumerations listed here may be imported from SDL2::FFI with the
following tags:

=head2 C<:assertState>

=over

=item C<SDL_ASSERTION_RETRY> - Retry the assert immediately

=item C<SDL_ASSERTION_BREAK> - Make the debugger trigger a breakpoint

=item C<SDL_ASSERTION_ABORT> - Terminate the program

=item C<SDL_ASSERTION_IGNORE> - Ignore the assert

=item C<SDL_ASSERTION_ALWAYS_IGNORE> - Ignore the assert from now on

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

mutex userdata

=end stopwords

=cut

};
1;
