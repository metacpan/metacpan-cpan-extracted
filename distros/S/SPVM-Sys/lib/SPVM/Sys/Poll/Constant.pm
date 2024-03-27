package SPVM::Sys::Poll::Constant;

1;

=head1 Name

SPVM::Sys::Poll::Constant - Constant Values for The poll System Call

=head1 Description

The Sys::Poll::Constant class in L<SPVM> has methods to get constant values for the poll system call.

=head1 Usage

  use Sys::Poll::Constant;

=head1 Class Methods

=head2 POLLERR

C<static method POLLERR : int ();>

Gets the value of C<POLLERR>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLHUP

C<static method POLLHUP : int ();>

Gets the value of C<POLLHUP>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLIN

C<static method POLLIN : int ();>

Gets the value of C<POLLIN>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLNVAL

C<static method POLLNVAL : int ();>

Gets the value of C<POLLNVAL>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLOUT

C<static method POLLOUT : int ();>

Gets the value of C<POLLOUT>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLPRI

C<static method POLLPRI : int ();>

Gets the value of C<POLLPRI>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLRDBAND

C<static method POLLRDBAND : int ();>

Gets the value of C<POLLRDBAND>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLRDNORM

C<static method POLLRDNORM : int ();>

Gets the value of C<POLLRDNORM>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLWRBAND

C<static method POLLWRBAND : int ();>

Gets the value of C<POLLWRBAND>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLWRNORM

C<static method POLLWRNORM : int ();>

Gets the value of C<POLLWRNORM>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

