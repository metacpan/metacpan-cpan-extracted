package SPVM::IO::File;

1;

=head1 Name

SPVM::IO::File - File Input/Output

=head1 Usage
  
  use IO::File;
   
  my $io_file = IO::File->new("file", "r");
  $io_file->print("Hello");

=head1 Description

L<SPVM::IO::File> provides File Input/Output.

=head1 Parent Class

L<IO::Handle|SPVM::IO::Handle>.

=head1 Fields

=head2 autoflush;

  has autoflush : rw byte;

=head2 stream

  has stream : Sys::IO::FileStream;

=head2 new

  static method new : IO::File ($file_name = undef : string, $open_mode = undef : string);

=head2 new_from_fd

  static method new_from_fd : IO::Handle ($fd : int, $open_mode = undef : string);

=head2 open

  method open : void ($file_name : string, $open_mode : string);

=head2 fdopen

  method fdopen : void ($fd : int, $open_mode : string);

=head2 init

  protected method init : void ();

=head2 DESTROY

  method DESTROY : void ();

=head2 getline

  method getline : string ();

=head2 getlines

  method getlines : string ();

=head2 close

  method close : int ();

=head2 eof

  method eof : int ();

=head2 fileno

  method fileno : int ();

=head2 getc

  method getc : int ();

=head2 print

  method print : int ($string : string);

=head2 clearerr

  method clearerr : void ();

=head2 error

  method error : int ();

=head2 flush

  method flush : int ();

=head2 ungetc

  method ungetc : int ($c : int);

=head2 syswrite

  method syswrite : int ($buffer : string, $length : int, $offset = 0 : int);

=head2 sysread

  method sysread : int ($buffer : mutable string, $length : int, $offset = 0 : int);

=head1 See Also

=head2 Perl's IO::File

C<IO::File> is a Perl's L<IO::File|IO::File> porting to L<SPVM>.
