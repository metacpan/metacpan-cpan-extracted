package SDL2::timer 0.01 {
    use strict;
    use SDL2::Utils qw[attach define ffi load_lib threads_wrapped];
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::error;
    #
    load_lib('api_wrapper');
    #
    #
    ffi->type( '(uint32,opaque)->uint32' => 'SDL_TimerCallback' );
    ffi->type( 'int'                     => 'SDL_TimerID' );
    my %_timers;
    END { %_timers = () }
    attach timer => {
        SDL_GetTicks                => [ [], 'uint32' ],
        SDL_GetPerformanceCounter   => [ [], 'uint64' ],
        SDL_GetPerformanceFrequency => [ [], 'uint64' ],
        SDL_Delay                   => [
            ['uint32'] => sub ( $inner, $ticks ) {
                SDL2::FFI::SDL_Yield();
                $inner->($ticks);
                SDL2::FFI::SDL_Yield();
            }
        ],
        Bundle_SDL_AddTimer => [
            [ 'uint32', 'opaque', 'opaque' ],
            'SDL_TimerID',
            sub ( $inner, $delay, $code, $params = () ) {
                $inner->( $delay, $code, \$params );
            }
        ],
        SDL_RemoveTimer => [ ['SDL_TimerID'] => 'SDL_bool' ]
    };
    define timer => [ [ SDL_TICKS_PASSED => sub ( $A, $B ) { ( $B - $A ) <= 0 } ] ];

=encoding utf-8

=head1 NAME

SDL2::timer - SDL Time Management Routines

=head1 SYNOPSIS

    use SDL2 qw[:timer];

=head1 DESCRIPTION

SDL2::timer contains functions for dealing with time.

=head1 Functions

These may be imported by name or with the C<:timer> tag.

=head2 C<SDL_GetTicks( )>

Get the number of milliseconds since SDL library initialization.

	my $time = SDL_GetTicks( );

This value wraps if the program runs for more than C<~49> days.

Returns an unsigned 32-bit value representing the number of milliseconds since
the SDL library initialized.

=head2 C<SDL_TICKS_PASSED( ... )>

Compare SDL ticks values, and return true if C<lhs> has passed C<rhs>.

For example, if you want to wait 100 ms, you could do this:

    my $timeout = SDL_GetTicks() + 100;
    while ( !SDL_TICKS_PASSED( SDL_GetTicks(), $timeout ) ) {

        # ... do work until timeout has elapsed
    }

Expected parameters include:

=over

=item C<lhs> - tick value to compare

=item C<rhs> - tick value to compare

=back

=head2 C<SDL_GetPerformanceCounter( )>

Get the current value of the high resolution counter.

	my $high_timer = SDL_GetPerformanceCounter( );

This function is typically used for profiling.

The counter values are only meaningful relative to each other. Differences
between values can be converted to times by using L<<
C<SDL_GetPerformanceFrequency( )>|/C<SDL_GetPerformanceFrequency( )> >>.

Returns the current counter value.

=head2 C<SDL_GetPerformanceFrequency( )>

Get the count per second of the high resolution counter.

	my $hz = SDL_GetPerformanceFrequency( );

Returns a platform-specific count per second.

=head2 C<SDL_Delay( ... )>

Wait a specified number of milliseconds before returning.

	SDL_Delay( 1000 );

This function waits a specified number of milliseconds before returning. It
waits at least the specified time, but possibly longer due to OS scheduling.

Expected parameters include:

=over

=item C<ms> - the number of milliseconds to delay

=back

=head2 C<SDL_AddTimer( ... )>

Call a callback function at a future time.

   my $id = SDL_AddTimer( 1000, sub ( $interval, $data ) { warn 'ping!'; $interval; } );

If you use this function, you must pass C<SDL_INIT_TIMER> to C<SDL_Init( ...
)>.

The callback function is passed the current timer interval and returns the next
timer interval. If the returned value is the same as the one passed in, the
periodic alarm continues, otherwise a new alarm is scheduled. If the callback
returns C<0>, the periodic alarm is cancelled.

The callback is run on a separate thread.

Timers take into account the amount of time it took to execute the callback.
For example, if the callback took 250 ms to execute and returned 1000 (ms), the
timer would only wait another 750 ms before its next iteration.

Timing may be inexact due to OS scheduling. Be sure to note the current time
with L<< C<SDL_GetTicks( )>|/C<SDL_GetTicks( )> >> or  L<<
C<SDL_GetPerformanceCounter( )>|/C<SDL_GetPerformanceCounter( )> >> in case
your callback needs to adjust for variances.

Expected parameters include:

=over

=item C<interval> - the timer delay, in milliseconds, passed to C<callback>

=item C<callback> - the C<CODE> reference to call when the specified C<interval> elapses

=item C<param> - a pointer that is passed to C<callback>

=back

Returns a timer ID or C<0> if an error occurs; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_RemoveTimer( ... )>

Remove a timer created with L<< C<SDL_AddTimer( ... )>|/C<SDL_AddTimer( ... )>
>>.

	SDL_RemoveTimer( $id );

Expected parameters include:

=over

=item C<id> - the ID of the timer to remove

=back

Returns C<SDL_TRUE> if the timer is removed or C<SDL_FALSE> if the timer wasn't
found.

=head1 Defined Types

Time keeps on slipping...

=head2 C<SDL_TimerCallback>

Function prototype for the timer callback function.

The callback function is passed the current timer interval and returns the next
timer interval.

Parameters to expect include:

=over

=item C<interval>

=item C<param>

=back

If the returned value is the same as the one passed in, the periodic alarm
continues, otherwise a new alarm is scheduled. If the callback returns C<0>,
the periodic alarm is cancelled.

=head2 C<SDL_TimerID>

Timer ID type.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

ms

=end stopwords

=cut

};
1;
