package SPVM::Sys::IO::DirStream;

1;

=head1 Name

SPVM::Sys::IO::DirStream - C<DIR> structure in the C language.

=head1 Description

Sys::IO::DirStream class in L<SPVM> represents the L<DIR|https://linux.die.net/man/3/opendir> structure in the C language.

=head1 Usage
  
  use Sys::IO::DirStream;
  use Sys::IO;
  
  my $dir = "foo";
  
  # Sys::IO::DirStream
  my $dir_stream = Sys::IO->opendir($dir);

=head1 Details

This class is a pointer class. The pointer is set to an object of C<DIR> type in the C language.

=head1 Fields

=head2 closed

C<has closed : ro byte;>

The flag whether the directory stream is closed.

If this field is a true value, the directory stream is closed, otherwise opened.

=head1 Instance Methods

C<method DESTROY : void ();>

The destructor.

If L</"closed"> field is not a true value, closes the directory handle stored in the pointer.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

