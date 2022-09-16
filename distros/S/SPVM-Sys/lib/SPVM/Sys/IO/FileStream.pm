package SPVM::Sys::IO::FileStream;

1;

=head1 Name

SPVM::Sys::IO::FileStream - the class for the C<FILE> type in C<C language>.

=head1 Usage
  
  use Sys::IO::FileStream;
  use Sys::IO;
  
  my $file = "foo.txt";
  
  # Sys::IO::FileStream
  my $file_stream = Sys::IO->fopen($file, "rb");

=head1 Description

C<Sys::IO::FileStream> is the class for the C<FILE> type in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Instance Methods

  method DESTROY : void ();

The destructor.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
