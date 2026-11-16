package SPVM::UV::Handle::Signal;

1;

=encoding utf8

=head1 Name

SPVM::UV::Handle::Signal - Signal Handle for libuv

=head1 Description

C<UV::Handle::Signal> in L<SPVM> represents the signal handle for L<libuv|https://libuv.org/>, corresponding to the C<uv_signal_t> structure.

=head1 Super Class

L<UV::Handle|SPVM::UV::Handle>

=head1 Usage

  use UV::Handle::Signal;
  
  my $signal = UV::Handle::Signal->new;

=head1 Fields

=head2 signal_cb

C<has signal_cb : rw L<UV::Callback::Signal|SPVM::UV::Callback::Signal>;>

The callback called when the signal is received.

=head1 Class Methods

=head2 new

C<static method new : L<UV::Handle::Signal|SPVM::UV::Handle::Signal> ();>

Creates a new L<UV::Handle::Signal|SPVM::UV::Handle::Signal> object, and returns it.

=head1 Instance Methods

=head2 start

C<method start : void ($cb : L<UV::Callback::Signal|SPVM::UV::Callback::Signal>, $signum : int);>

Starts the signal handle with the callback C<$cb> and the signal number C<$signum>. 

The callback C<$cb> is stored in L</"signal_cb"> field.

The callback C<$cb> is invoked when the signal C<$signum> is received.

This method calls the L<uv_signal_start|https://docs.libuv.org/en/v1.x/signals.html#c.uv_signal_start> function.

Exceptions:

If $cb is not defined, an exception is thrown.

If uv_signal_start fails, an exception is thrown.

=head2 stop

C<method stop : void ();>

Stops the signal handle.

This method calls the L<uv_signal_stop|https://docs.libuv.org/en/v1.x/signals.html#c.uv_signal_stop> function.

Exceptions:

If uv_signal_stop fails, an exception is thrown.

=head1 Repository

L<https://github.com/kimoto/SPVM-UV>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
