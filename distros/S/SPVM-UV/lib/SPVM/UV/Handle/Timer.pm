package SPVM::UV::Handle::Timer;



1;

=encoding utf8

=head1 Name

SPVM::UV::Handle::Timer - Timer Handle for libuv

=head1 Description

C<UV::Handle::Timer> in L<SPVM> represents the timer handle for L<libuv|https://libuv.org/>, corresponding to the C<uv_timer_t> structure.

=head1 Super Class

L<UV::Handle|SPVM::UV::Handle>

=head1 Usage

  use UV::Handle::Timer;
  
  my $timer = UV::Handle::Timer->new;

=head1 Fields

=head2 timer_cb

C<has timer_cb : rw L<UV::Callback::Timer|SPVM::UV::Callback::Timer>;>

The callback called when the timer timeout expires.

=head1 Class Methods

=head2 new

C<static method new : L<UV::Handle::Timer|SPVM::UV::Handle::Timer> ();>

Creates a new L<UV::Handle::Timer|SPVM::UV::Handle::Timer> object, and returns it.

=head1 Instance Methods

=head2 start

C<method start : void ($cb : L<UV::Callback::Timer|SPVM::UV::Callback::Timer>, $timeout_msec : long, $interval_msec : long = 0);>

Starts the timer with a timeout of C<$timeout_msec> milliseconds and a repeat interval of C<$interval_msec> milliseconds.

The callback C<$cb> is stored in L</"timer_cb"> field.

The callback C<$cb> is invoked when the timer timeout expires.

This method calls the L<uv_timer_start|https://docs.libuv.org/en/v1.x/timer.html#c.uv_timer_start> function internally.

Exceptions:

If $cb is not defined, an exception is thrown.

If uv_timer_start fails, an exception is thrown.

=head2 stop

C<method stop : void ();>

Stops the timer.

This method calls the L<uv_timer_stop|https://docs.libuv.org/en/v1.x/timer.html#c.uv_timer_stop> function internally.

Exceptions:

If uv_timer_stop fails, an exception is thrown.

=head2 again

C<method again : void ();>

Start the timer if it has a repeat value set.

This method calls the L<uv_timer_again|https://docs.libuv.org/en/v1.x/timer.html#c.uv_timer_again> function internally.

Exceptions:

If uv_timer_again fails, an exception is thrown.

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
