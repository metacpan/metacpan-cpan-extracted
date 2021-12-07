package SDL2::thread 0.01 {
    use strict;
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::error;

    # Thread synchronization primitives
    use SDL2::atomic;
    use SDL2::mutex;
    #
    package SDL2::Thread {
        use SDL2::Utils;
        our $TYPE = has();
    };
    #
    ffi->type( 'ulong'          => 'SDL_threadID' );
    ffi->type( 'uint'           => 'SDL_TLSID' );
    ffi->type( '(opaque)->void' => '__destructor' );
    enum SDL_ThreadPriority => [
        qw[
            SDL_THREAD_PRIORITY_LOW
            SDL_THREAD_PRIORITY_NORMAL
            SDL_THREAD_PRIORITY_HIGH
            SDL_THREAD_PRIORITY_TIME_CRITICAL]
    ];
    ffi->type( '(opaque)->int' => 'SDL_ThreadFunction' );
    attach thread => {
        SDL_CreateThread => [
            [ 'SDL_ThreadFunction', 'string', 'opaque' ],
            'SDL_Thread' => sub ( $inner, $fn, $name, $data = () ) {
                my $cb = ffi->closure( sub ($ref) { $fn->($data) } );
                $cb->sticky;
                $inner->( $cb, $name, $data );
            }
        ],
        SDL_CreateThreadWithStackSize => [
            [ 'SDL_ThreadFunction', 'string', 'size_t', 'opaque' ],
            'SDL_Thread' => sub ( $inner, $fn, $name, $stacksize, $data = () ) {
                my $cb = ffi->closure( sub ($ref) { $fn->($data) } );
                $cb->sticky;
                $inner->( $cb, $name, $stacksize, $data );
            }
        ],
        SDL_GetThreadName     => [ ['SDL_Thread'],         'string' ],
        SDL_ThreadID          => [ [],                     'SDL_threadID' ],
        SDL_GetThreadID       => [ ['SDL_Thread'],         'SDL_threadID' ],
        SDL_SetThreadPriority => [ ['SDL_ThreadPriority'], 'int' ],
        SDL_WaitThread        => [ [ 'SDL_Thread', 'int*' ] ],
        SDL_DetachThread      => [ ['SDL_Thread'] ],
        SDL_TLSCreate         => [ [],            'SDL_TLSID' ],
        SDL_TLSGet            => [ ['SDL_TLSID'], 'opaque' ],
        SDL_TLSSet            => [
            [ 'SDL_TLSID', 'string', '__destructor' ],
            'int' => sub ( $inner, $id, $value, $cb ) {
                my $destructor = ffi->closure($cb);
                $destructor->sticky;
                $inner->( $id, $value, $destructor );
            }
        ],
        SDL_TLSCleanup => [ [] ]
    };

=encoding utf-8

=head1 NAME

SDL2::thread - SDL Thread Management Routines

=head1 SYNOPSIS

    use SDL2 qw[:thread];

    # Very simple thread - counts 0 to 9 delaying 50ms between increments
    sub TestThread ($ptr) {
        my $cnt;
        for ( $cnt = 0; $cnt < 10; ++$cnt ) {
            printf( "Thread counter: %d\n", $cnt );
            SDL_Delay(50);
        }
        return $cnt;
    }
    #
    printf("Simple SDL_CreateThread test:\n");

    # Simply create a thread
    my $thread = SDL_CreateThread( \&TestThread, 'TestThread', () );
    if ( !defined $thread ) {
        printf( "SDL_CreateThread failed: %s\n", SDL_GetError() );
    }
    else {
        SDL_WaitThread( $thread, \my $threadReturnValue );
        printf( "Thread returned value: %d\n", $threadReturnValue );
    }

=head1 DESCRIPTION

This package contains functions for system independent thread management
routines.

B<NOTE>: You should not expect to be able to create a window, render, or
receive events on any thread other than the main one.

=head1 Functions

These may be imported by name or with the C<:thread> tag.

=head2 C<SDL_CreateThread( ... )>

Create a new thread with a default stack size.

This is equivalent to calling:

	SDL_CreateThreadWithStackSize($fn, $name, 0, $data);

Expected parameters include:

=over

=item C<fn> - the C<SDL_ThreadFunction> function to call in the new thread

=item C<name> - the name of the thread

=item C<data> - a pointer that is passed to C<fn>

=back

Returns an opaque pointer to the new thread object on success, C<undef> if the
new thread could not be created; call C<SDL_GetError( )> for more information.

=head2 C<SDL_CreateThreadWithStackSize( ... )>

Create a new thread with a specific stack size.

SDL makes an attempt to report C<name> to the system, so that debuggers can
display it. Not all platforms support this.

Thread naming is a little complicated: Most systems have very small limits for
the string length (Haiku has 32 bytes, Linux currently has 16, Visual C++ 6.0
has _nine_!), and possibly other arbitrary rules. You'll have to see what
happens with your system's debugger. The name should be UTF-8 (but using the
naming limits of C identifiers is a better bet). There are no requirements for
thread naming conventions, so long as the string is null-terminated UTF-8, but
these guidelines are helpful in choosing a name:

