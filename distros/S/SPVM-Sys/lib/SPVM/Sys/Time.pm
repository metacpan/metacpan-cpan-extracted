package SPVM::Sys::Time;

1;

=head1 Name

SPVM::Sys::Time - System Calls for Time Manipulation

=head1 Description

The Sys::Process class in L<SPVM> has methods to call system calls for time manipulation.

=head1 Usage
  
  use Sys::Time;
  
  my $epoch = Sys::Time->time;
  
  my $time_info_local = Sys::Time->localtime($epoch);
  
  my $time_info_utc = Sys::Time->gmtime($epoch);

=head1 Class Methods

=head2 time

C<static method time : long ();>

Calls the L<time|https://linux.die.net/man/2/time> function and returns its return value.

=head2 localtime

C<static method localtime : L<Sys::Time::Tm|SPVM::Sys::Time::Tm> ($time_ref : long*);>

Calls the L<localtime|https://linux.die.net/man/3/localtime> function and creates a L<Sys::Time::Tm|SPVM::Sys::Time::Tm> object given its return value, and returns it.

=head2 gmtime

C<static method gmtime : L<Sys::Time::Tm|SPVM::Sys::Time::Tm> ($time_ref : long*);>

Calls the L<gmtime|https://linux.die.net/man/3/gmtime> function and creates a L<Sys::Time::Tm|SPVM::Sys::Time::Tm> object given its return value, and returns it.

=head2 gettimeofday

C<static method gettimeofday : int ($tv : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>, $tz : L<Sys::Time::Timezone|SPVM::Sys::Time::Timezone>);>

Calls the L<gmtime|https://linux.die.net/man/2/gettimeofday> function and creates a L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> object given its return value, and returns it.

Exceptions:

If the gettimeofday function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System>.

=head2 clock

C<static method clock : long ()>

Calls the L<clock|https://linux.die.net/man/3/clock> function, and returns its return value.

Exceptions:

If the clock function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System>.

=head2 clock_gettime

C<static method clock_gettime : int ($clk_id : int, $tp : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>);>

Calls the L<clock_gettime|https://linux.die.net/man/3/clock_gettime> function, and returns its return value.

See L<Sys::Time::Constant|SPVM::Sys::Time::Constant> about constant values given to $clk_id.

Exceptions:

$tp must be defined. Otherwise an exception is thrown.

If the clock_gettime function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System>.

=head2 clock_getres

C<static method clock_getres : int ($clk_id : int, $res : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>);>

Calls the L<clock_getres|https://linux.die.net/man/3/clock_getres> function, and returns its return value.

See L<Sys::Time::Constant|SPVM::Sys::Time::Constant> about constant values given to $clk_id.

Exceptions:

$res must be defined. Otherwise an exception is thrown.

If the clock_getres function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System>.

=head2 setitimer

C<static method setitimer : int ($which : int, $new_value : L<Sys::Time::Itimerval|SPVM::Sys::Time::Itimerval>, $old_value : L<Sys::Time::Itimerval|SPVM::Sys::Time::Itimerval>)>

Calls the L<setitimer|https://linux.die.net/man/2/setitimer> function, and returns its return value.

See L<Sys::Time::Constant|SPVM::Sys::Time::Constant> about constant values given to $which.

Exceptions:

$new_value must be defined. Otherwise an exception is thrown.

If the clock_getres function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System>.

In Windows the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. setitimer is not supported in this system(defined(_WIN32)).

=head2 getitimer

C<static method getitimer : int ($which : int, $curr_value : L<Sys::Time::Itimerval|SPVM::Sys::Time::Itimerval>);>

Calls the L<getitimer|https://linux.die.net/man/2/getitimer> function, and returns its return value.

See L<Sys::Time::Constant|SPVM::Sys::Time::Constant> about constant values given to $which.

Exceptions:

$curr_value must be defined. Otherwise an exception is thrown.

If the getitimer function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System>.

In Windows the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. getitimer is not supported in this system(defined(_WIN32)).

=head2 times

C<static method times : long ($buffer : L<Sys::Time::Tms|SPVM::Sys::Time::Tms>);>

Calls the L<times|https://linux.die.net/man/2/times> function, and returns its return value.

Exceptions:

$tms must be defined. Otherwise an exception is thrown.

If the times function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System>.

In Windows the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. times is not supported in this system(defined(_WIN32)).

=head2 clock_nanosleep

C<static method clock_nanosleep : int ($clockid : int, $flags : int, $request : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>, $remain : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>);>

Calls the L<clock_nanosleep|https://linux.die.net/man/2/clock_nanosleep> function, and returns its return value.

See L<Sys::Time::Constant|SPVM::Sys::Time::Constant> about constant values given to $clockid and $flags.

Exceptions:

$request must be defined. Otherwise an exception is thrown.

In Mac the following exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class. clock_nanosleep is not supported in this system(__APPLE__).

=head2 nanosleep

C<static method nanosleep : int ($rqtp : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>, $rmtp : L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>);>

Calls the L<nanosleep|https://linux.die.net/man/3/nanosleep> function, and returns its return value.

Exceptions:

$rqtp must be defined. Otherwise an exception is thrown.

If the nanosleep function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System>.

=head2 utime

C<static method utime : int ($filename : string, $times : L<Sys::Time::Utimbuf|SPVM::Sys::Time::Utimbuf>);>

Calls the L<utime|https://linux.die.net/man/2/utime> function, and returns its return value.

=head2 utimes

C<static method utimes : int ($filename : string, $times : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>[]);>

Calls the L<utimes|https://linux.die.net/man/2/utimes> function, and returns its return value.

The utime() system call changes the access and modification times of the inode specified by filename to the actime and modtime fields of times respectively.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

