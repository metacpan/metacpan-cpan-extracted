package SPVM::Sys::Ioctl;

1;

=head1 Name

SPVM::Sys::Ioctl - The ioctl System Call

=head1 Description

The Sys::Ioctl class in L<SPVM> has methods to call the ioctl functions.

=head1 Usage

  use Sys::Ioctl;
  use Sys::Ioctl::Constant as IOCTL;
  
  my $nonblocking_ref = [1];
  Sys::Ioctl->ioctl($socket_fd, IOCTL->FIONBIO, $nonblocking_ref);

=head1 Class Methods

=head2 ioctl

C<static method ioctl : int ($fd : int, $request : int, $request_arg_ref : object of byte[]|short[]|int[]|long[]|float[]|double[]|object = undef);>

Calls the L<ioctl|https://linux.die.net/man/2/ioctl> function and returns its return value.

See L<Sys::Ioctl::Constant|SPVM::Sys::Ioctl::Constant> about constant values given to the value of $request_arg_ref.

Exceptions:

$request_arg_ref must be an byte[]/short[]/int[]/long[]/float[]/double[] type object or the object that is a pointer class. Otherwise an exception is thrown.

If the ioctl function failed, an exception is thrown with C<eval_error_id> is set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 ioctlsocket

C<static method ioctlsocket : int ($fd : int, $request : int, $request_arg_ref : int[] = undef);>

Calls the L<ioctlsocket|https://learn.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-ioctlsocket> function and returns its return value.

See L<Sys::Ioctl::Constant|SPVM::Sys::Ioctl::Constant> about constant values given to the value of $request_arg_ref.

Exceptions:

If the ioctlsocket function failed, an exception is thrown with C<eval_error_id> is set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

