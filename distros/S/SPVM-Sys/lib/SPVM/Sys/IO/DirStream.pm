package SPVM::Sys::IO::DirStream;

1;

=head1 Name

SPVM::Sys::IO::DirStream - the class for the C<DIR> type in C<C language>.

=head1 Usage
  
  use Sys::IO::DirStream;
  use Sys::IO;
  
  my $dir = "foo";
  
  # Sys::IO::DirStream
  my $dir_stream = Sys::IO->opendir($dir);

=head1 Description

C<Sys::IO::DirStream> is the class for the C<DIR> type in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Instance Methods

  method DESTROY : void ();

The destructor.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
