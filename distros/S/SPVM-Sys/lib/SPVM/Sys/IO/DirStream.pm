package SPVM::Sys::IO::DirStream;

1;

=head1 Name

SPVM::Sys::IO::DirStream - C<DIR> structure in the C language.

=head1 Description

The Sys::IO::DirStream class in L<SPVM> represents the L<DIR|https://linux.die.net/man/3/opendir> structure in the C language.

=head1 Usage
  
  use Sys::IO::DirStream;
  use Sys::IO;
  
  my $dir = "foo";
  
  # Sys::IO::DirStream
  my $dir_stream = Sys::IO->opendir($dir);

=head1 Details

This class is a pointer class. The pointer the instance has is set to a C<DIR> object.

=head1 Fields

=head2 closed

C<has closed : ro byte;>

The directory stream is closed.

=head1 Instance Methods

C<method DESTROY : void ();>

The destructor.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

