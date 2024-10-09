package SPVM::IO::File;

1;

=head1 Name

SPVM::IO::File - File IO

=head1 Description

IO::File class in L<SPVM> has methods for File IO.

=head1 Usage
  
  use IO::File;
  
  # Write a line
  my $fh = IO::File->new("foo.txt", ">");
  $fh->say("Hello");>
  
  # Read lines
  my $fh = IO::File->new("foo.txt", "<");
  while (my $line = $fh->readline) {
    
  }

=head1 Details

This class is a Perl's L<IO::File|IO::File> porting to L<SPVM>.

=head1 Super Class

L<IO::Handle|SPVM::IO::Handle>

=head1 Fields

=head2 FileStream

C<has FileStream : Sys::IO::FileStream;>

A file stream associated with the file descriptoer L<FD|SPVM::IO::Handle/"FD">.

=head2 InputLineNumber

C<has InputLineNumber : long;>

The current line number. This value is incremented by L</"getline"> method.

=head1 Class Methods

=head2 new

C<static method new : L<IO::File|SPVM::IO::File> ($file_name : string = undef, $open_mode : string = undef);>

Creates a new L<IO::File|SPVM::IO::File> object.

And opens a file given the file name $file_name and the open mode $open_mode by calling L</"open"> method.

And returns the new object.

If $file_name is not defined, a file is not opened.

Exceptions:

Exceptions thrown by L</"open"> method could be thrown.

=head2 new_from_fd

C<static method new_from_fd : IO::Handle ($fd : int, $open_mode : string);>

Creates a new L<IO::File|SPVM::IO::File> object.

And opens a file given the file descriptor $fd and the open mode $open_mode by calling L</"fdopen"> method.

And returns the new object.

Exceptions:

Exceptions thrown by L</"fdopen"> method could be thrown.

=head2 open

C<method open : void ($file_name : string, $open_mode : string);>

Opens a file given the file name $file_name and the open mode $open_mode.

This method calls L<Sys#open|SPVM::Sys/"open"> method.

L</"FileStream"> field is set to the opened file stream.

L</"InputLineNumber"> field is set to 0.

Exceptions:

The file name $file_name must be defined. Otherwise an exception is thrown.

The open mode $open_mode must be defined. Otherwise an exception is thrown.

If a file is already opened, an exception is thrown.

=head2 fdopen

C<method fdopen : void ($fd : int, $open_mode : string);>

Opens a file given the file descriptor $fd and the open mode $open_mode.

This method calls L<Sys#fdopen|SPVM::Sys/"fdopen"> method.

L</"FileStream"> field is set to the opened file stream.

L</"InputLineNumber"> field is set to 0.

Exceptions:

The open mode $open_mode must be defined. Otherwise an exception is thrown.

If a file is already opened, an exception is thrown.

=head1 Instance Methods

=head2 input_line_number

C<method input_line_number : long ();>

Returns the value of L</"InputLineNumber"> field.

=head2 close

C<method close : void;>

Closes the file stream L</"FileStream">.

This method calls L<Sys::IO#fclose|SPVM::Sys::IO/"fclose"> method.

L</"InputLineNumber"> field is set to 0.

L<FD|SPVM::IO::Handle/"FD"> field is set to -1.

Exceptions:

Exceptions thrown by L<Sys::IO#fclose|SPVM::Sys::IO/"fclose"> method could be thrown.

=head2 read

C<method read : int ($string : mutable string, $length : int = -1, $offset : int = 0);>

Reads the length $length of data from the file stream L</"FileStream"> and store it to the offset $offset position of the string $string.

This method calls L<Sys#read|SPVM::Sys/"read"> method.

Exceptions:

Exceptions thrown by L<Sys#read|SPVM::Sys/"read"> method could be thrown.

=head2 getc

C<method getc : int ();>

Reads a character from the file stream L</"FileStream">, and returns the line.

This method calls L<Sys#getc|SPVM::Sys/"getc"> method with the file stream L</"FileStream">.

Exceptions:

Exceptions thrown by L<Sys#getc|SPVM::Sys/"getc"> method could be thrown.

=head2 getline

C<method getline : string ();>

Reads a line from the file stream L</"FileStream">, incrementes the input line number L</"InputLineNumber"> by 1, and returns the line.

