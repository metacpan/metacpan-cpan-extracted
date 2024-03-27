package SPVM::Sys::Signal::Constant;

1;

=head1 Name

SPVM::Sys::Signal::Constant - Signal Constant Values

=head1 Description

The Sys::Signal::Constant in L<SPVM> has methods to get constant values for signals.

=head1 Usage

  use Sys::Signal::Constant;
  
=head1 Class Methods

=head2 BUS_ADRALN

C<static method BUS_ADRALN : int ();>

Gets the value of C<BUS_ADRALN>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 BUS_ADRERR

C<static method BUS_ADRERR : int ();>

Gets the value of C<BUS_ADRERR>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 BUS_MCEERR_AO

C<static method BUS_MCEERR_AO : int ();>

Gets the value of C<BUS_MCEERR_AO>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 BUS_MCEERR_AR

C<static method BUS_MCEERR_AR : int ();>

Gets the value of C<BUS_MCEERR_AR>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 BUS_MCERR_

C<static method BUS_MCERR_ : int ();>

Gets the value of C<BUS_MCERR_>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 BUS_OBJERR

C<static method BUS_OBJERR : int ();>

Gets the value of C<BUS_OBJERR>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLD_CONTINUED

C<static method CLD_CONTINUED : int ();>

Gets the value of C<CLD_CONTINUED>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLD_DUMPED

C<static method CLD_DUMPED : int ();>

Gets the value of C<CLD_DUMPED>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLD_EXITED

C<static method CLD_EXITED : int ();>

Gets the value of C<CLD_EXITED>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLD_KILLED

C<static method CLD_KILLED : int ();>

Gets the value of C<CLD_KILLED>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLD_STOPPED

C<static method CLD_STOPPED : int ();>

Gets the value of C<CLD_STOPPED>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLD_TRAPPED

C<static method CLD_TRAPPED : int ();>

Gets the value of C<CLD_TRAPPED>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 FPE_FLTDIV

C<static method FPE_FLTDIV : int ();>

Gets the value of C<FPE_FLTDIV>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 FPE_FLTINV

C<static method FPE_FLTINV : int ();>

Gets the value of C<FPE_FLTINV>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 FPE_FLTOVF

C<static method FPE_FLTOVF : int ();>

Gets the value of C<FPE_FLTOVF>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 FPE_FLTRES

C<static method FPE_FLTRES : int ();>

Gets the value of C<FPE_FLTRES>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 FPE_FLTSUB

C<static method FPE_FLTSUB : int ();>

Gets the value of C<FPE_FLTSUB>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 FPE_FLTUND

C<static method FPE_FLTUND : int ();>

Gets the value of C<FPE_FLTUND>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 FPE_INTDIV

C<static method FPE_INTDIV : int ();>

Gets the value of C<FPE_INTDIV>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 FPE_INTOVF

C<static method FPE_INTOVF : int ();>

Gets the value of C<FPE_INTOVF>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 FUTEX_WAIT

C<static method FUTEX_WAIT : int ();>

Gets the value of C<FUTEX_WAIT>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ILL_BADSTK

C<static method ILL_BADSTK : int ();>

Gets the value of C<ILL_BADSTK>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ILL_COPROC

C<static method ILL_COPROC : int ();>

Gets the value of C<ILL_COPROC>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ILL_ILLADR

C<static method ILL_ILLADR : int ();>

Gets the value of C<ILL_ILLADR>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ILL_ILLOPC

C<static method ILL_ILLOPC : int ();>

Gets the value of C<ILL_ILLOPC>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ILL_ILLOPN

C<static method ILL_ILLOPN : int ();>

Gets the value of C<ILL_ILLOPN>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ILL_ILLTRP

C<static method ILL_ILLTRP : int ();>

Gets the value of C<ILL_ILLTRP>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ILL_PRVOPC

C<static method ILL_PRVOPC : int ();>

Gets the value of C<ILL_PRVOPC>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ILL_PRVREG

C<static method ILL_PRVREG : int ();>

Gets the value of C<ILL_PRVREG>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLL_ERR

C<static method POLL_ERR : int ();>

Gets the value of C<POLL_ERR>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLL_HUP

C<static method POLL_HUP : int ();>

Gets the value of C<POLL_HUP>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLL_IN

C<static method POLL_IN : int ();>

Gets the value of C<POLL_IN>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLL_MSG

C<static method POLL_MSG : int ();>

Gets the value of C<POLL_MSG>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLL_OUT

C<static method POLL_OUT : int ();>

Gets the value of C<POLL_OUT>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLL_PRI

C<static method POLL_PRI : int ();>

Gets the value of C<POLL_PRI>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SI_ASYNCIO

C<static method SI_ASYNCIO : int ();>

Gets the value of C<SI_ASYNCIO>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SI_KERNEL