L<https://stackoverflow.com/questions/149932/naming-conventions-for-threads>

If a system imposes requirements, SDL will try to munge the string for it
(truncate, etc), but the original string contents will be available from L<<
C<SDL_GetThreadName( ... )>|/C<SDL_GetThreadName( ... )> >>.

The size (in bytes) of the new stack can be specified. Zero means "use the
system default" which might be wildly different between platforms. x86 Linux
generally defaults to eight megabytes, an embedded device might be a few
kilobytes instead. You generally need to specify a stack that is a multiple of
the system's page size (in many cases, this is 4 kilobytes, but check your
system documentation).

In SDL 2.1, stack size will be folded into the original SDL_CreateThread
function, but for backwards compatibility, this is currently a separate
function.

Expected parameters include:

=over

=item C<fn> - the C<SDL_ThreadFunction> function to call in the new thread

=item C<name> - the name of the thread

=item C<stacksize> - the size, in bytes, to allocate for the new thread stack

=item C<data> - a pointer that is passed to C<fn>

=back

Returns an opaque pointer to the new thread object on success, C<undef> if the
new thread could not be created; call C<SDL_GetError( )> for more information.

=head2 C<SDL_GetThreadName( ... )>

Get the thread name as it was specified in L<< C<SDL_CreateThread( ...
)>|/C<SDL_CreateThread( ... )> >>.

This is internal memory, not to be freed by the caller, and remains valid until
the specified thread is cleaned up by L<< C<SDL_WaitThread( ...
)>|/C<SDL_WaitThread( ... )> >>.

Expected parameters include:

=over

=item C<thread> - the thread to query

=back

Returns a pointer to a UTF-8 string that names the specified thread, or
C<undef> if it doesn't have a name.

=head2 C<SDL_ThreadID( )>

Get the thread identifier for the current thread.

This thread identifier is as reported by the underlying operating system. If
SDL is running on a platform that does not support threads the return value
will always be zero.

This function also returns a valid thread ID when called from the main thread.

Returns the ID of the current thread.

=head2 C<SDL_GetThreadID( ... )>

Get the thread identifier for the specified thread.

This thread identifier is as reported by the underlying operating system. If
SDL is running on a platform that does not support threads the return value
will always be zero.

Expected parameters include:

=over

=item C<thread> - the thread to query

=back

Returns the ID of the specified thread, or the ID of the current thread if
C<thread> is C<undef>.

=head2 C<SDL_SetThreadPriority( ... )>

Set the priority for the current thread.

Note that some platforms will not let you alter the priority (or at least,
promote the thread to a higher priority) at all, and some require you to be an
administrator account. Be prepared for this to fail.

Expected parameters include:

=over

=item C<priority> the C<SDL_ThreadPriority> to set

=back

Returns 0 on success or a negative error code on failure; call C<SDL_GetError(
)> for more information.

=head2 C<SDL_WaitThread( ... )>

Wait for a thread to finish.

Threads that haven't been detached will remain (as a "zombie") until this
function cleans them up. Not doing so is a resource leak.

Once a thread has been cleaned up through this function, the SDL_Thread that
references it becomes invalid and should not be referenced again. As such, only
one thread may call C<SDL_WaitThread( ... )> on another.

The return code for the thread function is placed in the area pointed to by
C<status>, if C<status> is not C<undef>.

You may not wait on a thread that has been used in a call to L<<
C<SDL_WaitThread( ... )>|/C<SDL_WaitThread( ... )> >>

L<< C<SDL_DetachThread( ... )>|/C<SDL_DetachThread( ... )> >>. Use either that
function or this one, but not both, or behavior is undefined.

It is safe to pass a C<undef> thread to this function; it is a no-op.

Note that the thread pointer is freed by this function and is not valid
afterward.

Expected parameters include:

=over

