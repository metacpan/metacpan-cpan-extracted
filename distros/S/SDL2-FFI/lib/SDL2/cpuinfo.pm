package SDL2::version 0.01 {
    use SDL2::Utils;
    attach cpuinfo => {
        SDL_GetCPUCount         => [ [],                  'int' ],
        SDL_GetCPUCacheLineSize => [ [],                  'int' ],
        SDL_HasRDTSC            => [ [],                  'SDL_bool' ],
        SDL_HasAltiVec          => [ [],                  'SDL_bool' ],
        SDL_HasMMX              => [ [],                  'SDL_bool' ],
        SDL_Has3DNow            => [ [],                  'SDL_bool' ],
        SDL_HasSSE              => [ [],                  'SDL_bool' ],
        SDL_HasSSE2             => [ [],                  'SDL_bool' ],
        SDL_HasSSE3             => [ [],                  'SDL_bool' ],
        SDL_HasSSE41            => [ [],                  'SDL_bool' ],
        SDL_HasSSE42            => [ [],                  'SDL_bool' ],
        SDL_HasAVX              => [ [],                  'SDL_bool' ],
        SDL_HasAVX2             => [ [],                  'SDL_bool' ],
        SDL_HasAVX512F          => [ [],                  'SDL_bool' ],
        SDL_HasARMSIMD          => [ [],                  'SDL_bool' ],
        SDL_HasNEON             => [ [],                  'SDL_bool' ],
        SDL_GetSystemRAM        => [ [],                  'int' ],
        SDL_SIMDGetAlignment    => [ [],                  'int' ],
        SDL_SIMDAlloc           => [ ['int'],             'opaque' ],
        SDL_SIMDRealloc         => [ [ 'opaque', 'int' ], 'opaque' ],
        SDL_SIMDFree            => [ ['opaque'] ],
    };

=encoding utf-8

=head1 NAME

SDL2::cpuinfo - CPU feature detection for SDL

=head1 SYNOPSIS

    use SDL2 qw[:cpuinfo];

=head1 DESCRIPTION

SDL2::version represents the library's version as three levels: major, minor,
and patch level.

=head1 Functions

These functions may be imported with the C<:cpuinfo> tag.

=head2 C<SDL_GetCPUCount( )>

Get the number of CPU cores available.

    my $cores = SDL_GetCPUCount( );

Returns the total number of logical CPU cores. On CPUs that include
technologies such as hyperthreading, the number of logical cores may be more
than the number of physical cores.

=head2 C<SDL_GetCPUCacheLineSize( )>

Determine the L1 cache line size of the CPU.

    my $cache = SDL_GetCPUCacheLineSize( );

This is useful for determining multi-threaded structure padding or SIMD
prefetch sizes.

Returns the L1 cache line size of the CPU, in bytes.

=head2 C<SDL_HasRDTSC( )>

Determine whether the CPU has the RDTSC instruction.

    my $rdtsc = SDL_HasRDTSC( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has the RDTSC instruction or C<SDL_FALSE> if
not.

=head2 C<SDL_HasAltiVec( )>

Determine whether the CPU has AltiVec features.

    my $altiVec = SDL_HasAltiVec( );

This always returns false on CPUs that aren't using PowerPC instruction sets.

Returns C<SDL_TRUE> if the CPU has AltiVec features or C<SDL_FALSE> if not.

=head2 C<SDL_HasMMX( )>

Determine whether the CPU has MMX features.

    my $mmx = SDL_HasMMX( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has MMX features or C<SDL_FALSE> if not.

=head2 C<SDL_Has3DNow( )>

Determine whether the CPU has 3DNow! features.

    my $_3dnow = SDL_Has3DNow( );

This always returns false on CPUs that aren't using AMD instruction sets.

Returns C<SDL_TRUE> if the CPU has 3DNow! features or C<SDL_FALSE> if not.

=head2 C<SDL_HasSSE( )>

Determine whether the CPU has SSE features.

    my $sse = SDL_HasSSE( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has SSE features or C<SDL_FALSE> if not.

=head2 C<SDL_HasSSE2( )>

Determine whether the CPU has SSE2 features.

    my $sse2 = SDL_HasSSE2( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has SSE2 features or C<SDL_FALSE> if not.

=head2 C<SDL_HasSSE3( )>

Determine whether the CPU has SSE3 features.

    my $sse3 = SDL_HasSSE3( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has SSE3 features or C<SDL_FALSE> if not.

=head2 C<SDL_HasSSE41( )>

Determine whether the CPU has SSE4.1 features.

    my $sse41 = SDL_HasSSE41( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has SSE4.1 features or C<SDL_FALSE> if not.

=head2 C<SDL_HasSSE42( )>

Determine whether the CPU has SSE4.2 features.

    my $sse42 = SDL_HasSSE42( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has SSE4.2 features or C<SDL_FALSE> if not.

=head2 C<SDL_HasAVX( )>

Determine whether the CPU has AVX features.

    my $avx = SDL_HasAVX( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has AVX features or C<SDL_FALSE> if not.

=head2 C<SDL_HasAVX2( )>

Determine whether the CPU has AVX2 features.

    my $avx2 = SDL_HasAVX2( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has AVX2 features or C<SDL_FALSE> if not.

=head2 C<SDL_HasAVX512F( )>

Determine whether the CPU has AVX-512F (foundation) features.

    my $avx512 = SDL_HasAVX512F( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has AVX-512F features or C<SDL_FALSE> if not.

=head2 C<SDL_HasARMSIMD( )>

Determine whether the CPU has ARM SIMD (ARMv6) features.

    my $arm6 = SDL_HasARMSIMD( );

This is different from ARM NEON, which is a different instruction set.

This always returns false on CPUs that aren't using ARM instruction sets.

Returns C<SDL_TRUE> if the CPU has ARM SIMD features or C<SDL_FALSE> if not.

=head2 C<SDL_HasNEON( )>

Determine whether the CPU has NEON (ARM SIMD) features.

    my $neon = SDL_HasNEON( );

This always returns false on CPUs that aren't using ARM instruction sets.

Returns C<SDL_TRUE> if the CPU has ARM NEON features or C<SDL_FALSE> if not.

=head2 C<SDL_GetSystemRAM( )>

Get the amount of RAM configured in the system.

    my $mb = SDL_GetSystemRAM( );

Returns the amount of RAM configured in the system in MB.

=head2 C<SDL_SIMDGetAlignment( )>

Report the alignment this system needs for SIMD allocations.

    my $size = SDL_SIMDGetAlignment( );

This will return the minimum number of bytes to which a pointer must be aligned
to be compatible with SIMD instructions on the current machine. For example, if
the machine supports SSE only, it will return 16, but if it supports AVX-512F,
it'll return 64 (etc). This only reports values for instruction sets SDL knows
about, so if your SDL build doesn't have L<< C<SDL_HasAVX512F(
)>|/C<SDL_HasAVX512F( )> >>, then it might return 16 for the SSE support it
sees and not 64 for the AVX-512 instructions that exist but SDL doesn't know
about. Plan accordingly.

Returns alignment in bytes needed for available, known SIMD instructions.

=head2 C<SDL_SIMDAlloc( ... )>

Allocate memory in a SIMD-friendly way.

    my $ptr = SDL_SIMDAlloc( 1024 * 64 );

This will allocate a block of memory that is suitable for use with SIMD
instructions. Specifically, it will be properly aligned and padded for the
system's supported vector instructions.

The memory returned will be padded such that it is safe to read or write an
incomplete vector at the end of the memory block. This can be useful so you
don't have to drop back to a scalar fallback at the end of your SIMD processing
loop to deal with the final elements without overflowing the allocated buffer.

You must free this memory with L<< C<SDL_SIMDFree( )>|/C<SDL_SIMDFree( )> >>,
not C<SDL_free( ... )>, C<undef>, variable scope tricks, etc.

Note that SDL will only deal with SIMD instruction sets it is aware of; for
example, SDL 2.0.8 knows that SSE wants 16-byte vectors (L<< C<SDL_HasSSE(
)>|/C<SDL_HasSSE( )> >>), and AVX2 wants 32 bytes (L<< C<SDL_HasAVX2(
)>|/C<SDL_HasAVX2( )> >>), but doesn't know that AVX-512 wants 64. To be clear:
if you can't decide to use an instruction set with an C<SDL_Has*( )> function,
don't use that instruction set with memory allocated through here.

C<SDL_AllocSIMD( 0 )> will return a non-NULL pointer, assuming the system isn't
out of memory, but you are not allowed to dereference it (because you only own
zero bytes of that buffer).

Expected parameters include:

=over

=item C<len> - The length, in bytes, of the block to allocate. The actual allocated block might be larger due to padding, etc.

=back

Returns a pointer to newly-allocated block, NULL if out of memory.

=head2 C<SDL_SIMDRealloc( ... )>

Reallocate memory obtained from L<< C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc(
... )> >>.

    $ptr = SDL_SIMDRealloc( $ptr, 1024 * 32 );

It is not valid to use this function on a pointer from anything but L<<
C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc( ... )> >>. It can't be used on
pointers from malloc, realloc, L<< C<SDL_malloc( ...
)>|SDL2::stdinc/C<SDL_malloc( ... )> >>, memalign, new, etc.

Expected parameters include:

=over

=item C<mem> - The pointer obtained from L<< C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc( ... )> >>. This function also accepts NULL, at which point this function is the same as calling L<< C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc( ... )> >> with a NULL pointer.

=item C<len> - The length, in bytes, of the block to allocated. The actual allocated block might be larger due to padding, etc. Passing C<0> will return a non-NULL pointer, assuming the system isn't out of memory.

=back

Returns a pointer to newly-reallocated block, NULL if out of memory.

=head2 C<SDL_SIMDFree( )>

Deallocate memory obtained from L<< C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc(
... )> >>.

    SDL_SIMDFree( $ptr );

It is not valid to use this function on a pointer from anything but L<<
C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc( ... )> >> or L<< C<SDL_SIMDRealloc(
... )>|/C<SDL_SIMDRealloc( ... )> >>. It can't be used on pointers from malloc,
realloc, SDL_malloc, memalign, new, etc.

However, C<SDL_SIMDFree( undef )> is a legal no-op.

The memory pointed to by C<ptr> is no longer valid for access upon return, and
may be returned to the system or reused by a future allocation. The pointer
passed to this function is no longer safe to dereference once this function
returns, and should be discarded.

Expected parameters include:

=over

=item C<ptr> - The pointer, returned from L<< C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc( ... )> >> or L<< C<SDL_SIMDRealloc( ... )>|/C<SDL_SIMDRealloc( ... )> >>, to deallocate. NULL is a legal no-op.

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

hyperthreading prefetch PowerPC 3DNow ARMv6 (ARMv6) realloc memalign deallocate

=end stopwords

=cut

};
1;
