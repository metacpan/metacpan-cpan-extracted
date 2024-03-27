package SPVM::Sys::Process;

1;

=head1 Name

SPVM::Sys::Process - System Calls for Process Manipulation

=head1 Description

The Sys::Process class has methods to call system calls for process manipulation.

=head1 Usage
  
  use Sys::Process;
  use Sys::Process::Constant as PROCESS;
  
  # exit
  Sys::Process->exit(PROCESS->EXIT_FAILURE);
  
  # waitpid
  my $wstatus = -1;
  my $process_id = Sys::Process->waitpid($process_id, \$wstatus, PROCESS->WNOHANG);
  
  # getpid
  my $process_id = Sys::Process->getpid;
  
  # sleep
  Sys::Process->sleep(5);

=head1 Class Methods

=head2 fork

C<static method fork : int ();>

Calls the L<fork|https://linux.die.net/man/2/fork> function and returns its return value.

Exceptions:

If the fork function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows, the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. fork is not supported in this system(defined(_WIN32)).

=head2 getpriority

C<static method getpriority : int ($which : int, $who : int);>

Calls the L<getpriority|https://linux.die.net/man/2/getpriority> function and returns its return value.

See L<Sys::Process::Constant|SPVM::Sys::Process::Constant> about constant values given to $which.

Exceptions:

If the getpriority function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows, the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. getpriority is not supported in this system(defined(_WIN32)).

=head2 setpriority

C<static method setpriority : int ($which : int, $who : int, $prio : int);>

Calls the L<setpriority|https://linux.die.net/man/2/setpriority> function and returns its return value.

See L<Sys::Process::Constant|SPVM::Sys::Process::Constant> about constant values given to $which.

Exceptions:

If the setpriority function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows, the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. setpriority is not supported in this system(defined(_WIN32)).

=head2 sleep

C<static method sleep : int ($seconds : int);>

Calls the L<sleep|https://linux.die.net/man/3/sleep> function and returns its return value.

=head2 usleep

C<static method usleep : int ($usec : int);>

Calls the L<usleep|https://linux.die.net/man/3/usleep> function and returns its return value.

If the usleep function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 wait

C<static method wait : int ($wstatus : int*);>

Calls the L<wait|https://linux.die.net/man/2/wait> function and returns its return value.

Exceptions:

If the wait function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows, the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. wait is not supported in this system(defined(_WIN32)).

=head2 waitpid

C<static method waitpid : int ($pid : int, $wstatus : int*, $options : int);>

Calls the L<waitpid|https://linux.die.net/man/2/waitpid> function and returns its return value.

See L<Sys::Process::Constant|SPVM::Sys::Process::Constant> about constant values given to $options.

Exceptions:

If the waitpid function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows, the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. waitpid is not supported in this system(defined(_WIN32)).

=head2 system

C<static method system : int ($command : string);>

Calls the L<system|https://linux.die.net/man/3/system> function and returns its return value.

Exceptions:

If the system function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 exit

C<static method exit : int ($status : int);>

Calls the L<exit|https://linux.die.net/man/3/exit> function and returns its return value.

See L<Sys::Process::Constant|SPVM::Sys::Process::Constant> about constant values given to $satus.

=head2 pipe

C<static method pipe : int ($pipe_fds : int[]);>

Calls the L<pipe|https://linux.die.net/man/2/pipe> function and returns its return value.

Exceptions:

$pipefds must be defined. Otherwise an exception is thrown.

The length of $pipefds must 2. Otherwise an exception is thrown.

If the pipe function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows, the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. pipe is not supported in this system(defined(_WIN32)).

=head2 _pipe

  static method _pipe : int ($pipe_fds : int[], $psize : int, $textmode : int);

Calls the L<_pipe|https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/pipe?view=msvc-170> function and returns its return value.

Exceptions:

$pipefds must be defined. Otherwise an exception is thrown.

The length of $pipefds must 2. Otherwise an exception is thrown.

If the _pipe function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In OSs other than Windows, the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. _pipe is not supported in this system(!defined(_WIN32)).

=head2 getpgid

C<static method getpgid : int ($pid : int);>

Calls the L<getpgid|https://linux.die.net/man/2/getpgid> function and returns its return value.

Exceptions:

If the getpgid function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows, the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. getpgid is not supported in this system(defined(_WIN32)).

=head2 setpgid

C<static method setpgid : int ($pid : int, $pgid : int);>

Calls the L<setpgid|https://linux.die.net/man/2/setpgid> function and returns its return value.

Exceptions:

If the setpgid function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows, the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. setpgid is not supported in this system(defined(_WIN32)).

=head2 getpid

C<static method getpid : int ();>

Calls the L<getpid|https://linux.die.net/man/2/getpid> function and returns its return value.

=head2 getppid

C<static method getppid : int ();>

Calls the L<getppid|https://linux.die.net/man/2/getppid> function and returns its return value.

=head2 execv

C<static method execv : int ($path : string, $args : string[]);>

Calls the L<execv|https://linux.die.net/man/3/execv> function and returns its return value.

Exceptions:

$path must be defined. Otherwise an exception is thrown.

$args must be defined. Otherwise an exception is thrown.

All element of $args must be defined. Otherwise an exception is thrown.

If the execv function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 WIFEXITED

C<static method WIFEXITED : int ($wstatus : int);>

Calls the L<WIFEXITED|https://linux.die.net/man/2/waitpid> function and returns its return value.

=head2 WEXITSTATUS

C<static method WEXITSTATUS : int ($wstatus : int);>

Calls the L<WEXITSTATUS|https://linux.die.net/man/2/waitpid> function and returns its return value.

=head2 WIFSIGNALED

C<static method WIFSIGNALED : int ($wstatus : int);>

Calls the L<WIFSIGNALED|https://linux.die.net/man/2/waitpid> function and returns its return value.

=head2 WTERMSIG

C<static method WTERMSIG : int ($wstatus : int);>

Calls the L<WTERMSIG|https://linux.die.net/man/2/waitpid> function and returns its return value.

=head2 WCOREDUMP

C<static method WCOREDUMP : int ($wstatus : int);>

Calls the L<WCOREDUMP|https://linux.die.net/man/2/waitpid> function and returns its return value.

=head2 WIFSTOPPED

C<static method WIFSTOPPED : int ($wstatus : int);>

Calls the L<WIFSTOPPED|https://linux.die.net/man/2/waitpid> function and returns its return value.

=head2 WSTOPSIG

C<static method WSTOPSIG : int ($wstatus : int);>

Calls the L<WSTOPSIG|https://linux.die.net/man/2/waitpid> function and returns its return value.

=head2 WIFCONTINUED

C<static method WIFCONTINUED : int ($wstatus : int);>

Calls the L<WIFCONTINUED|https://linux.die.net/man/2/waitpid> function and returns its return value.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

