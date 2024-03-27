package SPVM::Sys::Process::Constant;

1;

=head1 Name

SPVM::Sys::Process::Constant - Constant Values for Process Manipulation

=head1 Description

The Sys::Process::Constant class in L<SPVM> has methods to get constant values for process manipulation.

=head1 Usage

  use Sys::Process::Constant;

=head1 Class Methods

=head2 EXIT_FAILURE

C<static method EXIT_FAILURE : int ();>

Gets the value of C<EXIT_FAILURE>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EXIT_SUCCESS

C<static method EXIT_SUCCESS : int ();>

Gets the value of C<EXIT_SUCCESS>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WNOHANG

C<static method WNOHANG : int ();>

Gets the value of C<WNOHANG>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WUNTRACED

C<static method WUNTRACED : int ();>

Gets the value of C<WUNTRACED>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WCONTINUED

C<static method WCONTINUED : int ();>

Gets the value of C<WCONTINUED>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 PRIO_PROCESS

C<static method PRIO_PROCESS : int ();>

Gets the value of C<PRIO_PROCESS>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 PRIO_PGRP

C<static method PRIO_PGRP : int ();>

Gets the value of C<PRIO_PGRP>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 PRIO_USER

C<static method PRIO_USER : int ();>

Gets the value of C<PRIO_USER>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

