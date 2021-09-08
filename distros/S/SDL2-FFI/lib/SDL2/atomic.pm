package SDL2::atomic {
    use strictures 2;
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::atomic_t;
    ffi->type( 'int' => 'SDL_SpinLock' );

    #ffi->type( 'int' => 'SDL_bool' ) if __FILE__ eq $0;
    attach atomic => {
        SDL_AtomicTryLock                => [ ['SDL_SpinLock*'], 'SDL_bool' ],
        SDL_AtomicLock                   => [ ['SDL_SpinLock*'] ],
        SDL_AtomicUnlock                 => [ ['SDL_SpinLock*'] ],
        SDL_MemoryBarrierReleaseFunction => [ [] ],                              # Undocumented
        SDL_MemoryBarrierAcquireFunction => [ [] ],                              # Undocumented
        SDL_AtomicCAS                    => [ [ 'SDL_atomic_t', 'int', 'int' ],  'SDL_bool' ],
        SDL_AtomicSet                    => [ [ 'SDL_atomic_t', 'int' ],         'int' ],
        SDL_AtomicAdd                    => [ [ 'SDL_atomic_t', 'int' ],         'int' ],
        SDL_AtomicCASPtr                 => [ [ 'opaque*', 'opaque', 'opaque' ], 'SDL_bool' ],
        SDL_AtomicSetPtr                 => [ [ 'opaque*', 'opaque' ],           'opaque' ],
        SDL_AtomicGetPtr                 => [ ['opaque*'],                       'opaque' ],
    };
    define atomic => [
        [ SDL_AtomicIncRef => sub ($a) { SDL_AtomicAdd( $a, 1 ) } ],
        [ SDL_AtomicDecRef => sub ($a) { SDL_AtomicAdd( $a, -1 ) } ]
    ];

=encoding utf-8

=head1 NAME

SDL2::atomic - SDL Atomic Operations

=head1 SYNOPSIS

    use SDL2::FFI qw[:atomic];
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

If you are not an expert in concurrent lockless programming, you should only be
using the atomic lock and reference counting functions in this file.  In all
other cases you should be protecting your data structures with full mutexes.

You can find out a little more about lockless programming and the subtle issues
that can arise here:
L<http://msdn.microsoft.com/en-us/library/ee418650%28v=vs.85%29.aspx>

There's also lots of good information here:

=over

=item L<http://www.1024cores.net/home/lock-free-algorithms>

=item L<http://preshing.com/>

=back

These operations may or may not actually be implemented using processor
specific atomic operations. When possible they are implemented as true
processor specific atomic operations. When that is not possible the are
implemented using locks that *do* use the available atomic operations.

All of the atomic operations that modify memory are full memory barriers.

=head1 Functions

=head2 C<SDL_AtomicTryLock( ... )>

Try to lock a spin lock by setting it to a non-zero value.

    my $lock = 1;
    my $ok = SDL_AtomicTryLock( \$lock );

B<Please note that spinlocks are dangerous if you don't know what you're doing.
Please be careful using any sort of spinlock!>

Expected parameters include:

=over

=item C<lock> - a pointer to a lock variable

=back

Returns C<SDL_TRUE> if the lock succeeded, C<SDL_FALSE> if the lock is already
held.

=head2 C<SDL_AtomicLock( ... )>

Lock a spin lock by setting it to a non-zero value.

    SDL_AtomicLock( \$lock );

B<Please note that spinlocks are dangerous if you don't know what you're doing.
Please be careful using any sort of spinlock!>

Expected parameters include:

=over

=item C<lock> - a pointer to a lock variable

=back

=head2 C<SDL_AtomicUnlock( ... )>

Unlock a spin lock by setting it to 0.

    SDL_AtomicUnlock( \$lock );

Always returns immediately.

B<Please note that spinlocks are dangerous if you don't know what you're doing.
Please be careful using any sort of spinlock!>

Expected parameters include:

=over

=item C<lock> - a pointer to a lock variable

=back


=head2 C<SDL_MemoryBarrierReleaseFunction( )>

Memory barriers are designed to prevent reads and writes from being reordered
by the compiler and being seen out of order on multi-core CPUs.

=head2 C<SDL_MemoryBarrierAcquireFunction( )>

Memory barriers are designed to prevent reads and writes from being reordered
by the compiler and being seen out of order on multi-core CPUs.

=head2 C<SDL_AtomicCAS( ... )>

Set an atomic variable to a new value if it is currently an old value.

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> variable to be modified

=item C<oldval> - the old value

=item C<newval> - the new value

=back

Returns C<SDL_TRUE> if the atomic variable was set, C<SDL_FALSE> otherwise.

=head2 C<SDL_AtomicSet( ... )>

Set an atomic variable to a value.

    my $value = SDL_AtomicSet( $a, 1000 );

This function also acts as a full memory barrier.

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> variable to be modified

=item C<v> - the desired value

=back

Returns the previous value of the atomic variable.

=head2 C<SDL_AtomicGet( ... )>

Get the value of an atomic variable.

    my $value = SDL_AtomicGet( $a );

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> variable to be modified

=back

Returns the current value of the atomic variable.

=head2 C<SDL_AtomicAdd( ... )>

Add to an atomic variable.

    my $value = SDL_AtomicAdd( $a, 1000 );

This function also acts as a full memory barrier.

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> variable to be modified

=item C<v> - the desired value to add

=back

Returns the previous value of the atomic variable.

=head2 C<SDL_AtomicIncRef( ... )>

Increment an atomic variable used as a reference count.

    my $value = SDL_AtomicIncRef( $a );

This function also acts as a full memory barrier.

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> variable to be modified

=back

Returns the previous value of the atomic variable.

=head2 C<SDL_AtomicDecRef( ... )>

Decrement an atomic variable used as a reference count.

    my $okay = SDL_AtomicDecRef( $a );

This function also acts as a full memory barrier.

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> variable to be modified

=back

Returns C<SDL_TRUE> if the atomic variable reached zero after decrementing,
C<SDL_FALSE> otherwise.

=head2 C<SDL_AtomicCASPtr( ... )>

Set a pointer to a new value if it is currently an old value.

    my $alpha = 1000;
    SDL_AtomicCASPtr( \$alpha, 2000, 10 ); # Returns SDL_FALSE
    SDL_AtomicCASPtr( \$alpha, 1000, 10 ); # Returns SDL_TRUE

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to a pointer

=item C<oldval> - the old pointer value

=item C<newval> - the new pointer value

=back

Returns C<SDL_TRUE> if the pointer was set, C<SDL_FALSE> otherwise.

=head2 C<SDL_AtomicSetPtr( ... )>

Set a pointer to a value atomically.

    my $alpha = 200;
    my $old = SDL_AtomicSetPtr( \$alpha, 100 ); # Returns 200

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to a pointer

=item C<v> - the desired pointer value

=back

Returns the previous value of the pointer.

=head2 C<SDL_AtomicGetPtr( ... )>

Get the value of a pointer atomically.

    my $alpha = 200;
    SDL_AtomicGetPtr( \$alpha ); # Returns 200

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to a pointer

=back

Returns the current value of a pointer.

=head1 Types

=head2 C<SDL_SpinLock>

The atomic locks are efficient spinlocks using CPU instructions, but are
vulnerable to starvation and can spin forever if a thread holding a lock has
been terminated.  For this reason you should minimize the code executed inside
an atomic lock and never do expensive things like API or system calls while
holding them.

The atomic locks are not safe to lock recursively.

=head2 C<SDL2::atomic_t>

A type representing an atomic integer value.  It is a struct so people don't
accidentally use numeric operations on it.

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

=head1 Memory barriers

Memory barriers are designed to prevent reads and writes from being reordered
by the compiler and being seen out of order on multi-core CPUs.

A typical pattern would be for thread A to write some data and a flag, and for
thread B to read the flag and get the data. In this case you would insert a
release barrier between writing the data and the flag, guaranteeing that the
data write completes no later than the flag is written, and you would insert an
acquire barrier between reading the flag and reading the data, to ensure that
all the reads associated with the flag have completed.

In this pattern you should always see a release barrier paired with an acquire
barrier and you should gate the data reads/writes with a single flag variable.

For more information on these semantics, take a look at the blog post:
L<http://preshing.com/20120913/acquire-and-release-semantics>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

lockless spinlock spinlocks

=end stopwords

=cut

};
1;
