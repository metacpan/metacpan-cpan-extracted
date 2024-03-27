package SPVM::Sys::Signal::Handler;

1;

=head1 Name

SPVM::Sys::Signal::Handler - Signal Handler

=head1 Description

The C<Sys::Signal::Handler> class has methods to manipulate signal handlers.

=head1 Usage

  use Sys::Signal::Handler;
  
=head1 Class Methods

C<static method eq : int ($handler1 : L<Sys::Signal::Handler|SPVM::Sys::Signal::Handler>, $handler2 : L<Sys::Signal::Handler|SPVM::Sys::Signal::Handler>);>

Checks if the $hander1 and $hander2 point to the same signal handler.

If the check is ok, returns 1, otherwise returns 0.

Exceptions:

$handler1 must be defined. Otherwise an exception is thrown.

$handler2 must be defined. Otherwise an exception is thrown.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

