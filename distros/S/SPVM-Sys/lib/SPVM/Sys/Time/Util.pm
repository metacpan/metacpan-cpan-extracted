package SPVM::Sys::Time::Util;



1;

=head1 Name

SPVM::Sys::Time::Util - Time Utilities

=head1 Description

The Sys::Time::Util class in L<SPVM> has utility methods to manipulate time.

=head1 Usage

  use Sys::Time::Util;

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

$ts must be defined. Otherwise an exception is thrown.

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

$tv must be defined. Otherwise an exception is thrown.

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

$ts must be defined. Otherwise an exception is thrown.

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

$tv must be defined. Otherwise an exception is thrown.

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

Calculates $tv_b minus $tv_a and returns it as floating seconds.

This method may result in a loss of precision.

Excetpions:

$tv_a must be defined. Otherwise an exception is thrown.

$tv_b must be defined. Otherwise an exception is thrown.

=head2 timespec_interval

C<static method timespec_interval : double ($ts_a : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>, $ts_b : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>);>

Calculates $ts_b minus $ts_a and returns it as floating seconds.

This method may result in a loss of precision.

Excetpions:

$ts_a must be defined. Otherwise an exception is thrown.

$ts_b must be defined. Otherwise an exception is thrown.

=head2 add_timespec

C<static method add_timespec : Sys::Time::Timespec ($ts : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>, $diff_ts : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>);>

Returns $ts plus $diff_ts.

Excetpions:

$ts must be defined. Otherwise an exception is thrown.

$diff_ts must be defined. Otherwise an exception is thrown.

=head2 add_timeval

C<static method add_timeval : Sys::Time::Timeval ($tv : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>, $diff_tv : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>);>

Returns $tv plus $diff_tv.

Excetpions:

$tv must be defined. Otherwise an exception is thrown.

$diff_tv must be defined. Otherwise an exception is thrown.

=head2 subtract_timespec

C<static method subtract_timespec : Sys::Time::Timespec ($ts : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>, $diff_ts : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>);>

Returns $ts minus $diff_ts.

Excetpions:

$ts must be defined. Otherwise an exception is thrown.

$diff_ts must be defined. Otherwise an exception is thrown.

=head2 subtract_timeval

C<static method subtract_timeval : Sys::Time::Timeval ($tv : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>, $diff_tv : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>);>

Returns $tv minus $diff_tv.

Excetpions:

$tv must be defined. Otherwise an exception is thrown.

$diff_tv must be defined. Otherwise an exception is thrown.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

