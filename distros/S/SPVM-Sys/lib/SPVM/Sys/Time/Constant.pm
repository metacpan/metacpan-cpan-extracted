package SPVM::Sys::Time::Constant;

1;

=head1 Name

SPVM::Sys::Time::Constant - Constant Values for Time

=head1 Usage

  use Sys::Time::Constant;

=head1 Description

C<Sys::Time::Constant> provides the methods for the constant values for the time manipulation.

=head1 Class Methods

=head2 CLOCKS_PER_SEC

C<static method CLOCKS_PER_SEC : int ();>

Gets the value of C<CLOCKS_PER_SEC>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_BOOTTIME

C<static method CLOCK_BOOTTIME : int ();>

Gets the value of C<CLOCK_BOOTTIME>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_HIGHRES

C<static method CLOCK_HIGHRES : int ();>

Gets the value of C<CLOCK_HIGHRES>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_MONOTONIC

C<static method CLOCK_MONOTONIC : int ();>

Gets the value of C<CLOCK_MONOTONIC>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_MONOTONIC_COARSE

C<static method CLOCK_MONOTONIC_COARSE : int ();>

Gets the value of C<CLOCK_MONOTONIC_COARSE>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_MONOTONIC_FAST

C<static method CLOCK_MONOTONIC_FAST : int ();>

Gets the value of C<CLOCK_MONOTONIC_FAST>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_MONOTONIC_PRECISE

C<static method CLOCK_MONOTONIC_PRECISE : int ();>

Gets the value of C<CLOCK_MONOTONIC_PRECISE>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_MONOTONIC_RAW

C<static method CLOCK_MONOTONIC_RAW : int ();>

Gets the value of C<CLOCK_MONOTONIC_RAW>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_PROCESS_CPUTIME_ID

C<static method CLOCK_PROCESS_CPUTIME_ID : int ();>

Gets the value of C<CLOCK_PROCESS_CPUTIME_ID>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_PROF

C<static method CLOCK_PROF : int ();>

Gets the value of C<CLOCK_PROF>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_REALTIME

C<static method CLOCK_REALTIME : int ();>

Gets the value of C<CLOCK_REALTIME>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_REALTIME_COARSE

C<static method CLOCK_REALTIME_COARSE : int ();>

Gets the value of C<CLOCK_REALTIME_COARSE>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_REALTIME_FAST

C<static method CLOCK_REALTIME_FAST : int ();>

Gets the value of C<CLOCK_REALTIME_FAST>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_REALTIME_PRECISE

C<static method CLOCK_REALTIME_PRECISE : int ();>

Gets the value of C<CLOCK_REALTIME_PRECISE>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_REALTIME_RAW

C<static method CLOCK_REALTIME_RAW : int ();>

Gets the value of C<CLOCK_REALTIME_RAW>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_SECOND

C<static method CLOCK_SECOND : int ();>

Gets the value of C<CLOCK_SECOND>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_SOFTTIME

C<static method CLOCK_SOFTTIME : int ();>

Gets the value of C<CLOCK_SOFTTIME>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_THREAD_CPUTIME_ID

C<static method CLOCK_THREAD_CPUTIME_ID : int ();>

Gets the value of C<CLOCK_THREAD_CPUTIME_ID>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_TIMEOFDAY

C<static method CLOCK_TIMEOFDAY : int ();>

Gets the value of C<CLOCK_TIMEOFDAY>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_UPTIME

C<static method CLOCK_UPTIME : int ();>

Gets the value of C<CLOCK_UPTIME>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_UPTIME_COARSE

C<static method CLOCK_UPTIME_COARSE : int ();>

Gets the value of C<CLOCK_UPTIME_COARSE>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_UPTIME_FAST

C<static method CLOCK_UPTIME_FAST : int ();>

Gets the value of C<CLOCK_UPTIME_FAST>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_UPTIME_PRECISE

C<static method CLOCK_UPTIME_PRECISE : int ();>

Gets the value of C<CLOCK_UPTIME_PRECISE>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_UPTIME_RAW

C<static method CLOCK_UPTIME_RAW : int ();>

Gets the value of C<CLOCK_UPTIME_RAW>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_VIRTUAL

C<static method CLOCK_VIRTUAL : int ();>

Gets the value of C<CLOCK_VIRTUAL>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ITIMER_PROF

C<static method ITIMER_PROF : int ();>

Gets the value of C<ITIMER_PROF>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ITIMER_REAL

C<static method ITIMER_REAL : int ();>

Gets the value of C<ITIMER_REAL>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ITIMER_REALPROF

C<static method ITIMER_REALPROF : int ();>

Gets the value of C<ITIMER_REALPROF>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ITIMER_VIRTUAL

C<static method ITIMER_VIRTUAL : int ();>

Gets the value of C<ITIMER_VIRTUAL>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TIMER_ABSTIME

C<static method TIMER_ABSTIME : int ();>

Gets the value of C<TIMER_ABSTIME>. If the value is not defined in the system, an exception is thrown with the C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

