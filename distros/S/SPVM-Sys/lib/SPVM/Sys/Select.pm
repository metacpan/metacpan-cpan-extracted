package SPVM::Sys::Select;

1;

=head1 Name

SPVM::Sys::Select - Select System Call

=head1 Description

The Sys::Select class has methods to call the select system call.

=head1 Usage
  
  use Sys::Select;

=head2 Details

In Windows, FD_SETSIZE is set to 1024.

=head1 Class Methods

=head2 FD_ZERO

C<static method FD_ZERO : void ($set : L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set>);>

Calls the L<FD_ZERO|https://linux.die.net/man/2/select> function.

Exceptions:

$set must be defined. Otherwise an exception is thrown.

=head2 FD_SET

C<static method FD_SET : void ($fd : int, $set : L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set>);>

Calls the L<FD_SET|https://linux.die.net/man/2/select> function.

Exceptions:

$fd must be greater than or equal to 0. Otherwise an exception is thrown.

$fd must be less than FD_SETSIZE. Otherwise an exception is thrown.

$set must be defined. Otherwise an exception is thrown.

=head2 FD_CLR

C<static method FD_CLR : void ($fd : int, $set : L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set>);>

Calls the L<FD_CLR|https://linux.die.net/man/2/select> function.

Exceptions:

$fd must be greater than or equal to 0. Otherwise an exception is thrown.

$fd must be less than FD_SETSIZE. Otherwise an exception is thrown.

$set must be defined. Otherwise an exception is thrown.

=head2 FD_ISSET

C<static method FD_ISSET : int ($fd : int, $set : L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set>);>

Calls the L<FD_ISSET|https://linux.die.net/man/2/select> function and returns its return value.

Exceptions:

$fd must be greater than or equal to 0. Otherwise an exception is thrown.

$fd must be less than FD_SETSIZE. Otherwise an exception is thrown.

$set must be defined. Otherwise an exception is thrown.

=head2 select

C<static method select : int ($nfds : int, $readfds : L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set>, $writefds : L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set>, $exceptfds : L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set>, $timeout : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>);>

Calls the L<select|https://linux.die.net/man/2/select> function and returns its return value.

Exceptions:

$fd must be greater than or equal to 0. Otherwise an exception is thrown.

$fd must be less than FD_SETSIZE. Otherwise an exception is thrown.

If the select function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

