package SPVM::Compress::Raw::Zlib::Deflate;



1;

=encoding utf8

=head1 Name

SPVM::Compress::Raw::Zlib::Deflate - Low-Level Interface to zlib inflate

=head1 Description

Compress::Raw::Zlib::Deflate class in L<SPVM> is a low-level interface to L<zlib|https://en.wikipedia.org/wiki/Zlib> C<inflate> function.

=head1 Usage

  use Compress::Raw::Zlib::Deflate;
  
  my $d = Compress::Raw::Zlib::Deflate->new($options);
  my $output_ref = [(string)undef];
  $d->deflate($input, $output_ref);
  $d->flush($output_ref);
  $d->deflateReset;
  $d->deflateParams($options);
  $d->deflateTune($good_length, $max_lazy, $nice_length, $max_chain);
  $d->adler;
  $d->total_in;
  $d->total_out;
  $d->get_Strategy;
  $d->get_Level;
  $d->get_BufSize;

=head1 Super Class

L<Compress::Raw::Zlib::Base|SPVM::Compress::Raw::Zlib::Base>

=head1 Class Methods

=head2 new

C<static method new : L<Compress::Raw::Zlib::Deflate|SPVM::Compress::Raw::Zlib::Deflate> ($options : object[] = undef);>

Creates a new L<Compress::Raw::Zlib::Deflate|SPVM::Compress::Raw::Zlib::Deflate> object, and returns it.

Options:

=over 2

=item * C<Level> : Int = Z_DEFAULT_COMPRESSION

The compression level.

=item * C<Method> : Int = Z_DEFLATED

The compression method.

=item * C<WindowBits> : Int = MAX_WBITS

To compress an RFC 1950 data stream, set WindowBits to a positive number between 8 and 15.

To compress an RFC 1951 data stream, set WindowBits to -C<MAX_WBITS>.

To compress an RFC 1952 data stream (i.e. gzip), set C<WindowBits> to C<WANT_GZIP>.

For a definition of the meaning and valid values for C<WindowBits> refer to the zlib documentation for deflateInit2.

=item * C<MemLevel> : Int = MAX_MEM_LEVEL

For a definition of the meaning and valid values for MemLevel refer to the zlib documentation for deflateInit2.

=item * C<Strategy> : Int = Z_DEFAULT_STRATEGY

The strategy used to tune the compression.

=item * C<Dictionary> : Int = undef

The dictionary.

=item * C<Bufsize> : Int = 4096

The initial size for the output buffer.

=item * C<AppendOutput> : Int = 0

If this option is set to false, the output buffers in L</"deflate"> and L</"flush"> methods will be truncated before uncompressed data is written to them.

If the option is set to true, uncompressed data will be appended to the output buffer in L</"deflate"> and L</"flush"> methods.

=back

See L<Compress::Raw::Zlib::Constant|SPVM::Compress::Raw::Zlib::Constant> about C<zlib> constants.

=head1 Instance Methods

=head2 deflate

C<method deflate : int ($input : string, $output_ref : string[]);>

Deflates the contents of $input and writes the compressed data to $output_ref->[0].

Returns the C<zlib> status of the last C<inflate> call.

=head2 flush

C<method flush : int ($output_ref : string[], $flush_type : int = -1);>

Typically used to finish the deflation.

If $flush_type is a negative value, it is set to C<Z_FINISH>.

Returns the C<zlib> status of the last C<inflate> call.

=head2 deflateParams

C<method deflateParams : void ($options : object[] = undef);>

Changes settings of the C<z_stream> object.

Options:

=over 2

=item * C<Level> : Int = Current C<Level>

The compression level.

=item * C<Strategy> : Int = Current C<Strategy>

The strategy used to tune the compression.

=back

=head2 deflateReset

C<method deflateReset : void ();>

Reset the C<z_stream> object.

=head2 deflateTune

C<method deflateTune : void ($good_length : int, $max_lazy : int, $nice_length : int, $max_chain : int);>

Tune the internal settings of the C<z_stream> object.

=head2 get_Strategy

C<method get_Strategy : int ();>

Returns the deflation strategy currently used.

=head2 get_Level

C<method get_Level : int ();>

Returns the compression level being used.

=head2 DESTROY

C<method DESTROY : void ();>

Finalizes and frees C<z_stream> object.

=head1 See Also

=over 2

=item * L<Compress::Raw::Zlib|SPVM::Compress::Raw::Zlib>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

