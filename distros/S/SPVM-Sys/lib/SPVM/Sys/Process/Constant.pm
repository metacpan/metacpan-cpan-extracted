package SPVM::Sys::Process::Constant;

1;

=head1 Name

SPVM::Sys::Process::Constant - Constant Values for Process

=head1 Usage

  use Sys::Process::Constant as Proc;
  
  my $value = Proc->EXIT_FAILURE;
  
=head1 Description

C<Sys::Process::Constant> provides the methods for the constant values for the process manipulation.

=head1 Class Methods

=head2 EXIT_FAILURE

  static method EXIT_FAILURE : int ();

Get the constant value of C<EXIT_FAILURE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EXIT_SUCCESS

  static method EXIT_SUCCESS : int ();

Get the constant value of C<EXIT_SUCCESS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WNOHANG

  static method WNOHANG : int ();

Get the constant value of C<WNOHANG>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WUNTRACED

  static method WUNTRACED : int ();

Get the constant value of C<WUNTRACED>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WCONTINUED

  static method WCONTINUED : int ();

Get the constant value of C<WCONTINUED>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 PRIO_PROCESS

  static method PRIO_PROCESS : int ();

Get the constant value of C<PRIO_PROCESS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 PRIO_PGRP

  static method PRIO_PGRP : int ();

Get the constant value of C<PRIO_PGRP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 PRIO_USER

  static method PRIO_USER : int ();

Get the constant value of C<PRIO_USER>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

