package SPVM::Sys::Poll::PollfdArray;

1;

=head1 Name

SPVM::Sys::Poll::PollfdArray - Array of C<struct pollfd> in the C language

=head1 Description

Sys::Poll::PollfdArray class in L<SPVM> represents the array of C<struct pollfd> in the C language.

=head1 Usage

  use Sys::Poll::PollfdArray;
  use Sys::Poll::Constant as POLL;
  
  my $pollfds = Sys::Poll::PollfdArray->new;
  
  # Add
  my $fd = 1;
  $pollfds->push($fd);
  
  # Get
  my $fd = $pollfds->fd($index);
  my $event = $pollfds->events($index);
  my $revent = $pollfds->revents($index);
  
  # Event Constant Values
  my $event = POLL->POLLIN;
  my $event = POLL->POLLOUT;
  
  # Set
  $pollfds->set_fd($index, $fd);
  $pollfds->set_events($index, $event);
  $pollfds->set_revents($index, $revent);
  
  # Remove
  $pollfds->remove($index);
  
  # Length
  my $length = $pollfds->length;

=head1 Details

This class is a pointer class. The pointer is set to an C<struct pollfd> array.

=head1 Fields

=head2 length

C<has length : ro int;>

The length of the array of C<struct pollfd> data.

=head2 capacity

C<has capacity : ro int;>

The capacity of the array of C<struct pollfd> data.

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Poll::PollfdArray|SPVM::Sys::Poll::PollfdArray> ($length : int = 0, $capacity : int = -1);>

Creates a new L<Sys::Poll::PollfdArray|SPVM::Sys::Poll::PollfdArray> object given the length $lenth and the capacity $capacity.

If $capacity is a negative value, $capacity is set to $length. And if $capacity is 0, $capacity is set to 1.

A C<struct pollfd> array is created and the pointer is set to it.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor. The C<struct pollfd> array is released.

=head2 fd

C<method fd : int ($index : int);>

Returns C<fd> of the array of C<struct pollfd> data at the index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

=head2 set_fd

C<method set_fd : void ($index : int, $fd : int);>

Sets C<fd> of the array of C<struct pollfd> data at the index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

=head2 events

C<method events : int ($index : int);>

Returns C<events> of the array of C<struct pollfd> data at the index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

=head2 set_events

C<method set_events : void ($index : int, $events : int);>

Sets C<events> of the array of C<struct pollfd> data at the index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

See L<Sys::Poll::Constant|SPVM::Sys::Poll::Constant> about constant values given to $revents.

=head2 events

C<method revents : int ($index : int);>

Returns C<revents> of the array of C<struct pollfd> data at the index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

=head2 set_revents

C<method set_revents : void ($index : int, $revents : int);>

Sets C<revents> of the array of C<struct pollfd> data at the index $index.

Excetpions:

$index must be greater than or equal to 0. Otherwise an exception is thrown.

$index must be less than the length of the file descripters. Otherwise an exception is thrown.

See L<Sys::Poll::Constant|SPVM::Sys::Poll::Constant> about constant values given to $revents.

=head2 push

C<method push : void ($fd : int);>

Adds an C<struct pollfd> data with the file descriptoer $fd to the end of the C<struct pollfd> array.

If the capacity stored in L</"capacity"> fields is not enough, it is extended to about twice its capacity.

=head2 remove

C<method remove : void ($index : int);>

Removes an C<struct pollfd> data at the index $index.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

