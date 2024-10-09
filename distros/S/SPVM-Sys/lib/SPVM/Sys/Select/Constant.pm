package SPVM::Sys::Select::Constant;

1;

=head1 Name

SPVM::Sys::Select::Constant - Constant Values for Select.

=head1 Description

Sys::Select::Constant class in L<SPVM> has methods to get constant values for the select system call.

=head1 Usage

  use Sys::Select::Constant;

=head1 Class Methods

=head2 FD_SETSIZE

C<static method FD_SETSIZE : int ();>

Gets the value of C<FD_SETSIZE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

