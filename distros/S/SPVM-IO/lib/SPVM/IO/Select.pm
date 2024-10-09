package SPVM::IO::Select;

1;

=head1 Name

SPVM::IO::Select - select System Call

=head1 Description

IO::Select class in L<SPVM> has methods for C<select> system call.

=head1 Usage

  use IO::Select;
  
  my $select = IO::Select->new;
  
  $select->add($fd0);
  $select->add($fd1);
  
  my $read_ready_fds = $select->can_read($timeout);
  
  my $write_ready_fds = $select->can_write($timeout);

=head2 Details

This class is a Perl's L<IO::Select|IO::Select> porting to L<SPVM>.

=head1 Fields

=head2 fds_list

C<has fds_list : L<IntList|SPVM::IntList>;>

A list of file descriptors.

=head1 Class Methods

=head2 new

C<static method new : L<IO::Select|SPVM::IO::Select> ();>

Creates a new L<IO::Select|SPVM::IO::Select> object and returns it.

Internally, a L<IntList|SPVM::IntList> object with zero-length is created, and L</"fds_list"> is set to it.

=head1 Instance Methods

=head2 add

C<method add : void ($fd : int);>

Adds the file descriptor $fd to L</"fds_list"> field.

If $fd is already contained in L</"fds_list"> field, nothing is performed.

=head2 remove

C<method remove : void ($fd : int);>

Removes the file descriptor $fd from L</"fds_list"> field.

If $fd is not found, nothing is performed.

=head2 exists

C<method exists : int ($fd : int);>

If the file descriptor $fd is contained in L</"fds_list"> field, returns 1, otherwise returns 0.

=head2 fds

C<method fds : int[] ();>

Converts L</"fds_list"> field to an array and returns it.

=head2 count

C<method count : int ();>

Returns the length of L</"fds_list"> field.

=head2 can_read

C<method can_read : int[] ($timeout : double = -1);>

Returns readable file descriptors in L</"fds_list"> field.

This method calls L<Sys::Select#select|SPVM::Sys::Select/"select"> method.

The timeout $timeout specifies the minimum interval that select() system call should block waiting for a file descriptor to become ready. If $timeout is 0, then select() returns immediately. If $timeout is a negative value, select() can block indefinitely.

=head2 can_write

C<method can_write : int[] ($timeout : double = -1);>

Returns writable file descriptors in L</"fds_list"> field.

The timeout $timeout specifies the minimum interval that select() system call should block waiting for a file descriptor to become ready. If $timeout is 0, then select() returns immediately. If $timeout is a negative value, select() can block indefinitely.

=head2 has_exception

C<method has_exception : int[] ($timeout : double = -1);>

Returns file descriptors that causes exceptions in L</"fds_list"> field.

The timeout $timeout specifies the minimum interval that select() system call should block waiting for a file descriptor to become ready. If $timeout is 0, then select() returns immediately. If $timeout is a negative value, select() can block indefinitely.

=head1 See Also

=over 2

=item * L<Sys::Select|SPVM::Sys::Select>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