=item C<thread> - the L<SDL2::Thread> pointer that was returned from the L<< C<SDL_CreateThread( ... )>|/C<SDL_CreateThread( ... )> >> call that started this thread

=item C<status> - pointer to an integer that will receive the value returned from the thread function by its 'return', or C<undef> to not receive such value back

=back

=head2 C<SDL_DetachThread( ... )>

Let a thread clean up on exit without intervention.

A thread may be "detached" to signify that it should not remain until another
thread has called SDL_WaitThread() on it. Detaching a thread is useful for
long-running threads that nothing needs to synchronize with or further manage.
When a detached thread is done, it simply goes away.

There is no way to recover the return code of a detached thread. If you need
this, don't detach the thread and instead use SDL_WaitThread().

Once a thread is detached, you should usually assume the SDL_Thread isn't safe
to reference again, as it will become invalid immediately upon the detached
thread's exit, instead of remaining until someone has called L<<
C<SDL_WaitThread( ... )>|/C<SDL_WaitThread( ... )> >> to finally clean it up.
As such, don't detach the same thread more than once.

If a thread has already exited when passed to C<SDL_DetachThread( ... )>, it
will stop waiting for a call to L<< C<SDL_WaitThread( ... )>|/C<SDL_WaitThread(
... )> >> and clean up immediately. It is not safe to detach a thread that
might be used with L<< C<SDL_WaitThread( ... )>|/C<SDL_WaitThread( ... )> >>.

You may not call L<< C<SDL_WaitThread( ... )>|/C<SDL_WaitThread( ... )> >> on a
thread that has been detached. Use either that function or this one, but not
both, or behavior is undefined.

It is safe to pass C<undef> to this function; it is a no-op.

Expected parameters include:

=over

=item C<thread> the L<SDL2::Thread> pointer that was returned from the L<< C<SDL_CreateThread( ... )>|/C<SDL_CreateThread( ... )> >> call that started this thread

=back

=head2 C<SDL_TLSCreate( )>

Create a piece of thread-local storage.

This creates an identifier that is globally visible to all threads but refers
to data that is thread-specific.

Returns the newly created thread local storage identifier or C<0> on error.

=head2 C<SDL_TLSGet( ... )>

Get the current thread's value associated with a thread local storage ID.

Expected parameters include:

=over

=item C<id> - the thread local storage ID

=back

Returns the value associated with the ID for the current thread or C<undef> if
no value has been set; call C<SDL_GetError( )> for more information.

=head2 C<SDL_TLSSet( ... )>

Set the current thread's value associated with a thread local storage ID.

The function prototype for C<destructor> is:

	sub ($value);

where its parameter C<value> is what was passed as C<value> to L<<
C<SDL_TLSSet( ... )>|/C<SDL_TLSSet( ... )> >>. The return value is ignored.

Expected parameters include:

=over

=item C<id> - the thread local storage ID

=item C<value> - the value to associate with the ID for the current thread

=item C<destructor> - a function called when the thread exits, to free the value

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_TLSCleanup( )>

Cleanup all TLS data for this thread.

=head1 Defined Values, Types, and Enumerations

Values and types may be imported by name or with the C<:thread> tag.
Enumerations may be imported with their given tags.

=head2 C<SDL_threadID>

The SDL thread ID.

=head2 C<SDL_TLSID>

Thread local storage ID, C<0> is the invalid ID.

=head2 C<SDL_ThreadPriority>

The SDL thread priority.

SDL will make system changes as necessary in order to apply the thread
priority. Code which attempts to control thread state related to priority
should be aware that calling L<< C<SDL_SetThreadPriority( ...
)>|/C<SDL_SetThreadPriority( ... )> >> may alter such state.
C<SDL_HINT_THREAD_PRIORITY_POLICY> can be used to control aspects of this
behavior.

On many systems you require special privileges to set high or time critical
priority.

=over

=item C<SDL_THREAD_PRIORITY_LOW>

=item C<SDL_THREAD_PRIORITY_NORMAL>

=item C<SDL_THREAD_PRIORITY_HIGH>

=item C<SDL_THREAD_PRIORITY_TIME_CRITICAL>

=back

=head2 C<SDL_ThreadFunction>

The function passed to L<< C<SDL_CreateThread( ... )>|/C<SDL_CreateThread( ...
)> >>.

Parameters to expect include:

=over

=item C<data> - what was passed as C<data> to C<SDL_CreateThread( ... )>

=back

Return a value that can be reported through C<SDL_WaitThread( ... )>.

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
