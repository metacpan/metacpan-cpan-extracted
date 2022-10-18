package SPVM::Sys::Select;

1;

=head1 Name

SPVM::Sys::Select - Select System Call

=head1 Usage
  
  use Sys::Select;

=head1 Description

C<Sys::Select> provides the select function and its utility functions.

=head1 Class Methods

=head2 FD_ZERO

  static method FD_ZERO : void ($set : Sys::Select::Fd_set);

FD_ZERO() clears a set.

See the L<select(2) - Linux man page|https://linux.die.net/man/2/select> in Linux.

The C<$set> is a L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set> object.

=head2 FD_SET

  static method FD_SET : void ($fd : int, $set : Sys::Select::Fd_set);

See the L<select(2) - Linux man page|https://linux.die.net/man/2/select> in Linux.

The C<$set> is a L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set> object.

=head2 FD_CLR

  static method FD_CLR : void ($fd : int, $set : Sys::Select::Fd_set);

FD_SET() respectively adds a given file descriptor from a set.

See the L<select(2) - Linux man page|https://linux.die.net/man/2/select> in Linux.

The C<$set> is a L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set> object.

=head2 FD_ISSET

  static method FD_ISSET : int ($fd : int, $set : Sys::Select::Fd_set);

FD_ISSET() tests to see if a file descriptor is part of the set.

See the L<select(2) - Linux man page|https://linux.die.net/man/2/select> in Linux.

The C<$set> is a L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set> object.

=head2 select

    static method select : int ($nfds : int, $readfds : Sys::Select::Fd_set, $writefds : Sys::Select::Fd_set, $exceptfds : Sys::Select::Fd_set, $timeout : Sys::Time::Timeval);

select() allows a program to monitor multiple file descriptors, waiting until one or more of the file descriptors become "ready" for some class of I/O operation (e.g., input possible). A file descriptor is considered ready if it is possible to perform the corresponding I/O operation (e.g., read(2)) without blocking.

See the L<select(2) - Linux man page|https://linux.die.net/man/2/select> in Linux.

The C<$readfds> is a L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set> object.

The C<$writefds> is a L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set> object.

The C<$exceptfds> is a L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set> object.

The C<$timeout> is a L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> object.
