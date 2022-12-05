package SPVM::IO::Handle::Interface;

1;

=head1 NAME

SPVM::IO::Handle::Interface - An interface for I/O Handling

=head1 Description

C<SPVM::IO::Handle::Interface> is the L<SPVM>'s C<IO::Handle::Interface> interface.

=head1 Usage
  
  interface IO::Handle::Interface;

=head1 Interface Methods

=head2 has_interfaces

  required method has_interfaces : int ();

=head2 blocking_flag

  method blocking_flag : int ();

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

=head2 printf

  method printf : int ($format : string, $args : object[]...);

=head2 say

  method say : int ($string : string);

=head2 clearerr

  method clearerr : void ();

=head2 error

  method error : int ();

=head2 flush

  method flush : int ();

=head2 truncate

  method truncate : int ($legnth : long);

=head2 ioctl

  method ioctl : int ($request : int, $request_arg = undef : object of Byte|Short|Int|Long|Float|Double|object);

=head2 ungetc

  method ungetc : int ($c : int);

=head2 sync

  method sync : int ();

=head2 stat

  method stat : int ($stat : Sys::IO::Stat);

=head2 blocking

  method blocking : void ($blocking : int);

=head2 fcntl

  method fcntl : int ($command : int, $command_arg = undef : object of Int|Sys::IO::Flock|object);

=head2 write

  method write : int ($buffer : string, $length : int, $offset = 0 : int);

=head2 read

  method read : int ($buffer : mutable string, $length : int, $offset = 0 : int);

=head2 syswrite

  method syswrite : int ($buffer : string, $length : int, $offset = 0 : int);

=head2 sysread

  method sysread : int ($buffer : mutable string, $length : int, $offset = 0 : int);

=head2 getline

  method getline : string ();

=head2 getlines

  method getlines : string ();

=head2 opened

  method opened : int ();

=head1 Well Known Implementation Classes

=head2 IO::Handle

L<IO::Handle|SPVM::IO::Handle>
