package SPVM::Sys::Poll::PollfdArray;

1;

=head1 Name

SPVM::Sys::Poll::PollfdArray - Array of C<struct pollfd> in the C language

=head1 Description

The Sys::Poll::PollfdArray class in L<SPVM> represents the array of C<struct pollfd> in the C language.

=head1 Usage

  use Sys::Poll::PollfdArray;
  
  my $pollfds = Sys::Poll::PollfdArray->new(1024);

=head1 Details

This class is a pointer class. The pointer the instance has is set to an C<struct pollfd> array.

=head1 Fields

=head2 length

C<has length : ro int;>

The length of the array.

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Poll::PollfdArray|SPVM::Sys::Poll::PollfdArray> ($length : int);>

Creates a new L<Sys::Poll::PollfdArray|SPVM::Sys::Poll::PollfdArray> object given the length $lenth.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor.

=head2 length

C<method length : int ();>

Gets the lenght of the array.

=head2 fd

C<method fd : int ($index : int);>

Returns C<fd> of the element at index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

=head2 set_fd

C<method set_fd : void ($index : int, $fd : int);>

Sets C<fd> of the element at index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

=head2 events

C<method events : int ($index : int);>

Returns C<events> of the element at index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

=head2 set_events

C<method set_events : void ($index : int, $events : int);>

Sets C<events> of the element at index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

See L<Sys::Poll::Constant|SPVM::Sys::Poll::Constant> about constant values given to $revents.

=head2 events

C<method revents : int ($index : int);>

Returns C<revents> of the element at index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

=head2 set_revents

C<method set_revents : void ($index : int, $revents : int);>

Sets C<revents> of the element at index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

See L<Sys::Poll::Constant|SPVM::Sys::Poll::Constant> about constant values given to $revents.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

