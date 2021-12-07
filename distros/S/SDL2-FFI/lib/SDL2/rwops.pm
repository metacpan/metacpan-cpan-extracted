package SDL2::rwops_h {
    use strict;
    use SDL2::Utils;
    use experimental 'signatures';
    use FFI::C::File;
    ffi->type( 'object(FFI::C::File)' => 'FILE' );
    #
    use SDL2::stdinc;
    use SDL2::error;
    #
    package SDL2::RWops {    # TODO: All of this
        use SDL2::Utils;
        has type => 'uint32';
    };
    #
    define rwops => [
        [ SDL_RWOPS_UNKNOWN   => 0 ],
        [ SDL_RWOPS_WINFILE   => 1 ],
        [ SDL_RWOPS_STDFILE   => 2 ],
        [ SDL_RWOPS_JNIFILE   => 3 ],
        [ SDL_RWOPS_MEMORY    => 4 ],
        [ SDL_RWOPS_MEMORY_RO => 5 ],
        [ SDL_RWOPS_VITAFILE  => 6 ],
        [ RW_SEEK_SET         => 0 ],
        [ RW_SEEK_CUR         => 1 ],
        [ RW_SEEK_END         => 2 ],
    ];
    attach rwops => {
        SDL_RWFromFile     => [ [ 'string', 'string' ], 'SDL_RWops' ],
        SDL_RWFromFP       => [ [ 'FILE', 'SDL_bool' ], 'SDL_RWops' ],
        SDL_RWFromMem      => [ [ 'string', 'int' ], 'SDL_RWops' ],
        SDL_RWFromConstMem => [ [ 'string', 'int' ], 'SDL_RWops' ],
        SDL_AllocRW        => [ [], 'SDL_RWops' ],
        SDL_FreeRW         => [ ['SDL_RWops'] ],
        SDL_RWsize         => [ ['SDL_RWops'],                                 'sint64' ],
        SDL_RWseek         => [ [ 'SDL_RWops', 'sint64', 'int' ],              'sint64' ],
        SDL_RWtell         => [ ['SDL_RWops'],                                 'sint64' ],
        SDL_RWread         => [ [ 'SDL_RWops', 'string', 'size_t', 'size_t' ], 'size_t' ],
        SDL_RWwrite        => [ [ 'SDL_RWops', 'string', 'size_t', 'size_t' ], 'size_t' ],
        SDL_RWclose        => [ ['SDL_RWops'],                                 'int' ],
        SDL_LoadFile_RW    => [ [ 'SDL_RWops', 'size_t', 'int' ],              'string' ],
        SDL_LoadFile       => [ [ 'string', 'size_t' ],                        'string' ],
        #
        SDL_ReadU8   => [ ['SDL_RWops'], 'uint8' ],
        SDL_ReadLE16 => [ ['SDL_RWops'], 'uint16' ],
        SDL_ReadBE16 => [ ['SDL_RWops'], 'uint16' ],
        SDL_ReadLE32 => [ ['SDL_RWops'], 'uint32' ],
        SDL_ReadBE32 => [ ['SDL_RWops'], 'uint32' ],
        SDL_ReadLE64 => [ ['SDL_RWops'], 'uint64' ],
        SDL_ReadBE64 => [ ['SDL_RWops'], 'uint64' ],
        #
        SDL_WriteU8   => [ [ 'SDL_RWops', 'uint8' ],  'size_t' ],
        SDL_WriteLE16 => [ [ 'SDL_RWops', 'uint16' ], 'size_t' ],
        SDL_WriteBE16 => [ [ 'SDL_RWops', 'uint16' ], 'size_t' ],
        SDL_WriteLE32 => [ [ 'SDL_RWops', 'uint32' ], 'size_t' ],
        SDL_WriteBE32 => [ [ 'SDL_RWops', 'uint32' ], 'size_t' ],
        SDL_WriteLE64 => [ [ 'SDL_RWops', 'uint64' ], 'size_t' ],
        SDL_WriteBE64 => [ [ 'SDL_RWops', 'uint64' ], 'size_t' ]
    };

=encoding utf-8

=head1 NAME

SDL2::rwops - General Interface to Read and Write Data Streams

=head1 SYNOPSIS

    use SDL2 qw[:rwops];

=head1 DESCRIPTION

This package provides a general interface for SDL to read and write data
streams.  It can easily be extended to files, memory, etc.

=head1 Functions

These functions may imported by name or with the C<:rwops> tag.

=head2 C<SDL_RWFromFile( ... )>

Creates a L<SDL2::RWops> structure from a file.

	my $file = SDL_RWFromFile('myimage.bmp', 'rb');

Expected parameters include:

=over

=item C<file> - a UTF-8 string representing the filename to open

=item C<mode> - an ASCII string representing the mode to be used for opening the file

=back

The C<mode> string is treated roughly the same as in a call to the C library's
C<fopen()>, even if SDL doesn't happen to use C<fopen()> behind the scenes.

Available mode strings:

=over

=item C<r>

Open a file for reading. The file must exist.

=item C<w>

Create an empty file for writing. If a file with the same name already exists
its content is erased and the file is treated as a new empty file.

=item C<a>

Append to a file. Writing operations append data at the end of the file. The
file is created if it does not exist.

=item C<r+>

Open a file for update both reading and writing. The file must exist.

=item C<w+>

Create an empty file for both reading and writing. If a file with the same name
already exists its content is erased and the file is treated as a new empty
file.

=item C<a+>

Open a file for reading and appending. All writing operations are performed at
the end of the file, protecting the previous content to be overwritten. You can
reposition (fseek, rewind) the internal pointer to anywhere in the file for
reading, but writing operations will move it back to the end of file. The file
is created if it does not exist.

=back

In order to open a file as a binary file, a "b" character has to be included in
the C<mode> string. This additional "b" character can either be appended at the
end of the string (thus making the following compound modes: "rb", "wb", "ab",
"r+b", "w+b", "a+b") or be inserted between the letter and the "+" sign for the
mixed modes ("rb+", "wb+", "ab+"). Additional characters may follow the
sequence, although they should have no effect. For example, "t" is sometimes
appended to make explicit the file is a text file.

This function supports Unicode filenames, but they must be encoded in UTF-8
format, regardless of the underlying operating system.

Returns a new L<SDL2::RWops> structure on success or undef on failure; call
C<SDL_GetErro( )> for more information.

=head2 C<SDL_RWFromFP( ... )>

Create a C<SDL2::RWops> structure from a standard I/O file pointer.

    use FFI::C::File;
    my $file = FFI::C::File->fopen( "foo.txt", "w" );
    my $ops  = SDL_RWFromFP( $file, SDL_FALSE );

Expected parameters include:

=over

=item C<fp> - L<FFI::C::File> object which wraps the C C<FILE> pointer

=item C<autoclose> - C<SDL_TRUE> to close the file handle when closing the L<SDL2::RWops>, C<SDL_FALSE> to leave the file handle open when the RWops is closed

=back

Returns a new L<SDL2::RWops> structure on success or undef on failure; call
C<SDL_GetErro( )> for more information.

=head2 C<SDL_RWFromMem( ... )>

Use this function to prepare a read-write memory buffer for use with
L<SDL2::RWops>.

    my $bitmap = ' ' x 100; # Must preallocate it in perl
    my $ops    = SDL_RWFromMem( $bitmap, length $bitmap );
    # ...write to $ops...
    print $bitmap; # contains everything you wrote

Expected parameters include:

=over

=item C<mem> - pointer to a buffer to feed an L<SDL2::RWops> stream

=item C<size> - the buffer size, in bytes

=back

Returns a new L<SDL2::RWops> structure on success or undef on failure; call
C<SDL_GetErro( )> for more information.

This memory buffer is not copied by the RWops; the pointer you provide must
remain valid until you close the stream. Closing the stream will not free the
original buffer.

=head2 C<SDL_RWFromConstMem( ... )>

Use this function to prepare a read-only memory buffer for use with RWops.

	my $bitmap = ...; # raw data
	my $rw  = SDL_RWFromConstMem( $bitmap, length $bitmap );
	my $img = SDL_LoadBMP_RW( $rw, 1 );
	# Do something with img

Expected parameters include:

=over

=item C<mem> - pointer to a read-only buffer to fee to an L<SDL2::RWops> stream

=item C<size> - the buffer size, in bytes

=back

Returns a new L<SDL2::RWops> structure on success or undef on failure; call
C<SDL_GetErro( )> for more information.

This function sets up an L<SDL2::RWops> struct based on a memory area of a
certain size. It assumes the memory area is not writable.

Attempting to write to this RWops stream will report an error without writing
to the memory buffer.

This memory buffer is not copied by the RWops; the pointer you provide must
remain valid until you close the stream. Closing the stream will not free the
original buffer.

=head2 C<SDL_AllocRW( ... )>

Creates an empty, unpopulated L<SDL2::RWops> structure.

	my $rw = SDL_AllocRW( );

Returns a new L<SDL2::RWops> structure on success or undef on failure; call
C<SDL_GetErro( )> for more information.

Applications do not need to use this function unless they are providing their
own C<SDL_RWops> implementation. If you just need a C<SDL_RWops> to read/write
a common data source, you should use the built-in implementations in SDL, like
C<SDL_RWFromFile( )> or C<SDL_RWFromMem( ... )>, etc.

You must free the returned pointer with C<SDL_FreeRW( ... )>. Depending on your
operating system and compiler, there may be a difference between the C<malloc(
)> and C<free( )> your program uses and the versions SDL calls internally.
Trying to mix the two can cause crashing such as segmentation faults. Since all
C<SDL_RWops> must free themselves when their close method is called, all
C<SDL_RWops> must be allocated through this function, so they can all be freed
correctly with C<SDL_FreeRW( )>.

=head2 C<SDL_FreeRW( ... )>

Use this function to free an L<SDL2::RWops> structure allocated by L<<
C<SDL_AllocRW( ... )>|/C<SDL_AllocRW( ... )> >>.

	SDL_FreeRW( $rw );

Expected parameters include:

=over

=item C<area> - the L<SDL2::RWops> structure to be freed

=back

Applications do not need to use this function unless they are providing their
own L<SDL2::RWops> implementation. If you just need a L<SDL2::RWops> to
read/write a common data source, you should use the built-in implementations in
SDL, like C<SDL_RWFromFile( ... )> or C<SDL_RWFromMem( ... )>, etc, and call
the close method on those L<SDL2::RWops> pointers when you are done with them.

Only use C<SDL_FreeRW( ... )> on pointers returned by C<SDL_AllocRW( )>. The
pointer is invalid as soon as this function returns. Any extra memory allocated
during creation of the L<SDL2::RWops> is not freed by C<SDL_FreeRW( ... )>; the
programmer must be responsible for managing that memory in their close method.

=head2 C<SDL_RWsize( ... )>

Get the size of the data stream in an L<SDL2::RWops>.

Expected parameters include:

=over

=item C<context> - the L<SDL2::RWops> structure to query

=back

Returns the size of the data stream on success, C<-1> if unknown or a negative
error code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_RWseek( ... )>

Seek within an L<SDL2::RWops> data stream.

This function seeks to byte C<offset>, relative to C<whence>.

Expected parameters include:

=over

=item C<context> - the L<SDL2::RWops> structure to seek through

=item C<offset> - an offset in bytes, relative to C<whence> location; can be negative

=item C<whence> - any of the L<< RWops week (C<whence>) values|/RWops Seek (C<whence>) Values >>

=back

Returns the final offset in the data stream after the seek or C<-1> on error.

=head2 C<SDL_RWtell( ... )>

Determine the current read/write offset in an L<SDL2::RWops> data stream.

Expected parameters include:

=over

=item C<context> - the L<SDL2::RWops> structure to query

=back

Returns the current offset in the stream, or C<-1> if the information can not
be determined.

=head2 C<SDL_RWread( ... )>

Read from a data source.

This function reads up to C<maxnum> objects each of size C<size> from the data
source to the area pointed at by C<ptr>. This function may read less objects
than requested. It will return zero when there has been an error or the data
stream is completely read.

Expected parameters include:

=over

=item C<context> - the L<SDL2::RWops> structure to read

=item C<ptr> - a pointer to a buffer to read data into

=item C<size> - the size of each object to read, in bytes

=item C<maxnum> - the maximum number of objects to be read

=back

Returns the number of objects read, or C<0> at error or end of file; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_RWwrite( ... )>

Write to an L<SDL2::RWops> data stream.

This function writes exactly C<num> objects each of size C<size> from the area
pointed at by C<ptr> to the stream. If this fails for any reason, it'll return
less than C<num> to demonstrate how far the write progressed. On success, it
returns C<num>.

Expected parameters include:

=over

=item C<context> - a pointer to an L<SDL2::RWops> structure

=item C<ptr> - a pointer to a buffer containing data to write

=item C<size> - the size of an object to write, in bytes

=item C<num> - the number of objects to write

=back

Returns the number of objects written, which will be less than C<num> on error;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_RWclose( ... )>

Close and free an allocated L<SDL2::RWops> structure.

This function releases any resources used by the stream and frees the structure
itself with C<SDL_FreeRW( ... )>.

Expected parameters include:

=over

=item C<context> - a pointer to an L<SDL2::RWops> structure to close

=back

Returns C<0> on success, or C<-1> if the stream failed to flush to its output
(e.g. to disk); call C<SDL_GetError( )> for more information.

=head2 C<SDL_LoadFile_RW( ... )>

Load all the data from an SDL data stream.

The data is allocated with a zero byte at the end (null terminated) for
convenience. This extra byte is not included in the value reported via
C<datasize>.

The data should be freed with C<SDL_free( ... )>.

Expected parameters include:

=over

=item C<src> - the L<SDL2::RWops> to read all available data from

=item C<datasize> - if not C<undef>, will store the number of bytes read

=item C<freesrc> - if non-zero, calls C<SDL_RWclose( ... )> on C<src> before returning

=back

Returns the data, or C<undef> if there was an error.

=head2 C<SDL_LoadFile( ... )>

Load all the data from a file path.

The data is allocated with a zero byte at the end (null terminated) for
convenience. This extra byte is not included in the value reported via
C<datasize>.

The data should be freed with C<SDL_free( ... )>.

Expected parameters include:

=over

=item C<file> - the path to read all available data from

=item C<datasize> - if not C<undef>, will store the number of bytes read

=back

Returns the data, or C<undef> if there was an error.

=head2 C<SDL_ReadU8( ... )>

Read an item of little endianness and return in native format.

Expected parameters include:

=over

=item C<src> - a L<SDL2::RWops> structure to read from

=back

Returns a 8-bit integer.

=head2 C<SDL_ReadLE16( ... )>

Read an item of little endianness and return in native format.

Expected parameters include:

=over

=item C<src> - a L<SDL2::RWops> structure to read from

=back

Returns a 16-bit integer.

=head2 C<SDL_ReadBE16( ... )>

Read an item of big endianness and return in native format.

Expected parameters include:

=over

=item C<src> - a L<SDL2::RWops> structure to read from

=back

Returns a 16-bit integer.

=head2 C<SDL_ReadLE32( ... )>

Read an item of little endianness and return in native format.

Expected parameters include:

=over

=item C<src> - a L<SDL2::RWops> structure to read from

=back

Returns a 32-bit integer.

=head2 C<SDL_ReadBE32( ... )>

Read an item of big endianness and return in native format.

Expected parameters include:

=over

=item C<src> - a L<SDL2::RWops> structure to read from

=back

Returns a 32-bit integer.

=head2 C<SDL_ReadLE64( ... )>

Read an item of little endianness and return in native format.

Expected parameters include:

=over

=item C<src> - a L<SDL2::RWops> structure to read from

=back

Returns a 64-bit integer.

=head2 C<SDL_ReadBE64( ... )>

Read an item of big endianness and return in native format.

Expected parameters include:

=over

=item C<src> - a L<SDL2::RWops> structure to read from

=back

Returns a 64-bit integer.

=head2 C<SDL_WriteU8( ... )>

Write an item of native format to little endianness.

Expected parameters include:

=over

=item C<dst> - a L<SDL2::RWops> structure to write to

=item C<value> - 8-bit unsigned integer

=back

Returns the amount of data written, in bytes.

=head2 C<SDL_WriteLE16( ... )>

Write an item of native format to little endianness.

Expected parameters include:

=over

=item C<dst> - a L<SDL2::RWops> structure to write to

=item C<value> - 16-bit unsigned integer

=back

Returns the amount of data written, in bytes.

=head2 C<SDL_WriteBE16( ... )>

Write an item of native format to big endianness.

Expected parameters include:

=over

=item C<dst> - a L<SDL2::RWops> structure to write to

=item C<value> - 16-bit unsigned integer

=back

Returns the amount of data written, in bytes.

=head2 C<SDL_WriteLE32( ... )>

Write an item of native format to little endianness.

Expected parameters include:

=over

=item C<dst> - a L<SDL2::RWops> structure to write to

=item C<value> - 32-bit unsigned integer

=back

Returns the amount of data written, in bytes.

=head2 C<SDL_WriteBE32( ... )>

Write an item of native format to big endianness.

Expected parameters include:

=over

=item C<dst> - a L<SDL2::RWops> structure to write to

=item C<value> - 32-bit unsigned integer

=back

Returns the amount of data written, in bytes.

=head2 C<SDL_WriteLE64( ... )>

Write an item of native format to little endianness.

Expected parameters include:

=over

=item C<dst> - a L<SDL2::RWops> structure to write to

=item C<value> - 64-bit unsigned integer

=back

Returns the amount of data written, in bytes.

=head2 C<SDL_WriteBE64( ... )>

Write an item of native format to big endianness.

Expected parameters include:

=over

=item C<dst> - a L<SDL2::RWops> structure to write to

=item C<value> - 64-bit unsigned integer

=back

Returns the amount of data written, in bytes.

=head1 Defined Values and Enumerations

These may be imported by name of with the C<:rwops> tag.

=head2 RWops Types

=over

=item C<SDL_RWOPS_UNKNOWN> - Unknown stream type

=item C<SDL_RWOPS_WINFILE> - Win32 file

=item C<SDL_RWOPS_STDFILE> - Stdio file

=item C<SDL_RWOPS_JNIFILE> - Android asset

=item C<SDL_RWOPS_MEMORY> - Memory stream

=item C<SDL_RWOPS_MEMORY_RO> - Read-Only memory stream

=item C<SDL_RWOPS_VITAFILE> - Vita file (if applicable)

=back

=head2 RWops Seek (C<whence>) Values

=over

=item C<RW_SEEK_SET> - Seek from the beginning of data

=item C<RW_SEEK_CUR> - Seek relative to current read point

=item C<RW_SEEK_END> - Seek relative to the end of data

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

rb wb rb+ wb+ RWops fseek struct unpopulated endianness

=end stopwords

=cut

};
1;
