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

  static method CLOCKS_PER_SEC : int ();

Get the constant value of C<CLOCKS_PER_SEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_BOOTTIME

  static method CLOCK_BOOTTIME : int ();

Get the constant value of C<CLOCK_BOOTTIME>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_HIGHRES

  static method CLOCK_HIGHRES : int ();

Get the constant value of C<CLOCK_HIGHRES>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_MONOTONIC

  static method CLOCK_MONOTONIC : int ();

Get the constant value of C<CLOCK_MONOTONIC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_MONOTONIC_COARSE

  static method CLOCK_MONOTONIC_COARSE : int ();

Get the constant value of C<CLOCK_MONOTONIC_COARSE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_MONOTONIC_FAST

  static method CLOCK_MONOTONIC_FAST : int ();

Get the constant value of C<CLOCK_MONOTONIC_FAST>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_MONOTONIC_PRECISE

  static method CLOCK_MONOTONIC_PRECISE : int ();

Get the constant value of C<CLOCK_MONOTONIC_PRECISE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_MONOTONIC_RAW

  static method CLOCK_MONOTONIC_RAW : int ();

Get the constant value of C<CLOCK_MONOTONIC_RAW>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_PROCESS_CPUTIME_ID

  static method CLOCK_PROCESS_CPUTIME_ID : int ();

Get the constant value of C<CLOCK_PROCESS_CPUTIME_ID>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_PROF

  static method CLOCK_PROF : int ();

Get the constant value of C<CLOCK_PROF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_REALTIME

  static method CLOCK_REALTIME : int ();

Get the constant value of C<CLOCK_REALTIME>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_REALTIME_COARSE

  static method CLOCK_REALTIME_COARSE : int ();

Get the constant value of C<CLOCK_REALTIME_COARSE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_REALTIME_FAST

  static method CLOCK_REALTIME_FAST : int ();

Get the constant value of C<CLOCK_REALTIME_FAST>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_REALTIME_PRECISE

  static method CLOCK_REALTIME_PRECISE : int ();

Get the constant value of C<CLOCK_REALTIME_PRECISE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_REALTIME_RAW

  static method CLOCK_REALTIME_RAW : int ();

Get the constant value of C<CLOCK_REALTIME_RAW>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_SECOND

  static method CLOCK_SECOND : int ();

Get the constant value of C<CLOCK_SECOND>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_SOFTTIME

  static method CLOCK_SOFTTIME : int ();

Get the constant value of C<CLOCK_SOFTTIME>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_THREAD_CPUTIME_ID

  static method CLOCK_THREAD_CPUTIME_ID : int ();

Get the constant value of C<CLOCK_THREAD_CPUTIME_ID>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_TIMEOFDAY

  static method CLOCK_TIMEOFDAY : int ();

Get the constant value of C<CLOCK_TIMEOFDAY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_UPTIME

  static method CLOCK_UPTIME : int ();

Get the constant value of C<CLOCK_UPTIME>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_UPTIME_COARSE

  static method CLOCK_UPTIME_COARSE : int ();

Get the constant value of C<CLOCK_UPTIME_COARSE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_UPTIME_FAST

  static method CLOCK_UPTIME_FAST : int ();

Get the constant value of C<CLOCK_UPTIME_FAST>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_UPTIME_PRECISE

  static method CLOCK_UPTIME_PRECISE : int ();

Get the constant value of C<CLOCK_UPTIME_PRECISE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_UPTIME_RAW

  static method CLOCK_UPTIME_RAW : int ();

Get the constant value of C<CLOCK_UPTIME_RAW>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CLOCK_VIRTUAL

  static method CLOCK_VIRTUAL : int ();

Get the constant value of C<CLOCK_VIRTUAL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ITIMER_PROF

  static method ITIMER_PROF : int ();

Get the constant value of C<ITIMER_PROF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ITIMER_REAL

  static method ITIMER_REAL : int ();

Get the constant value of C<ITIMER_REAL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ITIMER_REALPROF

  static method ITIMER_REALPROF : int ();

Get the constant value of C<ITIMER_REALPROF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ITIMER_VIRTUAL

  static method ITIMER_VIRTUAL : int ();

Get the constant value of C<ITIMER_VIRTUAL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 TIMER_ABSTIME

  static method TIMER_ABSTIME : int ();

Get the constant value of C<TIMER_ABSTIME>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.
