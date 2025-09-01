package SPVM::Compress::Raw::Zlib::Base;



1;

=encoding utf8

=head1 Name

SPVM::Compress::Raw::Zlib::Base - Raw::Zlib Base Class

=head1 Description

Compress::Raw::Zlib::Base class in L<SPVM> is the base class of L<Compress::Raw::Zlib::Deflate|SPVM::Compress::Raw::Zlib::Deflate> and L<Compress::Raw::Zlib::Inflate|SPVM::Compress::Raw::Zlib::Inflate>.

=head1 Usage

  use Compress::Raw::Zlib::Base;
  
  class Compress::Raw::Zlib::MyClass extends Compress::Raw::Zlib::Base {
    
  }

=head1 Instance Methods

=head2 total_out

C<method total_out : long ();>

Returns the value of C<total_out> member variable of C<z_stream> object.

=head2 total_in

C<method total_in : long ();>

Returns the value of C<total_in> member variable of C<z_stream> object.

=head2 get_Bufsize

C<method get_Bufsize : long ();>

Returns the buffer size used to carry out the compression or decompression.

=head2 adler

C<method adler : long ();>

Returns the value of C<adler> member variable of C<z_stream> object.

=head1 Well Known Child Classes

=over 2

=item * L<Compress::Raw::Zlib::Deflate|SPVM::Compress::Raw::Zlib::Deflate>

=item * L<Compress::Raw::Zlib::Inflate|SPVM::Compress::Raw::Zlib::Inflate>

=back

=head1 See Also

=over 2

=item * L<Compress::Raw::Zlib|SPVM::Compress::Raw::Zlib>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