A line is the part that ends with C<\n> or C<EOF>.

If C<EOF> has been reached, returns C<undef>.

This method calls L<Sys#readline|SPVM::Sys/"readline"> method with the file stream L</"FileStream">.

Exceptions:

Exceptions thrown by L<Sys#readline|SPVM::Sys/"readline"> method could be thrown.

=head2 getlines

C<method getlines : string ();>

Reads all lines from the file stream L</"FileStream">, joins them to a string, and returns it.

This method calls L</"getline"> method repeatedly.

If the first character is EOF, returns an empty string C<"">.

Exceptions:

Exceptions thrown by L</"getline"> method could be thrown.

=head2 write

C<method write : int ($string : string, $length : int = -1, $offset : int = 0);>

Writes the length $length from the offset $offset of the string $string to the file stream L</"FileStream">.

This method calls L<Sys::IO#fwrite|SPVM::Sys::IO/"fwrite"> method.

Exceptions:

Exceptions thrown by L<Sys::IO#fwrite|SPVM::Sys::IO/"fwrite"> method could be thrown.

=head2 flush

C<method flush : void ();>

Flushes the write buffer.

This method calls L<Sys::IO#fflush|SPVM::Sys::IO/"fflush"> method.

Exceptions:

Exceptions thrown by L<Sys::IO#fflush|SPVM::Sys::IO/"fflush"> method could be thrown.

=head2 error

C<method error : int ();>

If the file stream L</"FileStream"> reaches the end of file, returns 1, otherwise returns 0.

This method calls L<Sys::IO#ferror|SPVM::Sys::IO/"ferror"> method with the file stream L</"FileStream">.

Exceptions:

Exceptions thrown by L<Sys::IO#ferror|SPVM::Sys::IO/"ferror"> method could be thrown.

=head2 clearerr

C<method clearerr : void ();>

Clears the error satus of the file stream L</"FileStream">.

This method calls L<Sys::IO#clearerr|SPVM::Sys::IO/"clearerr"> method with the file stream L</"FileStream">.

Exceptions:

Exceptions thrown by L<Sys::IO#clearerr|SPVM::Sys::IO/"clearerr"> method could be thrown.

=head2 eof

C<method eof : int ();>

If the file stream L</"FileStream"> reaches the end of file, returns 1, otherwise returns 0.

This method calls L<Sys::IO#feof|SPVM::Sys::IO/"feof"> method with the file stream L</"FileStream">.

Exceptions:

Exceptions thrown by L<Sys::IO#feof|SPVM::Sys::IO/"feof"> method could be thrown.

=head2 ungetc

C<method ungetc : int ($c : int);>

Pushes the character $c back to the file stream L</"FileStream"> and returns the character that is actually pushed.

This method calls L<Sys::IO#ungetc|SPVM::Sys::IO/"ungetc"> method with the file stream L</"FileStream">.

Exceptions:

Exceptions thrown by L<Sys::IO#ungetc|SPVM::Sys::IO/"ungetc"> method could be thrown.

=head2 sync

C<method sync : void ();>

Transfers all modified in-core data of the file referred to by the file descriptor L<FD|SPVM::IO::Handle/"FD"> to the disk device.

This method calls L<Sys::IO#fsync|SPVM::Sys::IO/"fsync"> method with the file descriptor L<FD|SPVM::IO::Handle/"FD">.

Exceptions:

Exceptions thrown by L<Sys::IO#fsync|SPVM::Sys::IO/"fsync"> method could be thrown.

=head2 truncate

C<method truncate : void ($legnth : long);>

Causes the regular file named by referenced by the file descriptor L<FD|SPVM::IO::Handle/"FD"> to be truncated to a size of precisely $legnth bytes.

This method calls L<Sys::IO#ftruncate|SPVM::Sys::IO/"ftruncate"> method with the file descriptor L<FD|SPVM::IO::Handle/"FD">.

Exceptions:

Exceptions thrown by L<Sys::IO#ftruncate|SPVM::Sys::IO/"ftruncate"> method could be thrown.

=head1 See Also

=over 2

=item * L<IO::Handle|SPVM::IO::Handle>

=item * L<Sys|SPVM::Sys>

=item * L<Sys::IO|SPVM::Sys::IO>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

