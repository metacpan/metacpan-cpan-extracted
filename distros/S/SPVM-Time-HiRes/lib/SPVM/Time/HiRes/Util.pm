package SPVM::Time::HiRes::Util;



1;

=head1 Name

SPVM::Time::HiRes::Util - Short Description

=head1 Description

The Time::HiRes::Util class of L<SPVM> has utility methods to manipulate high resolution time.

=head1 Usage

  use Time::HiRes::Util;

=head1 Class Methods

=head2 nanoseconds_to_timespec

C<static method nanoseconds_to_timespec : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec> ($nanoseconds : long);>

Converts nanoseconds $nanoseconds to a L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec> object, and returns it.

Exceptions:

$nanoseconds must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 timespec_to_nanoseconds

C<static method timespec_to_nanoseconds : long ($ts : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>);>

Converts the L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec> object $ts to nanoseconds, and returns it.

This method could cause overflow.

Exceptions:

$ts->tv_sec must be greater than or equal to 0. Otherwise an exception is thrown.

$ts->tv_nsec must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 microseconds_to_timeval

C<static method microseconds_to_timeval : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> ($microseconds : long);>

Converts microseconds $microseconds to a L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> object, and returns it.

Exceptions:

$microseconds must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 timeval_to_microseconds

C<static method timeval_to_microseconds : double ($tv : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>);>

Converts the L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> object $tv to microseconds, and returns it.

This method could cause overflow.

Exceptions:

$tv->tv_sec must be greater than or equal to 0. Otherwise an exception is thrown.

$tv->tv_usec must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 float_seconds_to_timespec

C<static method float_seconds_to_timespec : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec> ($float_seconds : double);>

Converts floating seconds $float_seconds to a L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec> object, and returns it.

This method may result in a loss of precision.

Exceptions:

$float_seconds must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 timespec_to_float_seconds

C<static method timespec_to_float_seconds : double ($ts : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>);>

Converts the L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec> object $ts to floating seconds, and returns it.

This method may result in a loss of precision.

Exceptions:

$ts->tv_sec must be greater than or equal to 0. Otherwise an exception is thrown.

$ts->tv_nsec must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 float_seconds_to_timeval

C<static method float_seconds_to_timeval : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> ($float_seconds : double);>

Converts floating seconds $float_seconds to a L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> object, and returns it.

This method may result in a loss of precision.

Exceptions:

$float_seconds must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 timeval_to_float_seconds

C<static method timeval_to_float_seconds : double ($tv : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>);>

Converts the L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> object $tv to floating seconds, and returns it.

This method may result in a loss of precision.

Exceptions:

$tv->tv_sec must be greater than or equal to 0. Otherwise an exception is thrown.

$tv->tv_usec must be greater than or equal to 0. Otherwise an exception is thrown.
    
=head2 float_seconds_to_nanoseconds

C<static method float_seconds_to_nanoseconds : long ($float_seconds : double);>

Converts floating seconds $float_seconds to nanoseconds, and returns it.

This method may result in a loss of precision.

Excetpions:

$float_seconds must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 nanoseconds_to_float_seconds

C<static method nanoseconds_to_float_seconds : double ($nanoseconds : long);>

Converts nanoseconds $nanoseconds to floating seconds, and returns it.

This method may result in a loss of precision.

Excetpions:

$nanoseconds must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 float_seconds_to_microseconds

C<static method float_seconds_to_microseconds : long ($float_seconds : double);>

Converts floating seconds $float_seconds to microseconds, and returns it.

This method may result in a loss of precision.

Excetpions:

$float_seconds must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 microseconds_to_float_seconds

C<static method microseconds_to_float_seconds : double ($microseconds : long);>

Converts microseconds $microseconds to floating seconds, and returns it.

This method may result in a loss of precision.

Excetpions:

$float_seconds must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 timeval_interval

C<static method timeval_interval : double ($tv_a : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>, $tv_b : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>);>

Calculates $tv_b - $tv_a and returns it as floating seconds.

This method may result in a loss of precision.

Excetpions:

$tv_a->tv_sec must be greater than or equal to 0. Otherwise an exception is thrown.

$tv_a->tv_usec must be greater than or equal to 0. Otherwise an exception is thrown.

$tv_b->tv_sec must be greater than or equal to 0. Otherwise an exception is thrown.

$tv_b->tv_usec must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 timespec_interval

C<static method timespec_interval : double ($ts_a : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>, $ts_b : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>);>

Calculates $ts_b - $ts_a and returns it as floating seconds.

This method may result in a loss of precision.

Excetpions:

$ts_a->tv_sec must be greater than or equal to 0. Otherwise an exception is thrown.

$ts_a->tv_nsec must be greater than or equal to 0. Otherwise an exception is thrown.

$ts_b->tv_sec must be greater than or equal to 0. Otherwise an exception is thrown.

$ts_b->tv_nsec must be greater than or equal to 0. Otherwise an exception is thrown.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

