package SPVM::Sys::Signal;

1;

=head1 Name

SPVM::Sys::Signal - Signals

=head1 Description

The Sys::Signal class in L<SPVM> has methods to manipulate signals.

=head1 Usage
  
  use Sys::Signal;
  use Sys::Signal::Constant as SIGNAL;
  
  Sys::Signal->kill($process_id, SIGNAL->SIGINT);
  
  Sys::Signal->signal(SIGNAL->SIGTERM, Sys::Signal->SIG_IGN);

=head1 Class Methods

=head2 raise

C<static method raise : int ($sig : int)>

Calls the L<raise|https://linux.die.net/man/3/raise> function and returns its return value.

See L<Sys::Signal::Constant|SPVM::Sys::Signal::Constant> about constant values given to $sig.

Exceptions:

If the raise function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 kill

C<static method kill : int ($pid : int, $sig : int)>

Calls the L<kill|https://linux.die.net/man/2/kill> function and returns its return value.

See L<Sys::Signal::Constant|SPVM::Sys::Signal::Constant> about constant values given to $sig.

Exceptions:

If the kill function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following excetpion is thrown. kill is not supported in this system(defined(_WIN32)).

=head2 alarm

C<static method alarm : int ($seconds : int)>

Calls the L<alarm|https://linux.die.net/man/2/alarm> function and returns its return value.

Exceptions:

If the alarm function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following excetpion is thrown. alarm is not supported in this system(defined(_WIN32)).

=head2 ualarm

C<static method ualarm : int ($usecs : int, $interval : int)>

Calls the L<ualarm|https://linux.die.net/man/3/ualarm> function and returns its return value.

Exceptions:

In Windows the following excetpion is thrown. ualarm is not supported in this system(defined(_WIN32)).

=head2 signal

C<static method signal : L<Sys::Signal::Handler|SPVM::Sys::Signal::Handler> ($signum : int, $handler : L<Sys::Signal::Handler|SPVM::Sys::Signal::Handler>);>

Calls L<signal|https://linux.die.net/man/2/signal> function and creates a signal handler object with its pointer set to the function's return value, and returns it.

$handler can be L</"SIG_DFL"> and L</"SIG_IGN">.

See L<Sys::Signal::Constant|SPVM::Sys::Signal::Constant> about constant values given to $sig.

Exceptions:

$handler must be defined. Otherwise an exception is thrown.

If the signal function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 SIG_DFL

C<static method SIG_DFL : L<Sys::Signal::Handler|SPVM::Sys::Signal::Handler> ();>

Creates a new signal handler that represents C<SIG_DFL>.

=head2 SIG_IGN

C<static method SIG_IGN : L<Sys::Signal::Handler|SPVM::Sys::Signal::Handler> ();>

Creates a new signal handler that represents C<SIG_IGN>.

=head2 SIG_GO

C<static method SIG_GO : L<Sys::Signal::Handler|SPVM::Sys::Signal::Handler> ();>

Creates a new signal handler that represents the signal handler for L<Go::OS::Signal|SPVM::Go::OS::Signal>.

Do not use this signal handler because this signal handler is prepared to implement the  L<Go::OS::Signal|SPVM::Go::OS::Signal> class.

=head2 SET_SIG_GO_WRITE_FD

C<static method SET_SIG_GO_WRITE_FD : void ($fd : int);>

Set a write file descriptor for L<Go::OS::Signal|SPVM::Go::OS::Signal>.

Do not use this method because this method is prepared to implement the L<Go::OS::Signal|SPVM::Go::OS::Signal> class.

=head1 See Also

=over 2

L<Go::OS::Signal|SPVM::Go::OS::Signal>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

