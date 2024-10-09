package SPVM::IO::Poll;



1;

=head1 Name

SPVM::IO::Poll - poll system call

=head1 Description

IO::Poll class in L<SPVM> has methods for poll system call.

=head1 Usage

  use IO::Poll;
  use Sys::Poll::Constant as POLL;
  
  my $poll = IO::Poll->new;
   
  $poll->set_mask($input_fd => POLL->POLLIN);
  $poll->set_mask($output_fd => POLL->POLLOUT);
  
  $poll->poll($timeout);
  
  my $events = $poll->events($input_fd);

=head1 Details

=head2 Porting

This class is a Perl's L<IO::Poll> porting to L<SPVM>.

=head1 Fields

=head2 pollfd_array

C<has pollfd_array : L<Sys::Poll::PollfdArray|SPVM::Sys::Poll::PollfdArray>;>

A L<Sys::Poll::PollfdArray|SPVM::Sys::Poll::PollfdArray> object.

=head2 fd_indexes_h

C<has fd_indexes_h : L<Hash|SPVM::Hash> of L<Int|SPVM::Int>;>

A hash whose keys are file descriptors and whose values are indexes of L</"pollfd_array">.

=head2 disabled_fd_indexes

C<has disabled_fd_indexes : L<IntList|SPVM::IntList>;>

A list of indexes of disabled file descriptors of L</"pollfd_array">.

=head1 Class Methods

=head2 new

C<static method new : L<IO::Poll|SPVM::IO::Poll> ();>

Creates a new L<IO::Poll|SPVM::IO::Poll> object and returns it.

Implementation:

A L<Sys::Poll::PollfdArray|SPVM::Sys::Poll::PollfdArray> object is created and sets L</"pollfd_array"> field to it.

A L<Hash|SPVM::Hash> object is created and sets L</"fd_indexes_h"> field to it.

An L<IntList|SPVM::IntList> object is created and sets L</"disabled_fd_indexes"> field to it.

=head1 Instance Methods

=head2 fds

C<method fds : int[] ();>

Returns file descriptors.

Implementation:

Returned file descriptors are non-negative file descriptors in L</"pollfd_array">.

=head2 mask

C<method mask : int ($fd : int);>

Returns the current event mask for the file descriptor $fd.

If $fd is not found, returns 0.

Exceptions:

The file descriptor $fd must be greater than or equal to 0. Otherwise, an exception is thrown.

=head2 set_mask

C<method set_mask : void ($fd : int, $event_mask : int);>

If the event mask $event_mask is not 0, adds the file descriptor $fd.

If $event_mask is 0, removes the file descriptor $fd.

Implementation:

This method with $event_mask 0 is not remove a file descriptor from L</"pollfd_array">. It sets the file descriptor to -1 that means disabled.

L<poll|https://linux.die.net/man/2/poll> system call ignores file descriptors that have a negative value.

This method with $fd and $event_mask non-zero set a disabled file descriptor to $fd if there are disabled file descriptors.

With this impelmenetaion, the computational complexity of addition and removal of this method is O(1).

Exceptions:

The file descriptor $fd must be greater than or equal to 0. Otherwise, an exception is thrown.

=head2 remove

C<method remove : void ($fd : int);>

Removes the file descriptor $fd.

This method is the same as the following code using L</"set_mask"> method.

  $poll->set_mask($fd, 0);

=head2 poll

C<method poll : int ($timeout : double = -1);>

Calls L<poll|https://linux.die.net/man/2/poll> system call given the timeout seconds $timeout.

If $timeout is a negative value, the call blocks.

Returns the number of file descriptors which had events happen.

This method calls L<Sys::Poll#poll|SPVM::Sys::Poll/"poll"> method.

Exceptions:

Excetpions thrown by L<Sys::Poll#poll|SPVM::Sys::Poll/"poll"> method could be thrown.

=head2 events

C<method events : int ($fd : int);>

Returns the event mask which represents the events that happened on the file descriptor $fd during the last L</"poll"> method call.

=head1 See Also

=over 2

=item * L<IO::Select|SPVM::IO::Select>

=item * L<Go|SPVM::Go>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

