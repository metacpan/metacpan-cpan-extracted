package SPVM::Compress::Raw::Zlib::Inflate;



1;

=encoding utf8

=head1 Name

SPVM::Compress::Raw::Zlib::Inflate - Low-Level Interface to zlib inflate

=head1 Description

Compress::Raw::Zlib::Inflate class in L<SPVM> is a low-level interface to L<zlib|https://en.wikipedia.org/wiki/Zlib> C<inflate> function.

=head1 Usage

  use Compress::Raw::Zlib::Inflate;
  
  my $i = Compress::Raw::Zlib::Inflate->new($options);
  my $output_ref = [(string)undef];
  $i->inflate($input, $output_ref);
  $i->adler() ;
  $i->total_in() ;
  $i->total_out() ;
  $i->get_BufSize();

=head1 Super Class

L<Compress::Raw::Zlib::Base|SPVM::Compress::Raw::Zlib::Base>

=head1 Class Methods

=head2 new

C<static method new : L<Compress::Raw::Zlib::Inflate|SPVM::Compress::Raw::Zlib::Inflate> ($options : object[] = undef);>

Creates a new L<Compress::Raw::Zlib::Inflate|SPVM::Compress::Raw::Zlib::Inflate> object, and returns it.

Options:

=over 2

=item * C<WindowBits> : Int = MAX_WBITS

To compress an RFC 1950 data stream, set WindowBits to a positive number between 8 and 15.

To compress an RFC 1951 data stream, set WindowBits to -C<MAX_WBITS>.

To compress an RFC 1952 data stream (i.e. gzip), set C<WindowBits> to C<WANT_GZIP>.

For a definition of the meaning and valid values for C<WindowBits> refer to the zlib documentation for inflateInit2.

=item * C<Dictionary> : Int = undef

The dictionary.

=item * C<Bufsize> : Int = 4096

The initial size for the output buffer.

=item * C<LimitOutput> : Int = 0

See L</"inflate"> about this option.

=back

See L<Compress::Raw::Zlib::Constant|SPVM::Compress::Raw::Zlib::Constant> about C<zlib> constants.

=head1 Instance Methods

=head2 inflate

C<method inflate : int ($input : mutable string, $output_ref : string[]);>

Inflates the complete contents of $input and writes the uncompressed data to $output_ref->[0].

The $input parameter is modified by inflate.

If C<LimitOutput> option in L</"new"> method is a false value, all $input is consumed. Otherwise $input might not be fully consumed, and some of it might remain.

If all $input is consumed, the output data has been flushed.

=head2 inflateReset

C<method inflateReset : void ();>

Reset the C<z_stream> object.

=head2 DESTROY

C<method DESTROY : void ();>

Finalizes and frees the C<z_stream> object.

=head1 See Also

=over 2

=item * L<Compress::Raw::Zlib|SPVM::Compress::Raw::Zlib>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

