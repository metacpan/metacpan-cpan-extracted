package SPVM::Sys::Ioctl::Constant;

1;

=head1 Name

SPVM::Sys::Ioctl::Constant - Constant Values for The ioctl Function.

=head1 Description

The Sys::Ioctl::Constant class in L<SPVM> has methods to get constant values for the L<ioctl|https://linux.die.net/man/2/ioctl> function.

=head1 Usage

  use Sys::Ioctl::Constant;

=head1 Class Methods

=head2 FIONBIO

C<static method FIONBIO : int ();>

Gets the value of C<FIONBIO>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

