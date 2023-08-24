package SPVM::IO::Handle;

1;

=head1 NAME

SPVM::IO::Handle - I/O Handling

=head1 Description

C<SPVM::IO::Handle> is the L<SPVM>'s C<IO::Handle> class for I/O handling.

=head1 Usage
  
  use IO::Handle;
  my $handle = IO::Handle->new;
  $handle->set_autoflush(1);

=head1 Instance Methods

=head1 Fields

=head2 autoflush

  has autoflush : rw byte;

=head2 input_line_number

  has input_line_number : ro int;

=head2 opened

  has opened : ro protected int;

=head2 blocking_flag

  has blocking_flag : rw protected int;
  
=head1 Class methods

=head2 new

  static method new : IO::Handle ($options : object[]);

=head1 Instance Methods

=head2 init

  method init : void ($options : object[] = undef);

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

=head2 say

  method say : int ($string : string);

=head2 printf

  method printf : int ($format : string, $args : object[]...);

=head2 clearerr

  method clearerr : void ();

=head2 error

  method error : int ();

=head2 flush

  method flush : int ();

=head2 ungetc

  method ungetc : int ($c : int);

=head2 printflush

  method printflush : int ($string : string);

=head2 truncate

  method truncate : int ($legnth : long);

=head2 ioctl

  static method ioctl : int ($fd : int, $request : int, $request_arg_ref : object of byte[]|short[]|int[]|long[]|float[]|double[]|object = undef);

=head2 sync

  method sync : int ();

=head2 stat

  method stat : int ($stat : Sys::IO::Stat);

=head2 getline

  method getline : string ();

=head2 getlines

  method getlines : string ();

=head2 fcntl

  method fcntl : int ($command : int, $command_arg : object = undef of Int|Sys::IO::Flock|object);

=head2 blocking

  method blocking : void ($blocking : int);

=head2 write

  method write : int ($string : string, $length : int = -1, $offset : int = 0);

=head2 read

  method read : int ($string : mutable string, $length : int = -1, $offset : int = 0);

=head1 Well Known Child Classes

=head2 IO::File

L<IO::File|SPVM::IO::File>

=head2 IO::Socket

L<IO::Socket|SPVM::IO::Socket>

=head2 IO::Socket::INET

L<IO::Socket::INET|SPVM::IO::Socket::INET>

=head1 See Also

=head2 IO::Handle

C<SPVM::IO::Handle> is the Perl's L<IO::Handle> porting to L<SPVM>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

