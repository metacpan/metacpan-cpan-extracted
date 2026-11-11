package SPVM::UV::Handle::Poll;



1;

=encoding utf8

=head1 Name

SPVM::UV::Handle::Poll - Poll Handle for libuv

=head1 Description

C<UV::Handle::Poll> in L<SPVM> represents the poll handle for L<libuv|https://libuv.org/>, corresponding to the C<uv_poll_t> structure.

=head1 Super Class

L<UV::Handle|SPVM::UV::Handle>

=head1 Usage

  use UV::Handle::Poll;
  
  my $poll = UV::Handle::Poll->new;

=head1 Fields

=head2 poll_cb

C<has poll_cb : rw L<UV::Callback::Poll|SPVM::UV::Callback::Poll>;>

The callback called when file descriptor events occur.

=head1 Class Methods

=head2 new

C<static method new : L<UV::Handle::Poll|SPVM::UV::Handle::Poll> ();>

Creates a new L<UV::Handle::Poll|SPVM::UV::Handle::Poll> object, and returns it.

=head1 Instance Methods

=head2 start

C<method start : void ($cb : L<UV::Callback::Poll|SPVM::UV::Callback::Poll>, $events : int);>

Starts polling the file descriptor for events specified by C<$events> with the callback C<$cb>. 

The callback C<$cb> is stored in L</"poll_cb"> field.

The callback C<$cb> is invoked when the specified events occur.

This method calls the L<uv_poll_start|https://docs.libuv.org/en/v1.x/poll.html#c.uv_poll_start> function.

Exceptions:

If $cb is not defined, an exception is thrown.

If uv_poll_start fails, an exception is thrown.

=head2 stop

C<method stop : void ();>

Stops polling the file descriptor.

This method calls the L<uv_poll_stop|https://docs.libuv.org/en/v1.x/poll.html#c.uv_poll_stop> function.

Exceptions:

If uv_poll_stop fails, an exception is thrown.

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
