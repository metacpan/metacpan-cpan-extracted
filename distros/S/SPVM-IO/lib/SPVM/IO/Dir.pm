package SPVM::IO::Dir;



1;

=head1 Name

SPVM::IO::Dir - Directory Streams

=head1 Description

The IO::Dir class in L<SPVM> has methods for directory streams.

=head1 Usage

  use IO::Dir;
  
  my $dh = IO::Dir->new(".");
  
  while (my $dirent = $dh->read) {
    say $dirent->d_name;
  }
  
  my $offset = $dh->tell;
  
  $dh->seek($offset);

=head1 Details

=head2 Porting

This class is a Perl's L<IO::Dir> porting to L<SPVM>.

=head2 Implementation

An opened directory stream is automatically closed when the instance is destroyed.

=head1 Fields

=head2 dir_stream

C<has dir_stream : L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream>;>

A directory stream.

=head1 Class Methods

C<static method new : L<IO::Dir|SPVM::IO::Dir> ($dir_path : string = undef);>

Creates a new L<IO::Dir|SPVM::IO::Dir> object, calls L</"open"> method with the directory path $dir_path, and returns the created object.

If $dir_path is not defined, L</"open"> method is not called.

Exceptions:

Exceptions thrown by L</"open"> method could be thrown.

=head1 Instance Methods

=head2 open

C<method open : void ($dir_path : string);>

Opens a directory stream given the directory path $dir_path and sets L</"dir_stream"> field to it.

This method calls L<Sys#opendir|SPVM::Sys/"opendir"> method.

Exceptions:

Exceptions thrown by L<Sys#opendir|SPVM::Sys/"opendir"> method could be thrown.

=head2 read

C<method read : Sys::IO::Dirent ();>

Reads a directory entry from the directory stream stored in L</"dir_stream"> field and returns it.

This method calls L<Sys#readdir|SPVM::Sys/"readdir"> method.

Exceptions:

Exceptions thrown by L<Sys#readdir|SPVM::Sys/"readdir"> method could be thrown.

=head2 seek

C<method seek : void ($offset : long);>

Sets the location in the directory stream stored in L</"dir_stream"> field to the offset $offset.

$offset should be the return value of L</"tell"> method.

This method calls L<Sys#seekdir|SPVM::Sys/"seekdir"> method.

Exceptions:

Exceptions thrown by L<Sys#seekdir|SPVM::Sys/"seekdir"> method could be thrown.

=head2 tell

C<method tell : long ();>

Returns the location in the directory stream stored in L</"dir_stream"> field.

This method calls L<Sys#telldir|SPVM::Sys/"telldir"> method.

Exceptions:

Exceptions thrown by L<Sys#telldir|SPVM::Sys/"telldir"> method could be thrown.

=head2 rewind

C<method rewind : void ();>

Resets the position of the directory stream stored in L</"dir_stream"> field.

This method calls L<Sys#rewinddir|SPVM::Sys/"rewinddir"> method.

Exceptions:

Exceptions thrown by L<Sys#rewinddir|SPVM::Sys/"rewinddir"> method could be thrown.

=head2 close

C<method close : void ();>

Closes the directory stream stored in L</"dir_stream"> field.

This method calls L<Sys#closedir|SPVM::Sys/"closedir"> method.

Exceptions:

Exceptions thrown by L<Sys#closedir|SPVM::Sys/"closedir"> method could be thrown.

=head2 opened

C<method opened : int ();>

If the directory stream stored in L</"dir_stream"> is opened, returns 1, otherwise returns 0.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License
