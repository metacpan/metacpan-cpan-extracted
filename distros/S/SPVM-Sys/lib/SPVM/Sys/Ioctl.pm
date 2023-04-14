package SPVM::Sys::Ioctl;

1;

=head1 Name

SPVM::Sys::Ioctl - ioctl System Call

=head1 Usage
  
  use Sys::Ioctl;

=head1 Description

C<Sys::Ioctl> is the class for the ioctl function.

=head1 Class Methods

=head2 ioctl

  static method ioctl : int ($fd : int, $request : int, $request_arg = undef : object of Byte|Short|Int|Long|Float|Double|object);

The ioctl() function manipulates the underlying device parameters of special files. In particular, many operating characteristics of character special files (e.g., terminals) may be controlled with ioctl() requests. The argument d must be an open file descriptor.

See the L<ioctl|https://linux.die.net/man/2/ioctl> function in Linux.

On Windows, C<ioctl> calls C<ioctlsocket>.

See the L<ioctlsocket|https://learn.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-ioctlsocket> function in Windows.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

