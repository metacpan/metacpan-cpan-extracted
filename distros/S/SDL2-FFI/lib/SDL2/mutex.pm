package SDL2::mutex 0.01 {
    use SDL2::Utils;
    #
    use SDL2::stdinc;
    use SDL2::error;
    #
    define mutex => [ [ SDL_MUTEX_TIMEDOUT => 1 ], [ SDL_MUTEX_MAXWAIT => -1 ] ];

    package SDL2::Mutex {
        use SDL2::Utils;
        our $TYPE = has();
    };
    attach mutex => {
        SDL_CreateMutex  => [ [],            'SDL_Mutex' ],
        SDL_LockMutex    => [ ['SDL_Mutex'], 'int' ],
        SDL_TryLockMutex => [ ['SDL_Mutex'], 'int' ],
        SDL_UnlockMutex  => [ ['SDL_Mutex'], 'int' ],
        SDL_DestroyMutex => [ ['SDL_Mutex'] ]
    };

    package SDL2::Semaphore {
        use SDL2::Utils;
        our $TYPE = has();
    };
    attach mutex => {
        SDL_CreateSemaphore  => [ ['uint32'], 'SDL_Semaphore' ],
        SDL_DestroySemaphore => [ ['SDL_Semaphore'] ],
        SDL_SemWait          => [ ['SDL_Semaphore'],             'int' ],
        SDL_SemTryWait       => [ ['SDL_Semaphore'],             'int' ],
        SDL_SemWaitTimeout   => [ [ 'SDL_Semaphore', 'uint32' ], 'int' ],
        SDL_SemPost          => [ ['SDL_Semaphore'],             'int' ],
        SDL_SemValue         => [ ['SDL_Semaphore'],             'uint32' ]
    };

    package SDL2::Cond {
        use SDL2::Utils;
        our $TYPE = has();
    };
    attach mutex => {
        SDL_CreateCond      => [ [], 'SDL_Cond' ],
        SDL_DestroyCond     => [ ['SDL_Cond'] ],
        SDL_CondSignal      => [ ['SDL_Cond'],                          'int' ],
        SDL_CondBroadcast   => [ ['SDL_Cond'],                          'int' ],
        SDL_CondWait        => [ [ 'SDL_Cond', 'SDL_Mutex' ],           'int' ],
        SDL_CondWaitTimeout => [ [ 'SDL_Cond', 'SDL_Mutex', 'uint32' ], 'int' ],
    };

=encoding utf-8

=head1 NAME

SDL2::mutex - Functions to Provide Thread Synchronization Primitives

=head1 SYNOPSIS

    use SDL2 qw[:mutex];

=head1 DESCRIPTION

Functions in this group provide thread synchronization primitives for
multi-threaded programing.

There are three primitives available in SDL:

=over

=item Mutex

=item Semaphore

=item Condition Variable

=back

The SDL mutex is implemented as a recursive mutex so you can nest lock and
unlock calls to the same mutex.

=head1 Functions

These functions may be imported by name or with the C<:mutex> tag.

=head2 C<SDL_CreateMutex( )>

Create a new mutex.

All newly-created mutexes begin in the _unlocked_ state.

Calls to L<< C<SDL_LockMutex( ... )>|/C<SDL_LockMutex( ... )> >> will not
return while the mutex is locked by another thread. See L<< C<SDL_TryLockMutex(
... )>|/C<SDL_TryLockMutex( ... )> >> to attempt to lock without blocking.

SDL mutexes are reentrant.

Returns the initialized and unlocked mutex or C<undef> on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_LockMutex( ... )>

Lock the mutex.

This will block until the mutex is available, which is to say it is in the
unlocked state and the OS has chosen the caller as the next thread to lock it.
Of all threads waiting to lock the mutex, only one may do so at a time.

It is legal for the owning thread to lock an already-locked mutex. It must
unlock it the same number of times before it is actually made available for
other threads in the system (this is known as a "recursive mutex").

Expected parameters include:

=over

=item C<mutex> - the mutex to lock

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_TryLockMutex( ... )>

Try to lock a mutex without blocking.

This works just like L<< C<SDL_LockMutex( ... )>|/C<SDL_LockMutex( ... )> >>,
but if the mutex is not available, this function returns C<SDL_MUTEX_TIMEOUT>
immediately.

This technique is useful if you need exclusive access to a resource but don't
want to wait for it, and will return to it to try again later.

Expected parameters include:

=over

=item C<mutex> - the mutex to attempt to lock

=back

Returns C<0>, C<SDL_MUTEX_TIMEDOUT>, or C<-1> on error; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_UnlockMutex( ... )>

Unlock the mutex.

It is legal for the owning thread to lock an already-locked mutex. It must
unlock it the same number of times before it is actually made available for
other threads in the system (this is known as a "recursive mutex").

It is an error to unlock a mutex that has not been locked by the current
thread, and doing so results in undefined behavior.

It is also an error to unlock a mutex that isn't locked at all.

Expected parameters include:

=over

=item C<mutex> - the mutex to unlock

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_DestroyMutex( ... )>

Destroy a mutex created with SDL_CreateMutex().

This function must be called on any mutex that is no longer needed. Failure to
destroy a mutex will result in a system memory or resource leak. While it is
safe to destroy a mutex that is _unlocked_, it is not safe to attempt to
destroy a locked mutex, and may result in undefined behavior depending on the
platform.

Expected parameters include:

=over

=item C<mutex> - the mutex to destroy

=back

=head2 C<SDL_CreateSemaphore( ... )>

Create a semaphore.

This function creates a new semaphore and initializes it with the value
C<initial_value>. Each wait operation on the semaphore will atomically
decrement the semaphore value and potentially block if the semaphore value is
C<0>. Each post operation will atomically increment the semaphore value and
wake waiting threads and allow them to retry the wait operation.

Expected parameters include:

=over

=item C<initial_value> - the starting value of the semaphore

=back

Returns a new L<semaphore|SDL2::Semaphore> or C<undef> on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_DestroySemaphore( ... )>

Destroy a semaphore.

It is not safe to destroy a semaphore if there are threads currently waiting on
it.

Expected parameters include:

=over

=item C<sem> - the semaphore to destroy

=back

=head2 C<SDL_SemWait( ... )>

Wait until a semaphore has a positive value and then decrements it.

This function suspends the calling thread until either the semaphore pointed to
by `sem` has a positive value or the call is interrupted by a signal or error.
If the call is successful it will atomically decrement the semaphore value.

This function is the equivalent of calling L<< C<SDL_SemWaitTimeout( ...
)>|/C<SDL_SemWaitTimeout( ... )> >> with a time length of C<SDL_MUTEX_MAXWAIT>.

Expected parameters include:

=over

=item C<sem> - the semaphore to wait on

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SemTryWait( ... )>

See if a semaphore has a positive value and decrement it if it does.

This function checks to see if the semaphore pointed to by C<sem> has a
positive value and atomically decrements the semaphore value if it does. If the
semaphore doesn't have a positive value, the function immediately returns
C<SDL_MUTEX_TIMEDOUT>.

Expected parameters include:

=over

=item C<sem> - the semaphore to wait on

=back

Returns C<0> if the wait succeeds, C<SDL_MUTEX_TIMEDOUT> if the wait would
block, or a negative error code on failure; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_SemWaitTimeout( ... )>

Wait until a semaphore has a positive value and then decrements it.

This function suspends the calling thread until either the semaphore pointed to
by `sem` has a positive value, the call is interrupted by a signal or error, or
the specified time has elapsed. If the call is successful it will atomically
decrement the semaphore value.

Expected parameters include:

=over

=item C<sem> - the semaphore to wait on

=item C<ms> - the length of the timeout, in milliseconds

=back

Returns C<0> if the wait succeeds, C<SDL_MUTEX_TIMEDOUT> if the wait does not
succeed in the allotted time, or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SemPost( ... )>

Atomically increment a semaphore's value and wake waiting threads.

Expected parameters include:

=over

=item C<sem> - the semaphore to increment

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_SemValue( ... )>

Get the current value of a semaphore.

Expected parameters include:

=over

=item C<sem> - the semaphore to query

=back

Returns the current value of the semaphore.

=head2 C<SDL_CreateCond( )>

Create a condition variable.

Returns a new condition variable or C<undef> on failure; call C<SDL_GetError(
)> for more information.

=head2 C<SDL_DestroyCond( ... )>

Destroy a condition variable.

Expected parameters include:

=over

=item C<cond> - the condition variable to destroy

=back

=head2 C<SDL_CondSignal( ... )>

Restart one of the threads that are waiting on the condition variable.

Expected parameters include:

=over

=item C<cond> - the condition variable to signal

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_CondBroadcast( ... )>

Restart all threads that are waiting on the condition variable.

Expected parameters include:

=over

=item C<cond> - the condition variable to signal

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_CondWait( ... )>

Wait until a condition variable is signaled.

This function unlocks the specified C<mutex> and waits for another thread to
call L<< C<SDL_CondSignal( ... )>|/C<SDL_CondSignal( ... )> >> or L<<
C<SDL_CondBroadcast( ... )>|/C<SDL_CondBroadcast( ... )> >> on the condition
variable C<cond>. Once the condition variable is signaled, the mutex is
re-locked and the function returns.

The mutex must be locked before calling this function.

This function is the equivalent of calling L<< C<SDL_CondWaitTimeout( ...
)>|/C<SDL_CondWaitTimeout( ... )> >> with a time length of
C<SDL_MUTEX_MAXWAIT>.

Expected parameters include:

=over

=item C<cond> - the condition variable to wait on

=item C<mutex> - the mutex used to coordinate thread access

=back

Returns C<0> when it is signaled or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_CondWaitTimeout( ... )>

Wait until a condition variable is signaled or a certain time has passed.

This function unlocks the specified C<mutex> and waits for another thread to
call L<< C<SDL_CondSignal( ... )>|/C<SDL_CondSignal( ... )> >> or L<<
C<SDL_CondBroadcast( ... )>|/C<SDL_CondBroadcast( ... )> >> on the condition
variable C<cond>, or for the specified time to elapse. Once the condition
variable is signaled or the time elapsed, the mutex is re-locked and the
function returns.

The mutex must be locked before calling this function.


Expected parameters include:

=over

=item C<cond> - the condition variable to wait on

=item C<mutex> - the mutex used to coordinate thread access

=item C<ms> - the maximum time to wait, in milliseconds, or C<SDL_MUTEX_MAXWAIT> to wait indefinitely

=back

Returns C<0> if the condition variable is signaled, C<SDL_MUTEX_TIMEDOUT> if
the condition is not signaled in the allotted time, or a negative error code on
failure; call C<SDL_GetError( )> for more information.

=head1 Defined Variables and Enumerations

These variables may be imported by name or with the C<:mutex> tag. Enumerations
may be imported with the given tag.

=head2 C<SDL_MUTEX_TIMEDOUT>

Synchronization functions which can time out return this value if they time
out.

=head2 C<SDL_MUTEX_MAXWAIT>

This is the timeout value which corresponds to never time out.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

sem

=end stopwords

=cut

};
1;
