package SPVM::Time::HiRes;

our $VERSION = '0.002';

1;

=head1 Name

SPVM::Time::HiRes - High Resolution Time

=head1 Description

The Time::HiRes class in L<SPVM> has methods to manipulate high resolution time.

=head1 Usage

  use Time::HiRes;
  use Sys::Time::Constant as TIME;
  use Sys::Time::Timeval;
  
  my $time = Time::HiRes->time;
  
  my $time = Time::HiRes->clock_gettime(TIME->CLOCK_MONOTONIC);
  
  Time::HiRes->sleep(3.5);
  
  Time::HiRes->usleep(3.5 * 1_000_000);
  
  my $time_tv = Time::HiRes->gettimeofday;
  
  {
    my $tv_a = Sys::Time::Timeval->new;
    $tv_a->set_tv_sec(1);
    $tv_a->set_tv_usec(900_000);
    
    my $tv_a = Sys::Time::Timeval->new;
    $tv_a->set_tv_sec(2);
    $tv_a->set_tv_usec(800_000);
    
    my $tv_interval = Time::HiRes->tv_interval($tv_a, $tv_b);
  }

=head1 Class Methods

=head2 gettimeofday

C<static method gettimeofday : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> ();>

Gets the time as a L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> object and returns it.

See the L<gettimeofday|SPVM::Sys::Time/"gettimeofday"> method in the Sys::Time class in detail.

Exceptions:

The exceptions thrown by the L<gettimeofday|SPVM::Sys::Time/"gettimeofday"> method in the Sys::Time class could be thrown.

=head2 usleep

C<static method usleep : int ($usec : int);>

Sleeps for microseconds $usec and returns remaining time.

See the L<usleep|SPVM::Sys::Process/"usleep"> method in the Sys::Time class in detail.

Exceptions:

The exceptions thrown by the L<usleep|SPVM::Sys::Process/"usleep"> method in the Sys::Time class could be thrown.

=head2 nanosleep

C<static method nanosleep : long ($nanoseconds : long);>

Sleeps for nanoseconds $nanoseconds and returns remaining time.

See the L<nanosleep|SPVM::Sys::Time/"nanosleep"> method in the Sys::Time class in detail.

Exceptions:

The exceptions thrown by the L<nanosleep|SPVM::Sys::Time/"nanosleep"> method in the Sys::Time class could be thrown.

=head2 tv_interval

C<static method tv_interval : double ($a : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>, $b : L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> = undef);>

Returns the floating seconds between the two times. If the second argument $b is omitted, then the current time is used.

=head2 time

C<static method time : double ();>

Gets the time.

=head2 sleep

C<static method sleep : double ($float_seconds : double);>

Sleeps for floating point seconds $float_seconds and retunrs remaining time.

Exceptions:

The exceptions thrown by the L<usleep|SPVM::Sys::Process/"usleep"> method in the Sys::Time class could be thrown.

=head2 alarm

C<static method alarm : double ($float_seconds : double, $interval_float_seconds : double = 0);>

Alarm after floating point seconds $float_seconds with or without the interval $interval_float_seconds.

Exceptions:

The exceptions thrown by the L<ualarm|SPVM::Sys::Signal/"ualarm"> method in the Sys::Time class could be thrown.

=head2 setitimer

C<static method setitimer : L<Time::HiRes::ItimervalFloat|SPVM::Time::HiRes::ItimervalFloat> ($which : int, $new_itimer_float : L<Time::HiRes::ItimervalFloat|SPVM::Time::HiRes::ItimervalFloat>);>

Start up an interval timer: after a certain time(and a interval) $new_itimer_float, a signal ($which) arrives.

See the L<setitimer|SPVM::Sys::Time/"setitimer"> method in the Sys::Time class in detail.

Exceptions:

The exceptions thrown by the L<setitimer|SPVM::Sys::Time/"setitimer"> method in the Sys::Time class could be thrown.

=head2 getitimer

C<static method getitimer : L<Time::HiRes::ItimervalFloat|SPVM::Time::HiRes::ItimervalFloat> ($which : int);>

Return the remaining time in the interval timer specified by $which.

See the L<getitimer|SPVM::Sys::Time/"getitimer"> method in the Sys::Time class in detail.

Exceptions:

The exceptions thrown by the L<getitimer|SPVM::Sys::Time/"getitimer"> method in the Sys::Time class could be thrown.

=head2 clock_gettime

C<static method clock_gettime : double ($clk_id : int)>

Returns the time of the specified clock $clk_id.

See L<Sys::Time::Constant|SPVM::Sys::Time::Constant> about constant values given to $clockid.

See the L<clock_gettime|SPVM::Sys::Time/"clock_gettime"> method in the Sys::Time class in detail.

Exceptions:

The exceptions thrown by the L<clock_gettime|SPVM::Sys::Time/"clock_gettime"> method in the Sys::Time class could be thrown.

=head2 clock_getres

C<static method clock_getres : double ($clk_id : int)>

Returns the resolution (precision) of the specified clock $clk_id.

See L<Sys::Time::Constant|SPVM::Sys::Time::Constant> about constant values given to $clockid.

See the L<clock_getres|SPVM::Sys::Time/"clock_getres"> method in the Sys::Time class in detail.

Exceptions:

The exceptions thrown by the L<clock_getres|SPVM::Sys::Time/"clock_getres"> method in the Sys::Time class could be thrown.

=head2 clock_nanosleep

C<static method clock_nanosleep : long ($clockid : int, $nanoseconds : long, $flags : int = 0);>

Sleeps for nanoseconds $nanoseconds and returns remaining time.

See L<Sys::Time::Constant|SPVM::Sys::Time::Constant> about constant values given to $clockid and $flags.

See the L<clock_nanosleep|SPVM::Sys::Time/"clock_nanosleep"> method in the Sys::Time class in detail.

Exceptions:

The exceptions thrown by the L<clock_nanosleep|SPVM::Sys::Time/"clock_nanosleep"> method in the Sys::Time class could be thrown.

=head2 clock

C<static method clock : long ();>

Returns an approximation of processor time used by the program.

See the L<clock|SPVM::Sys::Time/"clock"> method in the Sys::Time class in detail.

Exceptions:

The exceptions thrown by the L<clock|SPVM::Sys::Time/"clock"> method in the Sys::Time class could be thrown.

=head1 See Also

=over 2

=item * L<Time::HiRes::Util|SPVM::Time::HiRes::Util>

=item * L<Time::HiRes::ItimervalFloat|SPVM::Time::HiRes::ItimervalFloat>

=back

=head1 Repository

L<SPVM::Time::HiRes - Github|https://github.com/yuki-kimoto/SPVM-Time-HiRes>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
