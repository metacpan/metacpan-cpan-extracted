package SPVM::Sys::IO::FileStream;

1;

=head1 Name

SPVM::Sys::IO::FileStream - C<FILE> structure in the C language.

=head1 Description

The Sys::IO::FileStream in L<SPVM> represetns the L<FILE|https://linux.die.net/man/3/fopen> structure in the C language.

=head1 Usage
  
  use Sys::IO::FileStream;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a C<FILE> object.

=head1 Fields

=head2 closed

C<has closed : ro byte;>

The file stream is closed.

=head2 is_pipe

C<has is_pipe : ro byte;>

The file stream is opend as a pipe stream.

=head2 no_destroy

C<has no_destroy : ro byte;>

Do not call the L</"DESTROY"> method.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor.

If the L<"no_destroy"> field is a true value, nothing is done.

If the L<"closed"> field is a false value, the file is closed.

If the the L</"is_pipe"> field is a true value, the file is closed by the C<pclose> function, otherwise closed by the C<fclose> function.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