C<static method SI_KERNEL : int ();>

Gets the value of C<SI_KERNEL>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SI_MESGQ

C<static method SI_MESGQ : int ();>

Gets the value of C<SI_MESGQ>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SI_QUEUE

C<static method SI_QUEUE : int ();>

Gets the value of C<SI_QUEUE>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SI_SIGIO

C<static method SI_SIGIO : int ();>

Gets the value of C<SI_SIGIO>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SI_TIMER

C<static method SI_TIMER : int ();>

Gets the value of C<SI_TIMER>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SI_TKILL

C<static method SI_TKILL : int ();>

Gets the value of C<SI_TKILL>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SI_USER

C<static method SI_USER : int ();>

Gets the value of C<SI_USER>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TRAP_BRANCH

C<static method TRAP_BRANCH : int ();>

Gets the value of C<TRAP_BRANCH>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TRAP_BRKPT

C<static method TRAP_BRKPT : int ();>

Gets the value of C<TRAP_BRKPT>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TRAP_HWBKPT

C<static method TRAP_HWBKPT : int ();>

Gets the value of C<TRAP_HWBKPT>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TRAP_TRACE

C<static method TRAP_TRACE : int ();>

Gets the value of C<TRAP_TRACE>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGABRT

C<static method SIGABRT : int ();>

Gets the value of C<SIGABRT>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGALRM

C<static method SIGALRM : int ();>

Gets the value of C<SIGALRM>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGBUS

C<static method SIGBUS : int ();>

Gets the value of C<SIGBUS>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGCHLD

C<static method SIGCHLD : int ();>

Gets the value of C<SIGCHLD>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGCONT

C<static method SIGCONT : int ();>

Gets the value of C<SIGCONT>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGFPE

C<static method SIGFPE : int ();>

Gets the value of C<SIGFPE>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGHUP

C<static method SIGHUP : int ();>

Gets the value of C<SIGHUP>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGILL

C<static method SIGILL : int ();>

Gets the value of C<SIGILL>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGINT

C<static method SIGINT : int ();>

Gets the value of C<SIGINT>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGIO

C<static method SIGIO : int ();>

Gets the value of C<SIGIO>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGKILL

C<static method SIGKILL : int ();>

Gets the value of C<SIGKILL>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGPIPE

C<static method SIGPIPE : int ();>

Gets the value of C<SIGPIPE>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGPROF

C<static method SIGPROF : int ();>

Gets the value of C<SIGPROF>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGPWR

C<static method SIGPWR : int ();>

Gets the value of C<SIGPWR>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGQUIT

C<static method SIGQUIT : int ();>

Gets the value of C<SIGQUIT>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGRTMAX

C<static method SIGRTMAX : int ();>

Gets the value of C<SIGRTMAX>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGRTMIN

C<static method SIGRTMIN : int ();>

Gets the value of C<SIGRTMIN>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGSEGV

C<static method SIGSEGV : int ();>

Gets the value of C<SIGSEGV>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGSTKFLT

C<static method SIGSTKFLT : int ();>

Gets the value of C<SIGSTKFLT>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGSTOP

C<static method SIGSTOP : int ();>

Gets the value of C<SIGSTOP>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGSYS

C<static method SIGSYS : int ();>

Gets the value of C<SIGSYS>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGTERM

C<static method SIGTERM : int ();>

Gets the value of C<SIGTERM>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGTRAP

C<static method SIGTRAP : int ();>

Gets the value of C<SIGTRAP>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGTSTP

C<static method SIGTSTP : int ();>

Gets the value of C<SIGTSTP>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGTTIN

C<static method SIGTTIN : int ();>

Gets the value of C<SIGTTIN>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGTTOU

C<static method SIGTTOU : int ();>

Gets the value of C<SIGTTOU>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGURG

C<static method SIGURG : int ();>

Gets the value of C<SIGURG>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGUSR1

C<static method SIGUSR1 : int ();>

Gets the value of C<SIGUSR1>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGUSR2

C<static method SIGUSR2 : int ();>

Gets the value of C<SIGUSR2>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGVTALRM

C<static method SIGVTALRM : int ();>

Gets the value of C<SIGVTALRM>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGWINCH

C<static method SIGWINCH : int ();>

Gets the value of C<SIGWINCH>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGXCPU

C<static method SIGXCPU : int ();>

Gets the value of C<SIGXCPU>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIGXFSZ

C<static method SIGXFSZ : int ();>

Gets the value of C<SIGXFSZ>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIG_DFL

C<static method SIG_DFL : int ();>

Gets the value of C<SIG_DFL>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIG_ERR

C<static method SIG_ERR : int ();>

Gets the value of C<SIG_ERR>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SIG_IGN

C<static method SIG_IGN : int ();>

Gets the value of C<SIG_IGN>. If the value is not defined in the system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

