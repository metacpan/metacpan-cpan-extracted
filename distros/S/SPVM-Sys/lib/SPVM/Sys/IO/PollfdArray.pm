package SPVM::Sys::IO::PollfdArray;

1;

=head1 Name

SPVM::Sys::IO::PollfdArray - Array of C<struct pollfd> in C<C language>

=head1 Usage

  use Sys::IO::PollfdArray;
  
  my $pollfds = Sys::IO::PollfdArray->new(1024);

=head1 Description

C<Sys::IO::PollfdArray> is the class for the array of C<struct pollfd> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Class Methods

=head2 new

  static method new : Sys::IO::PollfdArray ($length : int);

Create a new C<Sys::IO::PollfdArray> object with the length.

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

The destructor.

=head2 length

  method length : int ();

Get the lenght of the array.

=head2 fd

  method fd : int ($index : int);

Get C<fd> of the position specifed by the index.

The index must be greater than or equal to 0. Otherwise an exception will be thrown.

The index must be less than the length of the file descripters. Otherwise an exception will be thrown.

=head2 set_fd

  method set_fd : void ($index : int, $fd : int);

Set C<fd> of the position specifed by the index.

The index must be greater than or equal to 0. Otherwise an exception will be thrown.

The index must be less than the length of the file descripters. Otherwise an exception will be thrown.

=head2 events

  method events : short ($index : int);

Get C<events> of the position specifed by the index.

The index must be greater than or equal to 0. Otherwise an exception will be thrown.

The index must be less than the length of the file descripters. Otherwise an exception will be thrown.

=head2 set_events

  method set_events : void ($index : int, $events : short);

Set C<events> of the position specifed by the index.

The index must be greater than or equal to 0. Otherwise an exception will be thrown.

The index must be less than the length of the file descripters. Otherwise an exception will be thrown.

=head2 events

  method revents : short ($index : short);

Get C<revents> of the position specifed by the index.

The index must be greater than or equal to 0. Otherwise an exception will be thrown.

The index must be less than the length of the file descripters. Otherwise an exception will be thrown.

=head2 set_revents

  method set_revents : void ($index : int, $revents : short);

Set C<revents> of the position specifed by the index.

The index must be greater than or equal to 0. Otherwise an exception will be thrown.

The index must be less than the length of the file descripters. Otherwise an exception will be thrown.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

